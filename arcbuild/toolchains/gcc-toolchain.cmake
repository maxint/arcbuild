# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom gcc toolchain file.
#
# Supported (environment) variables:
#
# - SDK_ROOT: SDK root directory
#
# - SDK_ARCH: target architecture
#
#     Default: armv7-a
#     Posible values are:
#       arm
#       armv7-a
#       armv8-a (or arm64)
#

cmake_minimum_required(VERSION 3.4.0)

# CMake invokes the toolchain file twice during the first build, but only once
# during subsequent rebuilds. This was causing the various flags to be added
# twice on the first build, and on a rebuild ninja would see only one set of the
# flags and rebuild the world.
# https://github.com/android-ndk/ndk/issues/323
if(ARCBUILD_TOOLCHAIN_INCLUDED)
  return()
endif(ARCBUILD_TOOLCHAIN_INCLUDED)
set(ARCBUILD_TOOLCHAIN_INCLUDED 1)

# Touch toolchain variable to suppress "unused variable" warning.
# This happens if CMake is invoked with the same command line the second time.
if(CMAKE_TOOLCHAIN_FILE)
endif()

# SDK_ARCH
if(NOT SDK_ARCH)
  set(SDK_ARCH "armv7-a")
elseif(SDK_ARCH STREQUAL "arm64")
  set(SDK_ARCH "armv8-a")
endif()

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES SDK_ROOT SDK_ARCH)

# SDK_ROOT
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Please set SDK_ROOT variable to toolchain root directory")
endif()

# basic setup
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR ARM) # optional

# For convenience
set(UNIX 1)
set(ARM 1)

if(SDK_ARCH MATCHES "^armv8")
  set(SDK_TARGET_TRIPLE_PATTERN "aarch64-*gnu*")
else()
  set(SDK_TARGET_TRIPLE_PATTERN "arm-*gnu*")
endif()

# SDK_TARGET_TOOLCHAIN_ROOT
message(STATUS "SDK_ROOT: ${SDK_ROOT}")
file(GLOB SDK_TARGET_TOOLCHAIN RELATIVE ${SDK_ROOT} "${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
if(NOT SDK_TARGET_TOOLCHAIN)
  message(FATAL_ERROR "Can not find toolchain with pattern: ${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
endif()
set(SDK_TARGET_TOOLCHAIN_ROOT "${SDK_ROOT}/${SDK_TARGET_TOOLCHAIN}")
message(STATUS "SDK_TARGET_TOOLCHAIN: ${SDK_TARGET_TOOLCHAIN}")
message(STATUS "SDK_TARGET_TOOLCHAIN_ROOT: ${SDK_TARGET_TOOLCHAIN_ROOT}")

# CMAKE_SYSROOT
find_path(CMAKE_SYSROOT
  NAMES usr/include/assert.h
  HINTS ${SDK_TARGET_TOOLCHAIN_ROOT}/sysroot
        ${SDK_TARGET_TOOLCHAIN_ROOT}/libc
  NO_DEFAULT_PATH
  )
if(NOT CMAKE_SYSROOT)
  message(FATAL_ERROR "Can not find CMAKE_SYSROOT in ${SDK_TARGET_TOOLCHAIN_ROOT}")
endif()
message(STATUS "CMAKE_SYSROOT: ${CMAKE_SYSROOT}")

# C++ include directory
file(GLOB SDK_CXX_DIR "${SDK_TARGET_TOOLCHAIN_ROOT}/include/c++/*/")
message(STATUS "SDK_CXX_DIR: ${SDK_CXX_DIR}")

# compilers
find_program(CMAKE_C_COMPILER ${SDK_TARGET_TOOLCHAIN}-gcc PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER ${SDK_TARGET_TOOLCHAIN}-g++ PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_AR ${SDK_TARGET_TOOLCHAIN}-ar PATH "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_RANLIB ${SDK_TARGET_TOOLCHAIN}-ranlib PATH "${SDK_ROOT}/bin" NO_DEFAULT_PATH)

# compiler and linker flags
if(SDK_CXX_DIR)
  set(SDK_CXX_FLAGS "-I${SDK_CXX_DIR} -I${SDK_CXX_DIR}/${SDK_TARGET_TOOLCHAIN}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SDK_C_FLAGS}" CACHE STRING "C flags" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SDK_C_FLAGS} ${SDK_CXX_FLAGS}" CACHE STRING "C++ flags" FORCE)

# Support automatic link of system libraries
set(SDK_LIB "-Wl,--no-undefined -lpthread -lc -lm -lstdc++ -lgcc -ldl")
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} ${SDK_LIB}")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} ${SDK_LIB}")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} ${SDK_LIB}")

# NOTE: (optional) do not contribute to find compiler program, e.g. ar
#set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
#set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# vim:ft=cmake et ts=2 sts=2 sw=2:
