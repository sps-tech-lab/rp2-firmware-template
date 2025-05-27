
# PICO CMAKE PROJECT

---

### What you need to do
Clone the Pico SDK (if you haven’t already):
```
git clone https://github.com/raspberrypi/pico-sdk.git
```
Ensure your presets (or your shell) set:
```
PICO_SDK_PATH=../../pico-sdk   # relative to your build folder
```

Verify that file exists:
```
ls ../../pico-sdk/external/pico_sdk_import.cmake
```
template.cmake will then successfully include it, bringing in all of the SDK machinery.

---

### Dependencies

For this project [pico-sdk](https://github.com/raspberrypi/pico-sdk) is supposed to be placed in the same directory as the ```project folder``` placed

---

### Compiler

In the latest Pico-SDK workflow the SDK does not bundle its own compiler—you’re expected to install and manage 
the ARM GCC toolchain yourself.

#### MacOS

Install the ARM Embedded GCC toolchain
```shell
# Homebrew
brew tap ArmMbed/homebrew-formulae
brew install arm-none-eabi-gcc cmake

# Ports
sudo port selfupdate
sudo port install arm-none-eabi-gcc arm-none-eabi-binutils
```
By default MacPorts binaries live in /opt/local/bin, so in your shell init (e.g. ~/.zshrc) you should have:
```export PATH=/opt/local/bin:/opt/local/sbin:$PATH```

Once arm-none-eabi-gcc is on your PATH and PICO_SDK_PATH is set, the Pico-SDK’s CMake logic will automatically pick
the correct pico_arm_cortex_m0plus_gcc.cmake toolchain file, and your macOS build should succeed just like on Windows.