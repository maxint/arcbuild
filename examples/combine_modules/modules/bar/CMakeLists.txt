project(bar)
file(GLOB SRCS *.h *.c *.cpp)
add_library(${PROJECT_NAME} ${SRCS})
target_link_libraries(${PROJECT_NAME} core foo)
target_include_directories(${PROJECT_NAME} PUBLIC .)

