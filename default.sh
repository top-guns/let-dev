#!/bin/bash

default_command() {
    if [ "$#" -eq 0 ]; then
        $LETDEV_HOME/shell/start.sh
        return
    fi

    local cur_command=""
    if [ -n "$ZSH_VERSION" ]; then
        # Save the current command to the history
        fc -AI
        # Update the history file
        fc -R
        # Get the last command
        cur_command=$(fc -ln -1 | tail -n 1)
    elif [ -n "$BASH_VERSION" ]; then
        # Save the current command to the history
        history -a
        # Update the history file
        history -r
        # Get the last command
        cur_command=$(history | tail -n 1 | sed "s/^[ ]*[0-9]*[ ]*//")
    else
        echo "Unsupported shell"
        return 1
    fi

    # Add the current command to the let-dev history
    put_command_to_history "$cur_command"

    local cmd=`echo "$1"`
    shift
    if [ -z "$cmd" ]; then
        return
    fi
    # echo "cmd: $cmd"
    
    # # Remove ': ' from the beginning of the command
    # cmd=`echo "$cmd" | sed "s|^$LETDEV_SYMBOL[ ]*||"`

    # Replace spaces with /
    # cmd=`echo "$cmd" | tr " " "/"`
    # echo "cmd: $cmd"

    # If the first symbol is a colon, then add the home directory to the command
    if [[ "${cmd:0:1}" == "$LETDEV_SYMBOL" ]]; then
        # Remove let-dev command at the beginning of the line
        cmd=$(echo "$cmd" | sed "s/^[ ]*:[ ][ ]*//")
        # Remove the first symbol if it is a colon
        cmd=$(echo "$cmd" | sed "s/^://")
        # Replace colons with slashes
        cmd=`echo "$cmd" | tr ":" "/"`

        local project_command=$(list_commands --project --format=fullpath | grep "$cmd$")

        # Add the home directory to the command
        if [ -n "$project_command" ]; then
            cmd=`echo "$project_command"`
        elif [ -f "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd" ]; then
            cmd=`echo "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd"`
        elif [ -f "$LETDEV_HOME/commands/$cmd" ]; then
            cmd=`echo "$LETDEV_HOME/commands/$cmd"`
        else 
            echo "Command '$cmd' not found"
            return
        fi
    fi

    # Resolve symbolic links
    # cmd=`readlink -f $cmd`

    source "$cmd" "$@"
}

default_command "$@"
