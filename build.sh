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
echo "[1/10] Download Signal-Desktop from github"

cd ${BUILD_DIR}
signal_download_url=https://github.com/signalapp/Signal-Desktop/archive/refs/tags/v8.17.0-beta.1.tar.gz

if [ ! -e "Signal-Desktop" ]; then
    mkdir -p "Signal-Desktop"
    wget -O /tmp/signal.tar.gz "$signal_download_url"
    tar -xzf /tmp/signal.tar.gz -C "Signal-Desktop" --strip-components=1
fi

cd ${BUILD_DIR}/Signal-Desktop


# ========================
# STEP 2: APPLY PATCHES
# ========================
echo "[2/10] Applying patches"

if [ ! -e "${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/" ]; then

    #Patch to make the app responsive
    if [ ! -e ".fix-inject-responsive.patch-applyed" ]; then
        echo "Apply fix-inject-responsive.patch"
        patch -p1 < ${ROOT}/patches/Signal-Desktop/inject_js_responsive.patch
        echo "Add responsive.js"
        mkdir ${BUILD_DIR}/Signal-Desktop/js/ || true
        cp ${ROOT}/patches/Signal-Desktop/responsive.js ${BUILD_DIR}/Signal-Desktop/js/
        touch .fix-inject-responsive.patch-applyed
    fi
    
    #Patch to have ContentHub working
    if [ ! -e ".contentHub.patch-applyed" ]; then
        echo "Apply .contentHub.patch"
        patch -p1 < ${ROOT}/patches/Signal-Desktop/contentHub.patch
        touch .contentHub.patch-applyed
    fi
    
fi

# ==============================
# STEP 3: Build Signal-Desktop
# ==============================
echo "[3/10] Building Signal-Desktop..."

oldcc=$CC;
oldccx=$CXX;
oldar=$AR;
oldld=$LD;
export CC=gcc 
export CXX=g++ 
export AR=ar 
export LD=ld

 if [ ! -e "${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/" ]; then
    PATH=$PATH:${BUILD_DIR}/.clickable/home/.local/share/pnpm/
    
    echo "---> Downloading nvm from https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash || true
    export NVM_DIR="$HOME/.nvm"
    echo "---> load nvm: $NVM_DIR"
    . "$NVM_DIR/nvm.sh" || true # This loads nvm

    echo "---> nvm install 24.15.0"
    nvm install 24.15.0
    nvm use 24.15.0
    node -v
    
    echo "---> Download pnpm from get.pnpm.io"
    curl -fsSL https://get.pnpm.io/install.sh | env SHELL=bash sh -
    source ${BUILD_DIR}/.clickable/home/.bashrc

    pnpm -v
  
    echo "--->dlx node-gyp"
    pnpm dlx node-gyp --version
  
    export npm_config_arch=arm64
    export npm_config_target_arch=arm64
    export npm_config_target_platform=linux
    export ESBUILD_ARCH=arm64
    export SIGNAL_ENV=release
    
    echo "--->Install"
    sleep 5
    pnpm install      
    
    FS_EXTRA_DIR="$(find node_modules/.pnpm -maxdepth 1 -type d -name 'fs-extra@11.3.4*' | head -n 1)/node_modules/fs-extra"    
    echo "--->Patching fs-extra in $FS_EXTRA_DIR"   
    patch -d "$FS_EXTRA_DIR" -p1 < ${ROOT}/patches/Signal-Desktop/fs-extra+11.3.4.patch
 

    echo "--->Prepare"
    pnpm run prepare-linux-build deb arm64
   
    echo "--->Stickers"
    cd sticker-creator
        pnpm install
        pnpm run build
    cd ..
    
       
    echo "--->Build Signal"
    sleep 5;
    pnpm run build
  else
      echo "--->Re-Build Signal"
     
     PATH=$PATH:${BUILD_DIR}/.clickable/home/.local/share/pnpm/
     source ${BUILD_DIR}/.clickable/home/.bashrc
     export NVM_DIR="$HOME/.nvm"
     echo "---> load nvm: $NVM_DIR"
     . "$NVM_DIR/nvm.sh" || true # This loads nvm    
     nvm use 24.15.0
    
     pnpm run build
  fi

