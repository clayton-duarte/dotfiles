# Project Guidelines

Personal dotfiles for macOS/Linux with Fish shell, 1Password secrets management, and automatic sync.

## Architecture

```
dotfiles/
├── bootstrap.sh           # One-time setup entry point
├── .config/fish/
│   └── config.fish        # Main Fish config (~450 lines)
├── .ssh/config            # SSH host configurations
├── .gitconfig             # Git settings with SSH signing
└── scripts/
    ├── install.sh         # Symlink creation (idempotent)
    ├── secrets.sh         # 1Password secrets fetch
    ├── macos.sh           # Homebrew packages
    └── linux.sh           # apt/dnf/pacman packages
```

Symlinks point from `$HOME/` to `~/dotfiles/`. Auto-generated files (`secrets.fish`, SSH keys) are gitignored.

## Code Style

- **Function naming**: kebab-case for compound names (`secrets-refresh`, `kill-port`)
- **Config subcommands**: Use single entry function with switch (`config edit|sync|reload|status`)
- **Git shortcuts**: Short names (`fetch`, `push`, `commit`, `branch`, `pr`)
- **Platform detection**: Use `switch (uname)` with `case Darwin` / `case Linux`

See [.config/fish/config.fish](.config/fish/config.fish) for patterns.

## Build and Test

```bash
# Fresh setup
./bootstrap.sh

# After changes (Fish functions)
config install    # Reinstall symlinks
config secrets    # Refresh from 1Password
config reload     # Reload Fish config
```

## Project Conventions

- All scripts must be **idempotent** (safe to run repeatedly)
- Use `ln -sf` for symlinks with backup of existing files
- Set `chmod 600` on secrets/keys, `chmod 700` on `.ssh/`
- Linux scripts must detect distro via `/etc/os-release`
- 1Password agent paths differ by OS—use switch statements

## Security

**Never commit**:
- `secrets.fish`, SSH keys, `.env`, `*.key`, `*.pem`, tokens
- See [.gitignore](.gitignore) for full list

**Secrets pattern**: Store in 1Password "Development API Tokens" item → fetch via `op` CLI → write to `~/.config/fish/secrets.fish`

## Integration Points

- **1Password CLI**: All secrets via `op read` commands
- **SSH agent**: 1Password agent for key signing (paths in config.fish)
- **Git SSH signing**: Configured in [.gitconfig](.gitconfig)
- **GitHub CLI**: Authenticated via 1Password token
