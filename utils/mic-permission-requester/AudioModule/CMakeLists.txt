cmake_minimum_required(VERSION 3.5)
project(AudioWriter)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 REQUIRED COMPONENTS Qml Multimedia)

add_library(audiowriter SHARED
    audiowriter.cpp
    audiowriter.h
    plugin.cpp
)

target_link_libraries(audiowriter
    Qt5::Qml
    Qt5::Multimedia
)

set_target_properties(audiowriter PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
 
