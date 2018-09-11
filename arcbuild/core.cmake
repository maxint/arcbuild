# The MIT License (MIT)
# Copyright © 2016 Naiyang Lin <maxint@foxmail.com>

cmake_minimum_required(VERSION 3.1)

include(CMakeParseArguments)

if(NOT DEFINED ARCBUILD_VERBOSE)
  set(ARCBUILD_VERBOSE 2)
endif()
option(ARCBUILD_VERBOSE ${ARCBUILD_VERBOSE} "Verbose output of arcbuild")


function(arcbuild_debug)
  if(ARCBUILD_VERBOSE GREATER 2)
    message(STATUS "[D] ${ARGN}")
  endif()
endfunction()


function(arcbuild_echo)
  if(ARCBUILD_VERBOSE GREATER 1)
    message(STATUS "[I] ${ARGN}")
  endif()
endfunction()


function(arcbuild_warn)
  if(ARCBUILD_VERBOSE GREATER 0)
    message(STATUS "[W] " ${ARGN})
  endif()
endfunction()


function(arcbuild_error)
  message(FATAL_ERROR "[E] " ${ARGN})
endfunction()


macro(arcbuild_append_c_flags)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGN}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGN}")
  string(STRIP "${CMAKE_C_FLAGS}" CMAKE_C_FLAGS)
  string(STRIP "${CMAKE_CXX_FLAGS}" CMAKE_CXX_FLAGS)
endmacro()


macro(arcbuild_append_cxx_flags)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGN}")
  string(STRIP "${CMAKE_CXX_FLAGS}" CMAKE_CXX_FLAGS)
endmacro()


macro(arcbuild_append_link_flags)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ARGN}")
  set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    ${ARGN}")
  string(STRIP "${CMAKE_SHARED_LINKER_FLAGS}" CMAKE_SHARED_LINKER_FLAGS)
  string(STRIP "${CMAKE_EXE_LINKER_FLAGS}" CMAKE_EXE_LINKER_FLAGS)
endmacro()


###########################################################
# Common function

function(arcbuild_join var_name sep first)
  set(result "${first}")
  foreach(item ${ARGN})
    set(result "${result}${sep}${item}")
  endforeach()
  # string(REGEX REPLACE "([^\\]|^);" "\\1${sep}" result "${ARGN}")
  # string(REGEX REPLACE "[\\](.)" "\\1" result "${result}") #fixes escaping
  set(${var_name} "${result}" PARENT_SCOPE)
endfunction()


function(arcbuild_add_prefix var_name prefix)
  set(result)
  foreach(item ${ARGN})
    list(APPEND result "${prefix}${item}")
  endforeach()
  set(${var_name} ${result} PARENT_SCOPE)
endfunction()

#
###########################################################


function(arcbuild_collect_link_libraries var_name name)
  set(${var_name} PARENT_SCOPE)

  if(NOT TARGET "${name}")
    return()
  endif()

  get_target_property(TYPE ${name} TYPE)
  if(TYPE STREQUAL "INTERFACE_LIBRARY")
    return()
  endif()

  set(all_depends)
  foreach(prop LINK_LIBRARIES INTERFACE_LINK_LIBRARIES)
    get_target_property(prop_var ${name} ${prop})
    if(prop_var)
      foreach(target ${prop_var})
        if(NOT target MATCHES "^\\$<LINK_ONLY:.*>$")
          arcbuild_collect_link_libraries(depends ${target})
          list(APPEND all_depends ${target} ${depends})
        endif()
      endforeach()
    endif()
  endforeach()
  if(all_depends)
    list(REMOVE_DUPLICATES all_depends)
  endif()
  set(${var_name} ${all_depends} PARENT_SCOPE)
endfunction()


