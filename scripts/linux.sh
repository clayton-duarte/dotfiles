#!/bin/bash
# =============================================================================
# Linux Setup Script
# =============================================================================

set -e

echo "🐧 Setting up Linux..."

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution"
    exit 1
fi

case $DISTRO in
    ubuntu|debian)
        echo "📦 Installing essential packages (Ubuntu/Debian)..."
        sudo apt update
        sudo apt install -y \
            git \
            zsh \
            curl \
            jq \
            gh \
            fonts-powerline \
            neofetch
        ;;
    fedora|bazzite*)
        echo "📦 Installing essential packages (Fedora/Bazzite)..."
        # Bazzite is immutable, packages should be layered
        sudo rpm-ostree install -y \
            git \
            zsh \
            curl \
            jq \
            gh \
            powerline-fonts \
            neofetch || \
        sudo dnf install -y \
            git \
            zsh \
            curl \
            jq \
            gh \
            powerline-fonts \
            neofetch
        ;;
    arch|steamos*|holo*)
        echo "📦 Installing essential packages (Arch/SteamOS)..."
        # SteamOS is immutable, might need pacman or flatpak
        sudo pacman -S --noconfirm \
            git \
            zsh \
            curl \
            jq \
            github-cli \
            powerline-fonts \
            neofetch
        ;;
    *)
        echo "⚠️  Unsupported distribution: $DISTRO"
        echo "Please install git, zsh, gh, curl, jq, and powerline-fonts manually"
        ;;
esac

# Install n (node version manager)
if ! command -v n &> /dev/null; then
    echo "📦 Installing n (node version manager)..."
    curl -L https://git.io/n-install | bash -s -- -y
    export N_PREFIX="$HOME/.n"
    export PATH="$N_PREFIX/bin:$PATH"
else
    echo "✅ n already installed"
fi

# Install Node.js LTS
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js LTS..."
    n lts
else
    echo "✅ Node.js already installed ($(node --version))"
fi

# Install Sheldon (Zsh plugin manager)
if ! command -v sheldon &> /dev/null; then
    echo "📦 Installing Sheldon plugin manager..."
    if command -v cargo &> /dev/null; then
        cargo install sheldon
    else
        curl --proto '=https' -fLsS https://rosav0.github.io/sheldon/install.sh | bash
    fi
else
    echo "✅ Sheldon already installed"
fi

# Install Starship prompt
if ! command -v starship &> /dev/null; then
    echo "📦 Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "✅ Starship already installed"
fi

echo "✅ Linux setup complete"
