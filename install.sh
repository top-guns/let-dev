get_shell_config_file() {
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

    echo $rc_file
}

install() {
    # Get the default shell name (bash, zsh, etc.)
    local shell_name=$1
    local auto_update=$2

    echo "$shell_name integration ..."

    local rc_file=$(get_shell_config_file $shell_name)

    echo '' >> $rc_file
    echo '# Add let-dev aliases. Should be the last lines!!!' >> $rc_file
    echo "export LETDEV_HOME='$LETDEV_HOME'" >> $rc_file
    echo "export LETDEV_PROFILE='$LETDEV_PROFILE'" >> $rc_file
    echo "[ -d \"\$LETDEV_HOME\" ] && source \"\$LETDEV_HOME/init-shell.sh\" $shell_name $auto_update" >> $rc_file

    echo "successfully"
}

reload_shell() {
    local shell_name=$1

    local rc_file=$(get_shell_config_file $shell_name)

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
# If the shell name is not passed, then ask the user to enter the shell name
[ -z "$shell_name" ] && read -p "Enter the shell name (bash, zsh, etc.): " shell_name

auto_update=""
[ -z "$auto_update" ] && read -p "Do you want to auto-update let-dev? (y/n): " response
if [[ "$response" =~ ^[Nn][Oo]?$ ]]; then
    auto_update="--no-update"
else
    auto_update="--update"
fi


LETDEV_HOME=`dirname $SCRIPT_PATH`

# Get the user profile name
LETDEV_PROFILE=""
[ -z "$LETDEV_PROFILE" ] && read -p "Enter let-dev profile name: " LETDEV_PROFILE

if [ -z "$LETDEV_PROFILE" ]; then
    echo "Profile is required"
else
    echo "Install let-dev auto-completion"
    source $LETDEV_HOME/commands/install/fzf-completion-in-bash $shell_name
    echo "Installation of let-dev auto-completion has been completed."
    echo ""

    echo "Install let-dev"

    install $shell_name $auto_update
    reload_shell $shell_name

    echo ""

    echo "Installation of let-dev has been completed."
    echo "Use : to run let-dev commands."
fi
