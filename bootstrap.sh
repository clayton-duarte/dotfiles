#!/bin/bash
# =============================================================================
# Bootstrap Script for Fresh Machine
# =============================================================================
# Prerequisite: git and 1Password must be installed
# Usage: ./bootstrap.sh
#
# Supports two modes:
#   Interactive (macOS/Desktop): biometric auth, 1Password shell plugins
#   Headless (Linux servers):    OP_SERVICE_ACCOUNT_TOKEN env var
#
# Set OP_SERVICE_ACCOUNT_TOKEN before running on headless machines:
#   export OP_SERVICE_ACCOUNT_TOKEN="ops_..."
#   ./bootstrap.sh

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

# Detect if running headless (no display + Linux)
HEADLESS=false
if [[ "$OS" == "linux" ]] && [[ -z "${DISPLAY}" ]] && [[ -z "${WAYLAND_DISPLAY}" ]]; then
    HEADLESS=true
fi

echo "📍 Detected OS: $OS$(${HEADLESS} && echo ' (headless)')"
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
        sudo gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

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
if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN}" ]]; then
    # Service account mode (headless servers)
    if op whoami &> /dev/null; then
        echo "✅ Authenticated via service account"
    else
        echo "❌ OP_SERVICE_ACCOUNT_TOKEN is set but authentication failed"
        echo "   Check that the token is valid and has access to the required vaults"
        exit 1
    fi
elif ! op whoami &> /dev/null; then
    echo "🔑 Please sign in to 1Password..."
    eval "$(op signin)" || {
        echo "❌ Failed to authenticate with 1Password"
        echo "Please check your credentials and try again"
        echo ""
        echo "💡 For headless servers, set OP_SERVICE_ACCOUNT_TOKEN:"
        echo "   export OP_SERVICE_ACCOUNT_TOKEN=\"ops_...\""
        exit 1
    }
    if ! op whoami &> /dev/null; then
        echo "❌ Authentication failed"
        exit 1
    fi
    echo "✅ Authenticated with 1Password"
else
    echo "✅ Already authenticated with 1Password"
fi

echo ""

# Define the vault name (single source of truth)
OP_VAULT="Private"

# 3. Verify the Private vault exists
echo "🗄️  Checking 1Password vault..."
if op vault get "$OP_VAULT" &> /dev/null; then
    echo "✅ Vault '$OP_VAULT' found"
else
    echo "❌ Vault '$OP_VAULT' not found in 1Password"
    echo ""
    echo "Create it and add these items:"
    echo ""
    echo "  1. op vault create $OP_VAULT"
    echo ""
    echo "  2. SSH Key (SSH Key type):"
    echo "     op item create --vault $OP_VAULT --category 'SSH Key' --title 'SSH Key' \\"
    echo "       --ssh-key 'private key'=\$(cat ~/.ssh/id_ed25519) \\"
    echo "       'public key'=\$(cat ~/.ssh/id_ed25519.pub)"
    echo ""
    echo "  3. GitHub CLI (API Credential type):"
    echo "     op item create --vault $OP_VAULT --category 'API Credential' --title 'GitHub CLI' \\"
    echo "       'credential=ghp_your_token_here'"
    echo ""
    echo "  4. Environment (Secure Note with env var fields):"
    echo "     op item create --vault $OP_VAULT --category 'Secure Note' --title 'Environment' \\"
    echo "       'STRIPE_KEY=sk_live_...' \\"
    echo "       'DATABASE_URL=postgres://...'"
    echo ""
    echo "  For service accounts (headless servers):"
    echo "     Grant the service account read access to the $OP_VAULT vault"
    echo ""
    exit 1
fi

echo ""

# 4. Install essential tools for the OS
echo "📦 Installing essential tools..."
chmod +x ./scripts/${OS}.sh
./scripts/${OS}.sh

echo ""

# 5. Pull secrets from 1Password
echo "🔑 Fetching secrets from 1Password..."
# Source instead of execute to preserve 1Password session
source ./scripts/secrets.sh

echo ""

# 6. Symlink dotfiles
echo "🔗 Symlinking dotfiles..."
chmod +x ./scripts/install.sh
./scripts/install.sh

echo ""

# 7. Set zsh as default shell
if [[ "$SHELL" == *"zsh"* ]]; then
    echo "✅ Zsh is already default shell"
