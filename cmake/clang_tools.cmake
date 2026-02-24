function(rp2_enable_clang_tools)

  # Check
  set(RP2_SCRIPTS_DIR "${CMAKE_SOURCE_DIR}/scripts")
  foreach(_s IN ITEMS clang-format.sh check-format.sh clang-tidy.sh)
    if(NOT EXISTS "${RP2_SCRIPTS_DIR}/${_s}")
      message(WARNING "[CLANG TOOLS] missing scripts/${_s}. Target may fail.")
    endif()
  endforeach()

  # Targets
  add_custom_target(format
    COMMAND "${RP2_SCRIPTS_DIR}/clang-format.sh"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "[CLANG TOOLS] Running clang-format (apply)"
    VERBATIM
  )

  add_custom_target(format-check
    COMMAND "${RP2_SCRIPTS_DIR}/check-format.sh"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "[CLANG TOOLS] Running clang-format (check)"
    VERBATIM
  )

  add_custom_target(tidy-firmware
    COMMAND "${RP2_SCRIPTS_DIR}/clang-tidy.sh" --firmware -p "${CMAKE_BINARY_DIR}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "[CLANG TOOLS] Running clang-tidy (firmware)"
    VERBATIM
  )

  add_custom_target(tidy-tests
    COMMAND "${RP2_SCRIPTS_DIR}/clang-tidy.sh" --unit-tests -p "${CMAKE_BINARY_DIR}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "[CLANG TOOLS] Running clang-tidy (unit-tests)"
    VERBATIM
  )

  add_custom_target(quality)
  if(RP2_ENABLE_TESTS) #TODO: consider other ways to do this
    add_custom_target(tidy DEPENDS tidy-tests)
  else()
    add_custom_target(tidy DEPENDS tidy-firmware)
  endif()
  add_dependencies(quality format-check tidy)

endfunction()