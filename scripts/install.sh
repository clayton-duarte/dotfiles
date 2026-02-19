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

# Link zsh config directory
mkdir -p "$HOME/.config/zsh"

# Link individual zsh files (not the whole dir, since secrets.zsh lives there)
link .config/zsh/.zshenv
link .config/zsh/.zshrc
link .config/zsh/starship.toml
link .config/zsh/plugins.toml

# Link zsh modules
mkdir -p "$HOME/.config/zsh/modules"
for module in "$DOTFILES_DIR/.config/zsh/modules/"*.zsh; do
    if [[ -f "$module" ]]; then
        local_path=".config/zsh/modules/$(basename "$module")"
        link "$local_path"
    fi
done

# Bootstrap symlink: ~/.zshenv → dotfiles .zshenv (so Zsh finds ZDOTDIR)
backup_if_exists "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/.config/zsh/.zshenv" "$HOME/.zshenv"
echo -e "${GREEN}✓${NC} Linked ~/.zshenv → .config/zsh/.zshenv"

# Link git config if it exists
if [[ -f "$DOTFILES_DIR/.gitconfig" ]]; then
    link .gitconfig
fi

# Link SSH config if it exists
if [[ -f "$DOTFILES_DIR/.ssh/config" ]]; then
    link .ssh/config
    chmod 600 "$HOME/.ssh/config"
fi

# Link other configs as they're added
# link .tmux.conf
# link .vimrc
# link .npmrc

# Install Sheldon plugin manager
echo ""
echo "🔌 Setting up Sheldon plugin manager..."
if ! command -v sheldon &> /dev/null; then
    if command -v brew &> /dev/null; then
        echo "📦 Installing Sheldon via Homebrew..."
        brew install sheldon
    elif command -v cargo &> /dev/null; then
        echo "📦 Installing Sheldon via Cargo..."
        cargo install sheldon
    else
        echo "📦 Installing Sheldon via installer..."
        curl --proto '=https' -fLsS https://rosav0.github.io/sheldon/install.sh | bash
    fi
fi

# Point Sheldon to our config
export SHELDON_CONFIG_DIR="$HOME/.config/zsh"
export SHELDON_DATA_DIR="$HOME/.config/zsh/sheldon"

# Lock plugins (downloads them)
if command -v sheldon &> /dev/null; then
    sheldon lock
    echo -e "${GREEN}✓${NC} Sheldon plugins installed"
else
    echo -e "${YELLOW}⚠️  Sheldon not found, plugins not installed${NC}"
fi

# Install Starship prompt
echo ""
echo "🚀 Setting up Starship prompt..."
if ! command -v starship &> /dev/null; then
    if command -v brew &> /dev/null; then
        echo "📦 Installing Starship via Homebrew..."
        brew install starship
    else
        echo "📦 Installing Starship via installer..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
fi
echo -e "${GREEN}✓${NC} Starship prompt ready"

echo ""
echo "✅ Dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Your config will auto-sync with git on startup"
echo "  3. Use 'config edit' to edit dotfiles in VS Code"
echo "  4. Use 'config sync' to manually push changes"
