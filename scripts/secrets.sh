#!/bin/bash
# =============================================================================
# 1Password Secrets Loader
# =============================================================================
# Fetches secrets from the Private vault in 1Password.
# Run via: config secrets (or ./scripts/secrets.sh directly)
#
# On headless servers, set OP_SERVICE_ACCOUNT_TOKEN for non-interactive auth.
#
# Items (all in Private vault):
#   SSH Key      — private key, public key
#   Environment  — one field per env var (incl. GH_TOKEN)

set -e

OP_VAULT="Private"

echo "🔐 Fetching secrets from 1Password ($OP_VAULT vault)..."

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI not installed. Run bootstrap.sh first."
    exit 1
fi

# Authenticate — service accounts work automatically via OP_SERVICE_ACCOUNT_TOKEN
if ! op whoami &> /dev/null; then
    if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN}" ]]; then
        echo "❌ OP_SERVICE_ACCOUNT_TOKEN is set but authentication failed"
        echo "   Check that the token is valid and has access to the $OP_VAULT vault"
        exit 1
    fi
    echo "🔑 Please sign in to 1Password..."
    eval "$(op signin)" || {
        echo "❌ Failed to authenticate with 1Password"
        exit 1
    }
    if ! op whoami &> /dev/null; then
        echo "❌ Authentication failed"
        exit 1
    fi
fi

# Verify vault exists
if ! op vault get "$OP_VAULT" &> /dev/null; then
    echo "❌ Vault '$OP_VAULT' not found in 1Password"
    exit 1
fi

# =============================================================================
# 1. Environment variables (Secure Note "Environment" → secrets.zsh)
# =============================================================================
SECRETS_FILE="$HOME/.config/zsh/secrets.zsh"
mkdir -p "$(dirname "$SECRETS_FILE")"
cat > "$SECRETS_FILE" << EOF
# =============================================================================
# Auto-generated secrets from 1Password ($OP_VAULT vault)
# =============================================================================
# DO NOT COMMIT THIS FILE TO GIT
# Generated: $(date)

EOF

echo "📥 Fetching environment secrets..."

# Dynamically fetch ALL fields from the "Environment" Secure Note.
# Add new secrets as fields in 1Password → they appear as env vars automatically.
# Use field labels like: STRIPE_KEY, DATABASE_URL, GITHUB_TOKEN, etc.
ITEM_JSON=$(op item get "Environment" --vault "$OP_VAULT" --format=json 2>/dev/null)

