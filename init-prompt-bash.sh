#!/bin/bash

PS1='\[\033[47m\]\[\033[01;30m\] bash \[\033[00m\] '
FOOTER_BORDER='═'
#'\[\033[47m\]\[\033[01;30m\]

LAST_CLI_COMMAND=""

print_header() {
    # Get the current working directory
    pwd=$(pwd)
    # Get the username and hostname
    user_host="$(whoami)@$(hostname)"

    # Get the width of the terminal
    cols=$(tput cols)
    # Calculate the number of spaces needed for right alignment
    spaces=$((cols - ${#pwd} - ${#user_host} - 1))

    printf '%*s\n' "$cols" '' | tr ' ' "$FOOTER_BORDER"
    # Print the current working directory and the user@host aligned to the right
    echo -e "\033[1;32m$pwd\033[0m$(printf '%*s' "$spaces" '')\033[1;32m$user_host\033[0m"
    
    printf '%*s\n' "$cols" '' | tr ' ' "$FOOTER_BORDER"
}

clear_header() {
    tput cuu1
    tput el
    tput cuu1
    tput el
    tput cuu1
    tput el
    tput cuu1
    tput el
}

preexec() {
    # Read the last line of the terminal
    local last_line=$(history | tail -n 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    [ -z "$last_line" ] && return
    [ "$LAST_CLI_COMMAND" = "$last_line" ] && return
    [ "$BASH_COMMAND" = "precmd" ] && return;

    LAST_CLI_COMMAND="$last_line"

    clear_header

    # Manually print the prompt
    echo -n "${PS1@P}"
    echo "$LAST_CLI_COMMAND"
}
# Function to execute after each command
precmd() {
    if [ -z "$LAST_CLI_COMMAND" ]; then
        clear_header
        echo ""
    fi

    LAST_CLI_COMMAND=""
    print_header
}


# Set preexec to run before each command
trap 'preexec' DEBUG

# Set precmd to run before displaying the prompt
PROMPT_COMMAND='precmd'


# Print the header when the terminal is opened
# print_header
LAST_CLI_COMMAND="."
