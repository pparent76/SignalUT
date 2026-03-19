cmake_minimum_required(VERSION 3.16)

project(placeholder_killer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt5 
find_package(Qt5 REQUIRED COMPONENTS Gui)

# Executable
add_executable(placeholder-killer placeholder-killer.cpp)

# Link Qt
target_link_libraries(placeholder-killer PRIVATE Qt5::Gui)
