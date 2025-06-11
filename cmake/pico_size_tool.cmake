find_program(ELF_SIZE_EXECUTABLE
        NAMES size
        HINTS ENV PATH
)
if (NOT ELF_SIZE_EXECUTABLE)
    message(WARNING "Could not find 'size' in your PATH. Size summary won't be available!")
else()
    message(STATUS "Using size tool: ${ELF_SIZE_EXECUTABLE}")
    find_program(SIZE_SUMMARY_SCRIPT
            NAMES pico_size_tool.py
            HINTS "${CMAKE_SOURCE_DIR}/scripts"
    )
    if (NOT SIZE_SUMMARY_SCRIPT)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${ELF_SIZE_EXECUTABLE} --format=gnu $<TARGET_FILE:${PROJECT_NAME}>
        )
    else()
        message(STATUS "Using user-friendly size report")
        math(EXPR FLASH_SIZE_EVAL "${PICO_FLASH_SIZE_BYTES}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND python3 ${SIZE_SUMMARY_SCRIPT}
                --flash-size ${FLASH_SIZE_EVAL}
                --platform ${PICO_PLATFORM}
                $<TARGET_FILE:${PROJECT_NAME}>
        )
    endif()
endif()