# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom gcc toolchain file for ARM, support "-march=" and NEON compile flags.
#
# Supported (environment) variables:
#
# - SDK_ROOT (REQUIRED): SDK root directory which contains "arm-linux-gnueabihf" or "aarch64-linux-gnueabihf" etc.
#
#     Default: $ENV{ARCBUILD_PI_ROOT}
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
# https://github.com/abhiTronix/raspberry-pi-cross-compilers

cmake_minimum_required(VERSION 3.6.0)

# SDK_ARCH
if(NOT SDK_ARCH)
  set(SDK_ARCH "armv7-a")
elseif(SDK_ARCH MATCHES "^(arm64|aarch64)$")
  set(SDK_ARCH "armv8-a")
endif()

# compiler and linker flags
if(SDK_ARCH MATCHES "^arm")
  list(APPEND SDK_C_FLAGS -march=${SDK_ARCH})
endif()
if(SDK_ARCH MATCHES "^armv6")
  list(APPEND SDK_C_FLAGS -mfloat-abi=hard -mfpu=vfp)
elseif(SDK_ARCH MATCHES "^armv7")
  list(APPEND SDK_C_FLAGS -mfloat-abi=hard -mfpu=neon-vfpv4)
elseif(SDK_ARCH MATCHES "^armv8")
  list(APPEND SDK_C_FLAGS -mfloat-abi=hard -mfpu=neon-fp-armv8)
endif()

# SDK_ROOT
if(NOT SDK_ROOT)
  set(SDK_ROOT "$ENV{ARCBUILD_PI_ROOT}")
endif()

include(${CMAKE_CURRENT_LIST_DIR}/gcc-toolchain.cmake)
