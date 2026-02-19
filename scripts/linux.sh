#!/bin/bash
# =============================================================================
# Linux Setup Script
# Reads packages from packages.json and installs via system package manager
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_JSON="$SCRIPT_DIR/../packages.json"

echo "🐧 Setting up Linux..."

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution"
    exit 1
fi

echo "📍 Detected distro: $DISTRO"

# =============================================================================
# Helper: install package manager packages
# =============================================================================
install_packages() {
    local pm_key="$1"
    shift
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo "  No packages to install for $pm_key"
        return
    fi

    case $DISTRO in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y "${packages[@]}"
            ;;
        fedora|bazzite*)
            # Bazzite is immutable — try rpm-ostree first, fall back to dnf
            sudo rpm-ostree install -y "${packages[@]}" 2>/dev/null || \
            sudo dnf install -y "${packages[@]}"
            ;;
        arch|steamos*|holo*)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        *)
            echo "⚠️  Unsupported distribution: $DISTRO"
            echo "Please install manually: ${packages[*]}"
            ;;
    esac
}

# =============================================================================
# Determine package manager key for this distro
# =============================================================================
case $DISTRO in
    ubuntu|debian)      PM_KEY="apt" ;;
    fedora|bazzite*)    PM_KEY="dnf" ;;
    arch|steamos*|holo*) PM_KEY="pacman" ;;
    *)
        echo "⚠️  Unsupported distribution: $DISTRO"
        echo "Please install packages manually (see packages.json)"
        exit 1
        ;;
esac

# =============================================================================
# Bootstrap jq first (needed to parse packages.json)
# =============================================================================
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq (needed to parse packages.json)..."
    install_packages "$PM_KEY" "jq"
fi

# =============================================================================
# Install packages from packages.json
# =============================================================================
echo "📦 Installing packages from packages.json..."

# Collect packages that have a native name for this distro's package manager
NATIVE_PACKAGES=()
while IFS= read -r pkg; do
    NATIVE_PACKAGES+=("$pkg")
done < <(jq -r --arg key "$PM_KEY" 'to_entries[] | select(.value[$key]) | .value[$key]' "$PACKAGES_JSON")

if [ ${#NATIVE_PACKAGES[@]} -gt 0 ]; then
    echo "  Native packages ($PM_KEY): ${NATIVE_PACKAGES[*]}"
    install_packages "$PM_KEY" "${NATIVE_PACKAGES[@]}"
fi

# =============================================================================
# Run install_cmd for packages without a native name on this distro
# =============================================================================
while IFS= read -r cmd; do
    if [ -n "$cmd" ]; then
        echo "📦 Running custom install command..."
        echo "  $ $cmd"
        eval "$cmd"
    fi
done < <(jq -r --arg key "$PM_KEY" 'to_entries[] | select(.value[$key] == null and .value.install_cmd) | .value.install_cmd' "$PACKAGES_JSON")

# =============================================================================
# Post-install: Node.js via n
# =============================================================================
if command -v n &> /dev/null || [ -f "$HOME/.n/bin/n" ]; then
    export N_PREFIX="$HOME/.n"
    export PATH="$N_PREFIX/bin:$PATH"
    if ! command -v node &> /dev/null; then
        echo "📦 Installing Node.js LTS..."
        n lts
    else
        echo "✅ Node.js already installed ($(node --version))"
    fi
fi

echo "✅ Linux setup complete"
