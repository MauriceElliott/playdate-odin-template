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

# Update to your own desired values.
PROJ_NAME=Template
AUTHOR="Maurice Elliott"
DESC="A playdate game template for the Odin programming language."
BUNDLEID="com.mme.odintemplate"
VERSION="0.1.0"

PLAYDATE_SDK_PATH=${PLAYDATE_SDK_PATH:-$HOME/PlaydateSDK}
PDSIM=${PDSIM:-$PLAYDATE_SDK_PATH/bin/PlaydateSimulator}

BUILD_DIR=build
STAGING_DIR=$BUILD_DIR/staging
PDX_DIR=$BUILD_DIR/$PROJ_NAME.pdx
GAME_PATH=$PLAYDATE_SDK_PATH/Disk/Games/$PROJ_NAME.pdx
LIB_EXT=so
OBJ_EXT="obj"

# macOS specific adjustments
if [[ "$(uname)" = "Darwin" ]]; then
    LIB_EXT=dylib
    PDSIM=${PDSIM:-$PLAYDATE_SDK_PATH/bin/PlaydateSimulator} # TODO: Update this value to match MacOS setup.
    OBJ_EXT="o"
fi

# Pre build cleanup
rm -rf "$STAGING_DIR" "$PDX_DIR"
mkdir -p "$STAGING_DIR"

# Clone the odin-playdate-api
if [[ ! -d "./packages/playdate-api" ]]; then
    cd packages
    git clone https://www.github.com/MauriceElliott/odin-playdate-api ./playdate-api
    cd ..
fi

# Produces the Odin Object Files
odin build src/ \
    -out:$STAGING_DIR/pdex \
    -build-mode:obj \
    -target:freestanding_arm32 \
    -subtarget:playdate \
    -default-to-nil-allocator \
    -no-thread-local \
    -disable-unwind

# Using the link_map.ld and the setup.c, this links the individual object files together
arm-none-eabi-gcc \
    -I "$PLAYDATE_SDK_PATH/C_API" \
    -DTARGET_PLAYDATE=1 \
    -DTARGET_EXTENSION=1 \
    -D__FPU_USED=1 \
    -D__HEAP_SIZE=8388208 \
    -D__STACK_SIZE=61800 \
    -mthumb \
    -specs=nosys.specs \
    -mcpu=cortex-m7 \
    -mfloat-abi=hard \
    -mfpu=fpv5-sp-d16 \
    -nostartfiles \
    -T "$PLAYDATE_SDK_PATH/C_API/buildsupport/link_map.ld" \
    -Wl,-Map=$STAGING_DIR/pdex.map,--cref,--gc-sections,--no-warn-mismatch,--emit-relocs,--allow-multiple-definition,--defsym=__exidx_start=0,--defsym=__exidx_end=0 \
    -o "$STAGING_DIR/pdex.elf" \
    "$PLAYDATE_SDK_PATH/C_API/buildsupport/setup.c" \
    $STAGING_DIR/pdex-*.$OBJ_EXT

# Produce a binary for the simulator and add it to the staging director.
odin build src/ \
    -out:$STAGING_DIR/pdex.$LIB_EXT \
    -build-mode:dll \
    -default-to-nil-allocator

# Copy the pdxinfo and asset folder into the staging directory
# Set all the required values in the pdxinfo file.
sed -e "s/{{version}}/$VERSION/" \
    -e "s/{{buildNumber}}/$(date +"%y%m%d%H%M%S")/" \
    -e "s/{{projName}}/$PROJ_NAME/" \
    -e "s/{{author}}/$AUTHOR/" \
    -e "s/{{description}}/$DESC/" \
    -e "s/{{bundleID}}/$BUNDLEID/" \
    src/pdxinfo > "$STAGING_DIR/pdxinfo"

if [[ -d src/assets ]]; then
    cp -r src/assets "$STAGING_DIR/"
fi

# Produce the pdx file using the playdate compiler.
"$PLAYDATE_SDK_PATH/bin/pdc" --skip-unknown "$STAGING_DIR" "$PDX_DIR"

# Produce a pdx zip that can be sideloaded.
cd build
zip -r $PROJ_NAME.pdx.zip $PROJ_NAME.pdx
mv $PROJ_NAME.pdx.zip ../
cd ..

# Simlink so that it can be launched in the simulator.
if [[ ! -L "$GAME_PATH" ]]; then
    ln -s "$(realpath "$PDX_DIR")" "$GAME_PATH"
fi

$PDSIM "$GAME_PATH"
