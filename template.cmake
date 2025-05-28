# Check [pico-sdk]
if (NOT DEFINED ENV{PICO_SDK_PATH})
    message(FATAL_ERROR "Environment variable PICO_SDK_PATH is not set")
endif()
get_filename_component(_PICO_SDK_DIR
        "${CMAKE_BINARY_DIR}/$ENV{PICO_SDK_PATH}"
        REALPATH
)

# Include the SDK import
include("${_PICO_SDK_DIR}/external/pico_sdk_import.cmake")

# Check [picotool]
get_filename_component(_PICOTOOL_DIR
        "${CMAKE_SOURCE_DIR}/$ENV{PICOTOOL_FETCH_FROM_GIT_PATH}"
        REALPATH
)
set(PICOTOOL_FETCH_FROM_GIT_PATH "${_PICOTOOL_DIR}" CACHE PATH "" FORCE)

# Warn if not found
if (NOT EXISTS "${PICOTOOL_FETCH_FROM_GIT_PATH}")
    message(WARNING "Your shared picotool path does not exist: ${PICOTOOL_FETCH_FROM_GIT_PATH}")
endif()