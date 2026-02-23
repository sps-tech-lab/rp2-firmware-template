include(FetchContent)

FetchContent_Declare(
  Catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG v3.5.4
)

FetchContent_MakeAvailable(Catch2)

add_executable(unit-tests
  test_demo.cpp
)

target_link_libraries(unit-tests PRIVATE
  demo
  Catch2::Catch2WithMain
)

include(CTest)
include(Catch)
catch_discover_tests(unit-tests)