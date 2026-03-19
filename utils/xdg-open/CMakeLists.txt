cmake_minimum_required(VERSION 3.10)

project(xdg_open C)

# Trouver pkg-config
find_package(PkgConfig REQUIRED)

# Trouver gio-2.0 (inclut glib et gobject)
pkg_check_modules(GIO REQUIRED gio-2.0)

# Définir l'exécutable
add_executable(xdg-open xdg-open.c)

# Inclure les headers
target_include_directories(xdg-open PRIVATE ${GIO_INCLUDE_DIRS})

# Flags de compilation
target_compile_options(xdg-open PRIVATE ${GIO_CFLAGS_OTHER})

# Linker les libs
target_link_libraries(xdg-open ${GIO_LIBRARIES})

# Pour certains systèmes (optionnel mais safe)
target_link_directories(xdg-open PRIVATE ${GIO_LIBRARY_DIRS})
