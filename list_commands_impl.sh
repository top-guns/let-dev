#!/bin/bash

# This function extracts definitions of functions and variables from a given file
_extract_definitions() {
    # The name of the file
    local file="$1"

    # An empty string to store the definitions
    local definitions=""

    # Read the file line by line
    while IFS= read -r line
    do
        # If the line contains a function or variable definition
        if [[ $line =~ ^[[:space:]]*function || $line =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z_0-9]*= ]]; then
            # Add the line to the definitions
            definitions+="$line"$'\n'
        fi
    done < "$file"

    # Print the definitions
    echo "$definitions"
}

_get_list() {
    local dir="$1"
    # local with_descriptions="$2"
    # local with_examples="$3"
    local format="$2"
    # local from_path="$3"

    if [ -d "$dir" ]; then
        local cur_dir=`pwd`
        builtin cd "$dir"
        dir=$(pwd) # To make it absolute

        # # If with description option is provided, use 'eval "command description"' to get description and return 'command:description' as a result
        # if $with_descriptions; then
        #     # # All files that do not contain the variable DESCRIPTION
        #     # find . -type f -not -path '*/.*' -exec grep -L 'DESCRIPTION=' {} \; | sed 's|^./|:|'
        #     # # All files that contain the variable DESCRIPTION
        #     # find . -type f -not -path '*/.*' -exec grep -l 'DESCRIPTION=' {} \; | sed 's|^./||' | \
        #     #     xargs -I{} awk -F= '/DESCRIPTION=/ {gsub(/['"'"'\x22]/, "", $2); print FILENAME " - " $2}' {}
        #     echo "NOT IMPLEMENTED"
        # else
            #local result=$(find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print)
            # if $from_path; then
            #     echo "$result" | sed 's|^\./||'
            # else
            #     echo "$result" | sed 's|^\./|:|'
            # fi
            if [ "$format" = "command" ]; then
                # Print as ':dir:subdir:command'
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^\./|:|' | sed 's|/|:|g' | sed 's|::|:|'
            elif [ "$format" = "path" ]; then
                # Print as 'dir/subdir/command'
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^\./||'
            elif [ "$format" = "fullpath" ]; then
                # Print as '/.../dir/subdir/command'
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed "s|^\.|$dir|"
            elif [ "$format" = "var" ]; then
                # Print as ':dir:subdir:command="/.../dir/subdir/command"'
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^\./||' \
                    | awk -F/ -v OFS=":" -v dir="$dir" '{path=$0; gsub("/", ":", path); print path"=\"" dir "/" $0 "\""}' \
                    | sed 's|^|:|' | sed 's|^::|:|'
            elif [ "$format" = "alias" ]; then
                # Print as 'alias :dir:subdir:command="/.../dir/subdir/command"'
                # find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^\./||' \
                #     | awk -F/ -v OFS=":" -v dir="$dir" '{path=$0; gsub("/", ":", path); print "alias "path"=\"source " dir "/" $0 "\""}' \
                #     | sed 's|^alias |alias :|' | sed 's|::|:|'
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print \
                    | sed 's|^\./|:|' | sed 's|/|:|g' | sed 's|::|:|' | sed 's|^\(.*\)$|alias \1=": \1"|'
            elif [ "$format" = "raw" ]; then
                find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print
            else
                echo "Invalid format: '$format'. Supported formats are: command, path, var, raw."
                return 1
            fi
        # fi

        builtin cd "$cur_dir"
    fi
}

_collect_commands_recursive() {
    local cur_dir="$1"
    local sub_dir="$2"
    local format="$3"
    local command_list=""

    # Start from the specified directory and iterate up to the root directory
    while [ -d "$cur_dir" ]; do
        if [ -d "$cur_dir/$sub_dir" ]; then
            local commands=$(_get_list "$cur_dir/$sub_dir" "$format")
            # Iterate over the commands and add them to the command_list if it is not already present
            while IFS= read -r command; do
                if ! echo "$command_list" | grep -q "$command"; then
                    [ -n "$command_list" ] && command_list="$command_list\n"
                    command_list="$command_list$command"
                fi
            done <<< "$commands"
        fi

        local parent_dir=$(dirname "$cur_dir")  # Get the parent directory
        # If we reached the root directory or the parent directory is empty, stop iterating
        [ "$parent_dir" = "$cur_dir" ] && break
        cur_dir="$parent_dir"  # Update the start directory to the parent directory
    done

    echo -e "$command_list"
}

