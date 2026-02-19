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
    command lsof -i "tcp:$1" | awk 'NR!=1 {print $2}' | xargs kill
}

killport() {
    command sudo fuser -k "$1/tcp"
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
