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
git checkout 7.79.x

# ========================
# STEP 2: APPLY PATCHES
# ========================
echo "[2/8] Applying patches"

if [ ! -e "${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/" ]; then

    #Patch to build for arm64
    
    if [ ! -e ".bump_electronbuilder_version-applyed" ]; then
        echo "Apply bump_electronbuilder_version.patch"
        git apply ${ROOT}/patches/Signal-Desktop/bump_electronbuilder_version.patch
        touch .bump_electronbuilder_version-applyed
    fi
    
    echo "Add fs-extra+11.2.0.patch patches"
    cp ${ROOT}/patches/Signal-Desktop/fs-extra+11.2.0.patch patches/
    
    echo "Ajust package.json"
    cat package.json | jq -r --arg fs_extra patches/fs-extra+11.2.0.patch '.pnpm.patchedDependencies."fs-extra"=$fs_extra ' | sponge package.json
    
    #Patch to make the app responsive
    if [ ! -e ".fix-inject-responsive.patch-applyed" ]; then
        echo "Apply fix-inject-responsive.patch"
        git apply ${ROOT}/patches/Signal-Desktop/inject_js_responsive.patch
        touch .fix-inject-responsive.patch-applyed
    fi
    
    echo "Add responsive.js"
    cp ${ROOT}/patches/Signal-Desktop/responsive.js ${BUILD_DIR}/Signal-Desktop/app/
    
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
cp -r ${ROOT}/utils/xdg-open/ ${BUILD_DIR}/
cd ${BUILD_DIR}/xdg-open/
mkdir -p build
cd build
cmake ..
make
mkdir -p $INSTALL_DIR/bin/

# =================================================
# STEP 6: Downloading maliit-inputcontext-gtk3
# =================================================
echo "[6/8] Building maliit-inputcontext-gtk3 and download dependencies..."

# URLs des paquets .deb
URL2="http://launchpadlibrarian.net/723291297/libmaliit-glib2_2.3.0-4build5_arm64.deb"
XDOTOOL_URL="http://launchpadlibrarian.net/599174155/xdotool_3.20160805.1-5_arm64.deb"

# Téléchargement des fichiers .deb
wget -q "$URL2" -O "${BUILD_DIR}/pkg2.deb"
wget -q "$XDOTOOL_URL" -O "${BUILD_DIR}/xdotool.deb"

# Extraction des paquets
cd "${BUILD_DIR}"
for PKG in pkg2.deb xdotool.deb; do
    rm -rvf "${PKG%.deb}_extract_chsdjksd" || true
    mkdir "${PKG%.deb}_extract_chsdjksd"
    dpkg-deb -x "$PKG" "${PKG%.deb}_extract_chsdjksd"
done

# Copie des fichiers du dossier /lib/ de chaque paquet
rm -rvf $INSTALL_DIR/lib
mkdir -p "$INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/"
for DIR in *_extract_chsdjksd; do
    if [ -d "$DIR/usr/lib/aarch64-linux-gnu/" ]; then
        cp -r "$DIR/usr/lib/aarch64-linux-gnu/"* "$INSTALL_DIR/lib/aarch64-linux-gnu/"
    fi
done

cp ${ROOT}/patches/maliit-inputcontext-gtk/immodules.cache $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/
# Copie des binaires xdotool dans bin/
mkdir -p "$INSTALL_DIR/bin"
cp *_extract_chsdjksd/usr/bin/xdotool "$INSTALL_DIR/bin/"


PKGNAME="maliit-inputcontext-gtk"
VERSION="0.99.1+git20151116.72d7576"
ORIG_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576.orig.tar.xz"
DEBIAN_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576-3build3.debian.tar.xz"



WORKDIR_MALIIT="${PKGNAME}-${VERSION}"
rm -r $WORKDIR_MALIIT/
mkdir -p "$WORKDIR_MALIIT"
cd "$WORKDIR_MALIIT"



echo "📦 Téléchargement des sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION}.debian.tar.xz"

echo "📂 Extraction du code source original..."
tar -xf "${PKGNAME}_${VERSION}.orig.tar.xz"
SRC_DIR_MALIIT=$(tar -tf "${PKGNAME}_${VERSION}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extraction des fichiers Debian..."
tar -xf "${PKGNAME}_${VERSION}.debian.tar.xz" -C "$SRC_DIR_MALIIT"

cd ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/
patch ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/gtk-input-context/client-gtk/client-imcontext-gtk.c  ${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch
echo "${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch"
EDITOR=true dpkg-source --commit . fix-keyboard
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64

cp ${BUILD_DIR}/$WORKDIR_MALIIT/maliit-inputcontext-gtk-$VERSION/builddir/gtk3/gtk-3.0/im-maliit.so $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/


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

mkdir -p "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/sleep.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/get-scale.sh "$INSTALL_DIR/utils/"

cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/

chmod +x $INSTALL_DIR/utils/sleep.sh
chmod +x $INSTALL_DIR/utils/get-scale.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/opt/Signal/signal-desktop
chmod +x $INSTALL_DIR/opt/Signal/chrome_crashpad_handler


# ========================
# STEP 7: BUILD THE CLICK PACKAGE
# ========================
echo "[8/8] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
