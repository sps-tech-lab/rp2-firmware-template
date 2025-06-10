cmake_minimum_required(VERSION 3.19)

# Check [pico-sdk] and [picotool]
include(cmake/bringup_helper.cmake)

# Include the SDK import
include(pico_sdk_import.cmake)

# Project name
project(pico-cmake-project)

# Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# Add executables
add_executable(${PROJECT_NAME}
        app/main.c
)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries(${PROJECT_NAME} pico_stdlib)

# Create map/bin/hex/uf2 file in addition to ELF.
pico_add_extra_outputs(${PROJECT_NAME})

# Add "size" feature
find_program(ELF_SIZE_EXECUTABLE
        NAMES size
        HINTS ENV PATH
)
if (NOT ELF_SIZE_EXECUTABLE)
    message(FATAL_ERROR "Could not find 'size' in your PATH")
else()
    message(STATUS "Using size tool: ${ELF_SIZE_EXECUTABLE}")
endif()
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "===== ${PROJECT_NAME} ELF size ====="
        COMMAND ${ELF_SIZE_EXECUTABLE} --format=gnu $<TARGET_FILE:${PROJECT_NAME}>
)
