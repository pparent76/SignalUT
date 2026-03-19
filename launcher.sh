#!/bin/bash

export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=/home/phablet/.config/signalut.pparent/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export DCONF_PROFILE=/nonexistent
export XDG_CONFIG_HOME=/home/phablet/.config/signalut.pparent/
export XDG_DATA_HOME=/home/phablet/.local/share/signalut.pparent/
export XDG_DESKTOP_DIR=/home/phablet/.config/signalut.pparent/
export LD_LIBRARY_PATH=$PWD/lib/aarch64-linux-gnu/

utils/mkdir.sh /home/phablet/.config/signalut.pparent/
echo "\"$PWD/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/im-maliit.so\""  > /home/phablet/.config/signalut.pparent/immodules.cache 
echo  "\"Maliit\" \"Maliit Input Method\" \"maliit\" \"\" \"en:ja:ko:zh:*\""  >> /home/phablet/.config/signalut.pparent/immodules.cache 

echo 'XDG_DESKTOP_DIR="/home/phablet/.cache/signalut.pparent/downloads/"'> /home/phablet/.config/signalut.pparent/user-dirs.dirs

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
utils/mkdir.sh /home/phablet/.cache/signalut.pparent/

#Read micstate in conf
while read p; do
  if [[ "$p" == *"microState="* ]]; then  micstate=$p; fi
  if [[ "$p" == *"keyboardHeight="* ]]; then   keyboardHeight="${p#keyboardHeight=}" ; fi
done <  /home/phablet/.config/signalut.pparent/signalut.pparent/signalut.pparent.conf 


if { [[ "$micstate" != *"microState=1"* ]] && [[ "$micstate" != *"microState=4"* ]]; } || \
   { [[ "$keyboardHeight" = "" ]] || [[ "$keyboardHeight" -lt "100" ]] || [[ "$keyboardHeight" -gt "4000" ]]; }; then
        xdotool sleep 2;
        qmlscene utils/mic-permission-requester/Main.qml -I utils/mic-permission-requester/ &
        xdotool sleep 5;
        while true; do
            xdotool sleep 1;
            while read p; do
                if [[ "$p" == *"microState="* ]]; then  micstate=$p; fi
            done <  /home/phablet/.config/signalut.pparent/signalut.pparent/signalut.pparent.conf 
            echo "$micstate"
            if  [ "$micstate" == "microState=1" ]||  [ "$micstate" == "microState=2" ]; then
                break;
            fi
            if  [ "$micstate" == "microState=4" ]; then
                    break;
            fi
        done
fi

#Read micstate in conf
while read p; do
  if [[ "$p" == *"keyboardHeight="* ]]; then keyboardHeight="${p#keyboardHeight=}" ; fi
done <  /home/phablet/.config/signalut.pparent/signalut.pparent/signalut.pparent.conf 
    
utils/rm.sh /home/phablet/.local/share/signalut.pparent/recently-used.xbel

for file in /home/phablet/.cache/signalut.pparent/downloads/* ; do
    utils/rm.sh $file
done


scale=$(./utils/get-scale.sh 2>/dev/null )

dpioptions="--high-dpi-support=1 --force-device-scale-factor=$scale --keyboard-height=$keyboardHeight"
sandboxoptions="--no-sandbox"
gpuoptions="--use-gl=egl --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=UseSkiaRenderer,VaapiVideoDecoder --disable-frame-rate-limit --disable-gpu-vsync --enable-oop-rasterization"

#Start a dummy Qt app called "placeholder-killer" to realease lomiri from its waiting
( utils/sleep.sh; $PWD/bin/placeholder-killer )&
( utils/filedialog-deamon.sh $$ )&

initpwd=$PWD
utils/mkdir.sh /home/phablet/.cache/signalut.pparent/downloads/
cd /home/phablet/.cache/signalut.pparent/downloads/
exec $initpwd/opt/Signal/signal-desktop $dpioptions $sandboxoptions $gpuoptions
