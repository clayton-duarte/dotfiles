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
