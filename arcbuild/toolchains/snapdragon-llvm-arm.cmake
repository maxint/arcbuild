# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom toolchain file for Snapdragon LLVM ARM C/C++ Toolchain (from 4.0 to 8.0).
#
# Supported (environment) variables:
#
# - SDK_ROOT (REQUIRED): SDK root directory which contains "armv7-linux-gnueabi" or "aarch64-linux-gnu" etc.
#
#     Default: $ENV{ARCBUILD_QTEE_ROOT}
#
# - SDK_ARCH: target architecture
#
#     Default: armv7-a
#     Posible values are:
#       armv5
#       armv6m
#       armv7
#       armv7m
#       arm64 or aarch64
#
# - SDK_TARGET_TRIPLET: target toolchain triplet
#
#     Default: auto-detection w.r.t SDK_ARCH
#     e.g. aarch64-none-elf, armv7-none-eabi, etc.
#

cmake_minimum_required(VERSION 3.6.0)

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
  set(SDK_ARCH "aarch64")
elseif(SDK_ARCH STREQUAL "arm64")
  set(SDK_ARCH "aarch64")
endif()

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES SDK_ROOT SDK_ARCH SDK_TARGET_TRIPLET SDK_VERSION)

# SDK_VERSION
if(NOT SDK_VERSION)
  file(GLOB SDK_RELEASE_NOTES "${SDK_ROOT}/RELEASE_NOTES*")
  file(READ "${SDK_RELEASE_NOTES}" SDK_VERSION)
  string(REGEX MATCH "([0-9.]+) release of the Snapdragon LLVM" SDK_VERSION "${SDK_VERSION}")
  string(REGEX MATCH "([0-9.]+)" SDK_VERSION "${SDK_VERSION}")
endif()
message(STATUS "SDK_VERSION: ${SDK_VERSION}")

# SDK_ROOT
if(NOT SDK_ROOT)
  set(SDK_ROOT "$ENV{ARCBUILD_QTEE_ROOT}")
endif()
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Please set SDK_ROOT variable to toolchain root directory")
endif()
message(STATUS "SDK_ROOT: ${SDK_ROOT}")

# Basic setup
set(CMAKE_SYSTEM_NAME GNU)
set(CMAKE_SYSTEM_VERSION 1)

# Reset flags
set(SDK_C_FLAGS -DBARE_METAL=1)
set(SDK_CXX_FLAGS)
set(SDK_LINKER_FLAGS)
set(SDK_LINKER_FLAGS_EXE)

