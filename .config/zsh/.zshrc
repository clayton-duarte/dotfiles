# =============================================================================
# Zsh Configuration
# =============================================================================
# This config is managed in ~/dotfiles and symlinked via ZDOTDIR
# Auto-syncs with git on terminal startup

# =============================================================================
# Load secrets from 1Password (refresh with 'config secrets')
# =============================================================================
if [[ -f "${ZDOTDIR}/secrets.zsh" ]]; then
    source "${ZDOTDIR}/secrets.zsh"
fi

# =============================================================================
# Plugin Manager (Sheldon)
# =============================================================================
export SHELDON_CONFIG_DIR="${ZDOTDIR}"
export SHELDON_DATA_DIR="${ZDOTDIR}/sheldon"

if command -v sheldon &>/dev/null; then
    eval "$(sheldon source)"
fi

# =============================================================================
# Prompt (Starship)
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# =============================================================================
# Zsh Options
# =============================================================================
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # Push dirs onto stack automatically
setopt PUSHD_IGNORE_DUPS    # No duplicate dirs in stack
setopt HIST_IGNORE_ALL_DUPS # Remove older duplicate entries from history
setopt HIST_FIND_NO_DUPS    # Don't show duplicates when searching
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks from history
setopt SHARE_HISTORY        # Share history across sessions
setopt APPEND_HISTORY       # Append instead of overwrite
setopt INC_APPEND_HISTORY   # Write immediately, not on exit
setopt EXTENDED_GLOB        # Extended globbing syntax
setopt NO_BEEP              # Silence

HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# =============================================================================
# Key Bindings
# =============================================================================
bindkey -e  # Emacs keybindings (Ctrl-A, Ctrl-E, etc.)
bindkey '^[[A' history-substring-search-up   2>/dev/null  # Up arrow
bindkey '^[[B' history-substring-search-down 2>/dev/null  # Down arrow

# =============================================================================
# Core Functions
# =============================================================================
sudo() {
    if [[ "$1" == "!!" ]]; then
        eval command sudo "$(fc -ln -1)"
    else
        command sudo "$@"
    fi
}

mkdir() {
    command mkdir -p "$@"
}

bc() {
    command bc -l "$@"
}

# =============================================================================
# Load Modules
# =============================================================================
for module in "${ZDOTDIR}/modules/"*.zsh(N); do
    source "$module"
done

# =============================================================================
# Startup (once per session via precmd hook)
# =============================================================================
__startup_done=0
__startup() {
    (( __startup_done )) && return
    __startup_done=1

    # Show neofetch if installed
    if command -v neofetch &>/dev/null; then
        neofetch
    fi

    # Auto-sync dotfiles
    __dotfiles_sync

    # Remove ourselves from precmd after first run
    precmd_functions=(${precmd_functions:#__startup})
}

precmd_functions+=(__startup)
