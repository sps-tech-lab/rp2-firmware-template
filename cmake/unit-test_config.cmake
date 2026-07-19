macro(config_unit_tests)

    message(STATUS "Configure unit-tests")

    project(rp2-firmware-template LANGUAGES C CXX)

    # Enable clang-tools like targets
    include(cmake/clang_tools.cmake)
    rp2_enable_clang_tools()

    # Shared libraries
    add_subdirectory(src/demo)

    enable_testing()
    add_subdirectory(tests)

endmacro()





