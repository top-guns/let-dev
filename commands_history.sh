#!/bin/bash

HISTORY_FILE="$LETDEV_HOME/profiles/$LETDEV_PROFILE/.shell_history"
BLOCK_SEPARATOR='─────────────────────────────'
MAX_COMMAND_HISTORY=10



put_command_to_history() {
    [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
    
    local command="$1"
    shift
    local command_params="$@"

    # Remove spaces from the beginning and end of the command
    command=$(echo "$command" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    local command_name=$(echo "$command" | awk '{print $1}')
    
    _remove_first_history_command "$command"

    # If the command with the same name is already in the history, limit the number of commands
    history_count=$(_get_history_commands_count "^$command_name")
    [ "$history_count" -ge "$MAX_COMMAND_HISTORY" ] && _remove_first_history_command_by_name "$command_name"

    echo "$BLOCK_SEPARATOR" >> "$HISTORY_FILE"
    echo "$command" >> "$HISTORY_FILE"
    for text in "$@"; do
        echo "$text" >> "$HISTORY_FILE"
    done
}

# Get commands from history file by filter
get_history_commands() {
    local filter="$@"
    local commands=""

    [ ! -f "$HISTORY_FILE" ] && return 0

    # Command - is the first line of the separator
    # find all lines immediately following the separator
    commands=$(grep -A 1 "$BLOCK_SEPARATOR" "$HISTORY_FILE" | grep -v "$BLOCK_SEPARATOR" | grep -v -- "^--$" | grep -E "$filter" | tac)

    [ -n "$commands" ] && echo "$commands"
}

_get_history_commands_count() {
    local filter="$@"

    [ ! -f "$HISTORY_FILE" ] && echo '0' && return 0

    # Find count of lines immediately following the separator and containing the filter
    local count=$(grep -A 1 "$BLOCK_SEPARATOR" "$HISTORY_FILE" | grep -v "$BLOCK_SEPARATOR" | grep -v -- "^--$" | grep -E "$filter" | wc -l | tr -d ' ')
    echo "$count"
}

# Remove the first command from the history file, with the separator if necessary
_remove_first_history_command_by_name() {
    command_name="$1" # The name of the command to be removed

    output=""
    after_separator=0
    in_removing_block=0
    block_is_removed=0

    # Process the file block by block, separated by the separator
    while IFS= read -r line; do
        # If the block is already removed, just add the line to the output
        if [ "$block_is_removed" -eq 1 ]; then
            [ -n "$output" ] && output+="\n"
            output+="$line"
            continue
        fi

        # If we in the block that should be removed
        if [ "$in_removing_block" -eq 1 ]; then
            # If the line is the separator then the block is ended
            if [[ "$line" == "$BLOCK_SEPARATOR" ]]; then
                in_removing_block=0
                block_is_removed=1
                [ -n "$output" ] && output+="\n"
                output+="$BLOCK_SEPARATOR"
            fi
            continue
        fi

        [[ "$line" == "$BLOCK_SEPARATOR" ]] && after_separator=1 && continue

        if [[ "$after_separator" -eq 1 ]]; then
            after_separator=0
            # If the line starts with the command that should be removed, then we should remove the block
            if [ -z "$command_name" ] || [[ "$line" == "$command_name "* ]] || [[ "$line" == "$command_name" ]]; then
                in_removing_block=1
            else
                [ -n "$output" ] && output+="\n"
                output+="$BLOCK_SEPARATOR\n$line"
            fi
            continue
        fi

        [ -n "$output" ] && output+="\n"
        output+="$line"
    done < "$HISTORY_FILE"

    # Rewrite the file with the updated content
    echo "$output" > "$HISTORY_FILE"
}

# Remove the first command from the history file, with the separator if necessary
_remove_first_history_command() {
    command="$1" # The command to remove

    output=""
    after_separator=0
    in_removing_block=0
    block_is_removed=0

    # Process the file block by block, separated by the separator
    while IFS= read -r line; do
        # If the block is already removed, just add the line to the output
        if [ "$block_is_removed" -eq 1 ]; then
            [ -n "$output" ] && output+="\n"
            output+="$line"
            continue
        fi

        # If we in the block that should be removed
        if [ "$in_removing_block" -eq 1 ]; then
            # If the line is the separator then the block is ended
            if [[ "$line" == "$BLOCK_SEPARATOR" ]]; then
                in_removing_block=0
                block_is_removed=1
                [ -n "$output" ] && output+="\n"
                output+="$BLOCK_SEPARATOR"
            fi
            continue
        fi

        [[ "$line" == "$BLOCK_SEPARATOR" ]] && after_separator=1 && continue

        if [[ "$after_separator" -eq 1 ]]; then
            after_separator=0
            # If the line is match the regexp, then we should remove the block
            if [ -z "$command" ] || [[ "$line" = $command ]]; then
                in_removing_block=1
            else
                [ -n "$output" ] && output+="\n"
                output+="$BLOCK_SEPARATOR\n$line"
            fi
            continue
        fi

        [ -n "$output" ] && output+="\n"
        output+="$line"
    done < "$HISTORY_FILE"

    # Rewrite the file with the updated content
    echo "$output" > "$HISTORY_FILE"
}