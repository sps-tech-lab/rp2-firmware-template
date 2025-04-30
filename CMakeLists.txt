cmake_minimum_required(VERSION 3.22)

#Fetch external content
include(FetchContent)
FetchContent_Declare(
        pico_sdk
        GIT_REPOSITORY https://github.com/raspberrypi/pico-sdk
        GIT_TAG 2.1.1
        GIT_SHALLOW TRUE)
if(NOT PICO_SDK_PATH)
    message(WARNING "There is no <pico-sdk> yet, it will take some time to fetch it...")
endif()
FetchContent_MakeAvailable(pico_sdk)

# Initialize the SDK
set(PICOTOOL_FETCH_FROM_GIT_PATH ON)
include(${CMAKE_BINARY_DIR}/_deps/pico_sdk-src/pico_sdk_init.cmake)

#Project
project(pico-cmake-project)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# Add an executable to the project
add_subdirectory(app)
