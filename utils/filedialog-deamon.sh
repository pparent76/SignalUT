#!/bin/sh

PID=$1
needtoexport=0;
echo "" > /home/phablet/.cache/signalut.pparent/exportlock

xev -root  | while read -r _; do

  # flush pending events pour éviter d'accumuler
    while read -t 0.01 -r _; do :; done
    
    windows=$(xdotool search --all --pid $PID --onlyvisible)
    count=0
    for window in $windows ; do
        count=$(( count + 1 ))
    done
    
    if [ "$count" -gt "1" ]; then
        echo "more than one window"
        for window in $windows ; do
            prop=$(xprop -id $window WM_WINDOW_ROLE)
            if [ "$prop" = 'WM_WINDOW_ROLE(STRING) = "GtkFileChooserDialog"' ]; then
                echo "file chooser detected"
                xdotool windowfocus $window
                xdotool key --window $window KP_Enter
                needtoexport=$window
            fi
        done    
    fi
    
    if [ "$needtoexport" -ne "0" ]; then
                xprop -id $needtoexport >/dev/null 2>&1
                if [ "$?" -eq "1" ]; then
                    export needtoexport=0
                    echo "download file" 
                     read lock < /home/phablet/.cache/signalut.pparent/exportlock
                    if [ "$lock" != "lock" ]; then
                        echo "lock" > /home/phablet/.cache/signalut.pparent/exportlock
                       ( qmlscene utils/download-helper/qml/ExportPage.qml -I  utils/download-helper/; echo "" >/home/phablet/.cache/signalut.pparent/exportlock)  &
                       xdotool sleep 5;
                    fi
                fi
    fi
done
