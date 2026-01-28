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
            fish \
            curl \
            jq \
            gh \
            fonts-powerline \
            neofetch

        # Install Google Cloud SDK
        echo "📦 Installing Google Cloud SDK..."
        if ! command -v gcloud &> /dev/null; then
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
            sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
            sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

            sudo apt update && sudo apt install -y google-cloud-sdk
        else
            echo "✅ Google Cloud SDK already installed"
        fi
        ;;
    fedora|bazzite*)
        echo "📦 Installing essential packages (Fedora/Bazzite)..."
        # Bazzite is immutable, packages should be layered
        sudo rpm-ostree install -y \
            git \
            fish \
            curl \
            jq \
            gh \
            powerline-fonts \
            neofetch || \
        sudo dnf install -y \
            git \
            fish \
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
            fish \
            curl \
            jq \
            github-cli \
            powerline-fonts \
            neofetch
        ;;
    *)
        echo "⚠️  Unsupported distribution: $DISTRO"
        echo "Please install git, fish, gh, curl, jq, and powerline-fonts manually"
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

echo "✅ Linux setup complete"
