#!/bin/bash
# =============================================================================
# Bootstrap Script for Fresh Machine
# =============================================================================
# Prerequisite: git and 1Password must be installed
# Usage: ./bootstrap.sh

set -e

echo "🚀 Bootstrapping new machine..."
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "📍 Detected OS: $OS"
echo ""

# 1. Install 1Password CLI if needed
if ! command -v op &> /dev/null; then
    echo "📦 Installing 1Password CLI..."
    if [[ "$OS" == "macos" ]]; then
        # Check if Homebrew is available
        if command -v brew &> /dev/null; then
            brew install 1password-cli
        else
            echo "⚠️  Homebrew not found. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
            brew install 1password-cli
        fi
    else
        # Linux installation
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list

        sudo apt update && sudo apt install -y 1password-cli
    fi
    echo "✅ 1Password CLI installed"
else
    echo "✅ 1Password CLI already installed"
fi

echo ""

# 2. Authenticate with 1Password
echo "🔐 Authenticating with 1Password..."
if ! op account list &> /dev/null; then
    eval $(op signin)
else
    echo "✅ Already authenticated with 1Password"
fi

echo ""

# 3. Install essential tools for the OS
echo "📦 Installing essential tools..."
chmod +x ./scripts/${OS}.sh
./scripts/${OS}.sh

echo ""

# 4. Pull secrets from 1Password
echo "🔑 Fetching secrets from 1Password..."
chmod +x ./scripts/secrets.sh
./scripts/secrets.sh

echo ""

# 5. Symlink dotfiles
echo "🔗 Symlinking dotfiles..."
chmod +x ./scripts/install.sh
./scripts/install.sh

echo ""

# 6. Set fish as default shell
echo "🐚 Setting fish as default shell..."

# Get fish path
FISH_PATH=$(which fish)

# Check if fish is in /etc/shells
if ! grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
    echo "  Adding fish to /etc/shells (requires sudo)..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Set fish as default shell
if [[ "$SHELL" != *"fish"* ]]; then
    echo "  Setting fish as default shell (requires password)..."
    chsh -s "$FISH_PATH"
    echo "✅ Fish set as default shell"
else
    echo "✅ Fish is already default shell"
fi

echo ""

# 7. Configure git
echo "👤 Configuring git..."
git config --global user.email "cpd@duck.com"
git config --global user.name "cpd"
git config --global push.autoSetupRemote true
git config --global core.editor "code --wait"
git config --global pull.rebase true
git config --global merge.ff false
git config --global rebase.autoStash true

# Git SSH signing (macOS only for now)
if [[ "$OS" == "macos" ]]; then
    git config --global gpg.format ssh
    git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    git config --global commit.gpgsign true
    git config --global user.signingkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzlrKAQzna6inWC0rg3wCXgL0i0MzYHLxzt+s2Zf+wW"

    # Create allowed_signers file for commit verification
    mkdir -p "$HOME/.ssh"
    echo "cpd@duck.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzlrKAQzna6inWC0rg3wCXgL0i0MzYHLxzt+s2Zf+wW" > "$HOME/.ssh/allowed_signers"
    git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"

    echo "  ✓ Git SSH signing configured"
fi

echo "✅ Git configured"
echo ""

# 8. Initialize git repo for dotfiles (if not already initialized)
if [[ ! -d .git ]]; then
    echo "📦 Initializing git repository..."
    git init
    git add .
    git commit -m "Initial dotfiles setup from $(hostname)"
    echo ""
    echo "⚠️  Don't forget to:"
    echo "    1. Create a private repo on GitHub: gh repo create dotfiles --private"
    echo "    2. Push: git remote add origin git@github.com:yourusername/dotfiles.git && git push -u origin main"
else
    echo "✅ Git repository already initialized"
fi

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (exec fish)"
echo "  2. Your config will auto-sync on terminal startup"
echo "  3. Use 'config edit' to edit configs"
echo "  4. SSH config is ready with all hosts configured"
echo ""
