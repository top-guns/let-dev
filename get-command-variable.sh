#!/bin/bash

# This script extracts the specified variable from a given file

extract_variable_from_file() {
    local file=$1
    local variable_name=$2

    # Read the variable value from the file
    # local variable_value=$(awk -F= -v var="$variable_name" '$1 == var {gsub(/['"'"'\x22]/, "", $2); print $2}' $file)
    local variable_value=$(sed -n -e '/^'"$variable_name"'=/,/"/ p' $file | sed '1d;$d' | tr -d '"')

    # Print the variable value
    echo "$variable_value"
}

_do_command() {
    # All files that contain the variable DESCRIPTION
    # find . -type f -not -path '*/.*' -exec grep -l 'DESCRIPTION=' {} \; | sed 's|^./||' | \
    #     xargs -I{} awk -F= '/DESCRIPTION=/ {gsub(/['"'"'\x22]/, "", $2); print FILENAME " - " $2}' {}

    local command="$1"
    command=$(echo "$command" | sed 's/^: //' | sed 's/ .*//')
    local relative_path=$(echo "$command" | sed 's|:|/|g')
    local variable_name=$2
    local file=$($LETDEV_HOME/get-command-script-path.sh "$command")
    
    [ -f "$file" ] && echo "$(extract_variable_from_file "$file" "$variable_name")" && return

    # echo "Command not found: $command"
    return 1
}

_do_command "$@"
