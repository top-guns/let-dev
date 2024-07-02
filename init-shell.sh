#!/bin/bash

init_shell() {
    # Get the absolute path of the current script
    local SCRIPT_PATH=''
    [ -n "${BASH_SOURCE[0]}" ] && SCRIPT_PATH="${BASH_SOURCE[0]}" || SCRIPT_PATH="$0"

    # Check is the script run in interactive mode
    local interactive_mode=false
    [ -t 0 ] && interactive_mode=true

    # Check if the user wants to update the project
    local check_updates=$interactive_mode
    check_updates=false
    [ "$1" = "--no-update" ] && check_updates=false
    [ "$1" = "--update" ] && check_updates=true

    # Update project version
    if $check_updates; then
        # Check if there are changes in the let-dev project
        git fetch
        local changes_count=`(cd $LETDEV_HOME && git rev-list HEAD...FETCH_HEAD --count)`
        if [ $changes_count -gt 0 ]; then
            # Ask the user if he wants to update the project
            printf "There are $changes_count changes in the let-dev project. Do you want to update it? (Y/n) "
            local REPLY
            read REPLY
            if [[ $REPLY =~ ^[Nn][Oo]?$ ]]; then
                echo "Skip project update"
            else
                echo "Updating project..."
                (cd $LETDEV_HOME && git pull)
                # Start the script again to provide using new version of this script
                echo "Project updated, restarting..."
                "$SCRIPT_PATH" --no-update
                return
            fi
        fi
    fi


    # Set the global variables
    export LETDEV_SYMBOL=':'
    # export LETDEV_HOME=`dirname $SCRIPT_PATH`
    export LETDEV_COMMANDS_PATH=`echo "$HOME/let-dev/commands"`
    export LETDEV_USERS_PATH=`echo "$HOME/let-dev/profiles"`
    export LETDEV_PROJECT_PATH=`echo "./.let-dev"`

    # Default command alias
    alias "$LETDEV_SYMBOL"="$LETDEV_HOME/default.sh"

    # Shell command alias
    alias "$LETDEV_SYMBOL$LETDEV_SYMBOL"="$LETDEV_HOME/shell/start.sh"

    # Add commands to path
    export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/commands:$LETDEV_USERS_PATH/$LETDEV_PROFILE/commands:$LETDEV_HOME/commands:$PATH"

    # Auto-completion
    source $LETDEV_HOME/init-completion.sh
}

cur_dir=`pwd`
cd $LETDEV_HOME
init_shell
cd $cur_dir
