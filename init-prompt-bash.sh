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

# Bold foreground colors
FG_BOLD_BLACK='\033[1;30m'
FG_BOLD_RED='\033[1;31m'
FG_BOLD_GREEN='\033[1;32m'
FG_BOLD_YELLOW='\033[1;33m'
FG_BOLD_BLUE='\033[1;34m'
FG_BOLD_PURPLE='\033[1;35m'
FG_BOLD_CYAN='\033[1;36m'
FG_BOLD_WHITE='\033[1;37m'

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


# PS1='\[\033[47m\]\[\033[01;30m\] bash \[\033[00m\] '
PS1='\[\033[47m\]\[\033[01;30m\]#cmd ⏎\[\033[00m\] '

LAST_CLI_COMMAND=""

INTERNET_AVAILIBLE=1
export EXTERNAL_IP=""


vlength() {
    local str="$1"
    str=$(echo "$str" | sed 's/\\033[^m]*m//g')
    echo ${#str}
}

concat() {
    local separator="$1"
    shift
    local result=""
    for element in "$@"; do
        [ -z "$result" ] && result="$element" || result="$result$separator$element"
    done
    echo "$result"
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

check_internet_availability() {
    # google.com availability
    ping -q -c 1 -W 1 8.8.8.8 2>/dev/null >/dev/null
    return $?
}

check_dns_availability() {
    # google.com availability
    timeout 1 host google.com 2>/dev/null >/dev/null
    return $?
}

print_header() {
    local last_exit_code="$1"

    # ----------------------------------------------------------------
    # Fill the left and right parts of the header

    local left_part=()
    local right_part=()

    local left_part2=()
    local right_part2=()

    local internet_availible=1
    [ $INTERNET_AVAILIBLE -eq 0 ] && internet_availible=0 || internet_availible=$( ping -q -c 1 -W 1 8.8.8.8 2>/dev/null >/dev/null; echo $? )

    # Monkey
    # 🐵 🐒 🦊 🐞 🪲 🐸 🍀 🔥 🍏 🍌 📟 💡 🛠️ ♨️ ⚠️ 💤 ✔️ 🔘 🛜 📶 🟢 🔴 🟠 🟡 🔵 ⚪️ 👍 👌 🌀 🌏 🌍 🌎 🌐 💻 🔒 🔆 🔅 🫥 
    if [ $last_exit_code -eq 0 ]; then
        left_part+=("${FG_CYAN}BASH${RESET}")
        left_part2+=(" 🐵 ")
        # left_part2+=("${FG_GREEN}ok${RESET}")
    else
        left_part+=("${FG_CYAN}BASH${RESET}")
        left_part2+=(" 🐞 ")
        # left_part+=("⚠️")
        # left_part2+=("${FG_RED}  ${RESET}")
    fi

    # Get the current working directory
    left_part+=("pwd: ${FG_GREEN}$(pwd)${RESET}")

    # Last exit code
    if [ $last_exit_code -eq 0 ]; then
        left_part2+=("exit code: ${FG_GREEN}$last_exit_code (ok)${RESET}")
    else
        left_part2+=("exit code: ${FG_RED}$last_exit_code (error)${RESET}")
    fi

    # Git repository info
    if [ -d .git ]; then
        local branch=$(git branch --show-current)
        local unconmmited=$(git diff --shortstat 2> /dev/null | tail -n1)
        local untracked=$(git ls-files --others --exclude-standard | wc -l)
        local unpushed=$(git log origin/$branch..$branch --oneline 2> /dev/null | wc -l)
        local unmerged=$(git log --oneline --merges 2> /dev/null | wc -l)
        local stashes=$(git stash list | wc -l)
        local ahead=$(git log origin/$branch..$branch --oneline 2> /dev/null | wc -l)
        local behind=$(git log $branch..origin/$branch --oneline 2> /dev/null | wc -l)
        local commits=$(git log --oneline 2> /dev/null | wc -l)
        local tags=$(git tag --list | wc -l)
        local remotes=$(git remote | wc -l)
        local branches=$(git branch --list | wc -l)
        local submodules=$(git submodule status | wc -l)
        local conflicts=$(git diff --name-only --diff-filter=U | wc -l)

        local status=""
        if [ $conflicts -gt 0 ]; then
            status+="${FG_RED}C${RESET}"
        elif [ -n "$unconmmited" ]; then
            status+="${FG_YELLOW}*${RESET}"
        elif [ $untracked -gt 0 ]; then
            status+="${FG_YELLOW}+${RESET}"
        elif [ $unpushed -gt 0 ]; then
            status+="${FG_YELLOW}↑${RESET}$unpushed"
        elif [ $unmerged -gt 0 ]; then
            status+="${FG_YELLOW}⚠${RESET}$unmerged"
        else
            status+="${FG_GREEN}✓${RESET}"
        fi

        if [ $ahead -gt 0 ]; then
            status+="${FG_GREEN}↑${RESET}$ahead"
        fi
        if [ $behind -gt 0 ]; then
            status+="${FG_RED}↓${RESET}$behind"
        fi

        local git_info="git: $status $branch"
        
        if [ $stashes -gt 0 ]; then
            git_info+=" ${FG_YELLOW}⚑${RESET}$stashes"
        fi

        left_part2+=("$git_info")
    fi

    # Internet availability
    if [ $internet_availible -eq 0 ]; then
        if [ -z "$EXTERNAL_IP" ] && [ $INTERNET_AVAILIBLE -eq 0 ]; then
            EXTERNAL_IP=$(curl -s ifconfig.me)
        fi
        right_part+=("${FG_GREEN}✓${RESET} Internet ${EXTERNAL_IP}")
    else
        EXTERNAL_IP=""
        right_part+=("${FG_RED}✗${RESET} Internet")
    fi
    INTERNET_AVAILIBLE=$internet_availible

    # # DNS availability
    # local dns_availible=$( timeout 1 host google.com 2>/dev/null >/dev/null; echo $? )
    # if [ $dns_availible -eq 0 ]; then
    #     right_part2+=("${FG_GREEN}✓${RESET} DNS")
    # else
    #     right_part2+=("${FG_RED}✗${RESET} DNS")
    # fi

    # Office VPN availability
    if [ "$internet_availible" = "true" ] && ping -q -c 1 -W 1 office.lan 2>/dev/null >/dev/null; then
        right_part2+=("${FG_GREEN}✓${RESET} Office VPN")
    else
        right_part2+=("${FG_RED}✗${RESET} Office VPN")
    fi

    # Port availability - 3128
    local ports_info='Proxy: '
    if nc -z -w 1 127.0.0.1 3128 &> /dev/null; then
        ports_info="$ports_info ${FG_GREEN}✓${RESET} 3128"
    else
        ports_info="$ports_info ${FG_RED}✗${RESET} 3128"
    fi

    # Port availability - 1080
    if nc -z -w 1 127.0.0.1 1080 &> /dev/null; then
        ports_info="$ports_info ${FG_GREEN}✓${RESET} 1080"
    else
        ports_info="$ports_info ${FG_RED}✗${RESET} 1080"
    fi

    # Get the username and hostname
    local user_info="${FG_GREEN}$(whoami)${RESET}${FG_YELLOW}@${RESET}${FG_GREEN}$(hostname)${RESET}"


    local len1=$(vlength "$user_info")
    local len2=$(vlength "$ports_info")
    if [ $len1 -gt $len2 ]; then
        ports_info=$(printf "%*s" $((len1 - len2)) '' | tr ' ' ' ')${ports_info}
    else
        user_info=$(printf "%*s" $((len2 - len1)) '' | tr ' ' ' ')${user_info}
    fi

    right_part+=("$user_info")
    right_part2+=("$ports_info ")


    # # SOCKS proxy availability (port 1080)
    # local proxy_resp_status=$(curl -x http://127.0.0.1:1080 -s -o /dev/null -w "%{http_code}" http://www.google.com)
    # if [[ "$result" == "200" ]]; then
    #     right_part+=("SOCKS: ${FG_GREEN}✓${RESET}")
    # else
    #     right_part+=("SOCKS: ${FG_RED}✗${RESET}")
    # fi

    # # HTTP proxy availability (port 3128)
    # local proxy_resp_status=$(curl -x http://127.0.0.1:3128 -s -o /dev/null -w "%{http_code}" http://www.google.com)
    # if [[ "$result" == "200" ]]; then
    #     right_part+=("HTTP: ${FG_GREEN}✓${RESET}")
    # else
    #     right_part+=("HTTP: ${FG_RED}✗${RESET}")
    # fi


    # Get the username and hostname
    # right_part+=("${BG_BLUE}$(whoami)${FG_GREEN}@${RESET}${BG_BLUE}$(hostname)${RESET}")
    # right_part+=("$(whoami)${FG_GREEN}@${RESET}$(hostname)")
    # right_part+=("$(whoami)${FG_GREEN}🌀${RESET}$(hostname)")
    
    

    # ----------------------------------------------------------------
    # Concatenate the left parts with ' | ' separator

    local SEPARATOR=" ${FG_CYAN}│${RESET} "

    left_part="$(concat "${SEPARATOR}" "${left_part[@]}")"
    right_part="$(concat "${SEPARATOR}" "${right_part[@]}")"
    left_part2="$(concat "${SEPARATOR}" "${left_part2[@]}")"
    right_part2="$(concat "${SEPARATOR}" "${right_part2[@]}")"

    # ----------------------------------------------------------------
    # Calculate the number of spaces needed for right alignment

    local spaces_length=$(($(tput cols) - $(vlength "$left_part") - $(vlength "$right_part") - 3))
    local spaces_length2=$(($(tput cols) - $(vlength "$left_part2") - $(vlength "$right_part2") - 3))

    # ----------------------------------------------------------------
    # Print the header

    # ⌘ ⏎ ⏏ ⎋ ⌫ ⌦ ⌧ ⌤ ⌥ ⌃ ⌽ ⌾ ⌿ ⍀ ⍁ ⍂ ⍃ ⍄ ⍅ ⍆ ⍇ ⍈ ⍉ ⍊ ⍋ ⍌ ⍍ ⍎ ⍏ ⍐ ⍑ ⍒ ⍓ ⍔ ⍕ ⍖ ⍗ ⍘ ⍙ ⍚ ⍛ ⍜ ⍝ ⍞ ⍟ ⍠ ⍡ ⍢ ⍣ ⍤ 
    # ⍥ ⍦ ⍧ ⍨ ⍩ ⍪ ⍫ ⍬ ⍭ ⍮ ⍯ ⍰ ⍱ ⍲ ⍳ ⍴ ⍵ ⍶ ⍷ ⍸ ⍹ ⍺ ⍻ ⍼ ⍽ ⍾ ⍿ ⎀ ⎁ ⎂ ⎃ ⎄ ⎅ ⎆ ⎇ ⎈ ⎉ ⎊ ⎋ ⎌ ⎍ ⎎ ⎏ ⎐ ⎑ ⎒ 
    # ⎔ ⎕ ⎖ ⎗ ⎘ ⎙ ⎚ ⏀ ⏁ ⏂ ⏃ ⏄ ⏅ ⏆ ⏇ ⏈  ⏍ ⏥ ⏦ ⏧ ⏨ 
    # ⏩ ⏪ ⏫ ⏬ ⏭ ⏮ ⏯ ⏰ ⏱ ⏲ ⏳ ⏴ ⏵ ⏶ ⏷ ⏸ ⏹ ⏺ ⏻ ⏼ ⏽ ⏾ ⏿
    # ▲ △ ▴ ▵ ▶ ▷ ▸ ▹ ► ▻ ▼ ▽ ▾ ▿ ◀ ◁ ◂ ◃ ◄ ◅ ◆ ◇ ◈ ◉ ◊ ○ ◌ ◍ ◎ ● ◐ ◑ ◒ ◓ ◔ ◕ ◖ ◗ ⏢ ⏣ ◘ ◙ ◚ ◛  
    # ◢ ◣ ◤ ◥ ◦ ◧ ◨ ◩ ◪ ◫ ◬ ◭ ◮ ◯ ◰ ◱ ◲ ◳ ◴ ◵ ◶ ◷ ◸ ◹ ◺ ◻ ◼ ◽ ◾ ◿ ☀ ☁ ☂ ☃ ☄ ★ ☆ ☇ ☈ ☉ ☊ ☋ ☌ ☍ ☎ ☏
    # ⏉ ⏊ ⏋ ⏌ ⏐ ⏑ ⏒ ⏓ ⏔ ⏕ ⏖ ⏗ ⏘ ⏙ ⏚ ⏛ ⏜ ⏝ ⏞ ⏟ ⏠ ⏡ ◜ ◝ ◞ ◟ ◠ ◡ ⏤
    # ⎛ ⎜ ⎝ ⎞ ⎟ ⎠ ⎡ ⎢ ⎣ ⎤ ⎥ ⎦ ⎧ ⎨ ⎩ ⎪ ⎫ ⎬ ⎭ ⎮ ⎯ ⎰ ⎱ ⎲ ⎳ ⎴ ⎵ ⎶ ⎷ ⎸ ⎹ ⎺ ⎻ ⎼ ⎽ ⎾ ⎿ 
    # ⎓ ═ ║ ╒ ╓ ╔ ╕ ╖ ╗ ╘ ╙ ╚ ╛ ╜ ╝ ╞ ╟ ╠ ╡ ╢ ╣ ╤ ╥ ╦ ╧ ╨ ╩ ╪ ╫ ╬ ╭ ╮ ╯ ╰ ╱ ╲ ╳ ╴ ╵ ╶ ╷ ╸ ╹ ╺ ╻ ╼ ╽ ╾ ╿ ▀ 
    # ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▉ ▊ ▋ ▌ ▍ ▎ ▏ ▐ ░ ▒ ▓ ▔ ▕ ▖ ▗ ▘ ▙ ▚ ▛ ▜ ▝ ▞ ▟ ■ □ ▢ ▣ ▤ ▥ ▦ ▧ ▨ ▩ ▪ ▫ ▬ ▭ ▮ ▯ ▰ ▱ 
    # ─ ━ ┃ │ ┆ ┇ ┈ ┉ ┊ ┋ ┌ ┍ ┎ ┏ ┐ ┑ ┒ ┓ └ ┕ ┖ ┗ ┘ ┙ ┚ ┛ ├ ┝ ┞ ┟ ┠ ┡ ┢ ┣ ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫ 
    # ┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳ ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻ ┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋ ╌ ╍ ╎ ╏ ═ ║ ╒ ╓ ╔ ╕ ╖ ╗ 

    # Best
    # ⎯ ═ ━ ■ ⏛ ⏤ ⎼ ╍ ╌ ┉ ┈ ╺ ▬ ─

    print_separator "${FG_CYAN}═${RESET}"
    echo -e " ${left_part}$(printf '%*s' "$spaces_length" '')${right_part}"
    echo -e " ${left_part2}$(printf '%*s' "$spaces_length2" '')${right_part2}"
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
    print_separator "${FG_CYAN}─${RESET}"
    echo -n "${PS1@P}"
    echo "$LAST_CLI_COMMAND"
}
# Function to execute after each command
precmd() {
    local last_exit_code="$?"

    if [ -z "$LAST_CLI_COMMAND" ]; then
        clear_header
        # Clear cache
        INTERNET_AVAILIBLE=1
        EXTERNAL_IP=""
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
