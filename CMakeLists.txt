cmake_minimum_required(VERSION 3.5)
project(signalut C CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Exemple dans ton CMakeLists.txt
set(MON_DOSSIER "${CMAKE_SOURCE_DIR}/crackle")
set(MON_SCRIPT "${CMAKE_SOURCE_DIR}/crackle-build.sh")

# Cible qui exécute le script
add_custom_target(pre_install_script
    COMMAND bash ${MON_SCRIPT} ${MON_DOSSIER}
    COMMENT "Exécution du script avant installation"
)

# On rend la cible d’installation dépendante de notre script
add_dependencies(install pre_install_script)


set(DEB_URL "https://github.com/0mniteck/Signal-Desktop-Mobian/raw/refs/heads/7.68.x/builds/release/signal-desktop_7.68.0_arm64.deb?download=")
set(DEB_FILE "${CMAKE_BINARY_DIR}/signal-desktop.deb")
set(EXTRACT_DIR "${CMAKE_BINARY_DIR}/deb_extracted")

# Étape 1 : Télécharger le .deb
file(DOWNLOAD
    ${DEB_URL}
    ${DEB_FILE}
    SHOW_PROGRESS
    STATUS status
    INACTIVITY_TIMEOUT 300
    EXPECTED_HASH SHA256=7ee73ff2b6057ed279fe22d871b2dff28f53384f9da6f43e0dda9f2664e097be
    TLS_VERIFY ON
    FOLLOWLOCATION 1  # ← essentiel pour suivre les redirections HTTPs
)

# Étape 2 : Créer le dossier d’extraction
file(MAKE_DIRECTORY ${EXTRACT_DIR})
execute_process(
    COMMAND ar x ${DEB_FILE}
    WORKING_DIRECTORY ${EXTRACT_DIR}
)

execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xvf ${EXTRACT_DIR}/data.tar.xz
    WORKING_DIRECTORY ${EXTRACT_DIR}
)



install(DIRECTORY ${CMAKE_BINARY_DIR}/usr/lib/ DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/)
install(DIRECTORY ${EXTRACT_DIR}/opt/ DESTINATION ${CMAKE_INSTALL_PREFIX}/opt/)
install(PROGRAMS ${EXTRACT_DIR}/opt/Signal/signal-desktop  DESTINATION ${CMAKE_INSTALL_PREFIX}/opt/Signal/)
install(PROGRAMS ${EXTRACT_DIR}/opt/Signal/chrome_crashpad_handler  DESTINATION ${CMAKE_INSTALL_PREFIX}/opt/Signal/)
install(PROGRAMS ${EXTRACT_DIR}/opt/Signal/chrome-sandbox  DESTINATION ${CMAKE_INSTALL_PREFIX}/opt/Signal)


install(PROGRAMS launcher.sh  DESTINATION ${CMAKE_INSTALL_PREFIX}/)


# Installer les fichier de lancement
install(FILES signalut.desktop DESTINATION ${CMAKE_INSTALL_PREFIX})
# Installer les icones
install(FILES icon.png DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES icon-splash.png DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES signalut.apparmor DESTINATION ${CMAKE_INSTALL_PREFIX})
