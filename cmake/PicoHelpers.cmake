# cmake/PicoHelpers.cmake

# Example helper: wrap add_executable by auto-linking pico_stdlib
function(pico_exe name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} PRIVATE pico_stdlib)
    pico_add_extra_outputs(${name})
endfunction()

# Example helper: a pin-map sanity check
function(check_pin pin)
    if (pin LESS 0 OR pin GREATER 29)
        message(FATAL_ERROR "GPIO${pin} is out of range on the RP2040")
    endif()
endfunction()