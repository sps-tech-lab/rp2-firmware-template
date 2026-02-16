# Check [pico-sdk]
if (NOT DEFINED ENV{PICO_SDK_PATH})
    message(FATAL_ERROR "[BRINGUP HELPER] Environment variable PICO_SDK_PATH is not set")
else()
    message(STATUS "[BRINGUP HELPER] Detected PICO_SDK_PATH = $ENV{PICO_SDK_PATH}")
endif()
get_filename_component(_PICO_SDK_DIR
        "$ENV{PICO_SDK_PATH}"
        REALPATH
)
message(STATUS "[BRINGUP HELPER] Resolved PICO_SDK_PATH → ${_PICO_SDK_DIR}")


# Include the SDK import
include("${_PICO_SDK_DIR}/external/pico_sdk_import.cmake")
message(STATUS "[BRINGUP HELPER] Included pico_sdk_import.cmake")


# Check [picotool]
if (NOT DEFINED ENV{PICOTOOL_FETCH_FROM_GIT_PATH})
    message(STATUS "[BRINGUP HELPER] Variable PICOTOOL_FETCH_FROM_GIT_PATH not set; using default")
    set(PICOTOOL_FETCH_FROM_GIT_PATH "${CMAKE_SOURCE_DIR}/third_party/picotool")
endif()


# Warn if not found
if (NOT EXISTS "${PICOTOOL_FETCH_FROM_GIT_PATH}")
    message(WARNING "[BRINGUP HELPER] Your shared picotool path does not exist: ${PICOTOOL_FETCH_FROM_GIT_PATH}")
else()
    message(STATUS "[BRINGUP HELPER] Resolved PICOTOOL_FETCH_FROM_GIT_PATH → ${PICOTOOL_FETCH_FROM_GIT_PATH}")
endif()