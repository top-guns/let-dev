#!/usr/bin/env bash
# set -euo pipefail

_edit_config() {
    local FILE_TO_OPEN="$1"
    shift

    # Parse command and options
    local command="edit"    # Default command is 'edit', commands: edit, view, cat, path, help
    local CAN_BE_CREATED="ask"
    local SUDO_MODE="false" 

    for arg in "$@"; do
        case $arg in
            --create=*)
                CAN_BE_CREATED="${arg#*=}"
                ;;
            --create)
                CAN_BE_CREATED="true"
                ;;
            --no-create)
                CAN_BE_CREATED="false"
                ;;
            --sudo=*)
                SUDO_MODE="${arg#*=}"
                ;;
            --sudo)
                SUDO_MODE="true"
                ;;
            --no-sudo)
                SUDO_MODE="false"
                ;;
            *)
                command="$arg"
                ;;
        esac
    done

    # echo "Editing file: $FILE_TO_OPEN"
    # echo "Command: $command"
    # echo "Can be created: $CAN_BE_CREATED"
    # echo "Sudo mode: $SUDO_MODE"


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
            echo "The file '$FILE_TO_OPEN' does not exist. Creating it..."
            [ "$SUDO_MODE" = "true" ] && :sudo touch "'$FILE_TO_OPEN'" || touch "'$FILE_TO_OPEN'"
        elif [ "$CAN_BE_CREATED" = "false" ]; then
            echo "File '$FILE_TO_OPEN' is not found"
            return 1
        else
            echo "The file '$FILE_TO_OPEN' does not exist. Do you want to create it? [y/N]"
            read -r answer
            if [ "$answer" = "y" ]; then
                [ "$SUDO_MODE" = "true" ] && :sudo touch "'$FILE_TO_OPEN'" || touch "'$FILE_TO_OPEN'"
            else
                return 1
            fi
        fi
    fi

    if [ "$command" = "cat" ]; then
        [ "$SUDO_MODE" = "true" ] && :sudo cat "'$FILE_TO_OPEN'" || cat "'$FILE_TO_OPEN'"
        return
    fi

    if [ "$command" = "view" ]; then
        if [ "$SUDO_MODE" = "true" ]; then
            :sudo :view "'$FILE_TO_OPEN'" "'$FILE_TO_OPEN'"
        else
            :view "'$FILE_TO_OPEN'" "'$FILE_TO_OPEN'"
        fi
        return
    fi

    if [ "$command" = "edit" ]; then
        if [ "$SUDO_MODE" = "true" ]; then
            :sudo :edit "'$FILE_TO_OPEN'"
        elif [ "$SUDO_MODE" = "false" ]; then
            :edit "'$FILE_TO_OPEN'"
        fi
        return
    fi

    echo "Unknown command '$command'"
    return 1
}
