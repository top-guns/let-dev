#!/bin/bash

_do_command() {
    local command="$@"
    command=$(echo "$command" | sed 's/^: //')
    local relative_path=$(echo $command | sed 's|:|/|g')
    local file=""
    
    # Find command file
    
    # in project commands
    file=".let-dev/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$file" ] && echo "$file" && return

    # in users commands
    file="$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands$relative_path"
    [ -f "$file" ] && echo "$file" && return

    # in system commands
    file="$LETDEV_HOME/commands$relative_path"
    [ -f "$file" ] && echo "$file" && return

    return 1
}

_do_command "$@"
