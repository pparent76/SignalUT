#!/bin/bash

echo "df84ff50557373cd882941cafb7ad344  /lib/aarch64-linux-gnu/liblomiri-private.so"| md5sum -c -
#If we are running the latest version of lomiri we'll use Xcb to display ContentHub Windows
if [ "$?" -eq "0" ]; then
    export QT_QPA_PLATFORM=xcb
fi

PID=$1
needtoexport=0;
echo "" > /home/phablet/.cache/signalut.pparent/exportlock
allreadynavigated=0
allreadyseenwindow=0
firstimport=1;

xev -root  | while read -r _; do

  # flush pending events pour éviter d'accumuler
    while read -t 0.01 -r _; do :; done
    
    windows=$(xdotool search --all --pid $PID --onlyvisible)
    count=0
    for window in $windows ; do
        count=$(( count + 1 ))
    done
    
    if [ "$count" -eq "0" ]; then
        windows=$(xdotool search --all --pid $PID)
        for window in $windows ; do
            count=$(( count + 1 ))
        done
        if [ "$count" -eq "0" ]&&  [ "$allreadyseenwindow" -eq "1" ] ; then
            echo "No window left exiting...";
            exit 0;
        fi
    else
        allreadyseenwindow=1;
    fi
    
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
                    qmlscene utils/upload-helper/qml/ImportPage.qml -I  utils/upload-helper/ &
                    pid=$!
                    while kill -0 "$pid" 2>/dev/null; do
                        while read -t 0.01 -r _; do :; done
                    done
                    xdotool windowfocus $window
                    if [ "$firstimport" -eq "1" ]; then
                        bin/xdotool key  --window $window --repeat 5 Tab
                        firstimport=0;
                        xdotool sleep 0.1
                        xdotool key  --window $window KP_Enter
                        xdotool sleep 0.5 
                        xdotool key  --window $window F6
                        xdotool sleep 0.3
                    else
                        bin/xdotool key  --window $window --repeat 2 F6
                    fi
                    xdotool key  --window $window KP_Enter
                  
                    needtoexport=0
                    while read -t 0.01 -r _; do :; done
                    xdotool sleep 1
                    echo "">/home/phablet/.cache/signalut.pparent/downloads/00000000.png
                    xdotool sleep 4
                    while read -t 0.01 -r _; do :; done
                    for file in /home/phablet/.cache/signalut.pparent/downloads/* ; do
                        utils/rm.sh $file
                    done
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
                       ( qmlscene utils/download-helper/qml/ExportPage.qml -I  utils/download-helper/; echo "" >/home/phablet/.cache/signalut.pparent/exportlock; echo "">/home/phablet/.cache/signalut.pparent/downloads/00000000.png )  &
                       xdotool sleep 5;
                       utils/rm.sh /home/phablet/.local/share/signalut.pparent/recently-used.xbel
                    fi
                fi
    fi
done
