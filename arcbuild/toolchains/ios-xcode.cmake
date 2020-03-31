# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>
#
# Options:
#
# SDK_ROOT = automatic (default: xcode-select --print-path) or /path/to/Contents/Developer
#
# SDK_ARCH = empty (default: "armv7;armv7s;arm64;arm64e") or "armv7;armv7s;arm64;arm64e"|"i386;x86_64"|"i686;x86_64"
#   set the architecture for iOS - sets armv7;armv7s;arm64;arm64e and appears to be XCode's standard.
#
# SDK_API_VERSION = empty (default: oldest) or 6.1|7.1|8.1
#
# IOS_BITCODE = empty (default: off)
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

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES SDK_ROOT SDK_API_VERSION SDK_ARCH IOS_TARGET IOS_BITCODE XCODE_VERSION)

# select xcode version and get SDK_ROOT
if(NOT SDK_ROOT)
  find_program(XCODE_SELECT_COMMAND xcode-select)
  message(STATUS "XCODE_SELECT_COMMAND: ${XCODE_SELECT_COMMAND}")
  if(XCODE_SELECT_COMMAND)
    execute_process(COMMAND ${XCODE_SELECT_COMMAND} "-print-path"
      OUTPUT_VARIABLE SDK_ROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
  if(SDK_ROOT MATCHES "/Library/Developer/CommandLineTools")
    message(STATUS "`xcode-select -print-path` returns \"${SDK_ROOT}\", which is not iOS toolchain directory!")
    unset(SDK_ROOT)
  endif()
  set(DEFAULT_XCODE_APP_ROOT "/Applications/Xcode.app/Contents/Developer")
  if(NOT SDK_ROOT AND EXISTS ${DEFAULT_XCODE_APP_ROOT})
    set(SDK_ROOT ${DEFAULT_XCODE_APP_ROOT})
  endif()
endif()
if(NOT SDK_ROOT)
  message(FATAL_ERROR "Please set SDK_ROOT variable to toolchain root directory (e.g. /Applications/Xcode8.0.app/Contents/Developer)")
endif()
message(STATUS "SDK_ROOT: ${SDK_ROOT}")

# find xcode version
if(NOT XCODE_VERSION)
  # xcodebuild -version
  if(EXISTS "${SDK_ROOT}/../version.plist")
    file(READ "${SDK_ROOT}/../version.plist" XCODE_VERSION)
    string(REGEX REPLACE "[ \t\r\n]" "" XCODE_VERSION "${XCODE_VERSION}")
    string(REGEX MATCH "<key>CFBundleShortVersionString</key><string>([0-9.]+)" XCODE_VERSION "${XCODE_VERSION}")
    string(REGEX MATCH "([0-9.]+)" XCODE_VERSION "${XCODE_VERSION}")
  else()
    message(FATAL_ERROR "${SDK_ROOT}/../version.plist does not existed!")
  endif()
endif()
message(STATUS "XCODE_VERSION: ${XCODE_VERSION}")

# Initialize compiler and linker flags
set(SDK_C_FLAGS)
set(SDK_CXX_FLAGS)
set(SDK_LINKER_FLAGS)
set(SDK_LINKER_FLAGS_EXE)

# hard set values
if(NOT SDK_ARCH)
  set(SDK_ARCH "armv7;armv7s;arm64;arm64e")
else()
  string(REPLACE " " ";" SDK_ARCH "${SDK_ARCH}") # Add support of arch's seperated by space
endif()
message(STATUS "SDK_ARCH: ${SDK_ARCH}")

# iOS target
if(SDK_ARCH MATCHES "^arm.*")
  set(IOS_TARGET "iPhoneOS")
  list(APPEND SDK_C_FLAGS -miphoneos-version-min=7.0 -ftree-vectorize -ffast-math)
  if(SDK_ARCH MATCHES "(armv7|armv7s)")
    list(APPEND SDK_C_FLAGS -mfloat-abi=softfp -mfpu=neon ) # Enable NEON for ARM
  endif()
elseif(SDK_ARCH MATCHES "(i386|i686|x86_64)")
  set(IOS_TARGET "iPhoneSimulator")
  list(APPEND SDK_C_FLAGS -mios-simulator-version-min=7.0)
  else()
  message(FATAL_ERROR "Unknown target architectures: SDK_ARCH=${SDK_ARCH}")
endif()
message(STATUS "IOS_TARGET: ${IOS_TARGET}")

# some internal values
set(IOS_DEVELOPER_ROOT "${SDK_ROOT}/Platforms/${IOS_TARGET}.platform/Developer")
set(OSX_TOOLCHAIN_ROOT "${SDK_ROOT}/Toolchains/XcodeDefault.xctoolchain")

# Target specific architectures for OS X.
set(CMAKE_OSX_ARCHITECTURES "${SDK_ARCH}" CACHE STRING "Build architectures for iOS")

# Specify the location or name of the OS X platform SDK to be used.
if(NOT SDK_API_VERSION)
  file(GLOB SDK_API_VERSION_SUPPORTED "${IOS_DEVELOPER_ROOT}/SDKs/*")
  list(SORT SDK_API_VERSION_SUPPORTED)
  # has compile error when using the oldest one (0)
  # clang: error: invalid version number in '-miphoneos-version-min=.sd'
  list(GET SDK_API_VERSION_SUPPORTED -1 CMAKE_OSX_SYSROOT)
  string(REGEX MATCH "([0-9.]+)\\.sdk" SDK_API_VERSION "${CMAKE_OSX_SYSROOT}")
  string(REPLACE ".sdk" "" SDK_API_VERSION "${SDK_API_VERSION}")
  string(REGEX MATCHALL "([0-9.]+)\\.sdk" SDK_API_VERSION_SUPPORTED "${SDK_API_VERSION_SUPPORTED}")
  string(REPLACE ".sdk" "" SDK_API_VERSION_SUPPORTED "${SDK_API_VERSION_SUPPORTED}")
  message(STATUS "SDK_API_VERSION available: ${SDK_API_VERSION_SUPPORTED}")
else()
  set(CMAKE_OSX_SYSROOT "${IOS_DEVELOPER_ROOT}/SDKs/${IOS_TARGET}${SDK_API_VERSION}.sdk")
endif()
message(STATUS "SDK_API_VERSION: ${SDK_API_VERSION}")
message(STATUS "CMAKE_OSX_SYSROOT: ${CMAKE_OSX_SYSROOT}")
set(CMAKE_OSX_SYSROOT "${CMAKE_OSX_SYSROOT}" CACHE PATH "Sysroot used for iOS support")
# Specify the minimum version of OS X on which the target binaries are to be deployed.
# CMAKE_OSX_DEPLOYMENT_TARGET # get from CMAKE_OSX_SYSROOT

# cross compiling setup
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_VERSION ${SDK_API_VERSION})
#set(CMAKE_SYSTEM_PROCESSOR arm) # optional

