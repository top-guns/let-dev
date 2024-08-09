#!/usr/bin/env bash
# set -euo pipefail

_edit_config() {
    local FILE_TO_OPEN="$1"
    local CAN_BE_CREATED="${2:-false}"

    local FILE_NAME=$(basename $FILE_TO_OPEN)
    local CURRENT_COMMAND=$(basename $0)

    local command=$2
    [ -z "$command" ] && command='edit'

    if [ "$command" = "--help" ] || [ "$command" = "help" ]; then
        echo "$COMMAND_HELP"
        return
    fi

    if [ "$command" = "path" ]; then
        echo "$FILE_TO_OPEN"
        return
    fi

    if [ "$command" = "cat" ]; then
        if [ "$CAN_BE_CREATED" = "true" ]; then
            echo "The file $FILE_TO_OPEN does not exist"
        else
            sudo cat "$FILE_TO_OPEN"
        fi
        return
    fi

    if [ "$command" = "view" ]; then
        if [ "$CAN_BE_CREATED" = "true" ]; then
            echo "The file $FILE_TO_OPEN does not exist"
        else
            sudo "$LETDEV_HOME/commands/view" "$FILE_TO_OPEN"
        fi
        return
    fi

    if [ ! "$command" = "edit" ]; then
        echo "Unknown command '$command'"
        return
    fi

    # Check if the file exists
    if [ ! -f "$FILE_TO_OPEN" ]; then
        if [ "$CAN_BE_CREATED" = "true" ]; then
            echo "The file $FILE_TO_OPEN does not exist. Creating it..."
            touch "$FILE_TO_OPEN"
        else
            echo "File $FILE_TO_OPEN is not found"
            return 1
        fi
    fi

    sudo "$LETDEV_HOME/commands/edit" "$FILE_TO_OPEN"
}
