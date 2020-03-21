# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

cmake_minimum_required(VERSION 3.1)

include(CMakeParseArguments)

if(NOT DEFINED ARCBUILD_VERBOSE)
  set(ARCBUILD_VERBOSE 2)
endif()
if(NOT CMAKE_VERSION VERSION_LESS 3.13)
  cmake_policy(SET CMP0077 NEW) # prefer nornal non-cache variable with same name
endif()
option(ARCBUILD_VERBOSE ${ARCBUILD_VERBOSE} "Verbose output of arcbuild")


function(arcbuild_debug)
  if(ARCBUILD_VERBOSE GREATER 2)
    message(STATUS "ARCBUILD/D: " ${ARGN})
  endif()
endfunction()


function(arcbuild_echo)
  if(ARCBUILD_VERBOSE GREATER 1)
    message(STATUS "ARCBUILD/I: " ${ARGN})
  endif()
endfunction()


function(arcbuild_warn)
  if(ARCBUILD_VERBOSE GREATER 0)
    message(STATUS "ARCBUILD/W: " ${ARGN})
  endif()
endfunction()


function(arcbuild_error)
  message(FATAL_ERROR "ARCBUILD/E: " ${ARGN})
endfunction()


macro(arcbuild_append_flags _flag_name)
  set(_var_name CMAKE_${_flag_name})
  set(${_var_name} "${${_var_name}} ${ARGN}")
  string(STRIP "${${_var_name}}" ${_var_name})
  unset(_var_name)
endmacro()


macro(arcbuild_append_c_flags)
  arcbuild_append_flags(C_FLAGS ${ARGN})
  arcbuild_append_flags(CXX_FLAGS ${ARGN})
endmacro()


macro(arcbuild_append_cxx_flags)
  arcbuild_append_flags(CXX_FLAGS ${ARGN})
endmacro()


macro(arcbuild_append_link_flags)
  arcbuild_append_flags(EXE_LINKER_FLAGS ${ARGN})
  arcbuild_append_flags(MODULE_LINKER_FLAGS ${ARGN})
  arcbuild_append_flags(SHARED_LINKER_FLAGS ${ARGN})
endmacro()


function(arcbuild_copy_target_properties src_target dst_target)
  foreach(prop ${ARGN})
    get_target_property(prop_val ${src_target} ${prop})
    if(prop_val)
      set_target_properties(${dst_target} PROPERTIES ${prop} "${prop_val}")
    endif()
  endforeach()
endfunction()


function(arcbuild_target_map_file name map_path)
  if(MSVC)
    return()
  endif()
  get_target_property(build_type ${name} TYPE)
  if(NOT build_type STREQUAL "SHARED_LIBRARY")
    return()
  endif()
  get_target_property(LINK_FLAGS ${name} LINK_FLAGS)
  if(NOT LINK_FLAGS)
    set(LINK_FLAGS)
  endif()
  if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    list(APPEND LINK_FLAGS "-Wl,--gc-sections -Wl,--as-needed -Wl,--strip-all -Wl,--strip-debug")
    list(APPEND LINK_FLAGS "-Wl,--gc-sections -Wl,--as-needed -Wl,--strip-all -Wl,--strip-debug")
  elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # http://releases.llvm.org/2.9/docs/CommandGuide/html/llvm-ld.html
    # list(APPEND LINK_FLAGS "-Wl,-dead_strip -Wl,-s -Wl,-S")
    list(APPEND LINK_FLAGS "-Wl,-s -Wl,-S")
  endif()
  if(ARGN)
    get_filename_component(version_script_path "${ARGN}" REALPATH)
    list(APPEND LINK_FLAGS "-Wl,--version-script=\"${version_script_path}\"")
  endif()
  list(APPEND LINK_FLAGS "-Wl,--Map=\"${map_path}\"")
  arcbuild_join(LINK_FLAGS " " ${LINK_FLAGS})
  set_target_properties(${name} PROPERTIES LINK_FLAGS "${LINK_FLAGS}")
endfunction()


###########################################################
# Common function

function(arcbuild_join var_name sep)
  string(REPLACE ";" ${sep} result "${ARGN}")
  set(${var_name} "${result}" PARENT_SCOPE)
endfunction()


function(arcbuild_add_prefix var_name prefix)
  set(result)
  foreach(item ${ARGN})
    list(APPEND result "${prefix}${item}")
  endforeach()
  set(${var_name} ${result} PARENT_SCOPE)
endfunction()


function(arcbuild_get_realpaths var_name base_dir)
  set(paths)
  foreach(path ${ARGN})
    get_filename_component(path "${path}" REALPATH BASE_DIR "${base_dir}")
    list(APPEND paths "${path}")
  endforeach()
  set(${var_name} ${paths} PARENT_SCOPE)
endfunction()


set(ARCBUILD "${CMAKE_CURRENT_LIST_DIR}")
