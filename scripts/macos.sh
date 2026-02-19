#!/bin/bash
# =============================================================================
# macOS Setup Script
# Reads packages from packages.json and installs via Homebrew
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_JSON="$SCRIPT_DIR/../packages.json"

echo "🍎 Setting up macOS..."

# Install Homebrew if needed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew already installed"
fi

# Bootstrap jq first (needed to parse packages.json)
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq (needed to parse packages.json)..."
    brew install jq
fi

# Generate Brewfile from packages.json
echo "📦 Installing packages from packages.json..."

BREWFILE=$(mktemp)
trap "rm -f $BREWFILE" EXIT

# Extract brew formulae
jq -r 'to_entries[] | select(.value.brew) | "brew \"\(.value.brew)\"" ' "$PACKAGES_JSON" >> "$BREWFILE"

# Extract cask apps
jq -r 'to_entries[] | select(.value.cask) | "cask \"\(.value.cask)\"" ' "$PACKAGES_JSON" >> "$BREWFILE"

echo "  Generated Brewfile:"
sed 's/^/    /' "$BREWFILE"

brew bundle --file="$BREWFILE"

# Install Node.js LTS via n
if command -v n &> /dev/null; then
    if ! command -v node &> /dev/null; then
        echo "📦 Installing Node.js LTS..."
        n lts
    else
        echo "✅ Node.js already installed ($(node --version))"
    fi
fi

echo "✅ macOS setup complete"
