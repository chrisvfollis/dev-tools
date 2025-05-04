#!/bin/bash

# This script sets up a command (devhome) to easily cd into a base directory
# for your coding projects without specifying the whole path to it each time. When
# using devhome, you can include an extra argument for the name of a particular
# project within that base dir to navigate to it directly.

if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    echo "Unsupported shell. Please manually add the function to your shell config."
    exit 1
fi

# check if devhome function already exists:
if grep -q "devhome()" "$SHELL_RC"; then
    echo "Function 'devhome' already defined in $SHELL_RC"
    exit 0
fi

# append the function to the shell config file:
cat >> "$SHELL_RC" << 'EOF'

# Added by devhome setup

devhome() {
    # resolve the function file location:
    local script_dir_path="${BASH_SOURCE[0]:-${(%):-%x}}"
    script_dir_path="$(cd "$(dirname "$script_dir_path")" && pwd)"

    # ensure DEV_PROJECTS_ROOT is set:
    if [ -z "$DEV_PROJECTS_ROOT" ]; then
        local default_dir="$HOME/Documents/Projects"
        echo "Environment variable DEV_PROJECTS_ROOT not found"
        echo "Please set the variable (otherwise default will be used: $default_dir):"
        read -r user_input

        if [ -n "$user_input" ]; then
            DEV_PROJECTS_ROOT="$user_input"
        else
            DEV_PROJECTS_ROOT="$default_dir"
        fi

        echo "Exporting DEV_PROJECTS_ROOT for future sessions..."
        local shell_rc=""
        if [ -n "$BASH_VERSION" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        fi

        if [ -n "$shell_rc" ]; then
            echo "" >> "$shell_rc"
            echo "# Set by devhome function" >> "$shell_rc"
            echo "export DEV_PROJECTS_ROOT=\"$DEV_PROJECTS_ROOT\"" >> "$shell_rc"
        fi
    fi

    # add script dir to PATH if needed:
    if [[ ":$PATH:" != *":$script_dir_path:"* ]]; then
        echo "Adding $script_dir_path to PATH..."
        echo "export PATH=\"\$PATH:$script_dir_path\"" >> "$shell_rc"
    fi

    # navigate to project:
    local project_name="$1"
    local target_dir="$DEV_PROJECTS_ROOT"

    if [ -n "$project_name" ]; then
        target_dir="$DEV_PROJECTS_ROOT/$project_name"
    fi

    if [ ! -d "$target_dir" ]; then
        echo "Directory '$target_dir' does not exist."
        return 1
    fi

    cd "$target_dir" || {
        echo "Failed to cd into $target_dir"
        return 1
    }

    echo "Changed directory to $target_dir"
}
EOF

echo "'devhome' added to $SHELL_RC"
echo "Run the following command to activate it in your current session:"
echo "  source $SHELL_RC"
