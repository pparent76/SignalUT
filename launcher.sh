#!/bin/sh

#export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export DCONF_PROFILE=/nonexistent
export LIBGL_ALWAYS_SOFTWARE=1
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

dpioptions="--high-dpi-support=1 --force-device-scale-factor=2.75"
gpuoptions="--disable-gpu --disable-software-rasterizer  --in-process-gpu"
sandboxoptions="--no-sandbox"

#Open a dummy qt gui app to realease lomiri from its waiting
(sleep.sh; $PWD/bin/xdg-open)&

exec ./opt/Signal/Signal $dpioptions $gpuoptions $sandboxoptions
