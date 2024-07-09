#!/bin/bash

list_commands() {
    local filter=`echo "$@"`

    # Replace spaces with /
    filter=`echo "$filter" | tr " " "/"`

    # Remove the first symbol if it is a colon
    # filter=`echo "$filter" | sed "s/^:[ ]*//"`

    local cur_dir=`pwd`

    local PROJECT_COMMAND_LIST=""
    if [ -d ".let-dev/$LETDEV_PROFILE/commands" ]; then
        cd ".let-dev/$LETDEV_PROFILE/commands"
        PROJECT_COMMAND_LIST=$(find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^./|:|')
    fi

    cd "$LETDEV_HOME/commands"

    local SYS_COMMAND_LIST=$(find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^./|:|')

    local USER_COMMAND_LIST=""
    if [ -d "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands" ]; then
        cd "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands"
        USER_COMMAND_LIST=$(find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^./|:|')
    fi

    cd $cur_dir

    # Merge both command lists, user commands have higher priority
    COMMAND_LIST="$PROJECT_COMMAND_LIST\n$USER_COMMAND_LIST\n$SYS_COMMAND_LIST"
    local result=`echo "$COMMAND_LIST" | sort | uniq`

    [ -n "$filter" ] && result=`echo "$result" | grep "$filter"`
    echo "$result"
}

list_commands $@