export CC=$oldcc
export CXX=$oldccx
export AR=$oldar
export LD=$oldld


# ===================================
# STEP 4: BUILD THE FAKE xdg-open
# ===================================
echo "[4/10] Building fake xdg-open & placeholder-killer ..."
cp -r ${ROOT}/utils/xdg-open/ ${BUILD_DIR}/
cd ${BUILD_DIR}/xdg-open/
mkdir -p build
cd build
cmake ..
make


cp -r ${ROOT}/utils/placeholder-killer/ ${BUILD_DIR}/
cd ${BUILD_DIR}/placeholder-killer/
mkdir -p build
cd build
cmake ..
make

# ===================================
# STEP 5: BUILD QML modules
# ===================================
echo "[5/10] Building QML modules ..."
rm -rvf ${BUILD_DIR}/download-helper
cp -r ${ROOT}/utils/download-helper/ ${BUILD_DIR}/download-helper
cd ${BUILD_DIR}/download-helper/qml-download-helper-module/
mkdir build
cd build
cmake ..
cmake --build .

rm -rvf ${BUILD_DIR}/upload-helper
cp -r ${ROOT}/utils/upload-helper/ ${BUILD_DIR}/upload-helper
cd ${BUILD_DIR}/upload-helper/qml-upload-helper-module/
mkdir build
cd build
cmake ..
cmake --build .

rm -rvf ${BUILD_DIR}/mic-permission-requester/
cp -r ${ROOT}/utils/mic-permission-requester/ ${BUILD_DIR}/mic-permission-requester
cd ${BUILD_DIR}/mic-permission-requester/AudioModule/
mkdir build
cd build
cmake ..
cmake --build .


# =================================================
# STEP 6: Install dependencies
# =================================================
echo "[6/10] Install dependencies..."

cd ${BUILD_DIR}
DEPENDENCIES="libhybris-utils xdotool libmaliit-glib2 libxdo3 x11-utils"

for dep in $DEPENDENCIES ; do
    apt download $dep:arm64
    mv ${dep}_*.deb ${dep}.deb
    rm -rvf "${dep}.deb_extract_chsdjksd" || true
    mkdir "${dep}.deb_extract_chsdjksd"
    dpkg-deb -x "${dep}.deb" "${dep}.deb_extract_chsdjksd"
done

wget https://ports.ubuntu.com/pool/main/c/coreutils/coreutils_9.4-3ubuntu6_arm64.deb
rm -rvf "coreutils_9.4-3ubuntu6_arm64.deb_extract_chsdjksd" || true
mkdir "coreutils_9.4-3ubuntu6_arm64.deb_extract_chsdjksd"
dpkg-deb -x "coreutils_9.4-3ubuntu6_arm64.deb" "coreutils_9.4-3ubuntu6_arm64.deb_extract_chsdjksd"

# =================================================
# STEP 7: Downloading maliit-inputcontext-gtk3
# =================================================
echo "[7/10] Building maliit-inputcontext-gtk3..."

cd ${BUILD_DIR}

PKGNAME="maliit-inputcontext-gtk"
VERSION_MALIIT="0.99.1+git20151116.72d7576"
ORIG_URL="https://ports.ubuntu.com/ubuntu-ports/ubuntu-ports/pool/universe/m/maliit-inputcontext-gtk/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576.orig.tar.xz"
DEBIAN_URL="https://ports.ubuntu.com/ubuntu-ports/ubuntu-ports/pool/universe/m/maliit-inputcontext-gtk/maliit-inputcontext-gtk_0.99.1+git20151116.72d7576-3build3.debian.tar.xz"



