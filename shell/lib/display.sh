#!/bin/bash

# fzf
if [[ -e "/usr/local/opt/fzf/shell/completion.bash" ]]; then
  source "/usr/local/opt/fzf/shell/completion.bash"
fi
if [[ -e "/usr/local/opt/fzf/shell/key-bindings.bash" ]]; then
  source "/usr/local/opt/fzf/shell/key-bindings.bash"
fi

# # Получите список всех доступных команд
# commands=$(compgen -c | sort -u)

# # Вызовите fzf и сохраните результат в переменной
# selected_command=$(echo "$commands" | fzf)

# # Теперь вы можете использовать $selected_command...
# echo "Вы выбрали: $selected_command"



# source simple_curses.sh
source "$LETDEV_PATH/shell/ext/inquirer/inquirer.sh"

BORDER_SYMBOL_DOTTED='·'
BORDER_SYMBOL_DASHED='-'
BORDER_SYMBOL_THIN='─'
BORDER_SYMBOL_THICK='━'
BORDER_SYMBOL_DOUBLE='═'

###############################

COLOR_RESET='\033[0m'
COLOR_BLACK='\033[0;30m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'

FONT_BOLD='\033[1m'
FONT_UNDERLINE='\033[4m'

###############################

TPUT_COLOR_RESET=$(tput sgr0)

# Colors
TPUT_COLOR_BLACK=$(tput setaf 0)
TPUT_COLOR_RED=$(tput setaf 1)
TPUT_COLOR_GREEN=$(tput setaf 2)
TPUT_COLOR_YELLOW=$(tput setaf 3)
TPUT_COLOR_BLUE=$(tput setaf 4)
TPUT_COLOR_MAGENTA=$(tput setaf 5)
TPUT_COLOR_CYAN=$(tput setaf 6)
TPUT_COLOR_WHITE=$(tput setaf 7)

# Text properties
TPUT_TEXT_RESET=$(tput sgr0)
TPUT_TEXT_BOLD=$(tput bold)
TPUT_TEXT_UNDERLINE=$(tput smul)
TPUT_TEXT_NO_UNDERLINE=$(tput rmul)
TPUT_TEXT_BLINK=$(tput blink)
TPUT_TEXT_REVERSE=$(tput rev)
TPUT_TEXT_INVISIBLE=$(tput invis)

# Cursor movement
TPUT_CURSOR_UP=$(tput cuu1)
TPUT_CURSOR_DOWN=$(tput cud1)
TPUT_CURSOR_FORWARD=$(tput cuf1)
TPUT_CURSOR_BACKWARD=$(tput cub1)
TPUT_CURSOR_MOVE_HOME=$(tput hpa 0)
TPUT_CURSOR_SAVE=$(tput sc)
TPUT_CURSOR_RESTORE=$(tput rc)

###############################

COLOR_BORDER="$COLOR_BLUE"
COLOR_COMMAND="$COLOR_GREEN"
COLOR_VAR="$COLOR_YELLOW"
COLOR_FILL="$COLOR_CYAN"
COLOR_COMMENT="$COLOR_CYAN"
COLOR_HOT_KEY="$COLOR_RED"
# COLOR_TERM='\033[0;31m'
# COLOR_ERROR='\033[0;31m'
# COLOR_SUCCESS='\033[0;32m'
# COLOR_WARNING='\033[0;33m'
# COLOR_INFO='\033[0;36m'
# COLOR_QUESTION='\033[0;34m'
# COLOR_ANSWER='\033[0;32m'
# COLOR_PROMPT='\033[0;31m'
COLOR_INPUT='\033[7m'

# BLOCK_SEPARATOR_DISPLAY="$(printf '─%.0s' {1..100})"
# BLOCK_SEPARATOR_DISPLAY='━'
BLOCK_SEPARATOR_DISPLAY="$BORDER_SYMBOL_DASHED"

# HEADER_BORDER_OUTER='┌'
HEADER_BORDER_OUTER="$BORDER_SYMBOL_DOUBLE"
HEADER_BORDER_INNER="$BORDER_SYMBOL_THIN"

FILL_SYMBOL_DISPLAY='█'

# INPUT_INPUT="$TERM_SYMBOL   "
INPUT_INPUT="$TERM_SYMBOL  "


# Global variables
BLOCK_TYPE="" # command, fill, other
LINE_NUMBERS_ENABLED=false


switch_line_numbers() {
    if [ "$LINE_NUMBERS_ENABLED" == true ]; then
        LINE_NUMBERS_ENABLED=false
    else
        LINE_NUMBERS_ENABLED=true
    fi
}

display_and_wait() {
    echo "$@"
    wait_for_press
}

