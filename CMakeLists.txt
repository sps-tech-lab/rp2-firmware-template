cmake_minimum_required(VERSION 3.19)

# Tests
if(RP2_ENABLE_TESTS)
  project(rp2-firmware-template LANGUAGES C CXX)

  # Enable clang-tools like targets
  include(cmake/clang_tools.cmake)
  rp2_enable_clang_tools()

  # Shared libraries
  add_subdirectory(src/demo)

  enable_testing()
  add_subdirectory(tests)
  return()
endif()

# Check [pico-sdk] and [picotool]
include(cmake/bringup_helper.cmake)

# Include the SDK import
include(pico_sdk_import.cmake)

# Project name
project(rp2-firmware-template LANGUAGES C CXX ASM)

# Enable clang-tools like targets
include(cmake/clang_tools.cmake)
rp2_enable_clang_tools()

# Shared libraries
add_subdirectory(src/demo)

# Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Add executables
add_executable(${PROJECT_NAME}
        app/main.c
        src/demo/demo.cpp
        src/demo/demo.hpp
)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries(${PROJECT_NAME} pico_stdlib demo)

# Create map/bin/hex/uf2 file in addition to ELF.
pico_add_extra_outputs(${PROJECT_NAME})

# Add ELF size table to build report
include(cmake/pico_size_tool.cmake)

# Add extension board (if it specified)
if(DEFINED EXT_BOARD AND NOT EXT_BOARD STREQUAL "")
    message(STATUS "Using extension board [${EXT_BOARD}] specifics")
    include(ext_boards/${EXT_BOARD}/ext_board.cmake)
endif()