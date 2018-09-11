cmake_minimum_required(VERSION 3.1)

project(CombineMultipleModules)

# Global flags
set(CMAKE_CXX_STANDARD 11)

# Modules
add_subdirectory(modules)

# Library
set(PROJECT_NAME sample_lib)
file(GLOB_RECURSE HDRS inc/*.h)
file(GLOB_RECURSE SRCS src/*.h src/*.c src/*.cpp)
add_library(${PROJECT_NAME} ${ARCBUILD_TYPE} ${HDRS} ${SRCS})
target_include_directories(${PROJECT_NAME} PUBLIC inc)
target_link_libraries(${PROJECT_NAME} bar)

# Sample codes
add_executable(demo demo/demo.c)
target_link_libraries(demo ${PROJECT_NAME})

# Enable arcbuild functions
if(ARCBUILD)
  # Only combine the modules into one library when building SDK
  include(${ARCBUILD}/core.cmake)
  arcbuild_combine_target(${PROJECT_NAME} ${PROJECT_NAME}_combined)
endif()
