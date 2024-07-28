#!/bin/bash

# 'cd' command implementation

_do_cd() {
    letdev_remove_project_aliases

    local dir="$1"
    if [ -n "$dir" ] && [ "$dir" != "$PWD" ]; then
        builtin cd "$dir"
    else
        echo "let-dev context updated"
    fi

    letdev_recreate_project_aliases
}

_do_cd "$@"

# _cd() {
#     local curcontext="$curcontext" state line
#     typeset -A opt_args

#     local -a commands
#     commands=(
#         'home:Go to the home directory'
#         'project:Go to the project directory'
#         'profile:Go to the profile directory'
#         'commands:Go to the commands directory'
#         'profiles:Go to the profiles directory'
#         'letdev:Go to the letdev directory'
#     )

#     _describe -t commands 'cd commands' commands
# }

# compdef _cd cd

# _cd
