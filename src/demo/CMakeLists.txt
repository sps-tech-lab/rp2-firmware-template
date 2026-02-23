add_library(demo STATIC
  demo.cpp
)

target_include_directories(demo PUBLIC
  ${CMAKE_CURRENT_LIST_DIR}
)

target_compile_features(demo PUBLIC cxx_std_20)