# platform flags
set(UNIX 1)
set(APPLE 1)
set(IOS 1)
if(SDK_ARCH MATCHES "^arm.*")
  set(ARM 1)
endif()

# root path
set(CMAKE_FIND_ROOT_PATH ${OSX_TOOLCHAIN_ROOT} ${IOS_DEVELOPER_ROOT} ${CMAKE_OSX_SYSROOT})
# only search the iOS sdks, not the remainder of the host filesystem
# search paths (for makefiles the first one might be switched to "NEVER")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# compiler
set(CMAKE_C_COMPILER   ${OSX_TOOLCHAIN_ROOT}/usr/bin/clang)
set(CMAKE_CXX_COMPILER ${OSX_TOOLCHAIN_ROOT}/usr/bin/clang++)
# include(CMakeForceCompiler)
# cmake_force_c_compiler(${CMAKE_C_COMPILER} Clang)
# cmake_force_cxx_compiler(${CMAKE_CXX_COMPILER} Clang)

# default to searching for frameworks first
set(CMAKE_FIND_FRAMEWORK FIRST)

# set up the default search directories for frameworks
set(CMAKE_SYSTEM_FRAMEWORK_PATH
  ${IOS_DEVELOPER_ROOT}/System/Library/Frameworks
  ${IOS_DEVELOPER_ROOT}/System/Library/PrivateFrameworks
  ${IOS_DEVELOPER_ROOT}/Developer/Library/Frameworks
  )

# RPATH is useless when cross compiling.
set(CMAKE_SKIP_RPATH ON)

# compiler and linker flags
# -v to print version
if(IOS_BITCODE)
  if(SDK_API_VERSION VERSION_GREATER "6.0" AND NOT XCODE_VERSION VERSION_LESS "7.0")
    list(APPEND SDK_C_FLAGS -fembed-bitcode) # enable bitcode when SDK>6.0 and xcode>=7.0
  else()
    message(FATAL_ERROR "No bitcode support for Xcode ${XCODE_VERSION} and iOS SDK ${SDK_API_VERSION}")
  endif()
endif()
# message("CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
# https://stackoverflow.com/questions/16294842/how-to-disable-c-dead-code-stripping-in-xcode
# get all the symbols from the all archives
set(SDK_LINKER_FLAGS "-Wl,-all_load")

# combine
string(REPLACE ";" " " SDK_C_FLAGS          "${SDK_C_FLAGS}")
string(REPLACE ";" " " SDK_CXX_FLAGS        "${SDK_CXX_FLAGS}")
string(REPLACE ";" " " SDK_LINKER_FLAGS     "${SDK_LINKER_FLAGS}")
string(REPLACE ";" " " SDK_LINKER_FLAGS_EXE "${SDK_LINKER_FLAGS_EXE}")

# Set or retrieve the cached flags.
# This is necessary in case the user sets/changes flags in subsequent
# configures. If we included the Android flags in here, they would get
# overwritten.
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

# vim:ft=cmake et ts=2 sts=2 sw=2:
