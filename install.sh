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

shell_integration() {
    # Get the default shell name (bash, zsh, etc.)
    local shell_name=$1
    local auto_update=$2

    echo "$shell_name integration ..."

    local rc_file=$(get_shell_config_file $shell_name)

    # Check if aliases are already added
    if grep -q "let-dev" $rc_file; then
        echo "let-dev aliases are already added to $rc_file"
    else
        echo "Add let-dev aliases to $rc_file"
        echo '' >> $rc_file
        echo '# Add let-dev aliases. Should be the last lines!!!' >> $rc_file
        echo "export LETDEV_HOME='$LETDEV_HOME'" >> $rc_file
        echo "export LETDEV_PROFILE='$LETDEV_PROFILE'" >> $rc_file
        echo "[ -d \"\$LETDEV_HOME\" ] && source \"\$LETDEV_HOME/init-shell.sh\" $shell_name true $auto_update" >> $rc_file
    fi

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

LETDEV_HOME=`dirname $SCRIPT_PATH`

# Get the command line arguments
shell_name=""               # Shell name
auto_update="--no-update"   # let-dev auto-update 
LETDEV_PROFILE=""           # User profile name
for arg in "$@"; do
    case $arg in
        --profile=*)
            LETDEV_PROFILE=`echo $arg | sed 's/--profile=//'`
            ;;
        --no-update)
            auto_update="--no-update"
            ;;
        --update)
            auto_update="--update"
            ;;
        --shell=*)
            shell_name=`echo $arg | sed 's/--shell=//'`
            ;;
        --help|help)
            echo "Usage: $0 [--shell=<bash|zsh>] [--profile=<letdev_profile_name>] [--update|--no-update]"
            return
            ;;
        *)
            echo "Unknown argument: $arg"
            return
            ;;
    esac
    shift
done

# If the shell name is not passed, ask the user to enter it
[ -z "$shell_name" ] && read -p "Enter the shell name (bash, zsh, etc.): " shell_name

# If the profile name is not passed, ask the user to enter it
[ -z "$LETDEV_PROFILE" ] && read -p "Enter let-dev profile name: " LETDEV_PROFILE


if [ -z "$LETDEV_PROFILE" ]; then
    echo "Profile is required"
else
    # Create profile directory structure if it does not exist 
    if [ -d "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands" ]; then
        echo "Profile directory structure already exists"
    else
        echo "Create profile directory structure"
        mkdir -p "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands"
    fi
    echo ''

    # Add fzf completion to the shell if it is not added and shell is bash
    if [ "$shell_name" == "bash" ]; then
        echo "Add fzf completion to $HOME/.bashrc"
        source $LETDEV_HOME/install-fzf-completion-in-bash $shell_name
    fi
    echo ""

    echo "Install let-dev"

    shell_integration $shell_name $auto_update

    # Reload the shell to apply changes
    # reload_shell $shell_name
    rc_file=$(get_shell_config_file $shell_name)
    echo "reload $shell_name to apply changes ..."
    source $rc_file
    echo "successfully"

    echo ""

    echo "Installation of let-dev has been completed successfully."
    echo "Use : prefix to run let-dev commands."
fi
