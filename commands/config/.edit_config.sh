#!/usr/bin/env bash
# set -euo pipefail

_edit_config() {
    local FILE_TO_OPEN="$1"
    shift

    local FILE_NAME=$(basename $FILE_TO_OPEN)
    local CURRENT_COMMAND=$(basename $0)

    local command=$1
    [ -z "$command" ] && command='edit' || shift

    local CAN_BE_CREATED="$1"
    [ -n "$CAN_BE_CREATED" ] && shift

    if [ "$command" = "--help" ] || [ "$command" = "help" ]; then
        echo "$COMMAND_HELP"
        return
    fi

    if [ "$command" = "path" ]; then
        echo "$FILE_TO_OPEN"
        return
    fi

    # Check if the file exists
    if [ ! -f "$FILE_TO_OPEN" ]; then
        if [ "$CAN_BE_CREATED" = "true" ]; then
            echo "The file $FILE_TO_OPEN does not exist. Creating it..."
            sudo touch "$FILE_TO_OPEN"
        elif [ "$CAN_BE_CREATED" = "false" ]; then
            echo "File $FILE_TO_OPEN is not found"
            return 1
        else
            echo "The file $FILE_TO_OPEN does not exist. Do you want to create it? [y/N]"
            read -r answer
            if [ "$answer" = "y" ]; then
                sudo touch "$FILE_TO_OPEN"
            else
                return 1
            fi
        fi
    fi

    [ "$command" = "cat" ] && sudo cat "$FILE_TO_OPEN" && return
    [ "$command" = "view" ] && source "$LETDEV_HOME/commands/view" "$FILE_TO_OPEN" && return
    [ "$command" = "edit" ] && source "$LETDEV_HOME/commands/edit" "$FILE_TO_OPEN" && return

    echo "Unknown command '$command'"
    return 1
}
