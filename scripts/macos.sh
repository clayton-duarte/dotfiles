#!/bin/bash
# =============================================================================
# macOS Setup Script
# =============================================================================

set -e

echo "🍎 Setting up macOS..."

# Install Homebrew if needed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew already installed"
fi

# Install tools via Brewfile
echo "📦 Installing packages from Brewfile..."

brew bundle --no-lock --file=- <<EOF
# Core tools
brew "git"
brew "gh"
brew "fish"

# Node version manager
brew "n"

# Modern CLI tools
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "exa"
brew "starship"

# Development tools (optional, uncomment as needed)
# brew "neovim"
# brew "tmux"
# cask "docker"
# cask "visual-studio-code"
EOF

echo "✅ macOS setup complete"
