cmake_minimum_required(VERSION 3.16)

# Set custom size tool
set(PICO_SIZE_TOOL "${CMAKE_SOURCE_DIR}/scripts/pico_size_tool.py")

# Check size existing options
find_program(ELF_SIZE_EXECUTABLE
        NAMES
        arm-none-eabi-size      # GCC ARM toolchain (Win/Linux/macOS)
        gsize                   # GNU binutils via Homebrew on macOS
        size                    # BSD size on macOS / GNU on Linux
        HINTS
        ENV PATH
)
if (ELF_SIZE_EXECUTABLE)
    message(STATUS "Basic size tool: ${ELF_SIZE_EXECUTABLE}")
else()
    message(WARNING "No 'size' program found in PATH — size summary may be unavailable.")
endif()

find_package(Python3 COMPONENTS Interpreter REQUIRED)

# Detect fallback options, like GNU vs BSD size
function(_detect_gnu_size OUTVAR)
    if (NOT ELF_SIZE_EXECUTABLE)
        set(${OUTVAR} FALSE PARENT_SCOPE)
        return()
    endif()

    execute_process(
            COMMAND "${ELF_SIZE_EXECUTABLE}" --help
            OUTPUT_VARIABLE _HELP
            ERROR_VARIABLE _HELP_ERR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE _HELP_RC
    )
    if (_HELP_RC EQUAL 0 AND _HELP MATCHES "--format=gnu")
        set(${OUTVAR} TRUE PARENT_SCOPE)
    else()
        execute_process(
                COMMAND "${ELF_SIZE_EXECUTABLE}" --version
                OUTPUT_VARIABLE _VER
                ERROR_VARIABLE _VER_ERR
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE
                RESULT_VARIABLE _VER_RC
        )
        if (_VER_RC EQUAL 0 AND (_VER MATCHES "GNU" OR _VER MATCHES "arm-none-eabi"))
            set(${OUTVAR} TRUE PARENT_SCOPE)
        else()
            set(${OUTVAR} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()

# Check arguments
if (DEFINED PICO_FLASH_SIZE_BYTES)
    math(EXPR FLASH_SIZE_EVAL "${PICO_FLASH_SIZE_BYTES}")
else()
    set(FLASH_SIZE_EVAL 2097152) # default 2 MiB
    message(WARNING "FLASH size is not provided by your toolchain - set default [2 MiB]")
endif()

# Platform default if not set by your build
if (NOT DEFINED PICO_PLATFORM OR PICO_PLATFORM STREQUAL "")
    set(PICO_PLATFORM "rp2040")
    message(WARNING "PLATFORM size is not provided by your toolchain - set default [rp2040]")
endif()

if (EXISTS "${PICO_SIZE_TOOL}")
    message(STATUS "Using custom size report: ${PICO_SIZE_TOOL}")

    # Run your Python tool after linking
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND "${Python3_EXECUTABLE}" "${PICO_SIZE_TOOL}"
            --flash-size "${FLASH_SIZE_EVAL}"
            --platform "${PICO_PLATFORM}"
            --size-exe "${ELF_SIZE_EXECUTABLE}"
            "$<TARGET_FILE:${PROJECT_NAME}>"
            COMMENT "Running pico_size_tool.py for memory summary"
            VERBATIM
    )

elseif(ELF_SIZE_EXECUTABLE)
    # Only if the script is unexpectedly missing — plain size fallback
    _detect_gnu_size(_SIZE_IS_GNU)
    if (_SIZE_IS_GNU)
        message(STATUS "pico_size_tool.py missing; falling back to GNU size: ${ELF_SIZE_EXECUTABLE}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND "${ELF_SIZE_EXECUTABLE}" --format=gnu "$<TARGET_FILE:${PROJECT_NAME}>"
                VERBATIM
        )
    else()
        message(STATUS "pico_size_tool.py missing; falling back to BSD size: ${ELF_SIZE_EXECUTABLE}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND "${ELF_SIZE_EXECUTABLE}" -m "$<TARGET_FILE:${PROJECT_NAME}>"
                VERBATIM
        )
    endif()

else()
    message(WARNING "pico_size_tool.py missing and no usable size tool found — skipping size summary.")
endif()