else
    echo "🐚 Setting zsh as default shell..."

    # Get zsh path (prefer Homebrew zsh on macOS)
    if [[ "$OS" == "macos" ]] && [[ -f /opt/homebrew/bin/zsh ]]; then
        ZSH_PATH="/opt/homebrew/bin/zsh"
    else
        ZSH_PATH=$(which zsh)
    fi

    # Check if zsh is in /etc/shells
    if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
        echo "  Adding zsh to /etc/shells (requires sudo)..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi

    echo "  Setting zsh as default shell (requires password)..."
    chsh -s "$ZSH_PATH"
    echo "✅ Zsh set as default shell"
fi

echo ""

# 8. Configure git
echo "👤 Configuring git..."
git config --global user.email "cpd@duck.com"
git config --global user.name "cpd"
git config --global push.autoSetupRemote true
git config --global push.useForceIfIncludes true
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global merge.ff false
git config --global rebase.autoStash true

# Git SSH signing
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedSignersFile "~/.ssh/allowed_signers"

# Create allowed_signers file for commit verification
mkdir -p "$HOME/.ssh"
if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    PUBKEY=$(cat "$HOME/.ssh/id_ed25519.pub")
    echo "cpd@duck.com ${PUBKEY}" > "$HOME/.ssh/allowed_signers"
    echo "  ✓ Git SSH allowed_signers updated"
else
    echo "  ⚠️  SSH public key not yet available (secrets.sh will set this up)"
fi

# Configure git SSH signing (key-file based, works on all platforms)
# No op-ssh-sign needed — standard ssh-keygen handles signing
if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    PUBKEY_CONTENT=$(awk '{print $1" "$2}' "$HOME/.ssh/id_ed25519.pub")
    git config --global user.signingkey "$PUBKEY_CONTENT"
    git config --global --unset gpg.ssh.program 2>/dev/null || true
    echo "  ✓ Git signing via SSH key file"
else
    echo "  ⚠️  SSH public key not yet available (secrets.sh will set this up)"
fi

# Configure gh credential helper (platform-specific path)
if command -v gh &> /dev/null; then
    case "$OS" in
        macos)
            GH_PATH="/opt/homebrew/bin/gh"
            ;;
        linux)
            GH_PATH=$(which gh)
            ;;
    esac
    git config --global credential.https://github.com.helper ""
    git config --global credential.https://github.com.helper "!${GH_PATH} auth git-credential"
    git config --global credential.https://gist.github.com.helper ""
    git config --global credential.https://gist.github.com.helper "!${GH_PATH} auth git-credential"
    echo "  ✓ Git credential helper configured for GitHub CLI"
fi

# Set editor to code only on non-headless machines
if ${HEADLESS}; then
    git config --global core.editor "vim"
else
    git config --global core.editor "code --wait"
fi

echo "✅ Git configured"
echo ""

# 9. Setup 1Password shell plugins (gh, aws, etc.)
echo "🔌 Setting up 1Password shell plugins..."
if ! ${HEADLESS} && command -v gh &> /dev/null; then
    if [[ ! -f "${HOME}/.config/op/plugins.sh" ]]; then
        echo "  Initializing gh plugin..."
        op plugin init gh 2>/dev/null && \
            echo "  ✓ GitHub CLI shell plugin configured" || \
            echo "  ⚠️  Could not init gh plugin (set up manually: op plugin init gh)"
    else
        echo "  ✓ Shell plugins already configured"
    fi
else
    if ${HEADLESS}; then
        echo "  ⚠️  Headless mode — skipping shell plugins (gh uses token from 1Password)"
    fi
fi
echo ""

# 10. Initialize git repo for dotfiles (if not already initialized)
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
echo "  1. Restart your terminal (exec zsh)"
echo "  2. Your config will auto-sync on terminal startup"
echo "  3. Use 'config edit' to edit configs"
echo "  4. Use 'op-env' in projects with op://Private/... references"
if ${HEADLESS}; then
    echo ""
    echo "Headless mode notes:"
    echo "  - Persist OP_SERVICE_ACCOUNT_TOKEN in your server's environment"
    echo "  - Git signing uses SSH key file (~/.ssh/id_ed25519)"
fi
echo ""
