#!/bin/bash

default_command() {
    # Return if no arguments passed
    if [ "$#" -eq 0 ]; then
        echo "No command passed"
        return
    fi

    local cmd=`echo "$@" | tr " " "/" | sed "s|^$LETDEV_SYMBOL/||"`
    cmd=`echo "$LETDEV_HOME/commands/:/$cmd"`

    if [ ! -f "$cmd" ]; then
        echo "Command '$cmd' not found"
        return
    fi

    eval $cmd
}

default_command $@
