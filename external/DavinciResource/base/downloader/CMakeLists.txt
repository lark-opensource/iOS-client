cmake_minimum_required(VERSION 3.6)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD 11)

# CPP_BASE_CORE_DIR
set(CPP_BASE_CORE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
include(${CPP_BASE_CORE_DIR}/CppBase.cmake)

aux_source_directory(. CURRENT_SOURCE)

message(STATUS "|---------------------------------|")
if (CMAKE_LIBRARY_TYPE STREQUAL STATIC)
    message(STATUS "|     ${DAVINCIDOWNLOAD_LIBRARY} STATIC")
    add_library(${DAVINCIDOWNLOAD_LIBRARY} STATIC ${CURRENT_SOURCE})
else()
    message(STATUS "|     ${DAVINCIDOWNLOAD_LIBRARY} SHARED")
    add_library(${DAVINCIDOWNLOAD_LIBRARY} SHARED ${CURRENT_SOURCE})
endif()
message(STATUS "|---------------------------------|")

target_include_directories(${DAVINCIDOWNLOAD_LIBRARY} PRIVATE ${DAVINCINETWORKER_DIR})
target_include_directories(${DAVINCIDOWNLOAD_LIBRARY} PRIVATE ${DAVINCITHIRDPARTY_DIR})
target_include_directories(${DAVINCIDOWNLOAD_LIBRARY} PRIVATE ${CBOXFILE_DIR})
target_include_directories(${DAVINCIDOWNLOAD_LIBRARY} PRIVATE ${DAVINCILOGGER_DIR})
target_include_directories(${DAVINCIDOWNLOAD_LIBRARY} PRIVATE ${DAVINCIUTIL_DIR})

if (CMAKE_LIBRARY_TYPE STREQUAL SHARED)
    target_link_libraries(
            ${DAVINCIDOWNLOAD_LIBRARY}
            ${DAVINCINETWORKER_LIBRARY}
            ${DAVINCILOGGER_LIBRARY}
            ${CBOXFILE_LIBRARY}
            ${DAVINCIUTIL_LIBRARY}
    )
endif()