project(core)
file(GLOB SRCS *.h *.c *.cpp)
add_library(${PROJECT_NAME} ${SRCS})
target_include_directories(${PROJECT_NAME} PUBLIC .)
