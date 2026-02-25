# Project Guidelines

Personal dotfiles for macOS/Linux with Zsh shell, 1Password secrets management, and automatic sync.

## Architecture

```
dotfiles/
├── bootstrap.sh           # One-time setup entry point
├── packages.json          # Single source of truth for all dependencies
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
    ├── macos.sh           # macOS packages (reads packages.json → Brewfile)
    └── linux.sh           # Linux packages (reads packages.json → apt/dnf/pacman)
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
- SSH agent differs by OS: persistent socket on Linux, system default on macOS
- Plugin management via **Oh My Zsh** (built-in + custom plugins in `$ZSH_CUSTOM`)
- Prompt via **agnoster** theme (powerline-style, requires Nerd Font / Powerline font)

## Security

**Never commit**:
- `secrets.zsh`, SSH keys, `.env`, `*.key`, `*.pem`, tokens
- See [.gitignore](.gitignore) for full list

**Secrets pattern**: All secrets live in the 1Password `Private` vault:
- `Private/SSH Key` (Secure Note) → `~/.ssh/id_ed25519{,.pub}`
- `Private/Environment` (Password) → `~/.config/zsh/secrets.zsh` (dynamic fields, incl. GH_TOKEN)
- Per-project: use `.env.op` files with `op://Private/Environment/FIELD` references

## Integration Points

- **1Password CLI**: All secrets from `Private` vault via `op read op://Private/...`
- **1Password Shell Plugins**: `gh` (and others) authenticate via `~/.config/op/plugins.sh`
- **SSH agent**: Standard ssh-agent (persistent on Linux via socket file, system default on macOS)
- **Git SSH signing**: Key-file based, works on all platforms (configured in .gitconfig)
- **GitHub CLI**: Shell plugin (interactive) or GH_TOKEN from vault (headless)
- **Environment injection**: `op-env` function uses `op run --env-file` with `op://` references

## Known Problems & Solutions

Issues encountered while setting up 1Password integration across macOS and Linux.

### 1. SSH Key: PKCS#8 export format (Linux incompatible)

**Problem**: 1Password's `SSH_KEY` category stores keys internally and exports them via `op read` in **PKCS#8 PEM format** (`BEGIN PRIVATE KEY`). OpenSSH on Linux rejects this format — it requires `BEGIN OPENSSH PRIVATE KEY`.

**Why it matters**: On macOS the 1Password SSH agent served the key directly (bypassing the file), so it worked. On headless Linux, `secrets.sh` writes the key to `~/.ssh/id_ed25519` via `op read`, producing an incompatible file.

**Solution**: Generate the SSH key with standard `ssh-keygen -t ed25519` and store it as a **Secure Note** (not SSH_KEY category). `op read` on a Secure Note returns raw text — the original OpenSSH format, compatible everywhere.

### 2. SSH Key: mismatched public/private key fields

**Problem**: After moving the SSH Key item between 1Password vaults, the "public key" field contained a different key than what was embedded in the "private key" field.

**Solution**: Generated a fresh keypair with `ssh-keygen`, stored both halves as separate text fields in a single Secure Note. No more mismatch possible.

### 3. op-ssh-sign incompatible with Secure Note keys

**Problem**: After switching the SSH key to a Secure Note, `op-ssh-sign` (1Password's SSH signing agent) stopped working. It only recognizes items with category `SSH_KEY`.

**Solution**: Removed `op-ssh-sign` entirely. Git signing now uses standard `ssh-keygen` with the key file on disk (`user.signingkey` in `.gitconfig` is the public key string). Works identically on macOS and Linux.

### 4. macOS SSH_AUTH_SOCK hijacked by 1Password agent

**Problem**: The 1Password macOS app sets `SSH_AUTH_SOCK` to its own agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`). This agent refuses to load our Secure Note key (`ssh-add` → "agent refused operation"), breaking git signing and SSH auth.

**Solution**: Override `SSH_AUTH_SOCK` in `.zshenv` on macOS:
```bash
export SSH_AUTH_SOCK="$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null)"
```
This restores the macOS system ssh-agent (`/private/tmp/com.apple.launchd.*/Listeners`), which accepts any standard key file.

### 5. Service accounts can't access Personal/Private vault

**Problem**: 1Password service account tokens (for headless automation) cannot access the Personal or Private vault — they only work with vaults explicitly shared with the service account.

**Solution**: Removed all service account logic. All machines use interactive `op signin` (one-time). Secrets persist on disk after first run, so re-auth is only needed when refreshing.

### 6. Git credential helper: OS-specific path

**Problem**: `.gitconfig` had `helper = !/opt/homebrew/bin/gh auth git-credential` (macOS-only path). On Linux, `gh` lives at `/usr/bin/gh`.

**Solution**: Use path-independent `helper = !gh auth git-credential`. Git resolves `gh` from `$PATH` on both platforms.

### 7. Linux inotify limits: "Too many open files"

**Problem**: Running `bootstrap.sh` on the homeserver (Ubuntu) showed `Failed to allocate directory watch: Too many open files` during `apt update`. Default `max_user_instances=128` was too low.

**Solution**: Persisted higher limits via sysctl:
```bash
# /etc/sysctl.d/99-inotify.conf
fs.inotify.max_user_instances = 512
fs.inotify.max_user_watches = 524288
```

### 8. gpg --dearmor not idempotent

**Problem**: `bootstrap.sh` ran `gpg --dearmor` to install the 1Password apt signing key. On subsequent runs, gpg prompted to overwrite the existing file, breaking idempotency.

**Solution**: Added `--yes` flag: `gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg`

### Summary of architecture decisions

| Decision | Rationale |
|---|---|
| SSH key as Secure Note | `op read` returns raw OpenSSH format (no PKCS#8 conversion) |
| No op-ssh-sign | Only works with SSH_KEY category items |
| No 1Password SSH agent | Only serves SSH_KEY category items; conflicts with standard ssh-agent |
| Standard ssh-agent | macOS: system default, Linux: persistent socket at `~/.ssh/agent.sock` |
| Key-file git signing | Cross-platform, no external dependencies |
| No service accounts | Can't access Personal/Private vault |
| Interactive op signin | One-time per machine, secrets persist on disk |
| Path-independent gh | `!gh` in credential helper works on all platforms |
