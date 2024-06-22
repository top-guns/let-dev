#!/bin/bash

echo "Install let-dev"

# Get the default shell name (bash, zsh, etc.)
shell_name=$(basename $SHELL)

rc_file=""
if [ "$shell_name" == "bash" ]; then
    rc_file="$HOME/.bashrc"
elif [ "$shell_name" == "zsh" ]; then
    rc_file="$HOME/.zshrc"
else
    echo "Unsupported shell: $shell_name"
    exit 1
fi

# Get the user profile name
profile=$1
[ -z "$profile" ] && read -p "Enter let-dev profile name: " profile
[ -z "$profile" ] && echo "Profile is required" && exit 1

echo '' >> $rc_file
echo '# Add let-dev aliases. Should be the last line!!!' >> $rc_file
echo "export LETDEV_PROFILE='$profile'" >> $rc_file
echo "[ -d '$HOME/let-dev' ] && source '$HOME/let-dev/create-aliases'" >> $rc_file

echo "Installation is done successfully. Please restart your shell to apply changes."