function(arcbuild_collect_manually_added_dependencies var_name)
  set(${var_name} PARENT_SCOPE)
  if(CMAKE_VERSION VERSION_LESS "3.8")
    arcbuild_warn("Fail to query manually added dependencies before CMake 3.8")
    return()
  endif()
  set(all_depends)
  foreach(target ${ARGN})
    if(TARGET ${target})
      get_target_property(TARGET_TYPE ${target} TYPE)
      if(NOT TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        get_target_property(MANUALLY_ADDED_DEPENDENCIES ${target} MANUALLY_ADDED_DEPENDENCIES)
        if(MANUALLY_ADDED_DEPENDENCIES)
          list(APPEND all_depends ${MANUALLY_ADDED_DEPENDENCIES})
        endif()
      endif()
    endif()
  endforeach()
  if(all_depends)
    list(REMOVE_DUPLICATES all_depends)
  endif()
  set(${var_name} ${all_depends} PARENT_SCOPE)
endfunction()


function(arcbuild_need_combine var_name name)
  get_target_property(TYPE ${name} TYPE)
  set(${var_name} OFF PARENT_SCOPE)
  if(TYPE STREQUAL "STATIC_LIBRARY")
    foreach(target ${ARGN})
      if(TARGET "${target}")
        get_target_property(IMPORTED ${target} IMPORTED)
        if(NOT IMPORTED)
          set(${var_name} ON PARENT_SCOPE)
          return()
        endif()
      endif()
    endforeach()
  # else()
  #   foreach(target ${ARGN})
  #     if(TARGET "${target}")
  #       get_target_property(IMPORTED ${target} IMPORTED)
  #       get_target_property(TYPE ${target} TYPE)
  #       if(NOT IMPORTED AND TYPE STREQUAL "SHARED_LIBRARY")
  #         set(${var_name} ON PARENT_SCOPE)
  #         return()
  #       endif()
  #     endif()
  #   endforeach()
  endif()
endfunction()


# Combine all dependencies into one target for SDK delivery
# Usage:
#   arcbuild_combine_target(foo foo_combined)
#   if(TARGET foo_combined)
#     # new target is created
#   endif()
function(arcbuild_combine_target name new_name)
  arcbuild_collect_link_libraries(all_depends ${name})
  if(NOT all_depends)
    return()
  endif()
  list(REMOVE_DUPLICATES all_depends)

  # debug output
  arcbuild_echo("Dependencies of ${name}:")
  foreach(target ${all_depends})
    arcbuild_echo("- ${target}")
  endforeach()

  arcbuild_collect_manually_added_dependencies(MANUALLY_ADDED_DEPENDENCIES ${name} ${all_depends})
  arcbuild_echo("Manually Added Dependencies of ${name}:")
  foreach(target ${MANUALLY_ADDED_DEPENDENCIES})
    arcbuild_echo("- ${target}")
  endforeach()

  arcbuild_need_combine(need_combine ${name} ${all_depends})
  if(NOT need_combine)
    return()
  endif()

  # Properties
  set(prop_names SOURCES INCLUDE_DIRECTORIES INTERFACE_INCLUDE_DIRECTORIES COMPILE_DEFINITIONS COMPILE_OPTIONS)
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
  set(flag_prop_names COMPILE_FLAGS COMPILE_FLAGS_${CMAKE_BUILD_TYPE} LINK_FLAGS LINK_FLAGS_${CMAKE_BUILD_TYPE})
  list(APPEND prop_names ${flag_prop_names})

  # Collect properties
  set(LINK_LIBRARIES)
  foreach(target ${all_depends} ${name})
    if(NOT TARGET "${target}")
      list(APPEND LINK_LIBRARIES "${target}")
      continue()
    endif()
    get_target_property(TYPE ${target} TYPE)
    # message(${target}:${TYPE})
    if(TYPE STREQUAL "INTERFACE_LIBRARY")
      list(APPEND LINK_LIBRARIES "${target}")
      continue()
    else()
      foreach(prop ${prop_names})
        get_target_property(prop_var ${target} ${prop})
        if(prop STREQUAL "SOURCES")
          set(new_prop_var)
          get_target_property(SOURCE_DIR ${target} SOURCE_DIR)
          foreach(a_var ${prop_var})
            if(NOT EXISTS "${a_var}")
              if(CMAKE_VERSION VERSION_LESS "3.4")
                arcbuild_error("CMAKE >= 3.4 is required for getting SOURCE_DIR of target")
              endif()
              set(a_var "${SOURCE_DIR}/${a_var}")
            endif()
            list(APPEND new_prop_var ${a_var})
          endforeach()
          set(prop_var ${new_prop_var})
        endif()
        if(prop_var)
          list(APPEND ${prop} ${prop_var})
        endif()
      endforeach()
      foreach(prop IMPORTED_IMPLIB IMPORTED_LOCATION)
        get_target_property(prop_var ${target} ${prop})
        if(prop_var)
          list(APPEND LINK_LIBRARIES ${prop_var})
        endif()
      endforeach()
    endif()
  endforeach()

  # Sources
  get_target_property(build_type ${name} TYPE)
  if(build_type STREQUAL "STATIC_LIBRARY")
    add_library(${new_name} STATIC ${SOURCES})
  elseif(build_type STREQUAL "SHARED_LIBRARY")
    add_library(${new_name} SHARED ${SOURCES})
  elseif(build_type STREQUAL "EXECUTABLE")
    add_executable(${new_name} ${SOURCES})
  else()
    arcbuild_error("Unknown build type (${build_type}) of target ${name}")
  endif()

  # Merge properties
  foreach(var_name INTERFACE_INCLUDE_DIRECTORIES)
    if(${var_name})
      list(APPEND INCLUDE_DIRECTORIES ${${var_name}})
    endif()
  endforeach()

  # Remove duplicates
  foreach(prop ${prop_names} LINK_LIBRARIES)
    if(${prop})
      list(REMOVE_DUPLICATES ${prop})
    endif()
  endforeach()

  # debug output
  arcbuild_echo("Prebuilt libraries linked by ${name}:")
  foreach(target ${LINK_LIBRARIES})
    arcbuild_echo("- ${target}")
  endforeach()

  # Set target properties
  if(INCLUDE_DIRECTORIES)
    arcbuild_debug("Add INCLUDE_DIRECTORIES:")
    foreach(a ${INCLUDE_DIRECTORIES})
      arcbuild_debug("- ${a}")
    endforeach()
    target_include_directories(${new_name} PUBLIC ${INCLUDE_DIRECTORIES})
  endif()
  if(COMPILE_DEFINITIONS)
    arcbuild_debug("Add COMPILE_DEFINITIONS: ${COMPILE_DEFINITIONS}")
    target_compile_definitions(${new_name} PUBLIC ${COMPILE_DEFINITIONS})
  endif()
  if(COMPILE_OPTIONS) # CMake>=3.0
    arcbuild_debug("Add COMPILE_OPTIONS: ${COMPILE_OPTIONS}")
    target_compile_options(${new_name} PUBLIC ${COMPILE_OPTIONS})
  endif()
  if(LINK_LIBRARIES)
    arcbuild_debug("Add LINK_LIBRARIES:")
    foreach(a ${LINK_LIBRARIES})
      arcbuild_debug("- ${a}")
    endforeach()
    target_link_libraries(${new_name} PUBLIC ${LINK_LIBRARIES})
  endif()
  if(MANUALLY_ADDED_DEPENDENCIES)
    arcbuild_debug("Add MANUALLY_ADDED_DEPENDENCIES: ${MANUALLY_ADDED_DEPENDENCIES}")
    add_dependencies(${new_name} ${MANUALLY_ADDED_DEPENDENCIES})
  endif()
  foreach(prop ${flag_prop_names})
    if(${prop})
      arcbuild_join(${prop} " " ${${prop}})
      arcbuild_debug("Add ${prop}: ${${prop}}")
      set_target_properties(${name} PROPERTIES ${prop} ${${prop}})
    endif()
  endforeach()
endfunction()


function(arcbuild_find_file var_name)
  cmake_parse_arguments(A
    "NO_DEFAULT_PATH" # options
    "" # single value
    "NAMES;PATHS" # multiple values
    ${ARGN}
  )
  if(EXISTS ${var_name})
    return()
  endif()
  foreach(path ${A_PATHS})
    foreach(name ${A_NAMES})
      set(full_path "${path}/${name}")
      if(EXISTS "${full_path}")
        set(found 1)
        break()
      endif()
    endforeach()
    if(found)
      break()
    endif()
  endforeach()
  if(found)
    set(${var_name} "${full_path}" CACHE FILEPATH "Path to a file")
    set(${var_name} "${full_path}" PARENT_SCOPE)
  endif()
endfunction()


function(arcbuild_find_path var_name)
  cmake_parse_arguments(A
    "NO_DEFAULT_PATH" # options
    "" # single value
    "NAMES;PATHS" # multiple values
    ${ARGN}
  )
  if(EXISTS ${var_name})
    return()
  endif()
  foreach(path ${A_PATHS})
    foreach(name ${A_NAMES})
      set(full_path "${path}/${name}")
      if(EXISTS "${full_path}")
        set(result_path "${path}")
        set(found 1)
        break()
      endif()
    endforeach()
    if(found)
      break()
    endif()
  endforeach()
  if(found)
    set(${var_name} "${result_path}" CACHE PATH "Path to a directory")
    set(${var_name} "${result_path}" PARENT_SCOPE)
  endif()
endfunction()


function(arcbuild_get_realpaths var_name)
  set(paths)
  foreach(path ${ARGN})
    get_filename_component(path "${path}" REALPATH)
    list(APPEND paths "${path}")
  endforeach()
  set(${var_name} ${paths} PARENT_SCOPE)
endfunction()


set(ARCBUILD "${CMAKE_CURRENT_LIST_DIR}")
#cmake_minimum_required(VERSION 3.0)
