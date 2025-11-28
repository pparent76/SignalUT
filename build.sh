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
echo "[1/10] Clone Signal-Desktop github"
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
echo "[2/10] Applying patches"

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
echo "[3/10] Building Signal-Desktop..."

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
echo "[4/10] Making logos..." 
rsvg-convert --width 2000 --height 2000 ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.svg > ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png
convert  -background "#3943fd" ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png -resize 1000x  -bordercolor "#3943fd"  -border 300 ${BUILD_DIR}/icon.png
convert  -background none ${BUILD_DIR}/Signal-Desktop/images/profile-avatar.png -resize 350x  -bordercolor none  -border 875 ${BUILD_DIR}/icon-splash.png


# ===================================
# STEP 5: BUILD THE FAKE xdg-open
# ===================================
echo "[5/10] Building fake xdg-open ..."
cp -r ${ROOT}/utils/xdg-open/ ${BUILD_DIR}/
cd ${BUILD_DIR}/xdg-open/
mkdir -p build
cd build
cmake ..
make

# ===================================
# STEP 5: BUILD download-helper
# ===================================
echo "[6/10] Building download-helper ..."
rm -rvf ${BUILD_DIR}/download-helper
cp -r ${ROOT}/utils/download-helper/ ${BUILD_DIR}/download-helper
cd ${BUILD_DIR}/download-helper/qml-download-helper-module/
mkdir build
cd build
cmake ..
cmake --build .


# =================================================
# STEP 6: Install dependencies
# =================================================
echo "[7/10] Install dependencies..."

cd ${BUILD_DIR}
DEPENDENCIES="libhybris-utils xdotool libmaliit-glib2 libxdo3 x11-utils"

for dep in $DEPENDENCIES ; do
    apt download $dep:arm64
    mv ${dep}_*.deb ${dep}.deb
    rm -rvf "${dep}.deb_extract_chsdjksd" || true
    mkdir "${dep}.deb_extract_chsdjksd"
    dpkg-deb -x "${dep}.deb" "${dep}.deb_extract_chsdjksd"
done

# =================================================
# STEP 7: Downloading maliit-inputcontext-gtk3
# =================================================
echo "[8/10] Building maliit-inputcontext-gtk3 and download dependencies..."


PKGNAME="maliit-inputcontext-gtk"
VERSION="0.99.1+git20151116.72d7576"
ORIG_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576.orig.tar.xz"
DEBIAN_URL="https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/maliit-inputcontext-gtk/0.99.1+git20151116.72d7576-3build3/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576-3build3.debian.tar.xz"



WORKDIR_MALIIT="${PKGNAME}-${VERSION}"
rm -rvf $WORKDIR_MALIIT/ || true
mkdir -p "$WORKDIR_MALIIT"
cd "$WORKDIR_MALIIT"

echo "📦 Download sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION}.debian.tar.xz"

echo "📂 Extract original code..."
tar -xf "${PKGNAME}_${VERSION}.orig.tar.xz"
SRC_DIR_MALIIT=$(tar -tf "${PKGNAME}_${VERSION}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extract debian files..."
tar -xf "${PKGNAME}_${VERSION}.debian.tar.xz" -C "$SRC_DIR_MALIIT"

echo "Apply patch..."
cd ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/
patch ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION/gtk-input-context/client-gtk/client-imcontext-gtk.c  ${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch
echo "${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch"

echo "Compile..."
EDITOR=true dpkg-source --commit . fix-keyboard
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64



# ==============================
# STEP 8: Copying files
# ==============================  
echo "[9/10] Copying files..." 


echo "Copying dependencies..."
cd ${BUILD_DIR}
# Copie des fichiers du dossier /lib/ de chaque paquet
rm -rvf $INSTALL_DIR/lib
mkdir -p "$INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/"
for DIR in *_extract_chsdjksd; do
    if [ -d "$DIR/usr/lib/aarch64-linux-gnu/" ]; then
        cp -r "$DIR/usr/lib/aarch64-linux-gnu/"* "$INSTALL_DIR/lib/aarch64-linux-gnu/"
    fi
done

# Copy binaries in bin/
mkdir -p "$INSTALL_DIR/bin"
cp *_extract_chsdjksd/usr/bin/xdotool "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/getprop "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/xprop "$INSTALL_DIR/bin/"

echo "Copying signal-desktop..."
mkdir -p "$INSTALL_DIR/opt/Signal"
cp -r ${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/* "$INSTALL_DIR/opt/Signal/" || true

echo "Copying maliit-input-context..."
cp ${ROOT}/patches/maliit-inputcontext-gtk/immodules.cache $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/
cp ${BUILD_DIR}/$WORKDIR_MALIIT/maliit-inputcontext-gtk-$VERSION/builddir/gtk3/gtk-3.0/im-maliit.so $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/

echo "Copying logos..."
cp ${BUILD_DIR}/icon.png "$INSTALL_DIR/"
cp ${BUILD_DIR}/icon-splash.png "$INSTALL_DIR/"

echo "Copying app files..."
cp ${ROOT}/signalut.desktop "$INSTALL_DIR/"
cp ${ROOT}/manifest.json "$INSTALL_DIR/"
cp ${ROOT}/signalut.apparmor "$INSTALL_DIR/"
cp ${ROOT}/launcher.sh "$INSTALL_DIR/"

echo "Copying utils..."
mkdir -p "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/sleep.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/mkdir-cache.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/get-scale.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/filedialog-deamon.sh "$INSTALL_DIR/utils/"
cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/
mkdir $INSTALL_DIR/utils/download-helper/
cp -r ${BUILD_DIR}/download-helper/qml $INSTALL_DIR/utils/download-helper/
mkdir -p $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/build/libDownloadHelperPlugin.so $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/qmldir $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/


echo "Make binaries executable..."
chmod +x $INSTALL_DIR/utils/sleep.sh
chmod +x $INSTALL_DIR/utils/mkdir-cache.sh
chmod +x $INSTALL_DIR/utils/get-scale.sh
chmod +x $INSTALL_DIR/utils/filedialog-deamon.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/opt/Signal/signal-desktop
chmod +x $INSTALL_DIR/opt/Signal/chrome_crashpad_handler


# ========================
# STEP 9: BUILD THE CLICK PACKAGE
# ========================
echo "[10/10] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