list_commands() {
    if [[ "$1" = "--help" ]]; then
        echo "List all available commands in the system, user and project contexts."
        echo "Usage:"
        echo "  :$0 [--system] [--user] [--project] [--with-description] [filter]"
        echo "Options:"
        echo "  filter: Filter commands by name."
        echo "  --format: Format the output (command | path | fullpath | var | raw)."
        echo "  --system: Include system commands."
        echo "  --user: Include user commands."
        echo "  --project: Include project commands."
        # echo "  --with-description: Include command description."
        # echo "  --with-examples: Include command examples."
        echo "If no filter is provided, all commands are listed."
        echo "If no format is provided, the output is commands."
        echo "If no option is provided, all commands are listed."
        echo "Example:"
        echo "  :$0 .env MY_ENV_VAR"
        echo "  :$0 .env MY_ENV_VAR --format=path --system --user"
        return
    fi

    # Parse arguments
    local filter=""
    local format="command"
    local include_system=false
    local include_user=false
    local include_project=false
    # local with_descriptions=false
    # local with_examples=false
    for arg in "$@"; do
        case $arg in
            --format=*)
                format=`echo $arg | sed 's/--format=//' | tr '[:upper:]' '[:lower:]'`
                shift
                ;;
            --system)
                include_system=true
                shift
                ;;
            --user)
                include_user=true
                shift
                ;;
            --project)
                include_project=true
                shift
                ;;
            # --with-descriptions)
            #     with_descriptions=true
            #     shift
            #     ;;
            # --with-examples)
            #     with_examples=true
            #     shift
            #     ;;
            *)
                [ -n "$filter" ] && filter+=" "
                filter+=$arg
                shift
                ;;
        esac
    done

    # Include all commands by default
    if [ "$include_system" = false ] && [ "$include_user" = false ] && [ "$include_project" = false ]; then
        include_system=true
        include_user=true
        include_project=true
    fi


    # Replace spaces with /
    filter=`echo "$filter" | tr " " "/"`

    # Remove the first symbol if it is a colon
    # filter=`echo "$filter" | sed "s/^:[ ]*//"`

    # Get project commands
    local PROJECT_COMMAND_LIST=""
    if $include_project; then
        #PROJECT_COMMAND_LIST=$(_get_list "$dir" $format)
        PROJECT_COMMAND_LIST=$(_collect_commands_recursive "$(pwd)" ".let-dev/$LETDEV_PROFILE/commands" "$format")
        # if [ "$format" = "command" ] || [ "$format" = "var" ]; then
        #     # PROJECT_COMMAND_LIST=$(echo "$PROJECT_COMMAND_LIST" | sed 's|^|: :project|')
        #     # PROJECT_COMMAND_LIST=$(echo "$PROJECT_COMMAND_LIST" | sed 's|$|\t\t -- project command|')
        #     PROJECT_COMMAND_LIST=$(echo "$PROJECT_COMMAND_LIST" | sed 's|^|: |')
        # fi
    fi

    # Get system commands
    local SYS_COMMAND_LIST=""
    if $include_system; then
        local dir="$LETDEV_HOME/commands"
        if [ -d "$dir" ]; then
            SYS_COMMAND_LIST=$(_get_list "$dir" $format)
        else
            echo "System commands directory not found: $dir"
            return 1
        fi
    fi

    # Get user commands
    local USER_COMMAND_LIST=""
    if $include_user; then
        local dir="$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands"
        if [ -d "$dir" ]; then
            USER_COMMAND_LIST=$(_get_list "$dir" $format)
        fi
    fi

    # Merge both command lists, user commands have higher priority
    local COMMAND_LIST=""
    # if [ -n "$PROJECT_COMMAND_LIST" ]; then
    #     [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
    #     COMMAND_LIST="$COMMAND_LIST$PROJECT_COMMAND_LIST"
    # fi
    if [ -n "$USER_COMMAND_LIST" ]; then
        [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
        COMMAND_LIST="$COMMAND_LIST$USER_COMMAND_LIST"
    fi
    if [ -n "$SYS_COMMAND_LIST" ]; then
        [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
        COMMAND_LIST="$COMMAND_LIST$SYS_COMMAND_LIST"
    fi

    if [ -n "$PROJECT_COMMAND_LIST" ]; then 
        [ -z "$filter" ] && echo -e "$PROJECT_COMMAND_LIST" || echo -e "$PROJECT_COMMAND_LIST" | grep "$filter"
    fi

    if [ -n "$COMMAND_LIST" ]; then 
        [ -z "$filter" ] && echo -e "$COMMAND_LIST" | sort | uniq || echo -e "$COMMAND_LIST" | grep "$filter" | sort | uniq
    fi
}
