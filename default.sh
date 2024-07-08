#!/bin/bash

default_command() {
    if [ "$#" -eq 0 ]; then
        $LETDEV_HOME/shell/start.sh
        return
    fi

    local cmd=`echo "$@"`
    # echo "cmd: $cmd"
    
    # # Remove ': ' from the beginning of the command
    # cmd=`echo "$cmd" | sed "s|^$LETDEV_SYMBOL[ ]*||"`

    # Replace spaces with /
    # cmd=`echo "$cmd" | tr " " "/"`
    # echo "cmd: $cmd"

    # If the first symbol is a colon, then add the home directory to the command
    if [ "${cmd:0:1}" == "$LETDEV_SYMBOL" ]; then
        # Remove the first symbol
        cmd=`echo "$cmd" | sed "s/^$LETDEV_SYMBOL[ ]*//"`
        # Replace colons with slashes
        cmd=`echo "$cmd" | tr ":" "/"`
        # Add the home directory to the command
        cmd=`echo "$LETDEV_HOME/commands/:/$cmd"`
    fi

    # if [ ! -f "$cmd" ]; then
    #     echo "Command '$cmd' not found"
    #     return
    # fi

    echo "Run command: $cmd"
    eval $cmd
}

default_command $@
