#!/bin/bash

PID=$1
needtoexport=0;
echo "" > /home/phablet/.cache/signalut.pparent/exportlock
allreadynavigated=0

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
                output=$(xprop -id "$window" WM_NORMAL_HINTS)
                second_line=${output#*$'\n'}
                second_line=${second_line%%$'\n'*}
                window_min_height=${second_line##* }
                
                if [ "$window_min_height" -gt "753" ]; then
                    echo "Export File"
                    for file in /home/phablet/.cache/signalut.pparent/downloads/* ; do
                        utils/rm.sh $file
                    done
                    xdotool windowfocus $window
                    xdotool key --window $window KP_Enter
                    needtoexport=$window
                else
                    echo "Import File"
                    qmlscene utils/upload-helper/qml/ImportPage.qml -I  utils/upload-helper/;
                    while read -t 0.01 -r _; do :; done
                    xdotool windowfocus $window
                    xdotool sleep 0.1
                    xdotool key  --window $window Alt+d
                    xdotool sleep 0.5
                    xdotool key  --window $window F6
                    xdotool sleep 0.1
                    xdotool key  --window $window F6
                    xdotool sleep 0.1
                    xdotool key  --window $window KP_Enter
                    xdotool sleep 0.1
                    xdotool key  --window $window KP_Enter                    
                    needtoexport=0
                    while read -t 0.01 -r _; do :; done
                    xdotool sleep 5
                    while read -t 0.01 -r _; do :; done
                    echo "">/home/phablet/.cache/signalut.pparent/downloads/00000000.png
                    utils/rm.sh /home/phablet/.local/share/signalut.pparent/recently-used.xbel
                fi
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
                       echo "">/home/phablet/.cache/signalut.pparent/downloads/00000000.png
                       utils/rm.sh /home/phablet/.local/share/signalut.pparent/recently-used.xbel
                    fi
                fi
    fi
done
