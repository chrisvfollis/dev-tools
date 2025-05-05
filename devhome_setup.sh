
#!/bin/bash

# This script sets up a command (devhome) to easily cd into the base directory
# of your coding projects without specifying the whole path each time.

# When using devhome, you can include an extra argument for the name of a
# particular project within that base dir to navigate to it directly.

BASH_RC="$HOME/.bashrc"
ZSH_RC="$HOME/.zshrc"
BASH_PROFILE="$HOME/.bash_profile"

update_shell_rc() {
    local file="$1"
    local func_body="$2"

    # remove any existing devhome() block:
    if grep -q "devhome()" "$file" 2>/dev/null; then
        echo "Updating 'devhome' in $file"
        # delete from the function definition to the closing '}' and remove
        # any preceding "# Added by devhome setup" lines:
        if sed --version >/dev/null 2>&1; then
            # GNU sed
            sed -i.bak '/^devhome()[[:space:]]*()/,/^}/d' "$file"
            sed -i.bak '/# Added by devhome setup/d' "$file"
        else
            # BSD/macOS sed
            sed -i '' '/^devhome()[[:space:]]*()/,/^}/d' "$file"
            sed -i '' '/# Added by devhome setup/d' "$file"
        fi
    else
        echo "Adding 'devhome' to $file"
    fi

    # add the newest version of devhome() to the file:
    echo "$func_body" >> "$file"
}

# function body for devhome (as a variable to reuse):
DEVHOME_FUNC=$(cat << 'EOF'

# Added by devhome setup

devhome() {
    local script_dir_path="${BASH_SOURCE[0]:-${(%):-%x}}"
    script_dir_path="$(cd "$(dirname "$script_dir_path")" && pwd)"

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
        for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            echo "" >> "$shell_rc"
            echo "# Set by devhome function" >> "$shell_rc"
            echo "export DEV_PROJECTS_ROOT=\"$DEV_PROJECTS_ROOT\"" >> "$shell_rc"
        done
    fi

    if [[ ":$PATH:" != *":$script_dir_path:"* ]]; then
        echo "Adding $script_dir_path to PATH..."
        for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            echo "export PATH=\"\$PATH:$script_dir_path\"" >> "$shell_rc"
        done
    fi

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
)

update_shell_rc "$BASH_RC" "$DEVHOME_FUNC"
update_shell_rc "$ZSH_RC" "$DEVHOME_FUNC"

# ensure .bash_profile sources .bashrc:
if [ ! -f "$BASH_PROFILE" ] || ! grep -q 'source ~/.bashrc' "$BASH_PROFILE"; then
    echo "" >> "$BASH_PROFILE"
    echo "# source .bashrc for interactive shell config" >> "$BASH_PROFILE"
    echo "[ -f ~/.bashrc ] && source ~/.bashrc" >> "$BASH_PROFILE"
    echo "Updated $BASH_PROFILE to source .bashrc"
fi

echo "Run the appropriate command below to activate it in your current session:"
echo "  source ~/.bashrc"
echo "  source ~/.zshrc"
