# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Custom gcc toolchain file for ARM, support "-march=" and NEON compile flags.
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

# SDK_ARCH
if(NOT SDK_ARCH)
  set(SDK_ARCH "armv7-a")
elseif(SDK_ARCH STREQUAL "arm64")
  set(SDK_ARCH "armv8-a")
endif()

# compiler and linker flags
if(SDK_ARCH MATCHES "^arm")
  set(SDK_C_FLAGS "-march=${SDK_ARCH}")
endif()
if(SDK_ARCH MATCHES "^armv7")
  set(SDK_C_FLAGS "${SDK_C_FLAGS} -mfloat-abi=softfp -mfpu=neon -ftree-vectorize -ffast-math")
endif()

include(${CMAKE_CURRENT_LIST_DIR}/gcc-toolchain.cmake)
