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

brew bundle --file=- <<EOF
# Core tools
brew "git"
brew "gh"          # GitHub CLI (for pr command)
brew "zsh"         # Latest Zsh (macOS ships with older version)
brew "sheldon"     # Zsh plugin manager
brew "starship"    # Cross-shell prompt
brew "n"           # Node version manager
brew "jq"          # JSON parser (for secrets script)
brew "neofetch"    # System info display

# Fonts
cask "font-meslo-lg-nerd-font"  # Nerd Font for Starship prompt
EOF

echo "✅ macOS setup complete"
