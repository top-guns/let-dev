#!/bin/bash

_find_command_file() {
    local relative_path="$1"
    local cur_path=''
    
    # in project commands
    cur_path=".let-dev/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$cur_path" ] && echo "$cur_path" && return

    # in users commands
    cur_path="$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$cur_path" ] && echo "$cur_path" && return

    # in system commands
    cur_path="$LETDEV_HOME/commands$relative_path"
    [ -f "$cur_path" ] && echo "$cur_path" && return

    return 1
}

_find_listed_folder() {
    local relative_path="$1"
    local cur_path=''
    
    # in project commands
    cur_path=".let-dev/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$cur_path/-ls" ] && echo "$cur_path" && return

    # in users commands
    cur_path="$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$cur_path/-ls" ] && echo "$cur_path" && return

    # in system commands
    cur_path="$LETDEV_HOME/commands$relative_path"
    [ -f "$cur_path/-ls" ] && echo "$cur_path" && return

    return 1
}

_do_command() {
    local command="$@"
    command=$(echo "$command" | sed 's/^: //')

    local relative_path=$(echo $command | sed 's|:|/|g')
    
    local folder=$(_find_listed_folder "$relative_path")
    [ -n "$folder" ] && echo "$folder/-ls" && return

    local file=''

    file=$(_find_command_file "$relative_path")
    [ -n "$file" ] && echo "$file" && return

    # Make the last part of the path started with a dash
    # If relative_path contains a slash, then replace the last part of the path with a dash, else add a dash to the begin of the path
    if [[ "$relative_path" == */* ]]; then
        relative_path=`echo "$relative_path" | sed "s|/\([^/]*\)$|/-\1|"`
    else
        relative_path="-$relative_path"
    fi

    file=$(_find_command_file "$relative_path")
    [ -n "$file" ] && echo "$file" && return

    return 1
}

_do_command "$@"
