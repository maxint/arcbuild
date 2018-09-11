cmake_minimum_required(VERSION 3.1)

project(ArcBuildExamples)

# save libs and executables in the same place
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_BINARY_DIR}" CACHE PATH "Output directory for applications")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH} CACHE INTERNAL "") # static
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH} CACHE INTERNAL "") # shared
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH} CACHE INTERNAL "") # exe

if(UNIX)
  # https://stackoverflow.com/questions/3961446/why-does-gcc-not-implicitly-supply-the-fpic-flag-when-compiling-static-librarie
  set(CFLAGS "-fPIC")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CFLAGS}")
endif()

add_subdirectory(examples)
