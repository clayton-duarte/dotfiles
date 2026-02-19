# =============================================================================
# SSH Management
# =============================================================================

ssh() {
    case "$1" in
        test|"")
            command ssh -T git@github.com
            ;;
        tunnel)
            command ssh -f -N -D 8015 ml
            ;;
        *)
            command ssh "$@"
            ;;
    esac
}
