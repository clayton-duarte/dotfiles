# =============================================================================
# Zsh Environment Variables
# =============================================================================
# Loaded first by Zsh — env vars and PATH only, no interactive features
# This file is symlinked from ~/dotfiles/.config/zsh/.zshenv → ~/.zshenv

# Tell Zsh to look for .zshrc in our config directory
export ZDOTDIR="${HOME}/.config/zsh"

# =============================================================================
# Core Environment Variables
# =============================================================================
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export BASE_BRANCH="main"

# Claude Code / Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION="global"
export ANTHROPIC_VERTEX_PROJECT_ID="team-engineering-dev-wfuk"

# =============================================================================
# Platform-specific Configuration
# =============================================================================
case "$(uname)" in
    Linux)
        # Set JAVA_HOME for Linux (common paths)
        if [[ -d /usr/lib/jvm/java-17-openjdk-amd64 ]]; then
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
        elif [[ -d /usr/lib/jvm/default-java ]]; then
            export JAVA_HOME="/usr/lib/jvm/default-java"
        fi

        # Persistent ssh-agent (reuse across sessions via socket file)
        # Handles stale sockets from dead agents (e.g. after reboot)
        SSH_AGENT_SOCK="${HOME}/.ssh/agent.sock"
        export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
        ssh-add -l &>/dev/null
        ssh_status=$?
        if [[ $ssh_status -eq 2 ]]; then
            # Agent unreachable — remove stale socket and start fresh
            rm -f "$SSH_AGENT_SOCK"
            eval "$(ssh-agent -a "$SSH_AGENT_SOCK" 2>/dev/null)" > /dev/null
        fi
        ;;
    Darwin)
        # Set JAVA_HOME to Android Studio's bundled JDK
        export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
        # Override 1Password SSH agent — use macOS system agent instead
        # (1Password agent only serves SSH_KEY category items, not our Secure Note key)
        export SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null)"
        ;;
    *)
        echo "⚠️  Unsupported OS"
        return 1
        ;;
esac

# =============================================================================
# PATH
# =============================================================================
typeset -U path  # Deduplicate PATH entries

path=(
    /usr/local/bin
    "${ANDROID_HOME}/emulator"
    "${ANDROID_HOME}/platform-tools"
    "${ANDROID_HOME}/cmdline-tools/latest/bin"
    "${ANDROID_HOME}/tools/bin"
    "${ANDROID_HOME}/tools"
    "${HOME}/.maestro/bin"
    $path
)

# Platform-specific PATH additions
case "$(uname)" in
    Darwin)
        # Initialize Homebrew environment
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        # Add VS Code to PATH
        path=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $path)
        ;;
esac

export PATH
