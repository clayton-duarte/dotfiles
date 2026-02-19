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

# Ensure Zsh is installed (needed on remote servers)
if ! command -v zsh &> /dev/null; then
    echo "📦 Installing Zsh..."
    if command -v apt &> /dev/null; then
        sudo apt update -qq && sudo apt install -yqq zsh
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y zsh
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh
    else
        echo -e "${YELLOW}⚠️  Cannot install zsh — unknown package manager${NC}"
    fi
fi

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

# Install Oh My Zsh
echo ""
echo "🔌 Setting up Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "📦 Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo -e "${GREEN}✓${NC} Oh My Zsh already installed"
fi

# Install custom plugins (not bundled with OMZ)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    echo "📦 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    echo "📦 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo -e "${GREEN}✓${NC} Oh My Zsh plugins ready"

echo ""
echo "✅ Dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Your config will auto-sync with git on startup"
echo "  3. Use 'config edit' to edit dotfiles in VS Code"
echo "  4. Use 'config sync' to manually push changes"
