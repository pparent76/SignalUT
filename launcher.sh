#!/bin/sh

#export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export DCONF_PROFILE=/nonexistent
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_CONFIG_HOME=/home/phablet/.config/signalut.pparent/

dpioptions="--high-dpi-support=1 --force-device-scale-factor=2.5"
gpuoptions="--disable-gpu --disable-software-rasterizer  --in-process-gpu"
sandboxoptions="--no-sandbox"

sleep 0.2

mkdir -p /home/phablet/.cache/signalut.pparent/
exec ./opt/Signal/signal-desktop $dpioptions $gpuoptions $sandboxoptions
