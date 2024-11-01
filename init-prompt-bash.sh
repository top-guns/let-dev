#!/bin/bash

# Color codes
RESET='\033[0m'

# Foreground colors
FG_BLACK='\033[30m'
FG_RED='\033[31m'
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_BLUE='\033[34m'
FG_PURPLE='\033[35m'
FG_CYAN='\033[36m'
FG_WHITE='\033[37m'

# Background colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Bright foreground colors
FG_BRIGHT_BLACK='\033[90m'
FG_BRIGHT_RED='\033[91m'
FG_BRIGHT_GREEN='\033[92m'
FG_BRIGHT_YELLOW='\033[93m'
FG_BRIGHT_BLUE='\033[94m'
FG_BRIGHT_PURPLE='\033[95m'
FG_BRIGHT_CYAN='\033[96m'
FG_BRIGHT_WHITE='\033[97m'

# Bright background colors
BG_BRIGHT_BLACK='\033[100m'
BG_BRIGHT_RED='\033[101m'
BG_BRIGHT_GREEN='\033[102m'
BG_BRIGHT_YELLOW='\033[103m'
BG_BRIGHT_BLUE='\033[104m'
BG_BRIGHT_PURPLE='\033[105m'
BG_BRIGHT_CYAN='\033[106m'
BG_BRIGHT_WHITE='\033[107m'

PS1='\[\033[47m\]\[\033[01;30m\] bash \[\033[00m\] '
FOOTER_BORDER='=' #$(printf '\xC4')
#'\[\033[47m\]\[\033[01;30m\]
COMMAND_SEPARATOR='-'

LAST_CLI_COMMAND=""

vlength() {
    local str="$1"
    str=$(echo "$str" | sed 's/\\033[^m]*m//g')
    echo ${#str}
}

concat() {
    local separator="$1"
    shift
    local strings=("$@")
    local str=""
    for (( i=0; i<${#strings[@]}; i++ )); do
        [ $i -gt 0 ] && str+="$separator"
        str+="${strings[$i]}"
    done
    echo $str
}

print_separator() {
    local fill="$1"

    local cols=$(tput cols)
    local fill_length=$(vlength "$fill")
    local fill_count=$((cols / fill_length))
    
    # Print the separator
    for (( i=0; i<fill_count; i++ )); do
        echo -n -e "$fill"
    done
    echo ""
}

print_header() {
    local last_exit_code="$1"

    # ----------------------------------------------------------------
    # Fill the left and right parts of the header

    local left_part=()
    local right_part=()

    # Monkey
    # 🐵 🐒 🦊 🐞 🪲 🐸 🍀 🔥 🍏 🍌 📟 💡 🛠️ ♨️ ⚠️ 💤 ✔️ 🔘 🛜 📶 🟢 🔴 🟠 🟡 🔵 ⚪️ 👍 👌 ☕ 🌀 🌏 🌍 🌎 🌐 💻 🔒 🔆 🔅 🫥 
    if [ $last_exit_code -eq 0 ]; then
        left_part+=("🐵")
    else
        left_part+=("🐞")
    fi

    # Get the current working directory
    left_part+=("pwd: ${FG_GREEN}$(pwd)${RESET}")

    # Last exit code
    if [ $last_exit_code -eq 0 ]; then
        left_part+=("last exit code: ${FG_GREEN}$last_exit_code${RESET}")
    else
        left_part+=("last exit code: ${FG_RED}$last_exit_code${RESET}")
    fi

    # Google availability
    if ping -q -c 1 -W 1 google.com 2>/dev/null >/dev/null; then
        right_part+=("Internet: ${FG_GREEN}✓${RESET}")
    else
        right_part+=("Internet: ${FG_RED}✗${RESET}")
    fi

    # Office availability
    if ping -q -c 1 -W 1 office.lan 2>/dev/null >/dev/null; then
        right_part+=("VPN: ${FG_GREEN}✓${RESET}")
    else
        right_part+=("VPN: ${FG_RED}✗${RESET}")
    fi

    # Get the username and hostname
    # right_part+=("${BG_BLUE}$(whoami)${FG_GREEN}@${RESET}${BG_BLUE}$(hostname)${RESET}")
    # right_part+=("$(whoami)${FG_GREEN}@${RESET}$(hostname)")
    right_part+=("$(whoami)${FG_GREEN}🌀${RESET}$(hostname)")

    # ----------------------------------------------------------------
    # Concatenate the left parts with ' | ' separator

    local SEPARATOR="   ${FG_CYAN}│${RESET}   "

    left_part=$(concat "${SEPARATOR}" "${left_part[@]}")
    right_part=$(concat "${SEPARATOR}" "${right_part[@]}")

    # ----------------------------------------------------------------
    # Calculate the number of spaces needed for right alignment

    local spaces_length=$(($(tput cols) - $(vlength "$left_part") - $(vlength "$right_part") - 4))

    # ----------------------------------------------------------------
    # Print the header

    print_separator "${FG_CYAN}═${RESET}"
    echo -e " ${left_part}$(printf '%*s' "$spaces_length" '')${right_part}"
    print_separator "${FG_CYAN}═${RESET}"
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
    print_separator "${FG_CYAN}┈${RESET}"
    echo -n "${PS1@P}"
    echo "$LAST_CLI_COMMAND"
}
# Function to execute after each command
precmd() {
    local last_exit_code=$?

    if [ -z "$LAST_CLI_COMMAND" ]; then
        clear_header
        echo ""
    fi

    LAST_CLI_COMMAND=""
    print_header "$last_exit_code"
}


# Set preexec to run before each command
trap 'preexec' DEBUG

# Set precmd to run before displaying the prompt
PROMPT_COMMAND='precmd'


# Print the header when the terminal is opened
# print_header
LAST_CLI_COMMAND="."
