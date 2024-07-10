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
    local with_descriptions="$2"
    local with_examples="$3"

    if [ -d "$dir" ]; then
        local cur_dir=`pwd`
        cd "$dir"

        # If with description option is provided, use 'eval "command description"' to get description and return 'command:description' as a result
        if $with_descriptions; then
            # All files that do not contain the variable DESCRIPTION
            find . -type f -not -path '*/.*' -exec grep -L 'DESCRIPTION=' {} \; | sed 's|^./|:|'
            # All files that contain the variable DESCRIPTION
            find . -type f -not -path '*/.*' -exec grep -l 'DESCRIPTION=' {} \; | sed 's|^./||' | \
                xargs -I{} awk -F= '/DESCRIPTION=/ {gsub(/['"'"'\x22]/, "", $2); print FILENAME " - " $2}' {}
        else
            find . -type f -not -path '*/.*' -print -o -type l -not -path '*/.*' -print | sed 's|^./|:|'
        fi

        cd $cur_dir
    fi
}

list_commands() {
    if [[ "$1" = "--help" ]]; then
        echo "List all available commands in the system, user and project contexts."
        echo "Usage:"
        echo "  :$0 [--system] [--user] [--project] [--with-description] [filter]"
        echo "Options:"
        echo "  filter: Filter commands by name."
        echo "  --system: Include system commands."
        echo "  --user: Include user commands."
        echo "  --project: Include project commands."
        echo "  --with-description: Include command description."
        echo "  --with-examples: Include command examples."
        echo "If no option is provided, all commands are listed."
        echo "Example:"
        echo "  :$0 .env MY_ENV_VAR"
        echo "  :$0 .env MY_ENV_VAR --system --user --with-description"
        return
    fi

    # Parse arguments
    local filter=""
    local include_system=false
    local include_user=false
    local include_project=false
    local with_descriptions=false
    local with_examples=false
    for arg in "$@"; do
        case $arg in
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
            --with-descriptions)
                with_descriptions=true
                shift
                ;;
            --with-examples)
                with_examples=true
                shift
                ;;
            *)
                filter=$arg
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

    local cur_dir=`pwd`

    # Get project commands
    local PROJECT_COMMAND_LIST=""
    if $include_project; then
        local dir=".let-dev/$LETDEV_PROFILE/commands"
        if [ -d "$dir" ]; then
            PROJECT_COMMAND_LIST=$(_get_list "$dir" $with_descriptions $with_examples)
        fi
    fi

    # Get system commands
    local SYS_COMMAND_LIST=""
    if $include_system; then
        local dir="$LETDEV_HOME/commands"
        if [ -d "$dir" ]; then
            SYS_COMMAND_LIST=$(_get_list "$dir" $with_descriptions $with_examples)
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
            USER_COMMAND_LIST=$(_get_list "$dir" $with_descriptions $with_examples)
        else
            echo "User $LETDEV_PROFILE commands directory not found: $dir"
            return 1
        fi
    fi

    cd $cur_dir

    # Merge both command lists, user commands have higher priority
    local COMMAND_LIST=""
    if [ -n "$PROJECT_COMMAND_LIST" ]; then
        [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
        COMMAND_LIST="$COMMAND_LIST$PROJECT_COMMAND_LIST"
    fi
    if [ -n "$USER_COMMAND_LIST" ]; then
        [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
        COMMAND_LIST="$COMMAND_LIST$USER_COMMAND_LIST"
    fi
    if [ -n "$SYS_COMMAND_LIST" ]; then
        [ -n "$COMMAND_LIST" ] && COMMAND_LIST="$COMMAND_LIST\n"
        COMMAND_LIST="$COMMAND_LIST$SYS_COMMAND_LIST"
    fi
    
    # $(echo "$PROJECT_COMMAND_LIST" && echo "$USER_COMMAND_LIST" && echo "$SYS_COMMAND_LIST")

    local result=`echo -e "$COMMAND_LIST" | sort | uniq`

    [ -n "$filter" ] && result=`echo "$result" | grep "$filter"`
    echo "$result"
}

list_commands $@
