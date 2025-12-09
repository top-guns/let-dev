#!/bin/bash

# Recreate all let-dev aliases

ask() {
    local param_name=${1:-'parameter'}
    local param
    if [[ -n $ZSH_VERSION ]]; then
        read "?Enter $param_name: " param
    elif [[ -n $BASH_VERSION ]]; then
        read -p "Enter $param_name: " param
    else
        echo "Error: Unsupported shell"
        return
    fi
    echo "$(eval echo $param)"
}

load() {
    local file_name=$1
    cat "$(eval echo $file_name)"
}

_remove_cd_alias() {
    unalias cd 2>/dev/null
    [ $? -eq 0 ] && return 1
    return 0
}

_restore_cd_alias() {
    local cd_alias_definition="source $LETDEV_HOME/cd.sh"
    [ "$#" -gt 0 ] && cd_alias_definition=$(echo "$1" | sed 's/^[^=]*=//')
    #echo "restore_cd_alias: $cd_alias_definition"
    [ -n "$cd_alias_definition" ] && alias cd="$cd_alias_definition"
}

letdev_remove_all_aliases() {
    _remove_cd_alias
    unalias $LETDEV_SYMBOL 2>/dev/null
    unalias "${LETDEV_SYMBOL}?" 2>/dev/null
    unalias "${LETDEV_SYMBOL}@" 2>/dev/null

    # Find and remove all let-dev aliases (like ':....=...')
    for alias in $(alias | grep -oE "^:.*=" | sed 's/=$//'); do
        unalias "$alias" 2>/dev/null
    done

    return 0
}

letdev_recreate_all_aliases() {
    letdev_remove_all_aliases

    # Create alias for every command
    # local alias_commands=$($LETDEV_HOME/list-commands.sh --system --user --format=alias)
    local alias_commands=$(list_commands --system --user --project --format=alias)
    eval "$alias_commands"
    export LETDEV_LAST_PROJECT_PATH="$project_dir"

    # Param value reader alias
    alias "${LETDEV_SYMBOL}?"="ask"
     # File value reader alias
    alias "${LETDEV_SYMBOL}@"="load"


    # Shell command alias
    # alias "$LETDEV_SYMBOL$LETDEV_SYMBOL"="$LETDEV_HOME/shell/start.sh"

    # Alias for the default command
    alias "$LETDEV_SYMBOL"="source $LETDEV_HOME/default.sh"

    # Alias for the text shell command
    alias "$LETDEV_SYMBOL$LETDEV_SYMBOL"="source $LETDEV_HOME/default.sh"
    alias "$LETDEV_SYMBOL$LETDEV_SYMBOL$LETDEV_SYMBOL"="source $LETDEV_HOME/default.sh"

    # Alias for the project-dir command
    alias "${LETDEV_SYMBOL}project-dir"='bash -c "cd $(dirname ${BASH_SOURCE:-$0})/../../.. && pwd"'

    # Alias for the cd command
    [ "$LETDEV_REPLACE_CD" = 'true' ] && _restore_cd_alias
}

letdev_remove_project_aliases() {
    [ -z "$LETDEV_LAST_PROJECT_PATH" ] && return

    local cur_dir="$PWD"
    builtin cd "$LETDEV_LAST_PROJECT_PATH"

    local unalias_commands=$(list_commands --project --format=command | sed 's/^/unalias /')
    eval "$unalias_commands"

    builtin cd "$cur_dir"

    export LETDEV_LAST_PROJECT_PATH=""
}
    

letdev_recreate_project_aliases() {
    letdev_remove_project_aliases

    # Create alias for every command
    local alias_commands=$(list_commands --project --format=alias)
    eval "$alias_commands"

    export LETDEV_LAST_PROJECT_PATH="$PWD"
}

# Функция для получения команды по расширению
letdev_get_command_processor() {
    local cmd="$1"

    local ext=$(echo "$cmd" | sed -n 's/.*\.\([^/.]*\)$/\1/p')
    case "$ext" in
        sh)   cmd="bash"        ;;  # shell scripts
        py)   cmd="python3"     ;;  # Python scripts
        rb)   cmd="ruby"        ;;  # Ruby scripts
        js)   cmd="node"        ;;  # JavaScript (Node.js)
        txt)  cmd="cat"         ;;  # plain text
        md)   cmd="cat"         ;;  # Markdown
        *)    cmd="bash"        ;;  # unknown extension
    esac
    printf '%s' "$cmd"
}

# Функция для исполнения скрипта нужным процессором
letdev_execute_script() {
    local cmd="$1"
    shift

    # Resolve symbolic links
    # cmd=`readlink -f $cmd`

    local cmd_processor=$(letdev_get_command_processor "$cmd")

    if [[ "$cmd_processor" == "bash" ]]; then
        source "$cmd" "$@"
    else
        eval "$cmd_processor '$cmd'" "$@"
    fi
}

letdev_init_project() {
    local init_folder="$(pwd)/.let-dev/$LETDEV_PROFILE/init"
    [ -d "$init_folder" ] || return

    find "$init_folder" -maxdepth 1 -type f -name '*' | while IFS= read -r file; do
        if [ -f "$file" ]; then
            letdev_execute_script "$file"
        fi
    done
}
