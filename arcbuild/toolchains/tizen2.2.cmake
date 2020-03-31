# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Supported (environment) variables:
#
# - SDK_ROOT (REQUIRED): Tizen SDK root directory
#
#     Default: $ENV{ARCBUILD_TIZEN_ROOT}
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

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES SDK_ROOT)

# SDK_ROOT
if(NOT SDK_ROOT)
  set(SDK_ROOT "$ENV{ARCBUILD_TIZEN_ROOT}")
endif()
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Please set SDK_ROOT variable to toolchain root directory")
endif()

# basic setup
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR arm) # optional

# platform flags
set(UNIX 1)
set(TIZEN 1)
set(ARM 1)

# SDK related directories
set(CMAKE_SYSROOT ${SDK_ROOT}/platforms/tizen2.2/rootstraps/tizen-device-2.2.native)
set(TIZEN_CXX_DIR ${CMAKE_SYSROOT}/usr/include/c++/4.5.3)
set(TIZEN_GCC_TOOLCHAIN ${SDK_ROOT}/tools/arm-linux-gnueabi-gcc-4.5)

# Search paths
list(APPEND CMAKE_FIND_ROOT_PATH ${SDK_ROOT} ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# compilers
find_program(CMAKE_C_COMPILER clang PATHS "${SDK_ROOT}/tools/llvm-3.1/bin" NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER clang++ PATHS "${SDK_ROOT}/tools/llvm-3.1/bin" NO_DEFAULT_PATH)
find_program(CMAKE_AR ar PATH "${TIZEN_GCC_TOOLCHAIN}/arm-linux-gnueabi/bin" NO_DEFAULT_PATH)
# NOTE: fix bug of no -D* passed when checking compilers
# include(CMakeForceCompiler)
# cmake_force_c_compiler(${CMAKE_C_COMPILER} Clang)
# cmake_force_cxx_compiler(${CMAKE_CXX_COMPILER} Clang)

# RPATH is useless when cross compiling.
set(CMAKE_SKIP_RPATH ON)

# compiler and linker flags
set(SDK_C_FLAGS "-fmessage-length=0 -march=${SDK_ARCH} -mtune=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=soft -mthumb -Wa,-mimplicit-it=thumb -mfloat-abi=softfp -mfpu=neon")
set(SDK_C_FLAGS "${SDK_C_FLAGS} -target arm-tizen-linux-gnueabi -gcc-toolchain ${TIZEN_GCC_TOOLCHAIN} -I${TIZEN_CXX_DIR} -I${TIZEN_CXX_DIR}/armv7l-tizen-linux-gnueabi")
set(SDK_LINKER_FLAGS "-Wl,--no-undefined -lc -lm -lstdc++ -lgcc -ldl -lrt")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SDK_C_FLAGS}" CACHE STRING "C flags" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SDK_C_FLAGS}" CACHE STRING "C++ flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${SDK_LINKER_FLAGS}" CACHE STRING "" FORCE)
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${SDK_LINKER_FLAGS}" CACHE STRING "" FORCE)
set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} ${SDK_LINKER_FLAGS}" CACHE STRING "" FORCE)

# NOTE: (optional) do not contribute to find compiler program, e.g. ar
#set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
#set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# vim:ft=cmake et ts=2 sts=2 sw=2:
