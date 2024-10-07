#!/bin/bash

# Load aliases to make them available in the current shell
shopt -s expand_aliases
# source $HOME/.bashrc
# Load letdev commands
source $LETDEV_HOME/create-aliases

source $LETDEV_HOME/shell/lib/settings.sh
source $LETDEV_HOME/shell/lib/utils.sh
source $LETDEV_HOME/shell/lib/commands.sh
source $LETDEV_HOME/shell/lib/history.sh
source $LETDEV_HOME/shell/lib/display.sh

SHELL_MODE=false
PINNED_COMMANDS=()
# Current command
COMMAND=""
COMMAND_ARGS=()

# Array to store command history
COMMAND_HISTORY=()
COMMAND_HISTORY_INDEX=-1

# Check for --clear-history option
for arg in "$@"
do
    if [ "$arg" == "--clear-history" ]; then
        > "$HISTORY_FILE"
    elif [ "$arg" == "clear-history" ]; then
        > "$HISTORY_FILE"
        echo "Command history cleared"
        exit 0
    elif [ "$arg" == "--help" ]; then
        echo "Usage: $0 [--clear-history] [--help]"
        echo "  --clear-history: Clear the command history"
        echo "  --help: Print this help message"
        exit 0
    else 
        echo "Unknown option: $arg"
        exit 1
    fi
done

# Check for the existence of the history file
if [ ! -f "$HISTORY_FILE" ]; then
    touch "$HISTORY_FILE"
fi


# Function to handle the window size change signal
handle_winch() {
    # Ignore the signal while we are handling it
    trap "" SIGWINCH
    redraw_screen
    # Reinstall the signal handler
    trap handle_winch SIGWINCH
}

input=()

# Function to read multiline user input (read while the user doesn't press Ctrl+D)
read_command() {
    input=()
    input_line_no=0

    # Initial cursor position
    # Get the total number of lines
    total_lines=$(tput lines)
    # Subtract 1 because line numbers start at 0
    row=$((total_lines - 1))
    # Initial column position
    col=0

    # Move cursor to initial position
    tput cup $row $col

    # Disable echo
    stty -echo

    # Read one character at a time
    while IFS= read -r -n1 key; do
        # Check for arrow keys
        case $key in
            $'\e') # If key is escape sequence
                read -r -n2 key # read two more chars
                case $key in
                    '[A') # Up arrow
                        ((row--))
                        ;;
                    '[B') # Down arrow
                        ((row++))
                        ;;
                    '[C') # Right arrow
                        ((col++))
                        ;;
                    '[D') # Left arrow
                        ((col--))
                        ;;
                esac
                ;;
            *)
                # Add the key to the current line
                input[$row]="${input[$row]:0:$col}$key${input[$row]:$col}"
                echo input
                read
                ((col++))
                ;;
        esac

        # Display the current state of the command input
        display_input_text

        # Move cursor to new position
        tput cup $row $col
    done

    # Enable echo
    stty echo
}

display_input_text() {
    # Calculate the start row to display the input text at the bottom
    start_row=$(( $(tput lines) - ${#input[@]} ))

    # Clear the lines from start_row to the bottom
    for (( i=$start_row; i<$(tput lines); i++ )); do
        tput cup $i 0
        tput el
    done

    # Print the input text
    for (( i=0; i<${#input[@]}; i++ )); do
        tput cup $(( $start_row + $i )) 0
        echo "${input[$i]}"
    done
}

display_command_input() {
    tput cup $(( $(tput lines) - 1 )) 0
    read_command
}

# Function to wait for the next command
wait_for_command() {
    display_command_input
    execute_command
}


# Handle the window size change signal
trap handle_winch SIGWINCH

# Main loop
while true; do
    [ "$SHELL_MODE" = false ] && redraw_screen
    wait_for_command
done