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
# Oh My Zsh
# =============================================================================
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="agnoster"

# Plugins (bundled with OMZ + custom cloned into $ZSH_CUSTOM/plugins/)
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)

# Load Oh My Zsh
if [[ -f "${ZSH}/oh-my-zsh.sh" ]]; then
    source "${ZSH}/oh-my-zsh.sh"
fi

# Override agnoster's context segment (moves user@host to right prompt)
prompt_context() {}
RPROMPT='%F{240}%f%K{240}%F{black}  %n@%m %f%k'

# =============================================================================
# Zsh Options (supplement OMZ defaults)
# =============================================================================
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # Push dirs onto stack automatically
setopt PUSHD_IGNORE_DUPS    # No duplicate dirs in stack
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
