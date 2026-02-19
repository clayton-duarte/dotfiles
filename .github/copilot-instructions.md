# Project Guidelines

Personal dotfiles for macOS/Linux with Zsh shell, 1Password secrets management, and automatic sync.

## Architecture

```
dotfiles/
├── bootstrap.sh           # One-time setup entry point
├── .config/zsh/
│   ├── .zshenv            # Environment variables & PATH (also symlinked to ~/.zshenv)
│   ├── .zshrc             # Main Zsh config entrypoint (Oh My Zsh + agnoster)
│   └── modules/
│       ├── git.zsh        # Git workflow functions
│       ├── dev.zsh        # Development tool functions
│       ├── ssh.zsh        # SSH management functions
│       └── dotfiles.zsh   # Dotfiles management & auto-sync
├── .ssh/config            # SSH host configurations
├── .gitconfig             # Git settings with SSH signing
└── scripts/
    ├── install.sh         # Symlink creation + Oh My Zsh install (idempotent)
    ├── secrets.sh         # 1Password secrets fetch
    ├── macos.sh           # Homebrew packages
    └── linux.sh           # apt/dnf/pacman packages
```

Symlinks point from `$HOME/` to `~/dotfiles/`. Auto-generated files (`secrets.zsh`, SSH keys) are gitignored.

## Code Style

- **Function naming**: kebab-case for compound names (`secrets-refresh`, `kill-port`)
- **Config subcommands**: Use single entry function with case (`config edit|sync|reload|status`)
- **Git shortcuts**: Short names (`fetch`, `push`, `commit`, `branch`, `pr`)
- **Platform detection**: Use `case "$(uname)"` with `Darwin)` / `Linux)`
- **Modular config**: Split by concern into `modules/*.zsh` files

See [.config/zsh/.zshrc](.config/zsh/.zshrc) and [.config/zsh/modules/](.config/zsh/modules/) for patterns.

## Build and Test

```bash
# Fresh setup
./bootstrap.sh

# After changes (Zsh functions)
config install    # Reinstall symlinks
config secrets    # Refresh from 1Password
config reload     # Reload Zsh config
```

## Project Conventions

- All scripts must be **idempotent** (safe to run repeatedly)
- Use `ln -sf` for symlinks with backup of existing files
- Set `chmod 600` on secrets/keys, `chmod 700` on `.ssh/`
- Linux scripts must detect distro via `/etc/os-release`
- 1Password agent paths differ by OS—use case statements
- Plugin management via **Oh My Zsh** (built-in + custom plugins in `$ZSH_CUSTOM`)
- Prompt via **agnoster** theme (powerline style, requires Nerd/Powerline font)

## Security

**Never commit**:
- `secrets.zsh`, SSH keys, `.env`, `*.key`, `*.pem`, tokens
- See [.gitignore](.gitignore) for full list

**Secrets pattern**: Store in 1Password "Development API Tokens" item → fetch via `op` CLI → write to `~/.config/zsh/secrets.zsh`

## Integration Points

- **1Password CLI**: All secrets via `op read` commands
- **SSH agent**: 1Password agent via `SSH_AUTH_SOCK` (set in .zshenv)
- **Git SSH signing**: Configured in [.gitconfig](.gitconfig)
- **GitHub CLI**: Authenticated via 1Password token
