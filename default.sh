#!/bin/bash

default_command() {
    # Return if no arguments passed
    if [ "$#" -eq 0 ]; then
        echo "No command passed"
        return
    fi

    local CMD=`echo "$@" | tr " " "/"`
    CMD="$LETDEV_HOME/commands/$CMD"

    if [ ! -f "$CMD" ]; then
        echo "Command '$CMD' not found"
        return
    fi

    eval $CMD
}

default_command $@
