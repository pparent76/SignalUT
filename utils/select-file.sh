#!/bin/bash

SCRIPT_DIR="${BASH_SOURCE[0]%/*}"

output=$(qmlscene $SCRIPT_DIR/upload-helper/qml/ImportPage.qml \
    -I $SCRIPT_DIR/upload-helper/ 2>&1)

while IFS= read -r line; do
    if [[ $line == *"RESULT-URL:"* ]]; then
        path=${line#*\"}
        path=${path%\"*}
        echo "$path"
        break
    fi
done <<< "$output"
