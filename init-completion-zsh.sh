#!/bin/bash

multiline_to_array() {
    local str=$1
    local arr_name=$2
    eval $arr_name'=()'
    [[ -n "$str" ]] && while IFS= read -r line; do eval $arr_name'+=("$line")'; done <<<"$str"
}

# _letdev_command() {
#     local -a commands
#     commands=$($LETDEV_HOME/list-commands.sh | sed 's|^|\\|')
#     multiline_to_array "$commands" commands
#     _describe 'command' commands
# }
# # if ! command -v compinit >/dev/null; then
# #     autoload -U compinit && compinit
# # fi
# compdef _letdev_command '\:'

_letdev_init_completion() {
    local commands=$($LETDEV_HOME/list-commands.sh)
    multiline_to_array "$commands" commands

    # Create alias for every command
    for command in $commands; do
        alias_name=$(echo $command | sed 's|/|:|g')
        alias ": $alias_name"="$LETDEV_HOME/default.sh $command"
    done
}

_letdev_init_completion

# TODO: change it and implement the / trigger behavior
# Disable / trigger continuous completion (used when completing a deep path)
zstyle ':fzf-tab:*' continuous-trigger ''
