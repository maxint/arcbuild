# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom toolchain file based on Emscripten.cmake.
#
# Supported (environment) variables:
#
# - SDK_ROOT: SDK root directory
#
#     Default: $ENV{EMSCRIPTEN_ROOT}
#

cmake_minimum_required(VERSION 3.0.0)

# SDK_ROOT
if(NOT SDK_ROOT)
  set(SDK_ROOT "$ENV{EMSCRIPTEN_ROOT}")
endif()
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Could not locate the Emscripten compiler toolchain directory! Either set the EMSCRIPTEN environment variable, or pass -DSDK_ROOT=xxx to CMake to explicitly specify the location of the compiler!")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")

# Include official toolchain file
get_filename_component(SDK_ROOT "${SDK_ROOT}" ABSOLUTE)
set(EMSCRIPTEN_ROOT_PATH "${SDK_ROOT}")
include("${EMSCRIPTEN_ROOT_PATH}/cmake/Modules/Platform/Emscripten.cmake")

# Add platform flag
set(EMSCRIPTEN 1)
add_definitions(-DEMSCRIPTEN=1)

# We would prefer to specify a standard set of Clang+Emscripten-friendly common convention for suffix files, especially for CMake executable files,
# but if these are adjusted, ${CMAKE_ROOT}/Modules/CheckIncludeFile.cmake will fail, since it depends on being able to compile output files with predefined names.
set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".bc")
set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")
set(CMAKE_LINK_LIBRARY_SUFFIX ".bc")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".bc")
set(CMAKE_EXECUTABLE_SUFFIX ".html")

# RPATH is useless when cross compiling.
set(CMAKE_SKIP_RPATH ON)
