cmake_minimum_required(VERSION 3.13)

# Provide an entry-point function
function(pico_template_start proj_name)
    # import SDK
    include(${CMAKE_CURRENT_LIST_DIR}/template.cmake)
    # project name, languages
    project(${proj_name} C CXX ASM)
    pico_sdk_init()
endfunction()

function(pico_template_end)
    # default executable wiring
    pico_add_extra_outputs(${PROJECT_NAME})
endfunction()
