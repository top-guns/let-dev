#!/bin/bash

get_history_command() {
    local history_count=${#COMMAND_HISTORY[@]}
    [ $history_count -eq 0 ] && return

    local index="$1"
    [ -z "$index" ] && index=-1
    
    [ "$index" -lt 0 ] && index=$((history_count + index))
    [ "$index" -lt 0 ] && return
    [ $index -lt $history_count ] && echo "${COMMAND_HISTORY[$index]}"
}

# Function to read a command with history navigation support
read_command_with_history() {
    local input=""
    local char=""
    local cursor_pos=0
    local ext_sym="$INPUT_INPUT"
    if [ "$SHELL_MODE" = true ]; then
        ext_sym="$(pwd): "
    fi
    local prompt="${COLOR_COMMAND}$ext_sym${COLOR_RESET}"

    # Use the shell's read function if in shell mode
    if [ "$SHELL_MODE" = true ]; then
        # use -n or -e to enable auto-completion
        prompt=$(echo -ne "$prompt")
        read -e -p "$prompt" COMMAND
        # tput el  # Clear to the end of the line
        return
    fi

    while true; do
        # Display the prompt and clear the current line
        echo -ne "\r$prompt"
        if [ $cursor_pos -eq ${#input} ]; then
            echo -ne "$input"
        else
            echo -ne "${input:0:cursor_pos}${COLOR_INPUT}${input:cursor_pos:1}${COLOR_RESET}{input:cursor_pos+1}"
        fi
        tput el  # Clear to the end of the line

        IFS= read -rsn1 char

        # Handle key presses
        case "$char" in
            # Handle arrow key presses
            $'\e')
                read -rsn2 char
                case "$char" in
                    '[A') # Up arrow
                        if [ ${#COMMAND_HISTORY[@]} -gt 0 ] && [ $COMMAND_HISTORY_INDEX -gt 0 ]; then
                            COMMAND_HISTORY_INDEX=$((COMMAND_HISTORY_INDEX - 1))
                            input="${COMMAND_HISTORY[$COMMAND_HISTORY_INDEX]}"
                            cursor_pos=${#input}
                        elif [ $COMMAND_HISTORY_INDEX -eq 0 ]; then
                            input="${COMMAND_HISTORY[0]}"
                            cursor_pos=${#input}
                        fi
                        ;;
                    '[B') # Down arrow
                        if [ $COMMAND_HISTORY_INDEX -lt $(( ${#COMMAND_HISTORY[@]} - 1 )) ]; then
                            COMMAND_HISTORY_INDEX=$((COMMAND_HISTORY_INDEX + 1))
                            input="${COMMAND_HISTORY[$COMMAND_HISTORY_INDEX]}"
                            cursor_pos=${#input}
                        elif [ $COMMAND_HISTORY_INDEX -eq $(( ${#COMMAND_HISTORY[@]} - 1 )) ]; then
                            input=""
                            cursor_pos=0
                        fi
                        ;;
                    '[C') # Right arrow
                        if [ $cursor_pos -lt ${#input} ]; then
                            cursor_pos=$((cursor_pos + 1))
                        fi
                        ;;
                    '[D') # Left arrow
                        if [ $cursor_pos -gt 0 ]; then
                            cursor_pos=$((cursor_pos - 1))
                        fi
                        ;;
                esac
                ;;
            # Handle Enter key press
            '')
                echo
                COMMAND="$input"
                return
                ;;
            # Handle Backspace key press
            $'\177')
                if [ $cursor_pos -gt 0 ]; then
                    input="${input:0:cursor_pos-1}${input:cursor_pos}"
                    cursor_pos=$((cursor_pos - 1))
                fi
                ;;
            # Handle all other characters
            *)
                input="${input:0:cursor_pos}$char${input:cursor_pos}"
                cursor_pos=$((cursor_pos + 1))
                ;;
        esac
    done
}

put_help_to_history() {
    if [ -s "$HISTORY_FILE" ]; then
        echo "$BLOCK_SEPARATOR_FILE" >> "$HISTORY_FILE"
    fi
    echo "let.dev shell commands" >> "$HISTORY_FILE"
    echo "  ${HELP_SYMBOL} Display this help message" >> "$HISTORY_FILE"
    echo "  ${FILE_SYMBOL} [filename] - Print the contents of a file to the history" >> "$HISTORY_FILE"
    echo "  ${VAR_SYMBOL} [variable_name] Print the value of an environment variable" >> "$HISTORY_FILE"
    echo "  ${VAR_SYMBOL} [variable_name] [value] - Set the value of an environment variable" >> "$HISTORY_FILE"
    echo "  ${VAR_SYMBOL}${VAR_SYMBOL} Print all environment variables" >> "$HISTORY_FILE"
    echo "  ${COMMENT_SYMBOL} [comment_text] - Add a comment to the history" >> "$HISTORY_FILE"
    echo "  ${DELETE_SYMBOL} Delete the last block from the history" >> "$HISTORY_FILE"
    echo "  ${DELETE_SYMBOL}${DELETE_SYMBOL} Clear the command history" >> "$HISTORY_FILE"
    echo "  ${TERM_SYMBOL} Switch to/from shell mode" >> "$HISTORY_FILE"
    echo "  ${TERM_SYMBOL}view [filename] - View the contents of a file" >> "$HISTORY_FILE"
    echo "  ${TERM_SYMBOL}edit [filename] - Edit a file" >> "$HISTORY_FILE"
    echo "  ${TERM_SYMBOL}line-numbers - Toggle line numbers" >> "$HISTORY_FILE"
    echo "  ${TERM_SYMBOL}exit - Exit the shell" >> "$HISTORY_FILE"
}

put_fill_to_history() {
    # Get the last line of the history file
    LAST_LINE=$(tail -n 1 "$HISTORY_FILE")

    # Check if the last line is not a separator
    if [ "$BLOCK_TYPE" != "fill" ]; then
        echo "$BLOCK_SEPARATOR_FILE" >> "$HISTORY_FILE"
    fi

    echo "$FILL_SYMBOL_FILE" >> "$HISTORY_FILE"
}

put_separator_to_history() {
    # Get the last line of the history file
    LAST_LINE=$(tail -n 1 "$HISTORY_FILE")

    # Check if the last line is not a separator
    if [ "$LAST_LINE" != "" ] && [ "$LAST_LINE" != "$BLOCK_SEPARATOR_FILE" ]; then
        # If it's not, append a separator
        echo "$BLOCK_SEPARATOR_FILE" >> "$HISTORY_FILE"
    fi
}

put_to_history() {
    put_separator_to_history

    for text in "$@"; do
        echo "$text" >> "$HISTORY_FILE"
    done
}

put_comment_to_history() {
    # Get the last line of the history file
    LAST_LINE=$(tail -n 1 "$HISTORY_FILE")

    # Check if the last line is not a separator
    if [ "$LAST_LINE" != "" ] && [ "$LAST_LINE" != "$BLOCK_SEPARATOR_FILE" ] && [ "$LAST_LINE" != "$FILL_SYMBOL_FILE" ]; then
        # If it's not, append a separator
        echo "$BLOCK_SEPARATOR_FILE" >> "$HISTORY_FILE"
    fi

    # Check if the last line is not a separator
    if [ "$BLOCK_TYPE" != "fill" ]; then
        echo "$FILL_SYMBOL_FILE" >> "$HISTORY_FILE"
    fi   
    
    echo "$@" >> "$HISTORY_FILE"
    echo "$FILL_SYMBOL_FILE" >> "$HISTORY_FILE"

    # echo "$@"
    # wait_for_press
}

put_file_to_history() {
    local filename=$1

    put_separator_to_history

    # Check if file exists
    if [ -f "$filename" ]; then
        put_to_history "$FILE_SYMBOL $filename" "$(cat "$filename")"
    else
        # display_and_wait "File not found: $filename"
        put_to_history "$FILE_SYMBOL $filename" "File not found"
    fi
}
