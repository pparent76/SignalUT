#!/bin/sh

export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export ELECTRON_ENABLE_LOGGING=true
export ELECTRON_ENABLE_STACK_DUMPING=true

export LIBGL_ALWAYS_SOFTWARE=1

mkdir -p /home/phablet/.cache/signalut.pparent/
mkdir -p /home/phablet/.cache/signalut.pparent/.cache/tmp
export TMPDIR=/home/phablet/.cache/signalut.pparent/tmp
./opt/Signal/signal-desktop --disable-gpu --enable-logging --v=1 --no-sandbox >/home/phablet/.cache/signalut.pparent/log 2>&1

