#!/bin/bash

install() {
    # Get the default shell name (bash, zsh, etc.)
    local shell_name=$1

    echo "$shell_name integration ..."

    rc_file=""
    if [ "$shell_name" == "bash" ]; then
        rc_file="$HOME/.bashrc"
    elif [ "$shell_name" == "zsh" ]; then
        rc_file="$HOME/.zshrc"
    else
        echo "Unsupported shell: $shell_name"
        return
    fi

    echo '' >> $rc_file
    echo '# Add let-dev aliases. Should be the last lines!!!' >> $rc_file
    echo "export LETDEV_HOME='$LETDEV_HOME'" >> $rc_file
    echo "export LETDEV_PROFILE='$LETDEV_PROFILE'" >> $rc_file
    echo "[ -d '$LETDEV_HOME' ] && source '$LETDEV_HOME/init-shell.sh'" >> $rc_file

    echo "successfully"
}

reload_shell() {
    local shell_name=$1

    rc_file=""
    if [ "$shell_name" == "bash" ]; then
        rc_file="$HOME/.bashrc"
    elif [ "$shell_name" == "zsh" ]; then
        rc_file="$HOME/.zshrc"
    else
        echo "Unsupported shell: $shell_name"
        return
    fi

    echo "reload $shell_name to apply changes ..."
    source $rc_file
    echo "successfully"
}


SCRIPT_PATH=''
[ -n "${BASH_SOURCE[0]}" ] && SCRIPT_PATH="${BASH_SOURCE[0]}" || SCRIPT_PATH="$0"
# Get the absolute path of the current script and expand the '..' to the real path
SCRIPT_PATH=`readlink -f $SCRIPT_PATH`

# Get the default shell name (bash, zsh, etc.)
shell_name=$1
[ -z "$shell_name" ] && shell_name=$(basename $SHELL)

LETDEV_HOME=`dirname $SCRIPT_PATH`

# Get the user profile name
LETDEV_PROFILE=""
[ -z "$LETDEV_PROFILE" ] && read -p "Enter let-dev profile name: " LETDEV_PROFILE

if [ -z "$LETDEV_PROFILE" ]; then
    echo "Profile is required"
else
    echo "Install let-dev"

    install $shell_name
    reload_shell $shell_name

    echo "Installation of let-dev has been completed."
    echo "Use : and :: to run let-dev commands."
fi
