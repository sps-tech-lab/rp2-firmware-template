cmake_minimum_required(VERSION 3.19)

# Fetch/build picotool
set(PICOTOOL_FETCH_FROM_GIT_PATH "${CMAKE_SOURCE_DIR}/third_party/picotool")

# Include the SDK import
include(pico_sdk_import.cmake)

# Project name
project(pico-cmake-project)

# Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# Add executables
add_executable(main
        main.c
)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries(main pico_stdlib)

# Create map/bin/hex/uf2 file in addition to ELF.
pico_add_extra_outputs(main)