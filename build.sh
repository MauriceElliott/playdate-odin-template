#!/usr/bin/env bash

# Expectations of the below script
# The playdateSDK is in your home directory
# If this is incorrect, update the below PLAYDATE_SDK_PATH variable
# The first phase builds using the Odin Compiler
# The second phase links upsing the link_map.ld provided by the playdateSDK
# Finally the third phase builds an x86 version of the binary so it can launch in the simulator
# We also zip the device version and put it in the build output folder
# so that it can be quickly picked up and sideloaded onto the playdate.

set -e

PLAYDATE_SDK_PATH=${PLAYDATE_SDK_PATH:-$HOME/PlaydateSDK}
PDSIM=${PDSIM:-$PLAYDATE_SDK_PATH/bin/PlaydateSimulator}

# 
PRODUCT_NAME=Template
BUILD_DIR=build
DEVICE_DIR=$BUILD_DIR/device
SOURCE_DIR=$BUILD_DIR/Source
PDX_DIR=$BUILD_DIR/$PRODUCT_NAME.pdx
GAME_PATH=$PLAYDATE_SDK_PATH/Disk/Games/$PRODUCT_NAME.pdx
LIB_EXT=so

# macOS specific adjustments
if [[ "$(uname)" = "Darwin" ]]; then
    LIB_EXT=dylib
    PDSIM=${PDSIM:-$PLAYDATE_SDK_PATH/bin/PlaydateSimulator} # TODO: Update this value to match MacOS setup.
fi

# Pre build cleanup
rm -rf "$DEVICE_DIR" "$SOURCE_DIR" "$PDX_DIR"
mkdir -p "$DEVICE_DIR" "$SOURCE_DIR"

odin build src/ \
    -out:$DEVICE_DIR/pdex \
    -build-mode:obj \
    -target:freestanding_arm32 \
    -subtarget:playdate \
    -no-thread-local \
    -disable-unwind \
    -default-to-nil-allocator

arm-none-eabi-gcc \
    -I "$PLAYDATE_SDK_PATH/C_API" \
    -DTARGET_PLAYDATE=1 \
    -DTARGET_EXTENSION=1 \
    -D__FPU_USED=1 \
    -D__HEAP_SIZE=8388208 \
    -D__STACK_SIZE=61800 \
    -mthumb \
    -mcpu=cortex-m7 \
    -mfloat-abi=hard \
    -mfpu=fpv5-sp-d16 \
    -nostartfiles \
    -T "$PLAYDATE_SDK_PATH/C_API/buildsupport/link_map.ld" \
    -Wl,-Map=$DEVICE_DIR/pdex.map,--cref,--gc-sections,--no-warn-mismatch,--emit-relocs,--allow-multiple-definition,--defsym=__exidx_start=0,--defsym=__exidx_end=0 \
    -o "$SOURCE_DIR/pdex.elf" \
    "$PLAYDATE_SDK_PATH/C_API/buildsupport/setup.c" \
    $DEVICE_DIR/pdex-*.obj

odin build src/ \
    -out:$SOURCE_DIR/pdex.$LIB_EXT \
    -build-mode:dll \
    -default-to-nil-allocator

cp src/pdxinfo "$SOURCE_DIR/"
if [[ -d src/assets ]]; then
    cp -r src/assets "$SOURCE_DIR/"
fi

"$PLAYDATE_SDK_PATH/bin/pdc" --skip-unknown "$SOURCE_DIR" "$PDX_DIR"

# rm -rf "$GAME_PATH"
# ln -s "$(pwd)/$PDX_DIR" "$GAME_PATH"

cd build
zip -r Template.pdx.zip Template.pdx

cd ..

$PDSIM "$GAME_PATH"
