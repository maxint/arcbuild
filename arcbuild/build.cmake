# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

include("${ARCBUILD}/core.cmake")

function(arcbuild_set_from_short_var prefix)
  foreach(name ${ARGN})
    if(DEFINED ${name})
      set(${prefix}_${name} "${${name}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

function(arcbuild_set_to_short_var prefix)
  foreach(name ${ARGN})
    set(prefix_name "${prefix}_${name}")
    if(${prefix_name})
      set(${name} "${${prefix_name}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

function(arcbuil_add_to_env_path)
  foreach(path ${ARGN})
    file(TO_NATIVE_PATH "${path}" path)
    if(WIN32)
      set(ENV{PATH} "$ENV{PATH};${path}")
    else()
      set(ENV{PATH} "$ENV{PATH}:${path}")
    endif()
  endforeach()
endfunction()

function(arcbuild_get_toolchain var_name platform)
  if(platform STREQUAL "android")
    set(path "android-ndk.cmake")
  elseif(platform MATCHES "^ios")
    set(path "ios-xcode.cmake")
  elseif(platform MATCHES "^tizen")
    set(path "tizen2.2.cmake")
  else()
    unset(path)
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
  elseif(platform STREQUAL "windows")
    if(sdk STREQUAL "vc6")
      set(path "nmake")
    else()
      set(path "devenv")
    endif()
  else()
    set(path "make")
  endif()
  if(path AND NOT path MATCHES "^(make|nmake|devenv|msbuild)$")
    get_filename_component(path "${path}" ABSOLUTE)
    file(TO_NATIVE_PATH "${path}" path)
  endif()
  set(${var_name} ${path} PARENT_SCOPE)
endfunction()


function(arcbuild_find_msbuild var_name vc_root)
  file(GLOB search_paths
    "$ENV{ProgramFiles}/MSBuild/*/Bin"
    "$ENV{ProgramFiles} (x86)/MSBuild/*/Bin"
  )
  if(search_paths)
    list(REVERSE search_paths)
  endif()
  list(INSERT search_paths 0 "${vc_root}/MSBuild/*/Bin")
  unset(path)
  find_file(path NAMES "msbuild.exe" "MSBuild.exe"
    PATHS ${search_paths}
    NO_DEFAULT_PATH
  )
  set(${var_name} ${path} PARENT_SCOPE)
endfunction()


function(arcbuild_find_devenv var_name vc_root)
  unset(path)
  find_file(path NAMES "devenv.com" "devenv.exe"
    PATHS
    "${vc_root}/Common/IDE/IDE98" # vc6
    "${vc_root}/Common7/IDE" # vs2015, vs2017
    NO_DEFAULT_PATH
  )
  set(${var_name} "${path}" PARENT_SCOPE)
endfunction()


function(arcbuild_find_vc_root_in_cache_file var_name binary_dir)
  file(READ "${binary_dir}/CMakeCache.txt" content)
  string(REGEX MATCH "CMAKE_LINKER:FILEPATH=.*/link.exe" line "${content}")
  string(REPLACE "CMAKE_LINKER:FILEPATH=" "" line "${line}")
  string(REGEX REPLACE "/VC/.*/link.exe" "" line "${line}")
  set(${var_name} "${line}" PARENT_SCOPE)
endfunction()


function(arcbuild_find_vc_build_cmd var_name name binary_dir)
  arcbuild_find_vc_root_in_cache_file(vc_root "${binary_dir}")
  arcbuild_echo("VC_ROOT: ${vc_root}")
  if(name STREQUAL "msbuild")
    arcbuild_find_msbuild(path "${vc_root}")
  elseif(name STREQUAL "devenv")
    arcbuild_find_devenv(path "${vc_root}")
  else()
    arcbuild_error("Unknown VC build tool: ${name}")
  endif()
  if(NOT path)
    arcbuild_error("Could not find VC build tool: ${name}")
  endif()
  set(${var_name} "${path}" PARENT_SCOPE)
endfunction()


function(arcbuild_get_vc_root root_var sdk)
  unset(path)
  if(sdk STREQUAL "vc6")
    find_path(path NAMES "Bin/VCVARS32.BAT"
      PATHS
      "$ENV{ProgramFiles}/Microsoft Visual Studio/VC98"
      "$ENV{ProgramFiles} (x86)/Microsoft Visual Studio/VC98"
      NO_DEFAULT_PATH
    )
  elseif(sdk STREQUAL "vs2017")
    file(GLOB search_paths
      "$ENV{ProgramFiles}/Microsoft Visual Studio/2017/*/VC"
      "$ENV{ProgramFiles} (x86)/Microsoft Visual Studio/2017/*/VC"
    )
    find_path(path NAMES "Auxiliary/Build/vcvarsall.bat"
      PATHS ${search_paths}
      NO_DEFAULT_PATH
    )
  else()
    if(sdk STREQUAL "vs2012")
      set(version 11)
    elseif(sdk STREQUAL "vs2013")
      set(version 12)
    elseif(sdk STREQUAL "vs2015")
      set(version 14)
    elseif(sdk STREQUAL "vs2017")
      set(version 15)
    endif()
    find_path(path NAMES "vcvarsall.bat"
      PATHS
      "$ENV{VS${version}0COMNTOOLS}/../../VC"
      "$ENV{ProgramFiles}/Microsoft Visual Studio ${version}.0/VC"
      "$ENV{ProgramFiles} (x86)/Microsoft Visual Studio ${version}.0/VC"
      NO_DEFAULT_PATH
    )
  endif()
  if(path)
    get_filename_component(path "${path}" ABSOLUTE)
    file(TO_NATIVE_PATH "${path}" path)
    set(${root_var} ${path} PARENT_SCOPE)
    unset(path CACHE)
  elseif(sdk STREQUAL "vc6")
    arcbuild_error("Unknown VC SDK: ${sdk}!")
  else()
    arcbuild_warn("Could not find SDK root for: ${sdk}")
  endif()
endfunction()

function(arcbuild_get_vc_env_run vc_env_run_var root sdk arch)
  unset(vc_env_run)
  if(sdk STREQUAL "vc6")
    if(arch STREQUAL "x86")
      set(vc_env_run "${root}\\Bin\\VCVARS32.BAT")
    endif()
  elseif(sdk STREQUAL "vs2017")
    if(arch STREQUAL "x86")
      set(vc_env_run "${root}\\Auxiliary\\Build\\vcvars32.bat")
    elseif(arch STREQUAL "x64")
      set(vc_env_run "${root}\\Auxiliary\\Build\\vcvars64.bat")
    endif()
  else()
    if(DEFINED ENV{ProgramW6432})
      if(arch STREQUAL "arm")
        set(arch "amd64_arm")
      elseif(arch STREQUAL "x64")
        set(arch "amd64")
      elseif(arch STREQUAL "x86")
        set(arch "amd64_x86")
      endif()
    else()
      if(arch STREQUAL "arm")
        set(arch "x86_arm")
      elseif(arch STREQUAL "x64")
        set(arch "x86_amd64")
      elseif(arch STREQUAL "x86")
        set(arch "x86")
      endif()
    endif()
    unset(path)
    if(arch)
      find_path(path NAMES "bin/${arch}/cl.exe" PATHS ${root} NO_DEFAULT_PATH)
      if(path)
        set(vc_env_run "${root}\\vcvarsall.bat" ${arch})
        unset(path CACHE)
      endif()
    endif()
  endif()
  if(vc_env_run)
    set(${vc_env_run_var} ${vc_env_run} PARENT_SCOPE)
  else()
    arcbuild_error("Unsupported arch(${arch}) in VC (${root})!")
  endif()
endfunction()


function(arcbuild_get_vs_cmake_generator generator_var sdk arch)
  if(sdk STREQUAL "vs2017")
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
  if(arch STREQUAL "x64")
    set(generator "${generator} Win64")
  elseif(arch STREQUAL "arm")
    set(generator "${generator} ARM")
  elseif(NOT arch STREQUAL "x86")
    arcbuild_error("Unsupported architecture for ${sdk}: ${arch}")
  endif()
  set(${generator_var} ${generator} PARENT_SCOPE)
endfunction()


function(arcbuild_get_make_targets var_name make_cmd work_dir)
  arcbuild_execute_process(
    COMMAND ${make_cmd} help
    WORKING_DIRECTORY "${work_dir}"
    RESULT_VARIABLE ret
    OUTPUT_VARIABLE output
    CMD_FILENAME "make_help"
    ERROR_QUIET
  )
  string(REGEX MATCHALL "\\.\\.\\. ([^ \r\n\"]+)" targets "${output}")
  string(REPLACE "... " ";" targets "${targets}")
  string(STRIP "${targets}" targets)
  set(${var_name} ${targets} PARENT_SCOPE)
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


function(arcbuild_execute_process)
  cmake_parse_arguments(A
    "CHECK_DIFF;NO_EXEC" # options
    "WORKING_DIRECTORY;CMD_FILENAME" # single value
    "COMMAND;CMD_ARGS" # multiple values
    ${ARGN}
  )
  set(content "")
  foreach(cmd ${A_COMMAND})
    string(REGEX REPLACE "\"[^\"]+\"" "" cmd_filtered "${cmd}")
    if(cmd_filtered MATCHES "[ \t]+")
      set(cmd "\"${cmd}\"")
    endif()
    set(content "${content}${cmd} ")
  endforeach()
  if(IS_WINDOWS)
    set(content "@echo off\n${content} %*")
  else()
    set(content "${content} $*")
  endif()
  if(CMAKE_COMMAND MATCHES "\\.exe$")
    set(A_CMD_FILENAME "${A_CMD_FILENAME}.bat")
  else()
    set(A_CMD_FILENAME "${A_CMD_FILENAME}.sh")
  endif()
  set(A_CMD_FILEPATH "${A_WORKING_DIRECTORY}/${A_CMD_FILENAME}")
  if(A_CHECK_DIFF)
    if(EXISTS "${A_CMD_FILEPATH}")
      file(READ "${A_CMD_FILEPATH}" old_content)
      if(content STREQUAL old_content)
        cmake_parse_arguments(A
          "" # options
          "RESULT_VARIABLE" # single value
          "" # multiple values
          ${ARGN}
        )
        arcbuild_warn("Ignore command runing when no DIFF: ${A_CMD_FILEPATH}")
        if(A_RESULT_VARIABLE)
          set(${A_RESULT_VARIABLE} 0 PARENT_SCOPE) # return 0
        endif()
        return()
      endif()
    endif()
  endif()
  file(WRITE "${A_CMD_FILEPATH}" "${content}")
  if(IS_WINDOWS)
    set(final_cmd "cmd" "/c" "${A_CMD_FILENAME}")
  else()
    set(final_cmd "bash" "${A_CMD_FILENAME}")
  endif()
  if(NOT CMAKE_VERSION VERSION_LESS "3.8")
    set(ENCODING_ARGUMENT ENCODING AUTO)
  endif()
  if(NOT A_NO_EXEC)
    execute_process(
      COMMAND ${final_cmd} ${A_CMD_ARGS}
      WORKING_DIRECTORY ${A_WORKING_DIRECTORY}
      ${ENCODING_ARGUMENT}
      ${A_UNPARSED_ARGUMENTS}
    )
    cmake_parse_arguments(A
      "" # options
      "RESULT_VARIABLE;OUTPUT_VARIABLE" # single value
      "" # multiple values
      ${ARGN}
    )
    if(A_RESULT_VARIABLE)
      set(${A_RESULT_VARIABLE} ${${A_RESULT_VARIABLE}} PARENT_SCOPE)
    endif()
    if(A_OUTPUT_VARIABLE)
      set(${A_OUTPUT_VARIABLE} ${${A_OUTPUT_VARIABLE}} PARENT_SCOPE)
    endif()
  endif()
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


function(arcbuild_build)
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

  arcbuild_echo("--------------------------")
  arcbuild_echo("--*-- START building --*--")

  ##############################
  # Default values

  # SOURCE_DIR
  if(NOT SOURCE_DIR)
    set(SOURCE_DIR ".")
  endif()

  if(NOT PLATFORM)
    arcbuild_error("Please set target platform, e.g. -DPLATFORM=android!")
  endif()

  # PLATFORM & SDK for vc
  if(PLATFORM MATCHES "^(vc|vs)[0-9]+")
    set(SDK ${PLATFORM})
    set(PLATFORM "windows")
  endif()

  # ARCH
  if(NOT DEFINED ARCH)
    if(PLATFORM MATCHES "^(windows|linux|mac)$")
      set(ARCH "x86")
    elseif(PLATFORM MATCHES "^(android|tizen)$")
      set(ARCH "armv7-a")
    elseif(PLATFORM MATCHES "^ios")
      set(ARCH "armv7;armv7s;arm64")
    endif()
  endif()

  # TYPE
  # if(NOT DEFINED TYPE)
  #   set(TYPE "SHARED")
  # endif()
  if(TYPE)
    string(TOUPPER "${TYPE}" TYPE)
  endif()

  # ROOT from system enviroment variables
  if(NOT ROOT)
    if(PLATFORM STREQUAL "android")
      if(DEFINED ENV{ANDROID_NDK_ROOT})
        arcbuild_get_first_available_path(ROOT $ENV{ANDROID_NDK_ROOT})
        arcbuild_warn("Set ROOT from ENV{ANDROID_NDK_ROOT}: ${ROOT}")
      endif()
    elseif(PLATFORM STREQUAL "windows")
      arcbuild_get_vc_root(ROOT "${SDK}")
    endif()
  endif()

  # Get make program
  if(NOT MAKE_PROGRAM)
    arcbuild_get_make_program(MAKE_PROGRAM ${PLATFORM} "${ROOT}" "${SDK}")
  endif()
  if(MAKE_PROGRAM STREQUAL "nmake")
    set(NMAKE TRUE)
    set(CMAKE_GENERATOR "NMake Makefiles")
  elseif(MAKE_PROGRAM MATCHES "^(msbuild|devenv)$")
    set(MSVC_IDE TRUE)
    if(MAKE_PROGRAM STREQUAL "msbuild")
      set(MSBUILD TRUE)
    else()
      set(DEVENV TRUE)
    endif()
    arcbuild_get_vs_cmake_generator(CMAKE_GENERATOR "${SDK}" "${ARCH}")
  else()
    set(CMAKE_GENERATOR "Unix Makefiles")
  endif()

  # Get toolchain file
  if(NOT TOOLCHAIN_FILE)
    if(NOT MSVC_IDE)
      arcbuild_get_toolchain(TOOLCHAIN_FILE ${PLATFORM})
      if(TOOLCHAIN_FILE MATCHES ".cmake$")
        set(TOOLCHAIN_FILE "${ARCBUILD}/toolchains/${TOOLCHAIN_FILE}")
      endif()
    endif()
  elseif(NOT EXISTS ${TOOLCHAIN_FILE})
    set(TOOLCHAIN_FILE "${ARCBUILD}/toolchains/${TOOLCHAIN_FILE}")
  else()
    get_filename_component(TOOLCHAIN_FILE "${TOOLCHAIN_FILE}" REALPATH)
  endif()

  # SKIP_RPATH and BUILD_TYPE
  if(NOT MSVC_IDE)
    if(NOT DEFINED SKIP_RPATH)
      set(SKIP_RPATH ON)
    endif()
  endif()
  if(NOT BUILD_TYPE)
    set(BUILD_TYPE "Release")
  endif()

  # Get binary direcotry
  if(TYPE STREQUAL "SHARED")
    set(TYPE_SUFFIX "shared")
  endif()
  arcbuild_join(binary_subdir "_" ${PLATFORM} ${SDK} ${ARCH} ${TYPE_SUFFIX})

  get_filename_component(SOURCE_DIR "${SOURCE_DIR}" ABSOLUTE)

  # Convert ROOT to cmake-style path
  if(ROOT)
    file(TO_CMAKE_PATH "${ROOT}" ROOT)
  endif()

  ##############################

  set(ARGUMENTS PLATFORM ARCH TYPE BUILD_TYPE
                SDK STL SOURCE_DIR VERBOSE
                ROOT TOOLCHAIN_FILE C_FLAGS CXX_FLAGS LINKER_FLAGS
                API_VERSION SKIP_RPATH VERBOSE_MAKEFILE
                MAKE_PROGRAM)

  # Remove processed arguments
  arcbuild_collect_argv_not_in(remained_cmake_args ARGUMENTS ${ARGN})

  # Commands of make and cmake
  # if(CMAKE_VERSION VERSION_LESS "3.4")
  #   arcbuild_download_cmake(CMAKE_CMD)
  #   arcbuild_warn("Use CMake: ${CMAKE_CMD}")
  # else()
  #   set(CMAKE_CMD ${CMAKE_COMMAND})
  # endif()
  set(CMAKE_CMD ${CMAKE_COMMAND})
  set(MAKE_CMD ${MAKE_PROGRAM})
  if(PLATFORM STREQUAL "windows")
    if(NMAKE)
      arcbuild_get_vc_env_run(VC_ENV_RUN "${ROOT}" "${SDK}" "${ARCH}")
      list(INSERT CMAKE_CMD 0 ${VC_ENV_RUN} &&)
      list(INSERT MAKE_CMD 0 ${VC_ENV_RUN} &&)
    else()
      unset(MAKE_PROGRAM) # make is useless for msbuild or devenv
    endif()
    unset(ROOT)
  endif()

  # Verbose of makefiles
  if(NOT MSVC_IDE)
    if(VERBOSE GREATER 3)
      arcbuild_echo("Enable verbose Makefiles")
      set(VERBOSE_MAKEFILE ON)
    else()
      set(VERBOSE_MAKEFILE OFF)
    endif()
  endif()

  # Print information
  arcbuild_echo("Building Information:")
  foreach(name ${ARGUMENTS} CMAKE_COMMAND CMAKE_VERSION CMAKE_GENERATOR VC_ENV_RUN CMAKE_CMD MAKE_CMD ${remained_cmake_args})
    if(DEFINED ${name})
      arcbuild_echo("- ${name}: ${${name}}")
    endif()
  endforeach()
  arcbuild_echo("Remained arguments: ${remained_cmake_args}")

  # Set from short variables
  arcbuild_set_from_short_var(ARCBUILD PLATFORM SDK VERBOSE)
  arcbuild_set_from_short_var(SDK ROOT ARCH API_VERSION STL)
  arcbuild_set_from_short_var(CMAKE TOOLCHAIN_FILE MAKE_PROGRAM VERBOSE_MAKEFILE BUILD_TYPE SKIP_RPATH)

  # Add compile and link flags
  if(C_FLAGS)
    arcbuild_append_c_flags(${C_FLAGS})
  endif()
  if(CXX_FLAGS)
    arcbuild_append_cxx_flags(${CXX_FLAGS})
  endif()
  if(LINKER_FLAGS)
    arcbuild_append_link_flags(${LINKER_FLAGS})
  endif()
  if(NOT PLATFORM STREQUAL "windows")
    arcbuild_append_c_flags("-Wall")
    if(ARCH STREQUAL "x86")
      arcbuild_append_c_flags("-m32")
    elseif(ARCH STREQUAL "x64")
      arcbuild_append_c_flags("-m64")
    endif()
  endif()

  # Collect cmake arguments
  set(cmake_args -G"${CMAKE_GENERATOR}")
  if(MSVC_IDE)
    list(APPEND cmake_args -DCMAKE_CONFIGURATION_TYPES="${BUILD_TYPE}")
  endif()
  foreach(name
    ARCBUILD
    ARCBUILD_VERBOSE

    SDK_ROOT
    SDK_ARCH
    SDK_API_VERSION
    SDK_STL

    CMAKE_BUILD_TYPE
    CMAKE_C_FLAGS
    CMAKE_CXX_FLAGS
    CMAKE_SHARED_LINKER_FLAGS
    CMAKE_EXE_LINKER_FLAGS

    CMAKE_TOOLCHAIN_FILE
    CMAKE_MAKE_PROGRAM
    CMAKE_VERBOSE_MAKEFILE
    CMAKE_SKIP_RPATH
    ${remained_cmake_args}
    )
    if(DEFINED ${name})
      list(LENGTH ${name} num_itms)
      if(num_items LESS 2)
        list(APPEND cmake_args "-D${name}=${${name}}")
      else()
        arcbuild_join(value_joined " " ${${name}})
        list(APPEND cmake_args "-D${name}=\"${value_joined}\"")
      endif()
    endif()
  endforeach()

  ##############################
  # Generate, build and pack

  if(VERBOSE EQUAL 0)
    list(APPEND extra_execute_args OUTPUT_QUIET)
  endif()

  get_filename_component(BINARY_DIR "." ABSOLUTE)

  arcbuild_join(cmake_args_joined " " ${cmake_args})
  arcbuild_debug("CMake arguments: ${cmake_args_joined}")

  # Generate Makfiles
  arcbuild_echo("Generating Makefiles ...")
  set(generate_extra_args ${extra_execute_args})
  if(LAZY_GENERATE)
    arcbuild_warn("Lazy generation is enabled")
    list(APPEND generate_extra_args CHECK_DIFF)
  endif()
  arcbuild_execute_process(
    COMMAND ${CMAKE_CMD} "${SOURCE_DIR}" ${cmake_args}
    WORKING_DIRECTORY "${BINARY_DIR}"
    RESULT_VARIABLE ret
    CMD_FILENAME "generate"
    ${generate_extra_args}
  )
  if(NOT ret EQUAL 0)
    arcbuild_error("Makefiles generation failed!")
  endif()

  if(MSVC_IDE)
    arcbuild_find_vc_build_cmd(MAKE_CMD ${MAKE_CMD} "${BINARY_DIR}")
    arcbuild_echo("MAKE_CMD: ${MAKE_CMD}")
    file(GLOB SLN_FILES "${BINARY_DIR}/*.sln")
    arcbuild_echo("SLN files: ${SLN_FILES}")
    list(APPEND MAKE_CMD ${SLN_FILES})
    if(MSBUILD)
      list(APPEND MAKE_CMD "/nologo")
      if(VERBOSE EQUAL 0)
        set(MSBUILD_VERBOSE "/noconsolelogger")
      elseif(VERBOSE EQUAL 1)
        set(MSBUILD_VERBOSE "/verbosity:quiet")
      elseif(VERBOSE EQUAL 2)
        set(MSBUILD_VERBOSE "/verbosity:minimal")
      elseif(VERBOSE EQUAL 3)
        set(MSBUILD_VERBOSE "/verbosity:normal")
      else()
        set(MSBUILD_VERBOSE "/verbosity:detailed")
      endif()
      list(APPEND MAKE_CMD "${MSBUILD_VERBOSE}")
    else()
      list(APPEND MAKE_CMD /Build ${BUILD_TYPE})
    endif()
  elseif(NOT NMAKE)
    list(APPEND MAKE_CMD "-j4") # speed up building
  endif()

  # Build
  arcbuild_echo("Generating Makefiles ...")
  if(IS_WINDOWS AND NOT PLATFORM STREQUAL "windows")
    get_filename_component(MAKE_PROGRAM_DIR "${MAKE_PROGRAM}" DIRECTORY)
    if(MAKE_PROGRAM_DIR)
      list(INSERT MAKE_CMD 0 SET PATH=${MAKE_PROGRAM_DIR} %PATH% &&)
    endif()
  endif()
  arcbuild_execute_process(
    COMMAND ${MAKE_CMD}
    WORKING_DIRECTORY "${BINARY_DIR}"
    NO_EXEC
    CMD_FILENAME "make"
    ${extra_execute_args}
  )
  arcbuild_echo("--*-- END building --*--")
endfunction()