# Function to display a separator that adjusts to the screen width
display_separator() {
    local char="${1:- }"
    local text="$2"
    local width=$(tput cols)
    local text_length=${#text}
    if [ -n "$text" ]; then
        text_length=$((text_length + 8)) # Add padding
    fi
    local padding=$((($width - $text_length) / 2))

    local left_padding=""
    local right_padding=""

    for (( i=1; i<=$padding; i++ )); do
        left_padding+="$char"
    done

    # If the width is an odd number, add one more char to the right padding
    if (( width % 2 != text_length % 2 )); then
        right_padding="$left_padding$char"
    else
        right_padding="$left_padding"
    fi

    echo -n "$left_padding"
    if [ -n "$text" ]; then
        echo -n "    $text    "
    fi
    echo "$right_padding"
}

display_history_command() {
    local index="$1"
    local label="$2"
    local max_length="$3"

    local command_text=$(get_history_command $index)
    if [ -n "$command_text" ]; then
        command_text=$(cut_str "$command_text" $max_length)
        command_text=$(printf "%-${max_length}s" "$command_text")
        echo -en "$COLOR_HOT_KEY$label$COLOR_RESET: $COLOR_COMMAND$command_text$COLOR_RESET"
    fi
}

display_footer() {
    # Move the cursor back to the bottom of the screen
    tput cup $(( $(tput lines) - 5 )) 0
    local history_count=${#COMMAND_HISTORY[@]}

    # Border
    echo -e "$COLOR_BORDER$(display_separator $HEADER_BORDER_OUTER)$COLOR_RESET"

    # Display attached commands
    if [ ${#PINNED_COMMANDS[@]} -gt 0 ]; then
        for index in "${!PINNED_COMMANDS[@]}"; do
            echo -en "$COLOR_HOT_KEY$((index+1))$COLOR_RESET: "
            echo -en "$COLOR_COMMAND${PINNED_COMMANDS[$index]}$COLOR_RESET"
            echo ""
        done
        # Border
        echo -e "$COLOR_BORDER$(display_separator $HEADER_BORDER_INNER)$COLOR_RESET"
    fi

    # User
    echo -en "${COLOR_VAR}user$COLOR_RESET: $USER@$HOSTNAME$COLOR_RESET"

    # If command history is not empty, display last command
    echo -en "\t"
    echo -en "   " && display_history_command -1 1 15
    echo -en "   " && display_history_command -2 2 15
    echo -en "   " && display_history_command -3 3 15
    echo -en "   " && display_history_command -4 4 15
    echo ""

    # Current directory
    echo -en "${COLOR_VAR}pwd$COLOR_RESET: $PWD"
    # Display the second last command if it exists
    echo ""

    # Border
    echo -e "${COLOR_BORDER}$(display_separator $HEADER_BORDER_OUTER)$COLOR_RESET"
}

display_command_input() {
    tput cup $(( $(tput lines) - 1 )) 0
    read_command_with_history
}

display_command_history() {
    #local history_lines=$(( $(tput lines) - 100 )) # Adjust the number of lines to display
    # local history_lines=$HISTORY_LINES

    # Initialize an empty string to hold the output
    local output=""
    local first_load=false
    if [ ${#COMMAND_HISTORY[@]} -eq 0 ]; then
        first_load=true
    fi

    # Check if the history file exists and is not empty
    if [ -s "$HISTORY_FILE" ]; then
        # # Replace the command separator with a display separator and add to the output string
        # output=$(cat "$HISTORY_FILE" | sed "s/$BLOCK_SEPARATOR_DISPLAY/$(display_separator '─')/g")
        # #output=$(tail -n "$history_lines" "$HISTORY_FILE" | sed "s/$BLOCK_SEPARATOR_DISPLAY/$(display_separator '─')/g")

        # Read the file line by line
        BLOCK_TYPE="" # command, fill, var, file, other
        line_no=-1
        while IFS= read -r line; do
            line_no=$((line_no + 1))

            # Start new usual block
            if [[ "$line" == "$BLOCK_SEPARATOR_FILE" ]]; then
                output+=$(display_separator "$BLOCK_SEPARATOR_DISPLAY")$'\n'
                line_no=-1
            # Start new fill block
            elif [[ "$line" == "$FILL_SYMBOL_FILE" && "$BLOCK_TYPE" != "fill" ]]; then
                BLOCK_TYPE="fill"
                output+=$(display_separator $FILL_SYMBOL_DISPLAY)$'\n'
                line_no=0
            # Continue block
            else
                # Check the first line to determine the block type
                if [[ $line_no == 0 ]]; then
                    if [[ "$line" == "$TERM_SYMBOL"* ]]; then
                        BLOCK_TYPE="command"
                        output+=${TPUT_COLOR_GREEN}$line${TPUT_COLOR_RESET}$'\n'
                        # If it is the first load, add the command to the history
                        if [ "$first_load" == true ]; then
                            # Get the command from the line by removing the TERM_SYMBOL
                            command="${line#$TERM_SYMBOL }"
                            COMMAND_HISTORY+=("$command")
                            COMMAND_HISTORY_INDEX=${#COMMAND_HISTORY[@]}
                        fi
                    elif [[ "$line" == "$VAR_SYMBOL"* ]]; then
                        BLOCK_TYPE="var"
                        output+=${TPUT_COLOR_YELLOW}$line${TPUT_COLOR_RESET}$'\n'
                        # If it is the first load, add the command to the history
                        if [ "$first_load" == true ]; then
                            # Get the command from the line
                            COMMAND_HISTORY+=("$line")
                            COMMAND_HISTORY_INDEX=${#COMMAND_HISTORY[@]}
                        fi
                    elif [[ "$line" == "$FILE_SYMBOL"* ]]; then
                        BLOCK_TYPE="file"
                        output+=${TPUT_COLOR_YELLOW}$line${TPUT_COLOR_RESET}$'\n'
                        # If it is the first load, add the command to the history
                        if [ "$first_load" == true ]; then
                            # Get the command from the line
                            COMMAND_HISTORY+=("$line")
                            COMMAND_HISTORY_INDEX=${#COMMAND_HISTORY[@]}
                        fi
                    elif [[ "$line" == "$FILL_SYMBOL_FILE "* ]]; then
                        BLOCK_TYPE="fill"
                        output+=$(display_separator $FILL_SYMBOL_DISPLAY)$'\n'
                    else
                        BLOCK_TYPE="other"
                        output+="$line"$'\n'
                    fi
                else
                    # Append the line based on the block type
                    if [[ "$BLOCK_TYPE" == "command" ]]; then
                        if [[ $LINE_NUMBERS_ENABLED == true ]]; then
                            # Format the line number with blue color and width of 3
                            # output+="$(tput setaf 4)$(printf '%3d' $line_no)$(tput sgr0)  "
                            # output+="$(printf '%3d' $line_no)  "

                            # Calculate the number of spaces needed for alignment
                            local line_no_str="$line_no"
                            local spaces=$((3 - ${#line_no_str}))
                            
                            # Add spaces for alignment
                            for (( i=0; i<$spaces; i++ )); do
                                output+=" "
                            done
                            
                            # Append line number and two spaces
                            output+="$line_no)  "
                        fi
                        output+="$line"$'\n'
                    elif [[ "$BLOCK_TYPE" == "fill" ]]; then
                        if [[ "$line" == "$FILL_SYMBOL_FILE" ]]; then
                            output+=$(display_separator $FILL_SYMBOL_DISPLAY)$'\n'
                        else
                            output+=$(display_separator $FILL_SYMBOL_DISPLAY "$line")$'\n'
                        fi
                    else
                        output+="$line"$'\n'
                    fi
                fi
            fi
        done < "$HISTORY_FILE"
    else
        output="Hello! Welcome to the let.dev shell. Start typing commands below."
    fi

    # Add empty lines for spacing
    output+="\n\n\n"

    clear
    echo -e "$output"
}

display_popup_dialog() {
    local options=("111" "222" "333")
    PS3="Choose: "
    select opt in "${options[@]}" "Cancel"; do
        case "$REPLY" in
            1) echo "$opt"; break;;
            2) echo "$opt"; break;;
            3) echo "$opt"; break;;
            $(( ${#options[@]}+1 )) ) echo "Cancel"; break;;
            *) echo "Wrong choise";;
        esac
    done
}

display_bottom_text() {
    # local text="$1"
    # local width=$(tput cols)
    # local text_width=${#text}
    # local padding=$(( (width - text_width) / 2 ))
    # local padding_text=""
    # for (( i=1; i<=$padding; i++ )); do
    #     padding_text+=" "
    # done
    # echo -e "$padding_text$text"

    for text in "$@"; do
        echo "$text"
    done
    wait_for_press
}

function display_menu() {
    local CHOICES=("$@")  # Получаем аргументы функции
    local SELECTED_INDEX=0

    # Основная функция, рисующая меню
    draw_menu() {
        window "Меню" "gray"
        for i in "${!CHOICES[@]}"; do
            if [ $i -eq $SELECTED_INDEX ]; then
                append_tabbed "$(tput setaf 3) > ${CHOICES[$i]} $(tput sgr0)"
            else
                append_tabbed "   ${CHOICES[$i]}"
            fi
        done
        endwin
    }

    # Основная петля для обработки ввода пользователя
    main_loop() {
        while true; do
            clear
            draw_menu
            read -rsn1 key
            case "$key" in
                $'\x1b') read -rsn2 -t 0.1 key
                          if [[ "$key" == "[A" ]]; then  # Вверх
                              ((SELECTED_INDEX--))
                              if [ $SELECTED_INDEX -lt 0 ]; then
                                  SELECTED_INDEX=$((${#CHOICES[@]} - 1))
                              fi
                          elif [[ "$key" == "[B" ]]; then  # Вниз
                              ((SELECTED_INDEX++))
                              if [ $SELECTED_INDEX -ge ${#CHOICES[@]} ]; then
                                  SELECTED_INDEX=0
                              fi
                          fi
                          ;;
                "") echo $SELECTED_INDEX
                    return
                    ;;
            esac
        done
    }

    # Запуск основного цикла
    main_loop
}

# Function to redraw the screen
redraw_screen() {
    # clear
    # tput cup 0 0
    # tput ed

    display_command_history
    display_footer
    # display_command_input
}
