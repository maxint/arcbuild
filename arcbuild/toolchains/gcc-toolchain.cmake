# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom gcc toolchain file.
#
# Supported (environment) variables:
#
# - SDK_ROOT (REQUIRED): SDK root directory which contains "arm-linux-gnueabihf" or "aarch64-linux-gnueabihf" etc.
#
# - SDK_ARCH: target architecture
#
#     Default: armv7-a
#     Posible values are:
#       arm
#       armv7-a
#       armv8-a (or arm64, or aarch64)
#
# - SDK_CXX_VERSION: C++ version to use, default use the latest one.
#
# - SDK_TARGET_TRIPLET: target toolchain triplet
#
#     Default: auto-detection w.r.t SDK_ARCH
#     e.g. aarch64-linux-gnu, armv7-linux-gnueabi, etc.
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

# https://stackoverflow.com/questions/43184251/cmake-command-line-too-long-windows
if(CMAKE_HOST_WIN32)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  set(CMAKE_C_RESPONSE_FILE_LINK_FLAG "@")
  set(CMAKE_CXX_RESPONSE_FILE_LINK_FLAG "@")
  set(CMAKE_NINJA_FORCE_RESPONSE_FILE 1 CACHE INTERNAL "")
endif()

# SDK_ARCH
if(NOT SDK_ARCH)
  set(SDK_ARCH "armv7-a")
elseif(SDK_ARCH MATCHES "^(arm64|aarch64)$")
  set(SDK_ARCH "armv8-a")
endif()

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES SDK_ROOT SDK_ARCH SDK_CXX_VERSION SDK_TARGET_TRIPLET)

# SDK_ROOT
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Please set SDK_ROOT variable to toolchain root directory")
endif()
message(STATUS "SDK_ROOT: ${SDK_ROOT}")

# basic setup
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)

# platform flags
set(UNIX 1)
if(SDK_ARCH MATCHES "(arm|aarch64)")
  set(ARM 1)
  set(CMAKE_SYSTEM_PROCESSOR ARM) # optional
endif()

