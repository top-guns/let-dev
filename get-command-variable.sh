#!/bin/bash

# This script extracts the specified variable from a given file

extract_variable_from_file() {
    local file=$1
    local variable_name=$2

    # Read the variable value from the file
    local variable_value=$(awk -F= -v var="$variable_name" '$1 == var {gsub(/['"'"'\x22]/, "", $2); print $2}' $file)

    # Print the variable value
    echo "$variable_value"
}

_do_command() {
    # All files that contain the variable DESCRIPTION
    # find . -type f -not -path '*/.*' -exec grep -l 'DESCRIPTION=' {} \; | sed 's|^./||' | \
    #     xargs -I{} awk -F= '/DESCRIPTION=/ {gsub(/['"'"'\x22]/, "", $2); print FILENAME " - " $2}' {}

    local command=$1
    local relative_path=$(echo $command | sed 's|:|/|g')
    local variable_name=$2
    local file=""
    
    # Find command file
    
    # in project commands
    file=".let-dev/$LETDEV_PROFILE/commands$relative_path"
    if [ -f "$file" ]; then
        echo "$(extract_variable_from_file "$file" "$variable_name")"
        return
    fi

    # in users commands
    file="$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands$relative_path"
    if [ -f "$file" ]; then
        echo "$(extract_variable_from_file "$file" "$variable_name")"
        return
    fi

    # in system commands
    file="$LETDEV_HOME/commands$relative_path"
    if [ -f "$file" ]; then
        echo "$(extract_variable_from_file "$file" "$variable_name")"
        return
    fi


    echo "Command not found: $command"
    return 1
}

_do_command $@
