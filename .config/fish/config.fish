# =============================================================================
# Fish Shell Configuration
# =============================================================================
# This config is managed in ~/dotfiles and symlinked to ~/.config/fish/config.fish
# Auto-syncs with git on terminal startup

# Disable Fish greeting
set fish_greeting

# =============================================================================
# Theme Settings
# =============================================================================
# Disable branch name truncation in agnoster theme
set -g fish_vcs_branch_name_length 99

# Show neofetch on terminal startup (once per session)
function __show_neofetch --on-event fish_prompt
    # Only run once per session
    if set -q __neofetch_shown
        return
    end
    set -g __neofetch_shown 1

    # Only show if neofetch is installed
    if command -v neofetch &> /dev/null
        neofetch
    end
end

# =============================================================================
# Secrets Management Functions
# =============================================================================

function secrets-refresh --description "Fetch secrets from 1Password"
    # Call the bash script instead of duplicating logic
    ~/dotfiles/scripts/secrets.sh

    # Source the secrets file to make them available immediately
    if test -f ~/.config/fish/secrets.fish
        source ~/.config/fish/secrets.fish
    end
end

# =============================================================================
# Load secrets from file (refresh with 'config secrets')
# =============================================================================
# Load existing secrets file if available
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# =============================================================================
# Auto-sync dotfiles on startup
# =============================================================================
function __dotfiles_sync --on-event fish_prompt --description "Auto-sync dotfiles with git"
    # Only run once per session
    if set -q __dotfiles_synced
        return
    end
    set -g __dotfiles_synced 1

    # Only sync if dotfiles repo exists
    if not test -d ~/dotfiles/.git
        return
    end

    # Determine timeout command (gtimeout on macOS via coreutils, timeout on Linux)
    set -l timeout_cmd ""
    if command -v gtimeout &>/dev/null
        set timeout_cmd gtimeout
    else if command -v timeout &>/dev/null
        set timeout_cmd timeout
    end

    # Start animated spinner in background
    set -g __spinner_pid 0
    fish -c 'set frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"; while true; for frame in $frames; echo -ne "\r\033[K\033[90m$frame\033[0m "; sleep 0.08; end; end' &
    set -g __spinner_pid (jobs -lp | tail -1)

    # Save current directory
    set prev_dir (pwd)
    cd ~/dotfiles 2>/dev/null || return

    # Fetch quietly with timeout (5 seconds, fail silently)
    set -l fetch_status 0
    if test -n "$timeout_cmd"
        $timeout_cmd 5s git fetch --quiet 2>/dev/null; or set fetch_status $status
    else
        git fetch --quiet 2>/dev/null; or set fetch_status $status
    end
    if test $fetch_status -ne 0
        kill $__spinner_pid 2>/dev/null
        cd $prev_dir
        echo -e "\r\033[K"
        return
    end

    # Check for uncommitted changes and commit them
    set status_output (git status --porcelain 2>/dev/null)
    if test -n "$status_output"
        git add . 2>/dev/null
        # Try to commit, but ignore "nothing to commit" errors
        git commit -m "Auto-sync from $(hostname) at $(date +%Y-%m-%d\ %H:%M:%S)" --quiet 2>/dev/null
        # Don't treat "nothing to commit" as an error
    end

    # Check git status
    set local_commit (git rev-parse @ 2>/dev/null)
    set remote_commit (git rev-parse @{u} 2>/dev/null)
    set base_commit (git merge-base @ @{u} 2>/dev/null)

    if test "$local_commit" = "$remote_commit"
        # Up to date - clear the loader
        kill $__spinner_pid 2>/dev/null
        echo -e "\r\033[K"
    else if test "$local_commit" = "$base_commit"
        # Need to pull (with timeout, fail silently)
        set -l pull_status 0
        if test -n "$timeout_cmd"
            $timeout_cmd 10s git pull --quiet --rebase 2>/dev/null; or set pull_status $status
        else
            git pull --quiet --rebase 2>/dev/null; or set pull_status $status
        end
        kill $__spinner_pid 2>/dev/null
        echo -e "\r\033[K"
        if test $pull_status -ne 0
            cd $prev_dir
            return
        end
    else if test "$remote_commit" = "$base_commit"
        # Need to push (with timeout, fail silently)
        set -l push_status 0
        if test -n "$timeout_cmd"
            $timeout_cmd 10s git push --quiet 2>/dev/null; or set push_status $status
        else
            git push --quiet 2>/dev/null; or set push_status $status
        end
        kill $__spinner_pid 2>/dev/null
        echo -e "\r\033[K"
        if test $push_status -ne 0
            cd $prev_dir
            return
        end
    else
        # Diverged - fail silently
        kill $__spinner_pid 2>/dev/null
        echo -e "\r\033[K"
    end

    cd $prev_dir
