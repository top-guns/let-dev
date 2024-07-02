#!/bin/bash

list_commands() {
    local LIST_MODE=false
    if [ "$1" = "--list" ]; then
        LIST_MODE=true
        shift
    fi

    local COLORED=''
    [[ $TERM =~ (color|ansi|xterm|rxvt) && $LIST_MODE = false ]] && COLORED='true'

    local CMD=''
    [ -n "$1" ] && CMD=`echo "$@" | tr " " "/"`

    CMD="$LETDEV_SYMBOL$CMD"
    # echo "cmd: $CMD"

    pushd "$LETDEV_HOME/commands" > /dev/null
    COMMAND_LIST=$(find . -type d -print -o -type f -print -o -type l -print)
    popd > /dev/null

    # Fix command start symbols
    COMMAND_LIST=`echo "$COMMAND_LIST" | sed 's/^\.//' | sed "s/^\//$LETDEV_SYMBOL/" | sed "s/^$LETDEV_SYMBOL$LETDEV_SYMBOL$LETDEV_SYMBOL/$LETDEV_SYMBOL$LETDEV_SYMBOL/"`

    # Remove hidden files and folders and empty commands
    COMMAND_LIST=`echo "$COMMAND_LIST" | grep -ve "^$LETDEV_SYMBOL\." | grep -ve '/\.' | grep -v "^[[:space:]]*$"`

    LIST=`echo "$COMMAND_LIST" | grep "$CMD"`

    if [ -n "$COLORED" ]; then
        LIST=`echo "$LIST" | sed "s/$LETDEV_SYMBOL$/\*/" | sed "s/^.*$LETDEV_SYMBOL/  /" | awk '{ printf "%-20s\n", $0 }' | sed 's/\*[ ]*$/&(...)/' | sed 's/\*//' | awk '{ printf "%-26s\n", $0 }'`
        #echo "3: $LIST"
        LIST=`echo "$LIST" | uniq | sort -t $'(' -k 2,2r -k 1,1n`
        LIST=`echo "$LIST" | awk '{gsub(/.*\(.*/,"\033[1;44m&\033[0m"); print}' | awk '{gsub(/^[^(]*$/,"\033[32;44m&\033[0m"); print}'`
    fi

    echo "$LIST"
}

list_commands $@
