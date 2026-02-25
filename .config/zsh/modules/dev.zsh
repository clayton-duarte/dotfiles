# =============================================================================
# Development Tools
# =============================================================================

ios() {
    command npm run ios
}

android() {
    command npm run android
}

kill-port() {
    case "$(uname)" in
        Darwin)
            command lsof -i "tcp:$1" | awk 'NR!=1 {print $2}' | xargs kill
            ;;
        Linux)
            command fuser -k "$1/tcp"
            ;;
    esac
}

npm() {
    case "$1" in
        deps|check|depcheck)
            command npx depcheck
            command npx npm-check-updates
            ;;
        *)
            command npm "$@"
            ;;
    esac
}

# =============================================================================
# 1Password Environment Injection
# =============================================================================
# Use op:// references in .env files → resolved at runtime via 1Password.
# Secrets are NEVER written to disk — injected into process env only.
#
# Example .env.op file:
#   DATABASE_URL=op://Private/Environment/DATABASE_URL
#   STRIPE_KEY=op://Private/Environment/STRIPE_KEY
#   ML_API_KEY=op://Private/Environment/ML_API_KEY
#
# Usage:
#   op-env                    # loads .env.op, starts subshell
#   op-env .env.staging       # loads custom env file
#   op-env .env.op npm start  # runs command with injected env vars
#   op-env .env.op -- make    # runs command after -- separator

op-env() {
    if ! command -v op &> /dev/null; then
        echo "❌ 1Password CLI not installed"
        return 1
    fi

    # Parse arguments: [env-file] [--] [command...]
    local env_file=".env.op"
    local cmd=()

    # First arg could be an env file
    if [[ -n "$1" ]] && [[ "$1" != "--" ]] && [[ -f "$1" ]]; then
        env_file="$1"
        shift
    fi

    # Skip -- separator if present
    [[ "$1" == "--" ]] && shift

    # Remaining args are the command
    cmd=("$@")

    if [[ ! -f "$env_file" ]]; then
        echo "❌ Environment file not found: $env_file"
        echo ""
        echo "Create one with op:// references:"
        echo "  DATABASE_URL=op://Private/Environment/DATABASE_URL"
        echo "  STRIPE_KEY=op://Private/Environment/STRIPE_KEY"
        return 1
    fi

    if [[ ${#cmd[@]} -eq 0 ]]; then
        # No command — inject env and start interactive subshell
        echo "🔐 Loading environment from $env_file..."
        op run --env-file="$env_file" -- zsh
    else
        # Run the specified command with injected env
        op run --env-file="$env_file" -- "${cmd[@]}"
    fi
}
