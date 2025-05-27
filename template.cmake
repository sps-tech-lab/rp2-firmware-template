# Import the Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Let CMake pick up whatever generator you’re already using
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Make presets.json from .def
execute_process(
        COMMAND ${Python3_EXECUTABLE}
        ${CMAKE_CURRENT_LIST_DIR}/generate_presets.py
        --generator "${CMAKE_GENERATOR}"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Pull in any helper functions you’ve put under cmake/
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
include(PicoHelpers)