# SDK_TARGET_TRIPLET
if(NOT SDK_TARGET_TRIPLET)
  set(SDK_TARGET_TRIPLE_PATTERN "${SDK_ARCH}-none-*")
  # set(SDK_TARGET_TRIPLE_PATTERN "${SDK_ARCH}-*gnu*")
  file(GLOB SDK_TARGET_TRIPLET RELATIVE ${SDK_ROOT} "${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
  if(NOT SDK_TARGET_TRIPLET)
    message(FATAL_ERROR "Can not find toolchain with pattern: ${SDK_ROOT}/${SDK_TARGET_TRIPLE_PATTERN}")
  endif()
endif()
set(SDK_TARGET_TOOLCHAIN_ROOT "${SDK_ROOT}/${SDK_TARGET_TRIPLET}")
set(CMAKE_SYSROOT "${SDK_ROOT}/${SDK_TARGET_TRIPLET}/libc")
message(STATUS "CMAKE_SYSROOT: ${CMAKE_SYSROOT}")
message(STATUS "SDK_TARGET_TRIPLET: ${SDK_TARGET_TRIPLET}")
message(STATUS "SDK_TARGET_TOOLCHAIN_ROOT: ${SDK_TARGET_TOOLCHAIN_ROOT}")

# Set platform flags
set(UNIX 1)
set(SNAPDRAGON 1)
set(ARM 1)
set(CMAKE_SYSTEM_PROCESSOR ARM) # optional
if(SDK_TARGET_TRIPLET MATCHES ".*-none-.*")
  set(BARE_METAL 1)
  set(TEE 1)
  set(QTEE 1)
endif()

# Compiler flags
list(APPEND SDK_C_FLAGS --target=${SDK_TARGET_TRIPLET})
list(APPEND SDK_C_FLAGS -fuse-baremetal-inc)
# https://stackoverflow.com/questions/42912038/what-is-the-difference-between-cxa-atexit-and-atexit
# list(APPEND SDK_C_FLAGS -fno-use-cxa-atexit) # avoid link error (undefined reference to `__dso_handle') when using local static or global object
# QTI recommends the following options for reducing the code size of a bare metal application
# list(APPEND SDK_C_FLAGS -fomit-frame-pointer -fshort-enums -mno-unaligned-access -fno-zero-initialized-in-bss)
# "-fshort-enums" may cause: the size of enumerated data item in input is not compatible with the output (value=1)
list(APPEND SDK_C_FLAGS -fomit-frame-pointer -mno-unaligned-access -fno-zero-initialized-in-bss)
if(SDK_ARCH STREQUAL "aarch64")
  # list(APPEND SDK_C_FLAGS -mgeneral-regs-only)
else()
  # list(APPEND SDK_C_FLAGS -mno-interrupt-stack-align)
endif()
if(SDK_ARCH MATCHES "^armv7")
  list(APPEND SDK_C_FLAGS -mfloat-abi=softfp -mfpu=neon -ftree-vectorize -ffast-math)
endif()
list(APPEND SDK_CXX_FLAGS -fno-exceptions -fno-rtti)

# Linker flags
# "-z now": Mark an object as non-lazy runtime binding.
# "-static": Do not link against shared libraries.
# "-Bsymbolic": Bind global references locally.
# "-Bdynamic": Link against shared libraries.
list(APPEND SDK_LINKER_FLAGS -march=${SDK_ARCH} -nostdlib -no-undefined -gc-sections -z now -static)
list(APPEND SDK_LINKER_FLAGS --sysroot==${CMAKE_SYSROOT})
# list(APPEND SDK_LINKER_FLAGS -Wl,--no-undefined -fuse-baremetal-libs -fuse-baremetal-rtlib -fuse-baremetal-crt -fuse-ld=qcld)
# list(APPEND SDK_LINKER_FLAGS --no-undefined --eh-frame-hdr -m ${SDK_ARCH}linux -export-dynamic -dynamic-linker /lib/ld-linux-${SDK_ARCH}.so)
# list(APPEND SDK_LINKER_FLAGS -shared -init main -march aarch64 -z now -static -no-undefined -Bsymbolic -Bdynamic -gc-sections)
list(APPEND SDK_LINKER_FLAGS -Bsymbolic)
list(APPEND SDK_LINKER_FLAGS -L"${SDK_TARGET_TOOLCHAIN_ROOT}/lib" -L"${SDK_TARGET_TOOLCHAIN_ROOT}/libc/lib")

# C++ include directory
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
# list(APPEND SDK_CXX_FLAGS -I"${SDK_CXX_DIR}")
message(STATUS "SDK_CXX_DIR: ${SDK_CXX_DIR}")
message(STATUS "SDK_CXX_VERSION: ${SDK_CXX_VERSION}")

# SDK_CLANG_LIB_DIR
file(GLOB SDK_CLANG_LIB_DIR "${SDK_ROOT}/lib/clang/*/lib")
message(STATUS "SDK_CLANG_LIB_DIR: ${SDK_CLANG_LIB_DIR}")

# Search paths
list(APPEND CMAKE_FIND_ROOT_PATH ${SDK_ROOT} ${CMAKE_SYSROOT} ${SDK_GCC_TOOLCHAIN_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Find compilers
find_program(CMAKE_C_COMPILER clang PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER clang++ PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_AR llvm-ar PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_RANLIB llvm-ranlib PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)
find_program(CMAKE_LINKER arm-link PATHS "${SDK_ROOT}/bin" NO_DEFAULT_PATH)

# RPATH is useless when cross compiling.
set(CMAKE_SKIP_RPATH ON)

# Join compiler and linker flags
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
# list(APPEND SDK_LIB --start-group)
set(SDK_LIB -lunwind -lc++ -lc++abi)
list(APPEND SDK_LIB "${SDK_CLANG_LIB_DIR}/baremetal/libclang_rt.builtins-${SDK_ARCH}.a")
list(APPEND SDK_LIB -lc -lm -ldl)
if(SDK_ARCH STREQUAL "aarch64")
  list(APPEND SDK_LIB "${SDK_CLANG_LIB_DIR}/linux/libclang_rt.builtins-aarch64.a")
else()
  list(APPEND SDK_LIB "${SDK_CLANG_LIB_DIR}/linux/libclang_rt.builtins-arm.a")
endif()
# list(APPEND SDK_LIB --end-group)
string(REPLACE ";" " " SDK_LIB "${SDK_LIB}")
foreach(LANG C CXX)
  set(CMAKE_${LANG}_CREATE_SHARED_LIBRARY "<CMAKE_LINKER> <CMAKE_SHARED_LIBRARY_${LANG}_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_${LANG}_FLAGS> -soname <TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${LANG}_CREATE_SHARED_MODULE  "<CMAKE_LINKER> <CMAKE_SHARED_LIBRARY_${LANG}_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_${LANG}_FLAGS> -soname <TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${LANG}_LINK_EXECUTABLE       "<CMAKE_LINKER> <CMAKE_${LANG}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
  set(CMAKE_${LANG}_CREATE_SHARED_LIBRARY "${CMAKE_${LANG}_CREATE_SHARED_LIBRARY} ${SDK_LIB}")
  set(CMAKE_${LANG}_CREATE_SHARED_MODULE  "${CMAKE_${LANG}_CREATE_SHARED_MODULE} ${SDK_LIB}")
  set(CMAKE_${LANG}_LINK_EXECUTABLE       "${CMAKE_${LANG}_LINK_EXECUTABLE} ${SDK_LIB}")
endforeach()

# vim:ft=cmake et ts=2 sts=2 sw=2:
