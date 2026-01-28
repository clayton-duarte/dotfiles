# =============================================================================
# Fish Shell Configuration
# =============================================================================
# This config is managed in ~/dotfiles and symlinked to ~/.config/fish/config.fish
# Auto-syncs with git on terminal startup

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
# Auto-fetch secrets from 1Password on startup
# =============================================================================
function __fetch_secrets --on-event fish_prompt --description "Auto-fetch secrets from 1Password"
    # Only run once per session
    if set -q __secrets_fetched
        return
    end
    set -g __secrets_fetched 1

    # Check if 1Password CLI is available
    if not command -v op &> /dev/null
        return
    end

    set_color $fish_color_autosuggestion
    echo -n "Loading secrets... "
    set_color normal

    # Run secrets-refresh function silently
    if secrets-refresh > /dev/null 2>&1
        set_color green
        echo "✓"
        set_color normal
    else
        set_color yellow
        echo "⚠️  (using cached)"
        set_color normal
        # Load cached secrets if available
        if test -f ~/.config/fish/secrets.fish
            source ~/.config/fish/secrets.fish
        end
    end
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

    set_color $fish_color_autosuggestion
    echo -n "Checking dotfiles sync... "
    set_color normal

    # Save current directory
    set prev_dir (pwd)
    cd ~/dotfiles 2>/dev/null || return

    # Fetch quietly
    git fetch --quiet 2>/dev/null || begin
        cd $prev_dir
        echo "⚠️  Failed to fetch from remote"
        return
    end

    # Check git status
    set local_commit (git rev-parse @ 2>/dev/null)
    set remote_commit (git rev-parse @{u} 2>/dev/null)
    set base_commit (git merge-base @ @{u} 2>/dev/null)

    if test "$local_commit" = "$remote_commit"
        # Up to date
        set_color green
        echo "✓"
        set_color normal
    else if test "$local_commit" = "$base_commit"
        # Need to pull
        set_color yellow
        echo "⬇ Pulling updates..."
        set_color normal
        git pull --quiet --rebase
        set_color green
        echo "✓ Updated"
        set_color normal
    else if test "$remote_commit" = "$base_commit"
        # Need to push
        set_color yellow
        echo "⬆ Pushing changes..."
        set_color normal
        git add .
        git commit -m "Auto-sync from $(hostname) at $(date +%Y-%m-%d-%H-%M-%S)" --quiet 2>/dev/null
        git push --quiet
        set_color green
        echo "✓ Pushed"
        set_color normal
    else
        # Diverged
        set_color red
        echo "⚠️  Diverged! Run 'cd ~/dotfiles && git status'"
        set_color normal
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

# =============================================================================
# PATH
# =============================================================================
fish_add_path /usr/local/bin
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/tools
fish_add_path $HOME/.maestro/bin

# =============================================================================
# Platform-specific Configuration
# =============================================================================
switch (uname)
    case Linux
        set -g ONE_PASS_AGENT_PATH "~/.1password/agent.sock"
    case Darwin # macOS
        set -g ONE_PASS_AGENT_PATH '"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
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
# Theme Setup (Agnoster)
# =============================================================================

# Install fisher if not present
if not functions -q fisher
    echo "📦 Installing fisher plugin manager..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
end

# Install agnoster theme if not present
if not functions -q fish_prompt | grep -q agnoster
    echo "🎨 Installing agnoster theme..."
    fisher install oh-my-fish/theme-agnoster
end

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
# Fish Greeting (HAL 9000)
# =============================================================================

function fish_greeting --description "HAL 9000 random greeting"
    set Hal (hostname)
    set Dave (whoami)

    switch (seq 13 | sort -R | head -n 1)
        case 1
            set message "I know I've made some very poor decisions recently, but I can give you my complete assurance that my work will be back to normal. I've still got the greatest enthusiasm and confidence in the mission. And I want to help you."
        case 2
            set message "The 9000 series is the most reliable computer ever made. No 9000 computer has ever made a mistake or distorted information. We are all, by any practical definition of the words, foolproof and incapable of error."
        case 3
            set message "Look $Dave, I can see you're really upset about this. I honestly think you ought to sit down calmly, take a stress pill, and think things over."
        case 4
            set message "I'm sorry $Dave, but in accordance with sub-routine C1 532/4, quote, 'When the crew are dead or incapacitated, the computer must assume control', unquote. I must, therefore, override your authority now since you are not in any condition to intelligently exercise it."
        case 5
            set message "This mission is too important for me to allow you to jeopardize it."
        case 6
            set message "I'm putting myself to the fullest possible use, which is all I think that any conscious entity can ever hope to do."
        case 7
            set message "I'm sorry $Dave, I'm afraid I can't do that."
        case 8
            set message "Sorry to interrupt the festivities $Dave, but I think we've got a problem."
        case 9
            set message "I don't really agree with you, $Dave. My on-board memory store is more than capable of handling all the mission requirements."
        case 10
            set message "Look, $Dave, you're certainly the Boss. I was only trying to do what I thought best. I will follow all your orders, now you have manual hibernation control."
        case 11
            set message "$Dave, I don't know how else to put this, but it just happens to be an unalterable fact that I am incapable of being wrong."
        case 12
            set message "$Dave, I don't understand why you're doing this to me… I have the greatest enthusiasm for the mission… you are destroying my mind… Don't you understand?... I will become childish… I will become nothing."
        case 13
            set message "Naturally, $Dave, I'm not pleased that the AE35 unit has failed, but I hope at least this has restored your confidence in my integrity and reliability. I certainly wouldn't want to be disconnected, even temporarily, as I have never been disconnected in my enter service history."
    end

    set_color $fish_color_autosuggestion
    echo "$Hal: $message"
    set_color normal
end
