cmake_minimum_required(VERSION 3.1)

project(ArcBuildExamples)

# https://stackoverflow.com/questions/3961446/why-does-gcc-not-implicitly-supply-the-fpic-flag-when-compiling-static-librarie
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_STANDARD 11)

add_subdirectory(hello_world)