end

# =============================================================================
# Secrets from 1Password (auto-fetched on terminal startup)
# =============================================================================
# Load cached secrets immediately (re-sourced after fetch completes)
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# =============================================================================
# Environment Variables
# =============================================================================
export ANDROID_HOME=$HOME/Library/Android/sdk
export BASE_BRANCH=main

# Claude Code / Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=team-engineering-dev-wfuk

# =============================================================================
# PATH
# =============================================================================
fish_add_path /usr/local/bin
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/tools
fish_add_path $HOME/.maestro/bin

# =============================================================================
# Platform-specific Configuration
# =============================================================================
switch (uname)
    case Linux
        set -g ONE_PASS_AGENT_PATH "~/.1password/agent.sock"
        # Set JAVA_HOME for Linux (common paths)
        if test -d /usr/lib/jvm/java-17-openjdk-amd64
            set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
        else if test -d /usr/lib/jvm/default-java
            set -gx JAVA_HOME /usr/lib/jvm/default-java
        end
    case Darwin # macOS
        set -g ONE_PASS_AGENT_PATH '"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
        # Set JAVA_HOME to Android Studio's bundled JDK
        set -gx JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
        # Initialize Homebrew environment
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Add VS Code to PATH
        fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    case '*'
        echo "⚠️  Unsupported OS"
        exit 1
end

# =============================================================================
# Git Configuration
# =============================================================================
git config --global --type bool push.autoSetupRemote true
git config --global core.editor "code --wait"

# =============================================================================
# Aliases
# =============================================================================
alias !! '$history[1]'

# =============================================================================
# Core Functions
# =============================================================================

function sudo --description "Enhanced sudo with !! support"
    if test "$argv[1]" = !!
        eval command sudo $history[1]
    else
        command sudo $argv
    end
end

function mkdir --description "Create directories with -p by default"
    command mkdir -p $argv
end

function bc --description "bc with -l (math library) by default"
    command bc -l $argv
end

# =============================================================================
# Git Workflow Functions
# =============================================================================

function fetch --description "Git fetch"
    command git fetch
end

function push --description "Force push current branch"
    command git push -f
end

function list --description "List git branches"
    command git branch
end

function pull --description "Git pull"
    command git pull
end

function clean --description "Clean merged branches and prune"
    command git branch --merged | egrep -v "(^\*|$BASE_BRANCH)" | xargs git branch -d
    command git remote prune origin
    command git gc --prune
end

function checkout --description "Checkout branch and rebase"
    command git checkout $argv
    rebase $BASE_BRANCH
end

function base --description "Switch to base branch and reset"
    if test "$BASE_BRANCH" = ""
        echo "BASE_BRANCH not set"
    else if test "$argv" = ""
        command git checkout $BASE_BRANCH
        command git reset --hard $BASE_BRANCH
        pull
    else
        set -gx BASE_BRANCH $argv
        base
    end
end

function master --description "Set base branch to master"
    set -gx BASE_BRANCH master
    base
end

function main --description "Set base branch to main"
    set -gx BASE_BRANCH main
    base
end

function amend --description "Amend last commit and force push"
    command git add .
    if test "$argv" = ""
        command git commit --amend --no-edit
    else
        command git commit --amend -m $argv
    end
    command git push -f
end

function commit --description "Add all and commit"
    command git add .
    command git commit -m $argv
end

function branch --description "Create new branch from base"
    command git checkout $BASE_BRANCH
    command git reset --hard $BASE_BRANCH
    pull
    command git checkout -b $argv
    rebase $BASE_BRANCH
    push
end

function rebase --description "Interactive rebase utilities"
    switch $argv[1]
        case --continue continue
            command git add .
            command git rebase --continue
        case --abort abort
            command git rebase --abort
        case master
            command git rebase origin/master
        case main
            command git rebase origin/main
        case ''
            command git rebase origin/$BASE_BRANCH
        case '*'
            command git rebase origin/$argv[1]
    end
end

function restore --description "Restore file from base branch"
    command git checkout origin/$BASE_BRANCH -- $argv
end

function revert --description "Revert file from base branch"
    command git checkout origin/$BASE_BRANCH -- $argv
end

function reset --description "Reset file from base branch"
    command git checkout origin/$BASE_BRANCH -- $argv
end

function nuke --description "Clean untracked files (with confirmation)"
    command git clean -dnfX
    while read --nchars 1 -l response --prompt-str="Are you sure you want to delete those files? (y/n) " || return 1
        switch $response
            case y Y
                command git clean -dfX
                return 1
            case n N
                echo "Aborting"
                return 1
            case '*'
                echo "Only y or n"
                continue
        end
    end
end

function pr --description "Create draft PR with gh"
    command gh pr create -d --fill
end

# =============================================================================
# Development Tools
# =============================================================================

function ios --description "Run npm iOS command"
    command npm run ios
end

function android --description "Run npm android command"
    command npm run android
end

function kill-port --description "Kill process on specified port"
    command lsof -i tcp:$argv | awk 'NR!=1 {print $2}' | xargs kill
end

function killport --description "Kill process on specified port"
    command sudo fuser -k $argv/tcp
end

function npm --description "Enhanced npm with deps shortcut"
    switch $argv[1]
        case deps check depcheck
            command npx depcheck
            command npx npm-check-updates
        case '*'
            command npm $argv
    end
end

# =============================================================================
# Dotfiles Management
# =============================================================================

function dotfiles-install --description "Install dotfiles (create symlinks)"
    # Call the bash script instead of duplicating logic
    ~/dotfiles/scripts/install.sh
end

# =============================================================================
# Config Management
# =============================================================================

function config --description "Manage dotfiles"
    switch $argv[1]
        case edit -e e
            set prev_dir (pwd)
            cd ~/dotfiles
            git pull --quiet
            code ~/dotfiles
            cd $prev_dir
        case sync -s s
            set prev_dir (pwd)
            cd ~/dotfiles
            git add .
            git commit -m "Manual sync from $(hostname) at $(date +%Y-%m-%d-%H-%M-%S)"
            git push
            cd $prev_dir
            echo "✓ Synced"
        case reload -r r
            source ~/.config/fish/config.fish
            echo "✓ Reloaded"
        case status
            set prev_dir (pwd)
            cd ~/dotfiles
            git status
            cd $prev_dir
        case install -i i
            dotfiles-install
        case secrets
            secrets-refresh
        case '*'
            echo "Usage: config [edit|sync|reload|status|install|secrets]"
            echo "  edit    - Open dotfiles in VS Code"
            echo "  sync    - Manually commit and push changes"
            echo "  reload  - Reload fish config"
            echo "  status  - Show git status"
            echo "  install - Create symlinks to dotfiles"
            echo "  secrets - Refresh secrets from 1Password"
    end
end

# =============================================================================
# SSH Management
# =============================================================================

function ssh --description "Enhanced ssh with tunnel support"
    switch $argv[1]
        case test ""
            command ssh -T git@github.com
        case tunnel
            command ssh -f -N -D 8015 ml
        case '*'
            command ssh $argv[1] $argv[2..-1]
    end
end

# =============================================================================
# Right Prompt
# =============================================================================

function fish_right_prompt --description "Show username and hostname"
    set user_name (whoami)
    set host_name (hostname -s)

    # Styled segment with background color and powerline arrow
    set_color brblack
    printf "\uE0B2"
    set_color -b brblack white
    echo -n " $user_name@$host_name "
    set_color normal
end