# SDK_TARGET_TRIPLET
if(NOT SDK_TARGET_TRIPLET)
  if(NOT SDK_TARGET_TRIPLE_PATTERN)
    if(SDK_ARCH MATCHES "^armv8")
      set(SDK_TARGET_TRIPLE_PATTERN "aarch64-*")
    else()
      set(SDK_TARGET_TRIPLE_PATTERN "arm-*")
    endif()
  endif()
  file(GLOB SDK_TARGET_TRIPLET RELATIVE ${SDK_ROOT} "${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
  if(NOT SDK_TARGET_TRIPLET)
    message(FATAL_ERROR "Can not find toolchain with pattern: ${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
  endif()
endif()
message(STATUS "SDK_TARGET_TRIPLET: ${SDK_TARGET_TRIPLET}")

# SDK_TARGET_TOOLCHAIN_ROOT
set(SDK_TARGET_TOOLCHAIN_ROOT "${SDK_ROOT}/${SDK_TARGET_TRIPLET}")
message(STATUS "SDK_TARGET_TOOLCHAIN_ROOT: ${SDK_TARGET_TOOLCHAIN_ROOT}")

# CMAKE_SYSROOT
find_path(CMAKE_SYSROOT
  NAMES usr/include/assert.h include/assert.h
  HINTS ${SDK_TARGET_TOOLCHAIN_ROOT}/sysroot
        ${SDK_TARGET_TOOLCHAIN_ROOT}/libc
  NO_DEFAULT_PATH
  )
if(NOT CMAKE_SYSROOT)
  message(FATAL_ERROR "Can not find CMAKE_SYSROOT in ${SDK_TARGET_TOOLCHAIN_ROOT}")
endif()
message(STATUS "CMAKE_SYSROOT: ${CMAKE_SYSROOT}")

# Search paths
list(APPEND CMAKE_FIND_ROOT_PATH ${SDK_ROOT} ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# C++ include directory
if(SDK_CXX_VERSION)
  set(SDK_CXX_DIR "${SDK_TARGET_TOOLCHAIN_ROOT}/include/c++/${SDK_CXX_VERSION}/")
else()
  file(GLOB SDK_CXX_DIR "${SDK_TARGET_TOOLCHAIN_ROOT}/include/c++/*/")
  if(SDK_CXX_DIR)
    list(LENGTH SDK_CXX_DIR SDK_CXX_DIR_SIZE)
    if(SDK_CXX_DIR_SIZE GREATER 1)
      list(GET SDK_CXX_DIR -1 SDK_CXX_DIR_LATEST)
      get_filename_component(SDK_CXX_DIR_LATEST_NAME "${SDK_CXX_DIR_LATEST}" NAME)
      message(STATUS "Multiple C++ include directories are found, use the latest one: ${SDK_CXX_DIR_LATEST_NAME}")
      set(SDK_CXX_DIR ${SDK_CXX_DIR_LATEST})
    endif()
    get_filename_component(SDK_CXX_VERSION "${SDK_CXX_DIR}" NAME)
  endif()
endif()
message(STATUS "SDK_CXX_DIR: ${SDK_CXX_DIR}")
message(STATUS "SDK_CXX_VERSION: ${SDK_CXX_VERSION}")

# compilers
find_program(CMAKE_C_COMPILER ${SDK_TARGET_TRIPLET}-gcc PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER ${SDK_TARGET_TRIPLET}-g++ PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_AR ${SDK_TARGET_TRIPLET}-ar PATH "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_RANLIB ${SDK_TARGET_TRIPLET}-ranlib PATH "${SDK_ROOT}/bin" NO_DEFAULT_PATH)

# compiler and linker flags
if(SDK_CXX_DIR)
  list(APPEND SDK_CXX_FLAGS -I"${SDK_CXX_DIR}" -I"${SDK_CXX_DIR}/${SDK_TARGET_TRIPLET}")
endif()

# RPATH is useless when cross compiling.
set(CMAKE_SKIP_RPATH ON)

# combine
string(REPLACE ";" " " SDK_C_FLAGS          "${SDK_C_FLAGS}")
string(REPLACE ";" " " SDK_CXX_FLAGS        "${SDK_CXX_FLAGS}")
string(REPLACE ";" " " SDK_LINKER_FLAGS     "${SDK_LINKER_FLAGS}")
string(REPLACE ";" " " SDK_LINKER_FLAGS_EXE "${SDK_LINKER_FLAGS_EXE}")

# Set or retrieve the cached flags.
# This is necessary in case the user sets/changes flags in subsequent
# configures. If we included the flags in here, they would get overwritten.
set(CMAKE_C_FLAGS "" CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_CXX_FLAGS "" CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_ASM_FLAGS "" CACHE STRING "Flags used by the compiler during all build types.")
set(CMAKE_MODULE_LINKER_FLAGS "" CACHE STRING "Flags used by the linker during the creation of modules.")
set(CMAKE_SHARED_LINKER_FLAGS "" CACHE STRING "Flags used by the linker during the creation of dll's.")
set(CMAKE_EXE_LINKER_FLAGS "" CACHE STRING "Flags used by the linker.")

set(CMAKE_C_FLAGS             "${SDK_C_FLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS           "${SDK_C_FLAGS} ${SDK_CXX_FLAGS} ${CMAKE_CXX_FLAGS}")
set(CMAKE_ASM_FLAGS           "${SDK_C_FLAGS} ${CMAKE_ASM_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "${SDK_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS "${SDK_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS    "${SDK_LINKER_FLAGS} ${SDK_LINKER_FLAGS_EXE} ${CMAKE_EXE_LINKER_FLAGS}")

# Support automatic link of system libraries
set(SDK_LIB "-Wl,--no-undefined -lc -lm -lstdc++ -lgcc -ldl")
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "<CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <CMAKE_SHARED_LIBRARY_SONAME_CXX_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} ${SDK_LIB}")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "${CMAKE_CXX_CREATE_SHARED_MODULE} ${SDK_LIB}")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} ${SDK_LIB}")

# vim:ft=cmake et ts=2 sts=2 sw=2:
