#!/bin/bash

output=$(qmlscene /opt/click.ubuntu.com/signalut.pparent/current/utils/upload-helper/qml/ImportPage.qml \
    -I /opt/click.ubuntu.com/signalut.pparent/current/utils/upload-helper/ 2>&1)

while IFS= read -r line; do
    if [[ $line == *"RESULT-URL:"* ]]; then
        path=${line#*\"}
        path=${path%\"*}
        echo "$path"
        break
    fi
done <<< "$output"
