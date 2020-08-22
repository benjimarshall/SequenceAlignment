cmake_minimum_required(VERSION 3.15)
project(PartIIProject C)

set(CMAKE_C_STANDARD 11)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
message("CMAKE_C_FLAGS_RELEASE is ${CMAKE_C_FLAGS_RELEASE}")

IF(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg")
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pg")
    add_definitions(${CMAKE_CXX_FLAGS} "-O3")
    add_definitions(${CMAKE_CXX_FLAGS} "-fno-reorder-functions")
    add_definitions(${CMAKE_CXX_FLAGS} "-fno-inline")
ENDIF(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)

add_executable(PartIIProject main.c tests.c tests.h helpers.c helpers.h nw.c nw.h sw.c sw.h nwParallel.c nwParallel.h swParallel.c swParallel.h swGotoh.c swGotoh.h swGotohParallel.c swGotohParallel.h)
target_link_libraries(PartIIProject Threads::Threads)
# set_target_properties(PartIIProject PROPERTIES COMPILE_FLAGS -pthread LINK_FLAGS -pthread)

