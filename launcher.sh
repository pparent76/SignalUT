#!/bin/sh

export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export DCONF_PROFILE=/nonexistent
export XDG_CONFIG_HOME=/home/phablet/.config/signalut.pparent/

if [ "$DISPLAY" = "" ]; then
    i=0
    while [ -e "/tmp/.X11-unix/X$i" ] ; do 
        i=$(( i + 1 ))
    done
    i=$(( i - 1 ))
    display=":$i"
    export DISPLAY=$display
fi

export PATH=$PWD/bin:$PATH

scale=$(./utils/get-scale.sh 2>/dev/null )

dpioptions="--high-dpi-support=1 --force-device-scale-factor=$scale --grid-unit-px=$GRID_UNIT_PX"
sandboxoptions="--no-sandbox"
gpuoptions="--use-gl=egl --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=UseSkiaRenderer,VaapiVideoDecoder --disable-frame-rate-limit --disable-gpu-vsync --enable-oop-rasterization"

#Open a dummy qt gui app to realease lomiri from its waiting
(utils/sleep.sh; $PWD/bin/xdg-open )&

exec ./opt/Signal/signal-desktop $dpioptions $sandboxoptions $gpuoptions
