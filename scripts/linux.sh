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
        echo "📦 Installing packages (Debian/Ubuntu)..."
        sudo apt update
        sudo apt install -y \
            git \
            fish \
            curl \
            wget \
            build-essential \
            gh
        ;;
    fedora)
        echo "📦 Installing packages (Fedora)..."
        sudo dnf install -y \
            git \
            fish \
            curl \
            wget \
            gcc \
            make \
            gh
        ;;
    arch)
        echo "📦 Installing packages (Arch)..."
        sudo pacman -S --noconfirm \
            git \
            fish \
            curl \
            wget \
            base-devel \
            github-cli
        ;;
    *)
        echo "⚠️  Unsupported distribution: $DISTRO"
        echo "Please install git, fish, and gh manually"
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
