# Dotfiles

Personal development environment configuration synced across machines.

## Features

- **Fish Shell** with extensive git workflow functions
- **Auto-sync** on terminal startup - automatically pulls/pushes config changes
- **1Password integration** for secrets management (no hardcoded tokens)
- **Cross-platform** - works on macOS and Linux
- **HAL 9000 greeting** - random startup messages
- **SSH management** with 1Password agent
- **Git commit signing** via 1Password SSH
- **One-line bootstrap** for fresh machines

## Quick Start

### Fresh Machine Setup

**Prerequisites:** Only git and 1Password app need to be installed

```bash
# Clone the repo
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run bootstrap (installs everything)
./bootstrap.sh
```

This will:
1. Install 1Password CLI
2. Authenticate with 1Password
3. Install essential tools (fish, git, gh, node, etc.)
4. Pull secrets from 1Password vault
5. Symlink all dotfiles
6. Configure git
7. Set fish as default shell

### Existing Machine

If dotfiles are already set up:

```bash
cd ~/dotfiles
git pull
./install.sh  # Re-create symlinks if needed
./scripts/secrets.sh  # Refresh secrets from 1Password
```

## Repository Structure

```
dotfiles/
├── .config/
│   └── fish/
│       └── config.fish          # Main fish configuration
├── .ssh/
│   └── config                   # SSH configuration template
├── scripts/
│   ├── macos.sh                # macOS-specific setup
│   ├── linux.sh                # Linux-specific setup
│   └── secrets.sh              # 1Password secrets loader
├── bootstrap.sh                # First-run setup script
├── install.sh                  # Symlink creator (idempotent)
├── .gitconfig                  # Git configuration
├── .gitignore                  # Security-critical!
└── README.md                   # This file
```

## Auto-Sync Behavior

Every time you open a new terminal, the config automatically:

1. **Fetches** from remote
2. **Pulls** if behind (auto-updates your config)
3. **Pushes** if ahead (auto-saves your changes)
4. **Warns** if diverged (manual git resolution needed)

No manual intervention needed for normal workflow!

## 1Password Setup

### Storing Secrets

Create items in 1Password for your secrets:

1. **API Tokens** - Store as "API Credential" type
   - Artifactory Token
   - Font Awesome Token
   - NPM Token

2. **SSH Keys** - Store as "SSH Key" type
   - Your private keys for git signing

### Reference Format

Edit [`scripts/secrets.sh`](scripts/secrets.sh:1) to match your 1Password vault structure:

```bash
op read "op://Vault Name/Item Name/field name"
```

Example:
```bash
op read "op://Private/NPM Token/credential"
```

### Refreshing Secrets

```bash
~/dotfiles/scripts/secrets.sh
```

## Config Management

### Available Commands

```fish
config edit     # Pull latest, open in VS Code
config sync     # Manually commit and push changes
config reload   # Reload fish config
config status   # Show git status
```

### Typical Workflow

1. Edit configs locally or via `config edit`
2. Changes auto-sync on next terminal open
3. Or manually sync with `config sync`
4. Other machines auto-pull on terminal open

## Git Workflow Functions

### Branch Management
- `fetch` - Git fetch
- `push` - Force push current branch
- `pull` - Git pull
- `branch <name>` - Create and switch to new branch from base
- `base` - Switch to base branch and reset
- `main` - Set base branch to main
- `master` - Set base branch to master
- `list` - List branches
- `clean` - Remove merged branches and prune

### Commits
- `commit "<message>"` - Add all and commit
- `amend ["<message>"]` - Amend last commit (optional new message)
- `pr` - Create draft PR with GitHub CLI

### Rebase
- `rebase` - Rebase on base branch
- `rebase <branch>` - Rebase on specified branch
- `rebase continue` - Continue after resolving conflicts
- `rebase abort` - Abort rebase

### File Operations
- `checkout <branch>` - Checkout branch and rebase
- `restore <file>` - Restore file from base branch
- `revert <file>` - Revert file from base branch
- `reset <file>` - Reset file from base branch
- `nuke` - Clean untracked files (with confirmation)

## Development Tools

- `ios` - Run npm iOS simulator
- `android` - Run npm Android emulator
- `kill-port <port>` - Kill process on specified port
- `npm deps` - Check dependencies with depcheck and npm-check-updates

## SSH Management

SSH configuration is managed in [`.ssh/config`](.ssh/config:1) with all hosts pre-configured:
- `homeserver` - 192.168.3.3
- `fedora` - 192.168.3.4
- `ml` - 192.168.3.100
- `_ml` - 10.0.0.100

All connections use 1Password SSH agent automatically.

### SSH Tunneling

```fish
ssh tunnel  # Creates SOCKS proxy on port 8015
ssh test    # Test GitHub SSH connection
```

## Platform-Specific Notes

### macOS
- Uses Homebrew for package management
- 1Password agent path: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- Git SSH signing configured automatically

### Linux
- Uses apt/dnf/pacman depending on distro
- 1Password agent path: `~/.1password/agent.sock`
- Git SSH signing needs manual setup

## Security

**CRITICAL:** This repo contains references to secrets via 1Password CLI.

- ✅ Secrets are stored in 1Password, not in git
- ✅ `secrets.fish` is auto-generated and gitignored
- ✅ SSH keys are fetched from 1Password, never committed
- ✅ `.gitignore` prevents accidental secret commits

**Never commit:**
- `secrets.fish`
- `.env` files
- SSH private keys
- API tokens
- Passwords

## Customization

### Adding New Tools

Edit [`scripts/macos.sh`](scripts/macos.sh:1) or [`scripts/linux.sh`](scripts/linux.sh:1):

```bash
brew "your-package"
```

### Adding Secrets

1. Store in 1Password
2. Edit [`scripts/secrets.sh`](scripts/secrets.sh:1)
3. Add new `op read` command
4. Run `~/dotfiles/scripts/secrets.sh`

### Adding Fish Functions

Edit [`.config/fish/config.fish`](.config/fish/config.fish:1) and run:

```fish
config sync  # Push changes
```

Other machines will auto-pull on next terminal open.

## Troubleshooting

### Auto-sync not working

```fish
# Check if git repo is initialized
cd ~/dotfiles && git status

# Check if remote is configured
git remote -v
```

### Secrets not loading

```fish
# Check if secrets.fish exists
cat ~/.config/fish/secrets.fish

# Re-fetch from 1Password
~/dotfiles/scripts/secrets.sh
```

### SSH keys not working

```fish
# Check 1Password agent
ssh-add -l

# Test GitHub connection
ssh -T git@github.com
```

### Diverged configs

If auto-sync shows "Diverged":

```fish
cd ~/dotfiles
git status
git log --oneline --graph --all -10

# Resolve manually
git pull --rebase  # or merge
```

## Requirements

- git
- 1Password app
- 1Password CLI (installed by bootstrap)
- Fish shell (installed by bootstrap)

## License

Personal use only.
