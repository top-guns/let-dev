#!/bin/bash

list_commands() {
    local filter=`echo "$@"`

    # Replace spaces with /
    filter=`echo "$filter" | tr " " "/"`

    # Remove the first symbol if it is a colon
    # filter=`echo "$filter" | sed "s/^:[ ]*//"`

    local cur_dir=`pwd`
    cd "$LETDEV_HOME/commands/:"
    local COMMAND_LIST=$(find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^./|:|')
    cd $cur_dir

    local result=`echo "$COMMAND_LIST"`
    [ -n "$filter" ] && result=`echo "$result" | grep "$filter"`

    echo "$result"
}

list_commands $@
