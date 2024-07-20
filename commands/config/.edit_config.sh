#!/usr/bin/env bash
# set -euo pipefail

_edit_config() {
    local FILE_TO_OPEN="$1"
    local CAN_BE_CREATED="${2:-false}"

    local FILE_NAME=$(basename $FILE_TO_OPEN)
    local CURRENT_COMMAND=$(basename $0)

    if [ "$2" = "--help" ] || [ "$2" = "help" ]; then
        echo "$COMMAND_HELP"
        return
    fi

    # Check if the file exists
    if [ ! -f "$FILE_TO_OPEN" ]; then
        if [ "$CAN_BE_CREATED" = "true" ]; then
            echo "The $FILE_TO_OPEN file does not exist. Creating it..."
            touch "$FILE_TO_OPEN"
        else
            echo "File $FILE_TO_OPEN is not found"
            return 1
        fi
    fi

    sudo "$LETDEV_HOME/commands/edit" "$FILE_TO_OPEN"
}