if [ $? -eq 0 ]; then
    # Extract fields from the item (skip metadata fields like notesPlain, password)
    echo "$ITEM_JSON" | jq -r '
        .fields[]
        | select(.value != null and .value != "")
        | select(.id != "notesPlain")
        | select(.id != "password")
        | select(.label != "" and .label != null)
        | "export \(.label)=\"\(.value)\""'\
        >> "$SECRETS_FILE"

    TOKEN_COUNT=$(echo "$ITEM_JSON" | jq -r '
        .fields[]
        | select(.value != null and .value != "")
        | select(.id != "notesPlain")
        | select(.id != "password")
        | select(.label != "" and .label != null)
        | .label' | wc -l | tr -d ' ')
    echo "  ✓ Loaded $TOKEN_COUNT env vars:"
    echo "$ITEM_JSON" | jq -r '
        .fields[]
        | select(.value != null and .value != "")
        | select(.id != "notesPlain")
        | select(.id != "password")
        | select(.label != "" and .label != null)
        | "    - \(.label)"'
else
    echo "  ⚠️  'Environment' item not found in $OP_VAULT vault"
fi

chmod 600 "$SECRETS_FILE"

# =============================================================================
# 2. SSH keys
# =============================================================================
echo ""
echo "🔑 Fetching SSH keys..."

SSH_VAULT="$OP_VAULT"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if op read "op://${SSH_VAULT}/SSH Key/public key" &> /dev/null; then
    # Public key — always needed (allowed_signers, git signing, authorized_keys)
    op read "op://${SSH_VAULT}/SSH Key/public key" > "$HOME/.ssh/id_ed25519.pub"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    echo "  ✓ SSH public key"

    # allowed_signers for git commit verification
    PUBKEY=$(cat "$HOME/.ssh/id_ed25519.pub")
    echo "cpd@duck.com ${PUBKEY}" > "$HOME/.ssh/allowed_signers"
    echo "  ✓ Updated allowed_signers"

    # authorized_keys for inbound SSH
    if ! grep -q "$(cat $HOME/.ssh/id_ed25519.pub)" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
        cat "$HOME/.ssh/id_ed25519.pub" >> "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "  ✓ Added to authorized_keys"
    fi

    # Private key — needed on headless servers (no 1Password agent)
    # On interactive machines, 1Password agent handles SSH via SSH_AUTH_SOCK
    if op read "op://${SSH_VAULT}/SSH Key/private key" &> /dev/null; then
        op read "op://${SSH_VAULT}/SSH Key/private key" > "$HOME/.ssh/id_ed25519"
        chmod 600 "$HOME/.ssh/id_ed25519"
        echo "  ✓ SSH private key"
    fi
else
    echo "  ⚠️  'SSH Key' item not found in $SSH_VAULT vault"
fi

# =============================================================================
# 3. Git signing (op-ssh-sign on interactive, key-file on headless)
# =============================================================================
echo ""
echo "🔏 Configuring git signing..."

if [[ "$(uname)" == "Darwin" ]]; then
    OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
else
    OP_SSH_SIGN="/opt/1Password/op-ssh-sign"
fi

if [[ -f "$OP_SSH_SIGN" ]]; then
    git config --global gpg.ssh.program "$OP_SSH_SIGN"
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        PUBKEY_CONTENT=$(awk '{print $1" "$2}' "$HOME/.ssh/id_ed25519.pub")
        git config --global user.signingkey "$PUBKEY_CONTENT"
    fi
    echo "  ✓ Git signing via 1Password (biometric)"
else
    git config --global user.signingkey "~/.ssh/id_ed25519"
    echo "  ✓ Git signing via SSH key file"
fi

# =============================================================================
# 4. GitHub CLI authentication (GH_TOKEN from Environment item)
# =============================================================================
echo ""
echo "🔑 Authenticating GitHub CLI..."

if command -v gh &> /dev/null; then
    # Shell plugin handles auth transparently (set up by bootstrap.sh)
    if [[ -f "${HOME}/.config/op/plugins.sh" ]] && grep -q "gh" "${HOME}/.config/op/plugins.sh" 2>/dev/null; then
        echo "  ✓ GitHub CLI managed by 1Password shell plugin"
    elif ! gh auth status &> /dev/null; then
        # GH_TOKEN is already in secrets.zsh from the Environment item
        GH_TOKEN=$(op read "op://${OP_VAULT}/Environment/GH_TOKEN" 2>/dev/null)
        if [[ -n "$GH_TOKEN" ]]; then
            echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null && \
            echo "  ✓ GitHub CLI authenticated" || \
            echo "  ⚠️  GitHub CLI authentication failed"
        else
            echo "  ⚠️  GH_TOKEN not found in $OP_VAULT/Environment"
        fi
    else
        echo "  ✓ GitHub CLI already authenticated"
    fi
else
    echo "  ⚠️  GitHub CLI not installed"
fi

echo ""
echo "✅ Secrets loaded"
echo ""
echo "📝 Summary:"
echo "   - Env vars  → ~/.config/zsh/secrets.zsh  (from $OP_VAULT/Environment)"
echo "   - SSH keys  → ~/.ssh/id_ed25519{,.pub}    (from $OP_VAULT/SSH Key)"
echo "   - Git signing configured"
echo "   - GitHub CLI authenticated                (from $OP_VAULT/Environment/GH_TOKEN)"
