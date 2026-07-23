# Odin for Playdate!

This is a repo that gives a short, simple setup for compiling and running Odin for the playdate simulator as well as the playdate hardware. This is currently untested on anything but linux, but within the coming weeks will have support for both MacOS and then Windows.

---

## Prerequisites
1. PlaydateSDK installed and PLAYDATE_SDK_PATH set and available in your shell session.
2. The latest Odin compiler, see [the documentation](https://odin-lang.org/docs/install/) for details in installation.
3. Cross Compilation development enabled see [the osdevwiki documentation](https://wiki.osdev.org/GCC_Cross-Compiler#Which_compiler_version_to_choose) on the subject for further details. For me on gentoo it was as simple as `sudo emerge -av crossdev`, on macOS use `brew install arm-none-eabi-gcc`. I will update this section when I have more details.

## Setup
1. Update the following variables within the `build.sh` file:
```bash
PROJ_NAME=Template
AUTHOR="Maurice Elliott"
DESC="A playdate game template for the Odin programming language."
BUNDLEID="com.mme.odintemplate"
VERSION="0.1.0"
```
2. Run `./build.sh` from your shell
3. ???
4. Profit. (sorry)

If everything was setup correctly the simulator should pop up displaying the following:
If you'd like to sideload it onto your playdate a zip of the pdx was created in the build folder.

## Remaining work
- [ ] MacOS once over
- [ ] Windows Support
- [ ] Extra Examples
