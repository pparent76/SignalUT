#!/bin/bash
set -e  # Exit immediately on error
if [ "$UNCONFINED" = "true" ]; then
echo "WARNING: building unconfined!"
fi


lsb_release -a
# ========================
# PROJECT CONFIGURATION
# ========================
PROJECT_NAME="signalut"
INSTALL_DIR="${BUILD_DIR}/install"

# ========================
# STEP 1: CLONE SIGNAL-DESKTOP
# ========================
echo "[1/8] Clone Signal-Desktop github"
cd ${BUILD_DIR}
if [ ! -e "Signal-Desktop" ]; then
    git clone https://github.com/signalapp/Signal-Desktop.git
fi
cd ${BUILD_DIR}/Signal-Desktop
git pull
git checkout 7.77.x

# ========================
# STEP 2: APPLY PATCHES
# ========================
echo "[2/8] Applying patches"

if [ ! -e "${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/" ]; then

    #Patch to build for arm64
    
    if [ ! -e ".bump_electronbuilder_version-applyed" ]; then
        echo "Apply bump_electronbuilder_version.patch"
        git apply ${ROOT}/patches/bump_electronbuilder_version.patch
        touch .bump_electronbuilder_version-applyed
    fi
    
    echo "Add fs-extra+11.2.0.patch patches"
    cp ${ROOT}/patches/fs-extra+11.2.0.patch patches/
    
    echo "Ajust package.json"
    cat package.json | jq -r --arg fs_extra patches/fs-extra+11.2.0.patch '.pnpm.patchedDependencies."fs-extra"=$fs_extra ' | sponge package.json
    
    #Patch to make the app responsive
    if [ ! -e ".fix-inject-responsive.patch-applyed" ]; then
        echo "Apply fix-inject-responsive.patch"
        git apply ${ROOT}/patches/inject_js_responsive.patch
        touch .fix-inject-responsive.patch-applyed
    fi
    
    echo "Add responsive.js"
    cp ${ROOT}/patches/responsive.js ${BUILD_DIR}/Signal-Desktop/app/
    
fi

# ==============================
# STEP 3: Build Signal-Desktop
# ==============================
echo "[3/8] Building Signal-Desktop..."

 if [ ! -e "${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/" ]; then
    curl -fsSL https://get.pnpm.io/install.sh | env SHELL=bash sh -
    source ${BUILD_DIR}/.clickable/home/.bashrc
    pnpm -v
  
    #pre-install X64 packages
    pnpm install --verbose  --network-concurrency=1 --child-concurrency=1 || true
  
    export npm_config_arch=amd64
    export npm_config_target_arch=arm64
    export npm_config_target_platform=linux
    export ESBUILD_ARCH=arm64
    export SIGNAL_ENV=release
    
    echo "Install"
    sleep 5
    pnpm install --verbose  --network-concurrency=1 --child-concurrency=1
    
    cd sticker-creator
    pnpm install
    pnpm run build
    cd ..
    pnpm run generate
       
    echo "Build Signal"
    sleep 5;
    # This is the equivalent of 'npm run build-linux' with some adjustments
    pnpm run build:esbuild:prod 
    pnpm run build:release --arm64 --publish=never --linux deb
  fi
  
  
# ==============================
# STEP 4: Making logos
# ==============================  
echo "[4/8] Making logos..." 
rsvg-convert --width 2000 --height 2000 ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.svg > ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png
convert  -background "#3943fd" ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png -resize 1000x  -bordercolor "#3943fd"  -border 300 ${BUILD_DIR}/icon.png
convert  -background none ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png -resize 350x  -bordercolor none  -border 875 ${BUILD_DIR}/icon-splash.png


# ===================================
# STEP 5: BUILD THE FAKE xdg-open
# ===================================
echo "[5/8] Building fake xdg-open ..."
cp -r ${ROOT}/xdg-open/ ${BUILD_DIR}/
cd ${BUILD_DIR}/xdg-open/
mkdir -p build
cd build
cmake ..
make
mkdir -p $INSTALL_DIR/bin/

# =================================================
# STEP 6: Downloading maliit-inputcontext-gtk3
# =================================================
echo "[6/8] Downloading maliit-inputcontext-gtk3 ..."
# URLs des paquets .deb
URL1="http://launchpadlibrarian.net/722617417/maliit-inputcontext-gtk3_0.99.1+git20151116.72d7576-3build3_arm64.deb"
URL2="http://launchpadlibrarian.net/723291297/libmaliit-glib2_2.3.0-4build5_arm64.deb"

# Téléchargement des fichiers .deb
wget -q "$URL1" -O "${BUILD_DIR}/pkg1.deb"
wget -q "$URL2" -O "${BUILD_DIR}/pkg2.deb"

# Extraction des paquets
cd "${BUILD_DIR}"
for PKG in pkg1.deb pkg2.deb; do
    rm -rvf "${PKG%.deb}_extract_chsdjksd" || true
    mkdir "${PKG%.deb}_extract_chsdjksd"
    dpkg-deb -x "$PKG" "${PKG%.deb}_extract_chsdjksd"
done

# Copie des fichiers du dossier /lib/ de chaque paquet
rm -rvf $INSTALL_DIR/lib
cp -r ${ROOT}/lib "$INSTALL_DIR/"
for DIR in *_extract_chsdjksd; do
        cp -r "$DIR/usr/lib/aarch64-linux-gnu/"* "$INSTALL_DIR/lib/aarch64-linux-gnu/"
done

# ==============================
# STEP 6: Copying files
# ==============================  
echo "[7/8] Copying files..." 
mkdir -p "$INSTALL_DIR/opt/Signal"
cp -r ${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/* "$INSTALL_DIR/opt/Signal/" || true

# Copy project files
#Copy built logos
cp ${BUILD_DIR}/icon.png "$INSTALL_DIR/"
cp ${BUILD_DIR}/icon-splash.png "$INSTALL_DIR/"

cp ${ROOT}/signalut.desktop "$INSTALL_DIR/"
cp ${ROOT}/manifest.json "$INSTALL_DIR/"

if [ "$UNCONFINED" = "true" ]; then
    echo "UNCONFINED!"
    cp ${ROOT}/signalut.apparmor.unconfined "$INSTALL_DIR/signalut.apparmor"
    cp ${ROOT}/launcher.sh.unconfined "$INSTALL_DIR/launcher.sh"
    jq '.version = (.version + "-unconfined")' ${INSTALL_DIR}/manifest.json > ${INSTALL_DIR}/tmp.json && mv ${INSTALL_DIR}/tmp.json ${INSTALL_DIR}/manifest.json
else
    cp ${ROOT}/signalut.apparmor "$INSTALL_DIR/"
    cp ${ROOT}/launcher.sh "$INSTALL_DIR/"
fi

cp ${ROOT}/sleep.sh "$INSTALL_DIR/"

cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/

chmod +x $INSTALL_DIR/sleep.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/opt/Signal/Signal
chmod +x $INSTALL_DIR/opt/Signal/chrome_crashpad_handler


# ========================
# STEP 7: BUILD THE CLICK PACKAGE
# ========================
echo "[8/8] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
