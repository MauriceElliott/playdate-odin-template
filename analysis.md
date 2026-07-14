# Playdate Subtarget Analysis

## The Problem

Using `-subtarget:playdate` causes `core:math` functions (e.g. `sin`) to produce wrong results or crash at runtime. The same code works when dropping the subtarget and using explicit `-target-features`.

## Root Cause

The playdate subtarget sets `microarch = "cortex-m7"`, which pulls in the full Cortex-M7 feature list from `build_settings_microarch.cpp`. That list assumes a **full double-precision FPU** — but the Playdate's Cortex-M7 has the **FPv5-SP-D16** variant, which is **single-precision only**.

The LLVM backend sees `fp-armv8d16`, `fp64`, `vfp4d16` etc. enabled, generates double-precision FP instructions, and those instructions trap on the Playdate hardware.

A secondary issue: `fpregs64` tells LLVM that 64 FP registers are available for AAPCS-VFP parameter passing, but the hardware has 16 double-precision / 32 single-precision registers. This corrupts the calling convention for multi-arg float functions.

---

## Feature-by-Feature Comparison

Features are from two sources:

- **Subtarget**: `microarch = "cortex-m7"` (LLVM 22+, line 395 of `build_settings_microarch.cpp`)
- **Working**: explicit `-target-features` from the known-good build command, mapped to valid Odin feature names

### Features in subtarget (cortex-m7) but NOT in working set

| Feature | Impact | Verdict |
|---|---|---|
| `branch-align-64` | Pipeline scheduling hint for Cortex-A class. No-op on M7. | **no** |
| `fp-armv8d16` | ARMv8 FP with 16 **double-precision** registers. Playdate FPU only does SP. LLVM emits DP instructions that trap. | **yes** |
| `fp16` | Half-precision float support. Playdate doesn't have it. Unlikely to be exercised by `sin`/`cos`. | **maybe** |
| `fp64` | Explicit double-precision FP enable. Same as `fp-armv8d16` — causes DP instruction emission. | **yes** |
| `fpregs64` | 64 FP registers for AAPCS-VFP parameter passing. Playdate has 16 (32 SP). Multi-arg float calls use wrong register indices. | **yes** |
| `use-mipipeliner` | MI pipeline scheduling. Harmless. | **no** |
| `use-misched` | Machine instruction scheduler. Harmless. | **no** |
| `v8m` | ARMv8-M architecture extension. Cortex-M7 is ARMv7E-M. Enables instructions (TT, VLLDM, VLSTM) that don't exist. | **maybe** |
| `vfp2`, `vfp2sp` | Superseded by VFPv4 features. Redundant but harmless. | **no** |
| `vfp3d16` | VFPv3 with 16 DP registers. Same DP problem. | **yes** |
| `vfp3d16sp` | VFPv3 SP (superseded). Harmless. | **no** |
| `vfp4d16` | VFPv4 with 16 DP registers. Same DP problem. | **yes** |

### Features in working set but NOT in subtarget (cortex-m7)

| Feature | Impact | Verdict |
|---|---|---|
| `fpregs16` | 16 FP registers for AAPCS-VFP parameter passing. The correct count for FPv5-SP-D16. | **yes** |

**All other features in the working set are already present in the cortex-m7 defaults.**

### Features in subtarget's `target_features_string` (appended by subtarget code)

| Feature | Impact | Verdict |
|---|---|---|
| `no-movt` | Suppresses MOVW/MOVT relocations. Required by Playdate linker. | **yes** (keep) |

---

## Why Removing Features From cortex-m7 Doesn't Work

Naively removing individual features from the cortex-m7 defaults (e.g. `-target-features:-fp-armv8d16,-fp64,...`) causes LLVM "Cannot select" crashes on basic operations like branches. The cortex-m7 feature set is internally consistent — mixing features from it with removals creates contradictions in LLVM's subtarget definition. The triplet `thumbv7em-none-eabihf` plus cortex-m7 features creates a specific LLVM subtarget, and surgically removing pieces breaks it.

The working approach starts from a **blank slate** (`microarch = "generic"` → no features for arm32) and adds only what's needed.

---

## Fixes Required in Odin

Two files need changes in `/home/maurice/repos/Odin/src/`:

### 1. `build_settings.cpp` (lines ~1962–1971)

Replace the current playdate block:

```cpp
} else if (subtarget == Subtarget_Playdate) {
    // Playdate uses the cortex-m7 as well and an FPU, requiring thumb instructions and hard floats.
    bc->microarch = str_lit("cortex-m7");
    bc->metrics.target_triplet = str_lit("thumbv7em-none-eabihf");
    // Remove MOVW/MOVT instructions as playdate only handles R_ARM_ABS32 relocations.
    if(bc->target_features_string.len > 0) {
        bc->target_features_string = concatenate_strings(permanent_allocator(), bc->target_features_string, str_lit(",no-movt"));
    } else {
        bc->target_features_string = str_lit("no-movt");
    }
}
```

With:

```cpp
} else if (subtarget == Subtarget_Playdate) {
    // Playdate uses a Cortex-M7 with FPv5-SP-D16 (single-precision only).
    // Start from a blank microarch baseline and set features explicitly.
    bc->microarch = str_lit("generic");
    bc->metrics.target_triplet = str_lit("thumbv7em-none-eabihf");

    // Explicit feature set matching the Playdate's FPv5-SP-D16 FPU.
    // Single-precision only: no fp-armv8d16, no fp64, no vfp4d16.
    // fpregs16 for correct AAPCS-VFP register count.
    // no-movt because Playdate linker only handles R_ARM_ABS32.
    String const playdate_features = str_lit("armv7e-m,thumb-mode,thumb2,mclass,m7,noarm,hwdiv,dsp,db,fp-armv8d16sp,vfp4d16sp,fpregs,fpregs16,v7,v7clrex,v6m,v6t2,v6k,v6,v5te,v5t,v4t,no-movt");

    if(bc->target_features_string.len > 0) {
        bc->target_features_string = concatenate3_strings(permanent_allocator(), playdate_features, str_lit(","), bc->target_features_string);
    } else {
        bc->target_features_string = playdate_features;
    }
}
```

Key changes:
- `microarch` = `"generic"` (no inherited features)
- Explicit feature list that's single-precision only
- `fpregs16` instead of `fpregs64`
- `no-movt` folded into the main feature string
- User-supplied `-target-features` are still appended after the defaults

### 2. `llvm_backend_proc.cpp` (lines 454–458 and 998–1001)

The forced `ARM_AAPCS_VFP` calling convention override is **not the root cause** but is also unnecessary. When `microarch = "generic"` and the triplet is `thumbv7em-none-eabihf` with `fpregs`, LLVM's default `C` calling convention already maps to AAPCS-VFP. The override can stay or be removed — it's cosmetic.

---

## Test Plan

1. Apply the `build_settings.cpp` change above
2. Rebuild Odin
3. In the playdate-odin-template, revert `build.sh` to use `-subtarget:playdate` (no manual `-target-features`)
4. Build and verify `sin` produces correct values
