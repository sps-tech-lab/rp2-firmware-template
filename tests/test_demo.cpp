//
// Created by SPS on 20/02/2026.
//

//Includes
#include "test_demo.hpp"
#include <catch2/catch_test_macros.hpp>
#include "demo.hpp"

TEST_CASE("demo::add adds two numbers") {
    REQUIRE(demo::add(1, 2) == 3);
    REQUIRE(demo::add(0, 0) == 0);
    REQUIRE(demo::add(10, 20) == 30);
}