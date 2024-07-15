#!/bin/bash

_ask() {
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

_load() {
    local path=$1
    # Expend the path
    path=$(eval echo $path)
    # Expand soft links
    path=$(readlink -f "$path")

    # If it is a file then return the content of the file
    if [ -f "$path" ]; then
        cat "$path"
        return
    fi

    # If it is a directory then return the list of files in the directory
    if [ -d "$path" ]; then
        ls -1 "$path"
        return
    fi

}

# Parse command line arguments and change there values:
# :?[param_name] replace with ask(param_name) function call result
# :.[file_name] and :/[file_name] replace with load(file_name) function call result
# help and --help print COMMAND_HELP variable and returns the empty array as result to stop calling the function
# description prings the COMMAND_DESCRIPTION variable and returns the empty array as result to stop calling the function
parse_letdev_arguments() {
    local args=()

    while [ $# -gt 0 ]; do
        echo "arg: $1"
        case $1 in
            :.*|:/*)
                echo "filename: ${1:1}"
                args+=("$(_load "${1:1}")")
                ;;
            help|--help)
                echo "$COMMAND_HELP"
                return
                ;;
            description)
                echo "$COMMAND_DESCRIPTION"
                return
                ;;
            *)
                # If the argument starts with ':' and has more than 1 character
                # then it is a parameter that needs to be asked
                if [[ $1 == :\?* ]]; then
                    args+=("$(_ask "${1:2}")")
                else
                    args+=("$1")
                fi
        esac
        shift
    done

    echo "${args[@]}"
}
