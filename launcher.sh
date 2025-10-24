#!/bin/sh

export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 

mkdir -p /home/phablet/.cache/signalut.pparent/
./opt/Signal/signal-desktop --no-sandbox >/home/phablet/.cache/signalut.pparent/log 2>&1

