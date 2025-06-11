#!/usr/bin/env bash
# set -euo pipefail

_create_if_need() {
    local FILE_TO_OPEN="$1"
    local CAN_BE_CREATED="$2"
    local SUDO_MODE="$3"

    if [ "$CAN_BE_CREATED" = "true" ]; then
        [ "$SUDO_MODE" = "true" ] && :sudo touch "'$FILE_TO_OPEN'" || touch "$FILE_TO_OPEN"
    elif [ "$CAN_BE_CREATED" = "false" ]; then
        echo "File '$FILE_TO_OPEN' is not found"
        return 1
    else
        echo "The file '$FILE_TO_OPEN' does not exist. Do you want to create it? [y/N]"
        read -r answer
        if [ "$answer" = "y" ]; then
            [ "$SUDO_MODE" = "true" ] && :sudo touch "$FILE_TO_OPEN" || touch "$FILE_TO_OPEN"
        else
            return 1
        fi
    fi
}

_edit_config() {
    echo "All args: $@"
    local FILE_TO_OPEN="$1"
    echo "File to open: $FILE_TO_OPEN"
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
        return 0
    fi
    
    if [ "$command" = "path" ]; then
        echo "$FILE_TO_OPEN"
        return 0
    fi

    if [ "$command" = "cat" ]; then
        [ "$SUDO_MODE" = "true" ] && sudo cat "$FILE_TO_OPEN" || cat "$FILE_TO_OPEN"
        return 0
    fi

    if [ "$command" = "view" ]; then
        if [ "$SUDO_MODE" = "true" ]; then
            :sudo :view "$FILE_TO_OPEN" "$FILE_TO_OPEN"
        else
            :view "$FILE_TO_OPEN" "$FILE_TO_OPEN"
        fi
        return 0
    fi

    if [ "$command" = "edit" ]; then 
        echo "Editing file !!!! '$FILE_TO_OPEN'..."
        if [ ! -f "$FILE_TO_OPEN" ]; then
            _create_if_need "$FILE_TO_OPEN" "$CAN_BE_CREATED" "$SUDO_MODE" || return 0
        fi

        # echo "Opening file '$FILE_TO_OPEN' for editing..."
        local edit_cmd=":edit '$FILE_TO_OPEN'"
        [ "$SUDO_MODE" = "true" ] && edit_cmd=":sudo \"$edit_cmd\""
        echo "edit_cmd '$edit_cmd'"
        eval "$edit_cmd"
        return $?
    fi

    echo "Unknown command '$command'"
    return 0
}
