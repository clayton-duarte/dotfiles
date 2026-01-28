#!/bin/bash
# =============================================================================
# Dotfiles Installer
# =============================================================================
# This script creates symlinks from dotfiles repo to home directory
# Safe to run multiple times (idempotent)

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "🔗 Installing dotfiles..."

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup function
backup_if_exists() {
    if [[ -f "$1" ]] || [[ -d "$1" ]]; then
        if [[ ! -L "$1" ]]; then
            local backup="$1.backup.$(date +%Y%m%d-%H%M%S)"
            echo -e "${YELLOW}⚠️  Backing up existing $1 to $backup${NC}"
            mv "$1" "$backup"
        else
            # Already a symlink, remove it
            rm "$1"
        fi
    fi
}

# Create symlink function
link() {
    local src="$DOTFILES_DIR/$1"
    local dest="$HOME/$1"
    local dest_dir=$(dirname "$dest")

    # Create parent directory if needed
    mkdir -p "$dest_dir"

    # Backup and create symlink
    backup_if_exists "$dest"
    ln -sf "$src" "$dest"
    echo -e "${GREEN}✓${NC} Linked $1"
}

# Link fish config
link .config/fish/config.fish

# Link git config if it exists
if [[ -f "$DOTFILES_DIR/.gitconfig" ]]; then
    link .gitconfig
fi

# Generate SSH config by combining platform-specific config with shared hosts
echo "🔑 Generating SSH config..."
mkdir -p "$HOME/.ssh"

# Remove existing symlink if present
if [[ -L "$HOME/.ssh/config" ]]; then
    rm "$HOME/.ssh/config"
fi

# Backup existing file if it's not a symlink
backup_if_exists "$HOME/.ssh/config"

# Determine which platform config to use
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM_CONFIG="$DOTFILES_DIR/.ssh/config.macos"
else
    PLATFORM_CONFIG="$DOTFILES_DIR/.ssh/config.linux"
fi

# Combine platform config + shared hosts
cat "$PLATFORM_CONFIG" > "$HOME/.ssh/config"
echo "" >> "$HOME/.ssh/config"
cat "$DOTFILES_DIR/.ssh/hosts" >> "$HOME/.ssh/config"

chmod 600 "$HOME/.ssh/config"
echo -e "${GREEN}✓${NC} Generated SSH config for $OSTYPE"

# Link other configs as they're added
# link .tmux.conf
# link .vimrc
# link .npmrc

# Install fisher and agnoster theme
echo ""
echo "🎨 Setting up fish theme..."
fish -c "
    # Install fisher if not present
    if not functions -q fisher
        echo '📦 Installing fisher plugin manager...'
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    end

    # Install agnoster theme
    echo '🎨 Installing agnoster theme...'
    fisher install oh-my-fish/theme-agnoster
"
echo -e "${GREEN}✓${NC} Fish theme installed"
echo ""
echo "✅ Dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec fish)"
echo "  2. Your config will auto-sync with git on startup"
echo "  3. Use 'config edit' to edit dotfiles in VS Code"
echo "  4. Use 'config sync' to manually push changes"