WORKDIR_MALIIT="${BUILD_DIR}/${PKGNAME}-${VERSION_MALIIT}"
rm -rvf $WORKDIR_MALIIT/ || true
mkdir -p "$WORKDIR_MALIIT"
cd "$WORKDIR_MALIIT"

echo "📦 Download sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION_MALIIT}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION_MALIIT}.debian.tar.xz"

echo "📂 Extract original code..."
tar -xf "${PKGNAME}_${VERSION_MALIIT}.orig.tar.xz"
SRC_DIR_MALIIT=$(tar -tf "${PKGNAME}_${VERSION_MALIIT}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extract debian files..."
tar -xf "${PKGNAME}_${VERSION_MALIIT}.debian.tar.xz" -C "$SRC_DIR_MALIIT"

echo "Apply patch..."
cd ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION_MALIIT/
patch ${BUILD_DIR}/$SRC_DIR_MALIIT/maliit-inputcontext-gtk-$VERSION_MALIIT/gtk-input-context/client-gtk/client-imcontext-gtk.c  ${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch
echo "${ROOT}/patches/maliit-inputcontext-gtk/client-imcontext-gtk.c.patch"

echo "Compile..."
EDITOR=true dpkg-source --commit . fix-keyboard
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64

# =================================================
# STEP 8: Build libnotify
# =================================================
echo "[8/10] Building libnotify..."

rm -rvf ${BUILD_DIR}/libnotify || true
mkdir -p ${BUILD_DIR}/libnotify
cd ${BUILD_DIR}/libnotify

PKGNAME="libnotify"
VERSION="0.8.3"
ORIG_URL="https://ports.ubuntu.com/pool/main/libn/libnotify/libnotify_0.8.3.orig.tar.xz"
DEBIAN_URL="https://ports.ubuntu.com/pool/main/libn/libnotify/libnotify_0.8.3-1build2.debian.tar.xz"

echo "📦 Download sources..."
wget -q "$ORIG_URL" -O "${PKGNAME}_${VERSION}.orig.tar.xz"
wget -q "$DEBIAN_URL" -O "${PKGNAME}_${VERSION}.debian.tar.xz"

echo "📂 Extract original code..."
tar -xf "${PKGNAME}_${VERSION}.orig.tar.xz"
SRC_DIR_LIBNOTIFY=$(tar -tf "${PKGNAME}_${VERSION}.orig.tar.xz" | head -1 | cut -d/ -f1)

echo "📂 Extract debian files..."
tar -xf "${PKGNAME}_${VERSION}.debian.tar.xz" -C "$SRC_DIR_LIBNOTIFY"

echo "Apply patch..."
cd ${BUILD_DIR}/libnotify/$SRC_DIR_LIBNOTIFY/
patch -p1 < ${ROOT}/patches/libnotify/notification.c.diff

EDITOR=true dpkg-source --commit . ut-notif
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -a arm64


# ==============================
# STEP 9: Copying files
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
cp *_extract_chsdjksd/usr/bin/xev "$INSTALL_DIR/bin/"
cp *_extract_chsdjksd/usr/bin/md5sum "$INSTALL_DIR/bin/"

echo "Copying signal-desktop..."
mkdir -p "$INSTALL_DIR/opt/Signal"
cp -r ${BUILD_DIR}/Signal-Desktop/release/linux-arm64-unpacked/* "$INSTALL_DIR/opt/Signal/" || true

echo "Copying maliit-input-context..."
cp $WORKDIR_MALIIT/maliit-inputcontext-gtk-$VERSION_MALIIT/builddir/gtk3/gtk-3.0/im-maliit.so $INSTALL_DIR/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/

echo "Copying libnotify"
cp ${BUILD_DIR}/libnotify/libnotify-0.8.3/obj-aarch64-linux-gnu/libnotify/* $INSTALL_DIR/lib/aarch64-linux-gnu/ || true

echo "Copying logos..."
cp ${BUILD_DIR}/icon.png "$INSTALL_DIR/"
cp ${BUILD_DIR}/icon-splash.png "$INSTALL_DIR/"

echo "Copying app files..."
cp ${ROOT}/signalut.desktop "$INSTALL_DIR/"
cp ${ROOT}/manifest.json "$INSTALL_DIR/"
cp ${ROOT}/content-hub.json "$INSTALL_DIR/"
cp ${ROOT}/signalut.apparmor "$INSTALL_DIR/"
cp ${ROOT}/launcher.sh "$INSTALL_DIR/"
cp ${ROOT}/pushexec "$INSTALL_DIR/"
cp ${ROOT}/push-apparmor.json "$INSTALL_DIR/"
cp ${ROOT}/signalut-push.apparmor "$INSTALL_DIR/"
cp ${ROOT}/signalut-push-helper.json "$INSTALL_DIR/"

echo "Copying utils..."
mkdir -p "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/rm.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/sleep.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/mkdir.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/get-scale.sh "$INSTALL_DIR/utils/"
cp ${ROOT}/utils/select-file.sh "$INSTALL_DIR/utils/"
cp ${BUILD_DIR}/xdg-open/build/xdg-open $INSTALL_DIR/bin/
cp ${BUILD_DIR}/placeholder-killer/build/placeholder-killer $INSTALL_DIR/bin/
mkdir $INSTALL_DIR/utils/download-helper/
cp -r ${BUILD_DIR}/download-helper/qml $INSTALL_DIR/utils/download-helper/

echo "Copying logos..." 
cp ${ROOT}/icon.png ${BUILD_DIR}/icon.png
cp ${ROOT}/icon-splash.png ${BUILD_DIR}/icon-splash.png

mkdir -p $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/build/libDownloadHelperPlugin.so $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/
cp ${BUILD_DIR}/download-helper/qml-download-helper-module/qmldir $INSTALL_DIR/utils/download-helper/Pparent/DownloadHelper/

mkdir $INSTALL_DIR/utils/upload-helper/
cp -r ${BUILD_DIR}/upload-helper/qml $INSTALL_DIR/utils/upload-helper/
mkdir -p $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper
cp ${BUILD_DIR}/upload-helper/qml-upload-helper-module/build/libUploadHelperPlugin.so $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper/
cp ${BUILD_DIR}/upload-helper/qml-upload-helper-module/qmldir $INSTALL_DIR/utils/upload-helper/Pparent/UploadHelper/


mkdir -p $INSTALL_DIR/utils/mic-permission-requester/AudioWriter/ || true
cp ${BUILD_DIR}/mic-permission-requester/AudioModule/libaudiowriter.so $INSTALL_DIR/utils/mic-permission-requester/AudioWriter/
cp ${BUILD_DIR}/mic-permission-requester/AudioModule/qmldir $INSTALL_DIR/utils/mic-permission-requester/AudioWriter/

cp -r ${ROOT}/utils/mic-permission-requester "$INSTALL_DIR/utils/"
cp ${BUILD_DIR}/icon.png "$INSTALL_DIR/utils/mic-permission-requester/"

echo "Make binaries executable..."
chmod +x $INSTALL_DIR/utils/rm.sh
chmod +x $INSTALL_DIR/utils/sleep.sh
chmod +x $INSTALL_DIR/utils/mkdir.sh
chmod +x $INSTALL_DIR/utils/get-scale.sh
chmod +x $INSTALL_DIR/utils/select-file.sh
chmod +x $INSTALL_DIR/launcher.sh
chmod +x $INSTALL_DIR/pushexec
chmod +x $INSTALL_DIR/opt/Signal/signal-desktop
chmod +x $INSTALL_DIR/opt/Signal/chrome_crashpad_handler


# ========================
# STEP 10: BUILD THE CLICK PACKAGE
# ========================
echo "[10/10] Building click package..."
# click build "$INSTALL_DIR"

echo "✅ Preparation done, building the .click package."
 
