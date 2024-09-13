#!/bin/bash

# _update_command_line() {
#     # Add : to the beginning of the line
#     READLINE_LINE=$(echo "$READLINE_LINE" | sed '/^: /!s/^/: /')
# }

multiline_to_array() {
    local str=$1
    local arr_name=$2
    eval $arr_name'=()'
    while IFS= read -r line; do
        eval $arr_name'+=("$line")'
    done <<< "$str"
}

init_shell() {
     # Set the global variables
    export LETDEV_SYMBOL=':'
    # export LETDEV_HOME=`dirname $SCRIPT_PATH`
    export LETDEV_COMMANDS_PATH=`echo "$HOME/let-dev/commands"`
    export LETDEV_USERS_PATH=`echo "$HOME/let-dev/profiles"`
    export LETDEV_PROJECT_PATH=`echo "./.let-dev"`
    export LETDEV_REPLACE_CD='true'

    cur_dir=`pwd`
    builtin cd $LETDEV_HOME

    # Get the absolute path of the current script
    local SCRIPT_PATH=''
    [ -n "${BASH_SOURCE[0]}" ] && SCRIPT_PATH="${BASH_SOURCE[0]}" || SCRIPT_PATH="$0"

    # Check if the user wants to update the project
    local check_updates=$interactive_mode
    [ "$1" = "--no-update" ] && check_updates=false
    [ "$1" = "--update" ] && check_updates=true

    # Update project version
    if $check_updates; then
        # Check if there are changes in the let-dev project
        git fetch
        local changes_count=`(builtin cd $LETDEV_HOME && git rev-list HEAD...FETCH_HEAD --count)`
        if [ $changes_count -gt 0 ]; then
            # Ask the user if he wants to update the project
            printf "There are $changes_count changes in the let-dev project. Do you want to update it? (Y/n) "
            local REPLY
            read REPLY
            if [[ $REPLY =~ ^[Nn][Oo]?$ ]]; then
                echo "Skip project update"
            else
                echo "Updating project..."
                (builtin cd $LETDEV_HOME && git pull)
                # Start the script again to provide using new version of this script
                echo "Project updated, restarting..."
                "$SCRIPT_PATH" --no-update
                return
            fi
        fi
    fi

    # Add commands to path
    # export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/commands:$LETDEV_USERS_PATH/$LETDEV_PROFILE/commands:$LETDEV_HOME/commands:$PATH"
    # export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/commands:$PATH"
    export PATH="$LETDEV_HOME/path:$PATH"
    export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/path:$PATH"

    # Load let.dev libraries
    # Load marked processes engine
    source "$LETDEV_HOME/marked_process.sh"
    # Load the functions for working with the storage
    source "$LETDEV_HOME/storage.sh"
    letdev_storage_started || [ "$interactive_mode" = true ] && letdev_storage_start
    # Load the functions for working with the commands list
    source "$LETDEV_HOME/list_commands_impl.sh"
    # Load commands history engine
    source "$LETDEV_HOME/commands_history.sh"

    # Auto-completion
    if [ "$interactive_mode" = true ]; then
        if [ "$shell_name" = "bash" ]; then
            # if set -o | grep -qE '^(emac|vi)[^\w]+on$'; then
                # echo "Init completion for bash"
                source $LETDEV_HOME/init-completion-bash.sh
            # fi
        elif [ "$shell_name" = "zsh" ]; then
            # echo "Init completion for zsh"
            source $LETDEV_HOME/init-completion-zsh.sh
        else 
            echo "Unsupported shell: $shell_name"
            echo "Supported shells: bash, zsh"
            echo "Skip completion initialization"
        fi
    else 
        # echo "Skip completion initialization"
        true
    fi

    # Bindings
    # if [ "$shell_name" = "bash" ]; then
    #     # Sequence can be used like bind -x '"\C-x\C-a": preprocess_command'
    #     # bind -x '"\e-;": _update_command_line'
    #     # bind -x '"\C-x;": _update_command_line'
    #     # bind -x '"\e;": _update_command_line'
    #     bind "\"\C-'\":\"\e;\""
    #     bind -x "\"\e;\":_update_command_line"
        
    # elif [ "$shell_name" = "zsh" ]; then
    #     # bindkey '^:' "$LETDEV_SYMBOL"
    #     bindkey "^;" _update_command_line
    # fi

    # Shell options configuration
    if [ "$shell_name" = "bash" ]; then
        # Disable replacment of glob patterns which don't match any files
        shopt -u nullglob
    elif [ "$shell_name" = "zsh" ]; then
        # Disable special characters substitution (like * and ?)
        setopt NO_NOMATCH
    fi

    builtin cd $cur_dir

    # Create aliases
    source $LETDEV_HOME/recreate-aliases.sh
    letdev_recreate_all_aliases
}


shell_name=""
# If there is no arguments, or the first argument is starts with '-', then use the current shell
if [ $# -eq 0 ] || [[ $1 == -* ]]; then
    # shell_name=`basename $SHELL`

    # If $0 contains 'zsh', then the current shell is zsh, otherwise it is bash
    shell_name=`[[ $0 == *zsh* ]] && echo "zsh" || echo "bash"`
else 
    shell_name=$1
    shift
fi

interactive_mode=false
if [ $# -eq 0 ] || [[ $1 == -* ]]; then
    [ -t 0 ] && interactive_mode=true
else
    interactive_mode=$1
    shift
fi


init_shell "$@"
