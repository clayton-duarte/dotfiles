# =============================================================================
# Dotfiles Management
# =============================================================================

secrets-refresh() {
    ~/dotfiles/scripts/secrets.sh

    if [[ -f "${ZDOTDIR}/secrets.zsh" ]]; then
        source "${ZDOTDIR}/secrets.zsh"
    fi
}

dotfiles-install() {
    ~/dotfiles/scripts/install.sh
}

config() {
    case "$1" in
        edit|-e|e)
            local prev_dir="$PWD"
            cd ~/dotfiles
            git pull --quiet
            code ~/dotfiles
            cd "$prev_dir"
            ;;
        sync|-s|s)
            local prev_dir="$PWD"
            cd ~/dotfiles
            git add .
            git commit -m "Manual sync from $(hostname) at $(date +%Y-%m-%d-%H-%M-%S)"
            git push
            cd "$prev_dir"
            echo "✓ Synced"
            ;;
        reload|-r|r)
            source "${ZDOTDIR}/.zshrc"
            echo "✓ Reloaded"
            ;;
        status)
            local prev_dir="$PWD"
            cd ~/dotfiles
            git status
            cd "$prev_dir"
            ;;
        install|-i|i)
            dotfiles-install
            ;;
        secrets)
            secrets-refresh
            ;;
        *)
            echo "Usage: config [edit|sync|reload|status|install|secrets]"
            echo "  edit    - Open dotfiles in VS Code"
            echo "  sync    - Manually commit and push changes"
            echo "  reload  - Reload zsh config"
            echo "  status  - Show git status"
            echo "  install - Create symlinks to dotfiles"
            echo "  secrets - Refresh secrets from 1Password"
            ;;
    esac
}

# =============================================================================
# Auto-sync dotfiles on startup
# =============================================================================
__dotfiles_sync() {
    # Only sync if dotfiles repo exists
    if [[ ! -d ~/dotfiles/.git ]]; then
        return
    fi

    # Determine timeout command (gtimeout on macOS via coreutils, timeout on Linux)
    local timeout_cmd=""
    if command -v gtimeout &>/dev/null; then
        timeout_cmd="gtimeout"
    elif command -v timeout &>/dev/null; then
        timeout_cmd="timeout"
    fi

    # Start animated spinner in background
    local spinner_pid=0
    (
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        while true; do
            for frame in "${frames[@]}"; do
                echo -ne "\r\033[K\033[90m${frame}\033[0m "
                sleep 0.08
            done
        done
    ) &
    spinner_pid=$!
    disown $spinner_pid  # Detach from job control to suppress termination messages

    # Save current directory
    local prev_dir="$PWD"
    cd ~/dotfiles 2>/dev/null || return

    # Fetch quietly with timeout (5 seconds)
    local fetch_status=0
    if [[ -n "$timeout_cmd" ]]; then
        $timeout_cmd 5s git fetch --quiet 2>/dev/null || fetch_status=$?
    else
        git fetch --quiet 2>/dev/null || fetch_status=$?
    fi
    if [[ $fetch_status -ne 0 ]]; then
        kill $spinner_pid 2>/dev/null
        cd "$prev_dir"
        if [[ $fetch_status -eq 124 ]]; then
            echo -e "\r\033[K\033[90m⚠️  Dotfiles sync timed out\033[0m"
        else
            echo -e "\r\033[K\033[90m⚠️  Dotfiles: fetch failed\033[0m"
        fi
        return
    fi

    # Check for uncommitted changes and commit them
    local status_output
    status_output=$(git status --porcelain 2>/dev/null)
    if [[ -n "$status_output" ]]; then
        git add . 2>/dev/null
        git commit -m "Auto-sync from $(hostname) at $(date +%Y-%m-%d\ %H:%M:%S)" --quiet 2>/dev/null
    fi

    # Check git status
    local local_commit remote_commit base_commit
    local_commit=$(git rev-parse @ 2>/dev/null)
    remote_commit=$(git rev-parse '@{u}' 2>/dev/null)
    base_commit=$(git merge-base @ '@{u}' 2>/dev/null)

    if [[ "$local_commit" == "$remote_commit" ]]; then
        # Up to date
        kill $spinner_pid 2>/dev/null
        echo -e "\r\033[K"
    elif [[ "$local_commit" == "$base_commit" ]]; then
        # Need to pull
        local pull_status=0
        if [[ -n "$timeout_cmd" ]]; then
            $timeout_cmd 10s git pull --quiet --rebase 2>/dev/null || pull_status=$?
        else
            git pull --quiet --rebase 2>/dev/null || pull_status=$?
        fi
        kill $spinner_pid 2>/dev/null
        if [[ $pull_status -ne 0 ]]; then
            if [[ $pull_status -eq 124 ]]; then
                echo -e "\r\033[K\033[90m⚠️  Dotfiles pull timed out\033[0m"
            else
                echo -e "\r\033[K\033[90m⚠️  Dotfiles: pull failed\033[0m"
            fi
            cd "$prev_dir"
            return
        fi
        echo -e "\r\033[K"
    elif [[ "$remote_commit" == "$base_commit" ]]; then
        # Need to push
        local push_status=0
        if [[ -n "$timeout_cmd" ]]; then
            $timeout_cmd 10s git push --quiet 2>/dev/null || push_status=$?
        else
            git push --quiet 2>/dev/null || push_status=$?
        fi
        kill $spinner_pid 2>/dev/null
        if [[ $push_status -ne 0 ]]; then
            if [[ $push_status -eq 124 ]]; then
                echo -e "\r\033[K\033[90m⚠️  Dotfiles push timed out\033[0m"
            else
                echo -e "\r\033[K\033[90m⚠️  Dotfiles: push failed\033[0m"
            fi
            cd "$prev_dir"
            return
        fi
        echo -e "\r\033[K"
    else
        # Diverged
        kill $spinner_pid 2>/dev/null
        echo -e "\r\033[K\033[90m⚠️  Dotfiles diverged\033[0m"
    fi

    cd "$prev_dir"
}
