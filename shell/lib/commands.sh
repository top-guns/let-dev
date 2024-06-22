#!/bin/bash

view_file() {
    local filename="$1"

    # Проверяем, установлена ли утилита bat
    if command -v bat &> /dev/null; then
        bat "$filename"
    else
        more "$filename"
    fi
}

edit_file() {
    local filename="$1"

    # Проверяем, установлен ли системный редактор по умолчанию
    if command -v "$EDITOR" &> /dev/null; then
        "$EDITOR" "$filename"
    else
        # Если редактор по умолчанию не установлен, используем vim
        vim "$filename"
    fi
}

clear_history() {
    COMMAND_HISTORY=()
    COMMAND_HISTORY_INDEX=-1
    > "$HISTORY_FILE"
}

delete_last_block() {
    # Check if the marker is in the file
    # if ! grep -q "$BLOCK_SEPARATOR_FILE" "$HISTORY_FILE"; then
    #     echo "Marker not found in file. Use :clear if you want to clear all history."
    #     wait_for_press
    #     return
    # fi

    # Check if the marker is in the file
    if ! grep -q "$BLOCK_SEPARATOR_FILE" "$HISTORY_FILE"; then
        clear_history
        return
    fi

    # Create a temporary file in the standard temporary directory
    local temp_file=$(mktemp)

    # Check if the temporary file was created
    if [[ ! -e "$temp_file" ]]; then
        echo "Could not create temporary file."
        wait_for_press
        return
    fi

    # Remove the last element from the history array
    # local new_last_element=${COMMAND_HISTORY[-2]}
    local array_length=${#COMMAND_HISTORY[@]}
    local second_last_index=$((array_length - 2))
    local new_last_element=${COMMAND_HISTORY[$second_last_index]}
    COMMAND_HISTORY=("${COMMAND_HISTORY[@]:0:$second_last_index}")
    [ $COMMAND_HISTORY_INDEX -gt $new_last_element ] && COMMAND_HISTORY_INDEX=$new_last_element

    # Reverse the file, remove the last block, and reverse it back
    tac "$HISTORY_FILE" | sed -n "/$BLOCK_SEPARATOR_FILE/,\$p" | sed "1d" | tac > "$temp_file"

    # Replace the original file with the modified one
    mv "$temp_file" "$HISTORY_FILE"
}

autocomplete_file_name() {
    local current_word=$1
    local files_in_current_directory=$(ls -1) # Get the list of files in the current directory.
    local matches=()

    # Iterate over the files in the current directory to find matches.
    for file in $files_in_current_directory; do
        if [[ $file == *$current_word* ]]; then
            matches+=("$file")
        fi
    done

    # Check the number of matches
    if [ ${#matches[@]} -eq 1 ]; then
        # If there is only one match, use it for autocompletion.
        COMPREPLY=(${matches[0]})
    elif [ ${#matches[@]} -gt 1 ]; then
        # If there are multiple matches, show a menu for the user to select from.
        display_menu "${matches[@]}"
    fi
}

exec_internal() {
    eval "$@"
}


execute_command() {
    if [ "$COMMAND" == "" ]; then 
        # put_fill_to_history
        return
    fi

    COMMAND_HISTORY+=("$COMMAND")
    COMMAND_HISTORY_INDEX=${#COMMAND_HISTORY[@]}

    # Split command and arguments
    # read -r command_name -a COMMAND_ARGS <<< "$COMMAND"
    # Split command and arguments
    # command_name=$(echo "$COMMAND" | awk '{print $1}')
    # arguments=$(echo "$COMMAND" | cut -d' ' -f2-)

    IFS=' ' read -r -a COMMAND_ARGS <<< "$COMMAND"
    command_name=${COMMAND_ARGS[0]}
    unset COMMAND_ARGS[0]
    COMMAND_ARGS=("${COMMAND_ARGS[@]:1}")

    # COMMAND_ARGS=($(echo "$COMMAND" | xargs -n1))
    # command_name=${COMMAND_ARGS[0]}
    # unset COMMAND_ARGS[0]
    # COMMAND_ARGS=("${COMMAND_ARGS[@]:1}")
    # display_and_wait "command_name: $command_name"
    # display_and_wait "arguments: ${COMMAND_ARGS[0]}"

    # Replace all arguments equal to '?' with the user input
    local interactive_args=false
    for index in "${!COMMAND_ARGS[@]}"; do
        if [ "${COMMAND_ARGS[$index]}" == "?" ]; then
            # read -p "Enter value for argument $((index+1)): " value
            if [ $interactive_args == false ]; then
                echo -e "Enter argument values for the command ${COLOR_COMMAND}$command_name${COLOR_RESET}"
                interactive_args=true
            fi
            # text_input "argument $((index+1)): " value
            echo -en "  ${COLOR_COMMAND}? argument $((index+1))${COLOR_RESET}: "
            read value
            COMMAND_ARGS[$index]="'$value'"
        elif [[ "${COMMAND_ARGS[$index]}" == *"=?"* ]]; then
            param_name="${COMMAND_ARGS[$index]%%=?}"
            if [ $interactive_args == false ]; then
                echo "Enter argument values for the command $command_name"
                interactive_args=true
            fi
            # text_input "$param_name: " value
            echo -en "  ${COLOR_COMMAND}? $param_name${COLOR_RESET}: "
            read value
            COMMAND_ARGS[$index]="${param_name}='$value'"
        fi
    done
    arguments="${COMMAND_ARGS[*]}"  # convert array back to string

    case "$command_name" in
        "${TERM_SYMBOL}exit")
            exit 0
            ;;
        "${TERM_SYMBOL}clear" | "$DELETE_SYMBOL$DELETE_SYMBOL")
            clear_history
            ;;
        "${TERM_SYMBOL}help" | "$HELP_SYMBOL")
            put_help_to_history
            ;;
        "${TERM_SYMBOL}comment" | "$COMMENT_SYMBOL")
            if [ -z "$arguments" ]; then
                display_and_wait "Usage: $command_name [comment_text]"
            else
                put_comment_to_history "$arguments"
            fi
            return
            ;;
        "${TERM_SYMBOL}delete" | "$DELETE_SYMBOL")
            # Delete the last block from the history file
            delete_last_block
            ;;
        "${TERM_SYMBOL}line-numbers")
            switch_line_numbers
            ;;
        "${TERM_SYMBOL}view")
            # Check if filename is provided
            if [ -z "$arguments" ]; then
                display_and_wait "Usage: :view [filename]"
            else
                # Extract filename from the arguments
                filename="$arguments"
                # Check if file exists
                if [ -f "$filename" ]; then
                    # View file using bat with syntax highlighting
                    view_file "$filename"
                else
                    display_and_wait "File not found: $filename"
                fi
            fi
            return
            ;;
        "${TERM_SYMBOL}edit")
            # Check if filename is provided
            if [ -z "$arguments" ]; then
                display_and_wait "Usage: :edit [filename]"
            else
                # Extract filename from the arguments
                filename="$arguments"
                # Check if file exists
                if [ -f "$filename" ]; then
                    edit_file "$filename"
                else
                    display_and_wait "File not found: $filename"
                fi
            fi
            return
            ;;
        "${TERM_SYMBOL}pin")
            local to_pin="$arguments"
            if [ -z "$to_pin" ]; then
                # Add the last command to the list of attached commands
                if [ ${#COMMAND_HISTORY[@]} -lt 2 ]; then
                    display_and_wait "No command to attach"
                    return
                fi
                to_pin=$(get_history_command -2)
            fi
            PINNED_COMMANDS+=("$to_pin")
            return
            ;;
        "${TERM_SYMBOL}test")
            test
            return
            ;;
        # [${FILE_SYMBOL}<file_name>] - Prints the contents of the file to the history
        "$FILE_SYMBOL")
            # Extract filename from the arguments
            filename="${command_name:1}"
            if [[ -z "$filename" ]]; then
                filename="$arguments"
            else
                filename="${command_name:1} $arguments"
            fi

            put_file_to_history "$filename"
            return
            ;;
        "$VAR_SYMBOL"*)
            if [ "$command_name" = "$VAR_SYMBOL$VAR_SYMBOL" ]; then
                # If the command is $$, print all environment variables
                put_to_history "$command_name" "$(env)"
            else
                if [ -z "$arguments" ]; then
                    # If no arguments are provided, print the value of the specific environment variable
                    put_to_history "$command_name" "$(eval echo $command_name)"
                else
                    # Otherwise, update the value of the specific environment variable and print the old and new values
                    local var_name="${command_name:1}"
                    local old_value=$(eval echo $command_name)
                    eval "$var_name='$arguments'"
                    put_to_history "$command_name" "Old value: '$old_value'" "New value: '$arguments'"
                fi
            fi
            return
            ;;
        "${TERM_SYMBOL}"*)
            if [ -z "$arguments" ]; then
                # echo -en "  \033[0;32m~\033[0m "
                # read arguments
                if [ "$SHELL_MODE" == true ]; then
                    SHELL_MODE=false
                else
                    SHELL_MODE=true
                fi
                return
            fi
            eval "$arguments"
            wait_for_press
            return
            ;;
        *)
            # For other commands, execute them as-is
            # OUTPUT=$(eval "$command_name $arguments" 2>&1)
            # eval "$command_name $arguments" 2>&1 | tee OUTPUT
            # eval "$command_name $arguments"
            # wait_for_press

            # source <(echo "$command")
            # ls | sed ... | source /dev/stdin

            if [ "$SHELL_MODE" = true ]; then
                eval "$command_name $arguments || true"
                if [ ! $? -eq 0 ]
                then
                    echo "Command execution failed"
                fi
            else
                # cmd=$(echo "$COMMAND_EXECUTOR" | sed "s/%s/$command_name $arguments/")
                # display_and_wait "$cmd"
                # source <(echo -e "$cmd")

                cmd=$(echo "$command_name $arguments")
                echo "$BLOCK_SEPARATOR_FILE" >> "$HISTORY_FILE"
                echo "$TERM_SYMBOL $cmd" >> $HISTORY_FILE
                exec_internal "$cmd"  >> $HISTORY_FILE 2>> $HISTORY_FILE || echo 'Command execution failed' >> $HISTORY_FILE
            fi
            ;;
    esac
}

test() {
    #     # Save current screen state
    #     local previous_screen="$(tput smcup)"
    #     # Show popup dialog
    #     # Restore previous screen state
    #     echo -e "${previous_screen}"

    # choice=$(display_popup_dialog)
    # echo ":test result: $choice"
    # wait_for_press
    # put_to_history "$TERM_SYMBOL :test" "$choice"

    text_input "What's your first name" name

    hawker_centres=( 'Old Airport Road Hawker Centre' 'Golden Mile Food Complex' 'Maxwell Food Centre' 'Newton Food Centre' )
    checkbox_input "Which hawker centres do you prefer?" hawker_centres selected_hawkers

    drinks=( 'Teh' 'Teh Ping Gao Siu Dai' 'Kopi O' 'Yuan Yang' )
    list_input "What would you like to drink today?" drinks selected_drink

    food=( 'Chicken Rice' 'Lor Mee' 'Nasi Lemak' 'Bak Kut Teh' )
    list_input "What would you like to eat today?" food selected_food

    display_and_wait "Test ok"
}
