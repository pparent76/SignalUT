#!/bin/sh

PID=$1

while true; do
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
                xdotool key KP_Enter
                xdotool sleep 0.5
                xprop -id $window WM_WINDOW_ROLE >/dev/null 2>&1
                if [ "$?" -eq "1" ]; then
                    echo "download file"
                    qmlscene utils/download-helper/qml/ExportPage.qml -I  utils/download-helper/
                else
                    xdotool sleep 0.7
                    xprop -id $window WM_WINDOW_ROLE >/dev/null 2>&1
                    if [ "$?" -eq "1" ]; then
                        echo "download file"
                        qmlscene utils/download-helper/qml/ExportPage.qml -I  utils/download-helper/
                    fi
                fi
                
            fi
        done    
    fi
    xdotool sleep 0.6   
done
