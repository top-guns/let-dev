#!/bin/bash

# _update_command_line() {
#     # Add : to the beginning of the line
#     READLINE_LINE=$(echo "$READLINE_LINE" | sed '/^: /!s/^/: /')
# }

init_shell() {
    local shell_name=$1
    shift

    # Get the absolute path of the current script
    local SCRIPT_PATH=''
    [ -n "${BASH_SOURCE[0]}" ] && SCRIPT_PATH="${BASH_SOURCE[0]}" || SCRIPT_PATH="$0"

    # Check is the script run in interactive mode
    local interactive_mode=false
    [ -t 0 ] && interactive_mode=true

    # Check if the user wants to update the project
    local check_updates=$interactive_mode
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
    alias "$LETDEV_SYMBOL"="source $LETDEV_HOME/default.sh"

    # Shell command alias
    # alias "$LETDEV_SYMBOL$LETDEV_SYMBOL"="$LETDEV_HOME/shell/start.sh"

    # Add commands to path
    # export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/commands:$LETDEV_USERS_PATH/$LETDEV_PROFILE/commands:$LETDEV_HOME/commands:$PATH"
    export PATH="$LETDEV_PROJECT_PATH/$LETDEV_PROFILE/commands:$PATH"

    # Param value reader alias
    alias "${LETDEV_SYMBOL}?"=":ask"
    # alias "${LETDEV_SYMBOL}u"=":ask"
    # alias "${LETDEV_SYMBOL}user"=":ask"

     # File value reader alias
    alias "${LETDEV_SYMBOL}@"=":load"
    # alias "${LETDEV_SYMBOL}file"=":load"


    # Auto-completion
    if [ "$shell_name" = "bash" ]; then
        source $LETDEV_HOME/init-completion-bash.sh
    elif [ "$shell_name" = "zsh" ]; then
        source $LETDEV_HOME/init-completion-zsh.sh
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
}

:ask() {
    local param_name=${1:-'parameter'}
    local param
    if [[ -n $ZSH_VERSION ]]; then
        read "?Enter $param_name: " param
    elif [[ -n $BASH_VERSION ]]; then
        read -p "Enter $param_name: " param
    else
        echo "Error: Unsupported shell"
        return
    fi
    echo "$(eval echo $param)"
}

:load() {
    local file_name=$1
    cat "$(eval echo $file_name)"
}

cur_dir=`pwd`
cd $LETDEV_HOME

shell_name=""
# If there is no arguments, or the first argument is starts with '-', then use the current shell
if [ $# -eq 0 ] || [[ $1 == -* ]]; then
    shell_name=`basename $SHELL`
else 
    shell_name=$1
    shift
fi

init_shell $shell_name $@

cd $cur_dir
