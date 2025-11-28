cmake_minimum_required(VERSION 3.5)

project(DownloadHelperPlugin LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Qml Quick)

# Ajouter la bibliothèque partagée (module QML)
add_library(DownloadHelperPlugin SHARED
    DownloadHelper.cpp
    DownloadHelper.h
    plugin.cpp      # Ce fichier contiendra l'enregistrement du module QML
)

# Lier Qt
target_link_libraries(DownloadHelperPlugin
    PRIVATE
        Qt5::Core
        Qt5::Qml
        Qt5::Quick
)

# Installer le module QML
install(TARGETS DownloadHelperPlugin
        LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/qml-plugins/Pparent/DownloadHelper)

install(FILES qmldir
        DESTINATION ${CMAKE_INSTALL_PREFIX}/qml-plugins/Pparent/DownloadHelper)
