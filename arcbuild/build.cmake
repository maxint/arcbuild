# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

include("${ARCBUILD}/core.cmake")


function(arcbuild_set_to_short_var prefix)
  foreach(name ${ARGN})
    if(NOT DEFINED ${name} AND DEFINED ${prefix}_${name})
      set(${name} "${${prefix}_${name}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()


function(arcbuild_set_from_short_var prefix)
  foreach(name ${ARGN})
    if(DEFINED ${name})
      set(${prefix}_${name} "${${name}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()


function(arcbuild_get_toolchain var_name platform)
  set(path)
  if(platform STREQUAL "android")
    set(path "android-ndk.cmake")
  elseif(platform STREQUAL "ios")
    set(path "ios-xcode.cmake")
  elseif(platform STREQUAL "tizen")
    set(path "tizen2.2.cmake")
  elseif(platform STREQUAL "emscripten")
    set(path "Platform/Emscripten.cmake")
  elseif(platform STREQUAL "pi")
    set(path "gcc-pi.cmake")
  elseif(platform STREQUAL "qtee")
    set(path "snapdragon-llvm-arm.cmake")
  elseif(platform STREQUAL "linux" AND ARGN MATCHES "^(arm|aarch64)") # arch
    set(path "gcc-arm.cmake")
  endif()
  set(${var_name} ${path} PARENT_SCOPE)
endfunction()


function(arcbuild_get_make_program var_name platform root sdk)
  file(TO_CMAKE_PATH "${root}" root)
  unset(path)
  if(platform STREQUAL "android")
    file(GLOB path "${root}/prebuilt/*/bin/make*")
  elseif(platform MATCHES "^tizen")
    file(GLOB path "${root}/tools/*/bin/make*")
  endif()
  if(NOT path)
    find_program(CMAKE_MAKE_PROGRAM make PATHS $ENV{PATH})
    set(path ${CMAKE_MAKE_PROGRAM})
  endif()
  set(${var_name} ${path} PARENT_SCOPE)
endfunction()


function(arcbuild_get_vs_cmake_generator generator_var sdk arch)
  if(sdk STREQUAL "vs2019")
    set(vs_version "16 2019")
  elseif(sdk STREQUAL "vs2017")
    set(vs_version "15 2017")
  elseif(sdk STREQUAL "vs2015")
    set(vs_version "14 2015")
  elseif(sdk STREQUAL "vs2013")
    set(vs_version "12 2013")
  elseif(sdk STREQUAL "vs2012")
    set(vs_version "11 2012")
  elseif(sdk STREQUAL "vs2010")
    set(vs_version "10 2010")
  elseif(sdk STREQUAL "vs2008")
    set(vs_version "9 2008")
  elseif(sdk STREQUAL "vs2005")
    set(vs_version "8 2005")
  else()
    arcbuild_error("Unsupported VS version: ${sdk}")
  endif()
  set(generator "Visual Studio ${vs_version}")
  if(arch STREQUAL "x86")
    if(sdk STRGREATER "vs2017")
      set(generator ${generator} -A Win32)
    else()
      set(generator "${generator}")
    endif()
  elseif(arch STREQUAL "x64")
    if(sdk STRGREATER "vs2017")
      set(generator ${generator} -A x64)
    else()
      set(generator "${generator} Win64")
    endif()
  elseif(arch STREQUAL "arm" AND sdk STRGREATER "vs2012") # from vs2013
    if(sdk MATCHES "^(vs2019)$")
      set(generator ${generator} -A ARM)
    else()
      set(generator "${generator} ARM")
    endif()
  elseif(arch STREQUAL "arm64" AND sdk STRGREATER "vs2015") # from vs2017
    if(sdk MATCHES "^(vs2019)$")
      set(generator ${generator} -A ARM64)
    else()
      set(generator "${generator} ARM64")
    endif()
  else()
    arcbuild_error("Unsupported architecture for ${sdk}: ${arch}")
  endif()
  set(${generator_var} ${generator} PARENT_SCOPE)
endfunction()


function(arcbuild_latest_vs_property property_name property_value_var)
  set(vswhere_exec "$ENV{ProgramFiles\(x86\)}\\Microsoft Visual Studio\\Installer\\vswhere.exe")
  if(EXISTS ${vswhere_exec})
    execute_process(COMMAND "${vswhere_exec}"
      -latest -property ${property_name}
      OUTPUT_VARIABLE property_value
      RESULT_VARIABLE vswhere_ret)
    if(NOT vswhere_ret EQUAL 0)
      arcbuild_error("Fail to query property ${property_name} from ${vswhere_exec}")
    endif()
    string(STRIP "${property_value}" property_value)
    set(${property_value_var} ${property_value} PARENT_SCOPE)
  else()
    unset(${property_value_var} PARENT_SCOPE)
  endif()
endfunction()


function(arcbuild_collect_argv_not_in var_name excludes)
  set(results)
  foreach(candidate ${ARGN})
    set(found 0)
    foreach(name ${${excludes}})
      if(candidate STREQUAL name)
        set(found 1)
        break()
      endif()
    endforeach()
    if(NOT found)
      list(APPEND results ${candidate})
    endif()
  endforeach()
  set(${var_name} ${results} PARENT_SCOPE)
endfunction()


function(arcbuild_clean_cmake_cache binary_dir)
  arcbuild_warn("Cleaning cache in ${binary_dir}")
  file(GLOB paths "${binary_dir}/CMakeCache.txt" "${binary_dir}/*.sln")
  foreach(path ${paths})
    arcbuild_echo("- ${path}")
    file(REMOVE ${path})
  endforeach()
endfunction()


function(arcbuild_get_first_available_path var_name)
  if(NOT IS_WINDOWS)
    string(REPLACE ":" ";" ARGN ${ARGN})
  endif()
  foreach(path ${ARGN})
    if(EXISTS "${path}")
      set(${var_name} "${path}" PARENT_SCOPE)
      break()
    endif()
  endforeach()
endfunction()


# Fill the defaults values before generate and build project.
macro(arcbuild_build_default_values)
  ##############################
  # Parse arguments

  # Helper variables
  if(CMAKE_COMMAND MATCHES "\\.exe$")
    set(IS_WINDOWS ON)
  endif()

  # Verbose
  if(NOT DEFINED VERBOSE)
    set(VERBOSE 2)
  endif()
  arcbuild_set_from_short_var(ARCBUILD VERBOSE)

  ##############################
  # Default values

  arcbuild_set_to_short_var(CMAKE TOOLCHAIN_FILE MAKE_PROGRAM VERBOSE_MAKEFILE BUILD_TYPE)

  if(NOT PLATFORM)
    arcbuild_error("Please set target platform, e.g. -DPLATFORM=android!")
  endif()

  # BUILD_TYPE
  if(NOT BUILD_TYPE)
    set(BUILD_TYPE Release)
  endif()

  # PLATFORM & SDK for vc
  if(PLATFORM MATCHES "^(vc|vs)[0-9]+")
    set(SDK ${PLATFORM})
    set(PLATFORM windows)
  endif()

  # ARCH
  if(NOT DEFINED ARCH)
    if(PLATFORM MATCHES "^(windows)$")
      set(ARCH x86)
    elseif(PLATFORM MATCHES "^(linux|mac)$")
      set(ARCH x86)
    elseif(PLATFORM MATCHES "^(android|tizen)$")
      set(ARCH armv7-a)
    elseif(PLATFORM MATCHES "^ios")
      set(ARCH armv7;armv7s;arm64;arm64e)
    endif()
  endif()

  # SOURCE_DIR
  if(NOT SOURCE_DIR)
    arcbuild_error("No source directory is provided!")
  endif()

  # BINARY_DIR
  if(NOT BINARY_DIR)
    set(BINARY_DIR ".")
  endif()

  # ROOT from system enviroment variables
  if(NOT ROOT)
    if(DEFINED ENV{SDK_ROOT})
      arcbuild_get_first_available_path(ROOT $ENV{SDK_ROOT})
      arcbuild_warn("Set ROOT from ENV{SDK_ROOT}: ${ROOT}")
    elseif(PLATFORM STREQUAL "android" AND DEFINED ENV{ANDROID_NDK_ROOT})
      arcbuild_get_first_available_path(ROOT $ENV{ANDROID_NDK_ROOT})
      arcbuild_warn("Set ROOT from ENV{ANDROID_NDK_ROOT}: ${ROOT}")
    endif()
  endif()

  # Get make program
  if(PLATFORM STREQUAL "windows")
    arcbuild_get_vs_cmake_generator(CMAKE_GENERATOR "${SDK}" "${ARCH}")
    # set(CMAKE_CONFIGURATION_TYPES ${BUILD_TYPE}) # ignore file generation warning for multiple configurations
  else()
    if(NOT MAKE_PROGRAM)
      arcbuild_get_make_program(MAKE_PROGRAM ${PLATFORM} "${ROOT}" "${SDK}")
    endif()
    set(CMAKE_GENERATOR "Unix Makefiles")
    # Get toolchain file
    if(NOT TOOLCHAIN_FILE)
      arcbuild_get_toolchain(TOOLCHAIN_FILE ${PLATFORM} ${ARCH})
    endif()
    if(TOOLCHAIN_FILE)
      get_filename_component(TOOLCHAIN_FILE "${TOOLCHAIN_FILE}" REALPATH BASE_DIR "${ARCBUILD}/toolchains")
    endif()
  endif()

  # Convert ROOT to absolute and cmake-style path
  if(ROOT)
    get_filename_component(ROOT "${ROOT}" ABSOLUTE)
    file(TO_CMAKE_PATH "${ROOT}" ROOT)
  endif()

  # ARCBUILD_EXECUTE_PROCESS_ARGS
  if(VERBOSE EQUAL 0)
    list(APPEND ARCBUILD_EXECUTE_PROCESS_ARGS OUTPUT_QUIET)
  endif()
  if(NOT CMAKE_VERSION VERSION_LESS "3.8")
    arcbuild_echo("ENCODING=AUTO for CMake>=3.8")
    list(APPEND ARCBUILD_EXECUTE_PROCESS_ARGS ENCODING AUTO)
  endif()
endmacro()


# Generate the cmake project.
function(arcbuild_build_generate)

  ##############################
  # Parsing and processing arguments

  set(ARGUMENTS
    SOURCE_DIR BINARY_DIR
    PLATFORM ARCH TYPE BUILD_TYPE
    SDK STL TOOLCHAIN VERBOSE
    ROOT TOOLCHAIN_FILE C_FLAGS CXX_FLAGS LINKER_FLAGS LD_FLAGS
    API_VERSION HIDDEN VERBOSE_MAKEFILE
    MAKE_PROGRAM)

  # Remove processed arguments
  arcbuild_collect_argv_not_in(remained_cmake_args ARGUMENTS ${ARGN})
  arcbuild_join(remained_cmake_args_display " " ${remained_cmake_args})
  arcbuild_echo("Remained arguments: ${remained_cmake_args_display}")

  # Hack for Visual Studio 2015
  if(PLATFORM STREQUAL "windows")
    arcbuild_latest_vs_property("installationVersion" latest_vs_install_version)
    arcbuild_echo("Lastest VS install version: ${latest_vs_install_version}")
    if(SDK STREQUAL "vs2015" AND latest_vs_install_version VERSION_GREATER "15")
      # https://gitlab.kitware.com/cmake/cmake/issues/17788
      arcbuild_warn("Add CMAKE_SYSTEM_VERSION=8.1 for vs2015 when vs>=2017 is installed")
      list(APPEND ARCBUILD_UNPARSED_ARGS -DCMAKE_SYSTEM_VERSION=8.1)
    endif()
  endif()

  # Verbose of makefiles
  if(VERBOSE GREATER 3)
    arcbuild_echo("Enable verbose Makefiles")
    set(VERBOSE_MAKEFILE ON)
  else()
    set(VERBOSE_MAKEFILE OFF)
  endif()

  # Print information
  arcbuild_echo("Building Information:")
  foreach(name ARCBUILD ARCBUILD_VERSION
    CMAKE_COMMAND CMAKE_VERSION CMAKE_GENERATOR
    ${ARGUMENTS} ${remained_cmake_args}
    )
    if(DEFINED ${name})
      arcbuild_echo("- ${name}: ${${name}}")
    endif()
  endforeach()

  # Set from short variables
  arcbuild_set_from_short_var(ARCBUILD TYPE PLATFORM SDK VERBOSE HIDDEN)
  arcbuild_set_from_short_var(SDK ROOT ARCH API_VERSION STL TOOLCHAIN)
  arcbuild_set_from_short_var(CMAKE TOOLCHAIN_FILE MAKE_PROGRAM VERBOSE_MAKEFILE BUILD_TYPE)

  # Add compile and link flags
  if(PLATFORM STREQUAL "windows")
    arcbuild_append_c_flags("/DARCBUILD=1")
  else()
    arcbuild_append_c_flags("-Wall -DARCBUILD=1")
    if(ARCH STREQUAL "x86")
      arcbuild_append_c_flags("-m32")
    elseif(ARCH STREQUAL "x64")
      arcbuild_append_c_flags("-m64")
    endif()
    if(HIDDEN)
      # arcbuild_append_c_flags("-fdata-sections -ffunction-sections")
      arcbuild_append_c_flags("-fvisibility=hidden -fdata-sections -ffunction-sections")
      arcbuild_append_cxx_flags("-fvisibility-inlines-hidden")
    endif()
  endif()
  if(C_FLAGS)
    arcbuild_append_c_flags(${C_FLAGS})
  endif()
  if(CXX_FLAGS)
    arcbuild_append_cxx_flags(${CXX_FLAGS})
  endif()
  if(LINKER_FLAGS)
    arcbuild_append_link_flags(${LINKER_FLAGS})
  endif()
  if(LD_FLAGS)
    arcbuild_append_link_flags(${LD_FLAGS})
  endif()

  # Collect cmake arguments
  set(cmake_args -G ${CMAKE_GENERATOR} ${ARCBUILD_UNPARSED_ARGS})
  foreach(name
    ARCBUILD
    ARCBUILD_VERBOSE
    ARCBUILD_HIDDEN

    SDK_ROOT
    SDK_ARCH
    SDK_API_VERSION
    SDK_STL
    SDK_TOOLCHAIN

    CMAKE_BUILD_TYPE
    CMAKE_CONFIGURATION_TYPES

    CMAKE_TOOLCHAIN_FILE
    CMAKE_MAKE_PROGRAM
    CMAKE_VERBOSE_MAKEFILE
    ${remained_cmake_args}
    )
    if(DEFINED ${name})
      # join list as execute_process() do not support list arguments
      arcbuild_join(${name} " " ${${name}})
      list(APPEND cmake_args -D${name}=${${name}})
    endif()
  endforeach()
  foreach(name
    CMAKE_C_FLAGS
    CMAKE_CXX_FLAGS
    CMAKE_EXE_LINKER_FLAGS
    CMAKE_MODULE_LINKER_FLAGS
    CMAKE_SHARED_LINKER_FLAGS
    )
    if(DEFINED ${name})
      if(CMAKE_TOOLCHAIN_FILE)
        list(APPEND cmake_args -D${name}=${${name}})
      else()
        # Use CMAKE_XXX_FLAGS_INIT for native compiling
        list(APPEND cmake_args -D${name}_INIT=${${name}})
      endif()
    endif()
  endforeach()

  ##############################
  # Generate, build and pack

  # Remove old SDK's
  file(GLOB zips "${BINARY_DIR}/*.ZIP")
  if(zips)
    arcbuild_warn("Removing old SDK's:")
    foreach(path ${zips})
      arcbuild_warn("- ${path}")
      file(REMOVE "${path}")
    endforeach()
  endif()

  # Create build directory if not existed
  if(NOT EXISTS "${BINARY_DIR}")
    arcbuild_echo("Make build directory: ${BINARY_DIR}")
    file(MAKE_DIRECTORY "${BINARY_DIR}")
  endif()

  # Clean cache in binary directory
  file(REMOVE "${BINARY_DIR}/arcbuild.dir")
  arcbuild_clean_cmake_cache("${BINARY_DIR}")

  # Generate Makfiles
  arcbuild_echo("Generating Makefiles ...")
  get_filename_component(SOURCE_DIR "${SOURCE_DIR}" ABSOLUTE)
  list(APPEND cmake_args "${SOURCE_DIR}")
  arcbuild_join(cmake_args_display " " ${cmake_args})
  arcbuild_echo("CMake arguments: ${cmake_args_display}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} ${cmake_args}
    WORKING_DIRECTORY "${BINARY_DIR}"
    RESULT_VARIABLE generate_ret
    ${ARCBUILD_EXECUTE_PROCESS_ARGS}
  )
  if(NOT generate_ret EQUAL 0)
    arcbuild_error("Makefiles generation failed!")
  endif()
endfunction()


function(arcbuild_build)
  arcbuild_build_default_values()
  arcbuild_build_generate(${ARGN})
endfunction()
