#!/bin/bash
# =============================================================================
# 1Password Secrets Loader
# =============================================================================
# This script fetches secrets from 1Password and generates ~/.config/fish/secrets.fish
# Run this after bootstrap or when you need to refresh secrets

set -e

echo "🔐 Fetching secrets from 1Password..."

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI not installed. Run bootstrap.sh first."
    exit 1
fi

# Check if authenticated
if ! op account list &> /dev/null; then
    echo "🔑 Please authenticate with 1Password..."
    eval $(op signin)
fi

# Create secrets.fish file
SECRETS_FILE="$HOME/.config/fish/secrets.fish"
mkdir -p "$(dirname "$SECRETS_FILE")"
cat > "$SECRETS_FILE" << 'EOF'
# =============================================================================
# Auto-generated secrets from 1Password
# =============================================================================
# DO NOT COMMIT THIS FILE TO GIT
# Generated: $(date)

EOF

echo "📥 Fetching API tokens from Private vault..."

# Dynamically fetch ALL fields from "Development API Tokens" item
# This way, new tokens are automatically available without code changes!

ITEM_JSON=$(op item get "Development API Tokens" --account=my.1password.com --format=json 2>/dev/null)

if [ $? -eq 0 ]; then
    # Extract all fields that look like tokens (not title, category, etc.)
    echo "$ITEM_JSON" | jq -r '.fields[] | select(.value != null and .value != "") | "export \(.label)=\"\(.value)\""' >> "$SECRETS_FILE"

    # Count and report
    TOKEN_COUNT=$(echo "$ITEM_JSON" | jq -r '.fields[] | select(.value != null and .value != "") | .label' | wc -l | tr -d ' ')
    echo "  ✓ Loaded $TOKEN_COUNT tokens:"
    echo "$ITEM_JSON" | jq -r '.fields[] | select(.value != null and .value != "") | "    - \(.label)"'
else
    echo "  ⚠️  Could not fetch Development API Tokens from 1Password"
    echo "  Make sure you're authenticated: eval \$(op signin)"
fi

# Set permissions on secrets file
chmod 600 "$SECRETS_FILE"

echo ""
echo "🔑 Fetching SSH keys..."

# Create .ssh directory if it doesn't exist
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# GitHub SSH Key (OpenSSH format - compatible with all OpenSSH versions)
if op read "op://Private/GH SSH Key/private key" --account=my.1password.com &> /dev/null; then
    op read "op://Private/GH SSH Key/private key" --account=my.1password.com > "$HOME/.ssh/id_ed25519"
    chmod 600 "$HOME/.ssh/id_ed25519"
    echo "  ✓ GitHub SSH private key"

    # Also get the public key if available
    if op read "op://Private/GH SSH Key/public key" --account=my.1password.com &> /dev/null; then
        op read "op://Private/GH SSH Key/public key" --account=my.1password.com > "$HOME/.ssh/id_ed25519.pub"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        echo "  ✓ GitHub SSH public key"

        # Add public key to authorized_keys for SSH access from other machines
        if ! grep -q "$(cat $HOME/.ssh/id_ed25519.pub)" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
            cat "$HOME/.ssh/id_ed25519.pub" >> "$HOME/.ssh/authorized_keys"
            chmod 600 "$HOME/.ssh/authorized_keys"
            echo "  ✓ Added public key to authorized_keys"
        else
            echo "  ✓ Public key already in authorized_keys"
        fi
    fi
else
    echo "  ⚠️  GitHub SSH key not found"
fi

echo ""
echo "✅ Secrets loaded successfully"
echo ""
echo "📝 Loaded:"
echo "   - API tokens → ~/.config/fish/secrets.fish"
echo "   - SSH keys → ~/.ssh/id_ed25519"
