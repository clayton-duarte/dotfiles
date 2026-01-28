# Dotfiles

Personal development environment configuration synced across machines.

## Features

- **Fish Shell** with extensive git workflow functions
- **Auto-sync** on terminal startup - automatically pulls/pushes config changes
- **1Password integration** for secrets management (no hardcoded tokens)
- **Cross-platform** - works on macOS and Linux
- **GitHub CLI** auto-authentication via 1Password
- **SSH management** with automated key deployment
- **Git commit signing** via SSH keys
- **One-line bootstrap** for fresh machines

## Quick Start

### Fresh Machine Setup

**Prerequisites:** Only git and 1Password app need to be installed

```bash
# Clone the repo
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# One command to set up everything
./bootstrap.sh
```

This will:
1. Install 1Password CLI
2. Authenticate with 1Password
3. Install essential tools (fish, git, gh, node, etc.)
4. Pull secrets from 1Password vault
5. Authenticate GitHub CLI
6. Symlink all dotfiles
7. Configure git with SSH signing
8. Set fish as default shell

**That's it!** After `bootstrap.sh`, all maintenance is done via fish functions.

### Maintenance Commands (Fish Functions)

After bootstrap, use these fish functions for all operations:

```fish
# Refresh secrets from 1Password
config secrets

# Reinstall symlinks
config install

# Edit dotfiles in VS Code
config edit

# Manually sync to GitHub
config sync

# Reload fish config
config reload

# Show git status
config status
```

Or call the functions directly:
```fish
secrets-refresh      # Refresh secrets from 1Password
dotfiles-install     # Create/recreate symlinks
```

## Repository Structure

```
dotfiles/
├── bootstrap.sh                # ⭐ Single setup script (run once)
├── .config/
│   └── fish/
│       └── config.fish         # Fish config (all maintenance functions)
├── .ssh/
│   └── config                  # SSH configuration
├── .gitconfig                  # Git configuration
├── .gitignore                  # Security-critical!
├── scripts/                    # Helper scripts (used by bootstrap only)
│   ├── install.sh              # Creates symlinks
│   ├── secrets.sh              # Fetches secrets & authenticates tools
│   ├── macos.sh                # macOS package installation (Homebrew)
│   └── linux.sh                # Linux package installation (apt/dnf/pacman)
└── README.md                   # This file
```

**Clean root:**
- `bootstrap.sh` → Single setup script
- All helper scripts in `scripts/` directory

**After bootstrap:**
- Use fish functions for all maintenance (no bash scripts needed)

## Auto-Sync Behavior

Every time you open a new terminal, the config automatically:

1. **Loads secrets** from cached file (refresh with `config secrets`)
2. **Fetches** dotfiles from remote
3. **Auto-commits** any local changes
4. **Pulls** if behind (auto-updates your config)
5. **Pushes** if ahead (auto-saves your changes)
6. **Warns** if diverged (manual git resolution needed)
7. **Shows neofetch** system info

No manual intervention needed for normal workflow!

## 1Password Setup

### Required Items

Create these items in your **Private** vault:

#### 1. Development API Tokens (type: Password)
Environment variables for development tools:
- ARTIFACTORY_TOKEN
- NPM_TOKEN
- FONT_AWESOME_TOKEN
- (Add more as needed - they're auto-discovered!)

#### 2. GH SSH Key (type: Secure Note)
SSH key for GitHub authentication:
- **private key** - OpenSSH format (from `ssh-keygen -t ed25519`)
- **public key** - Corresponding public key

#### 3. GitHub CLI Token (type: Password)
Personal Access Token for gh CLI:
- Get token from: `gh auth token`
- Or create at: https://github.com/settings/tokens/new
- Required scopes: `repo`, `read:org`, `gist`, `admin:public_key`

### Dynamic Token Discovery

**No code changes needed when adding tokens!**

The secrets script automatically fetches ALL fields from "Development API Tokens". Just add a new field in 1Password, and it's available on your next terminal open.

```bash
# Add OPENAI_API_KEY to 1Password item
# Open new terminal → automatically loaded!
echo $OPENAI_API_KEY  # Works immediately
```

### Refreshing Secrets

Secrets are cached on disk for performance. Refresh when:
- Adding new tokens to 1Password
- Secrets stop working
- Setting up a new machine

```fish
config secrets      # Refresh from 1Password
# or
secrets-refresh    # Direct function call
```

This will:
- Re-authenticate with 1Password if needed
- Fetch all tokens from "Development API Tokens"
- Fetch SSH keys from "GH SSH Key"
- Authenticate GitHub CLI
- Update `~/.config/fish/secrets.fish`

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

- ✅ All secrets stored in 1Password, not in git
- ✅ `secrets.fish` is auto-generated and gitignored
- ✅ SSH keys are fetched from 1Password, never committed
- ✅ GitHub CLI token in 1Password, never in environment (unless needed)
- ✅ `.gitignore` prevents accidental secret commits

**Never commit:**
- `~/.config/fish/secrets.fish`
- `.env` files
- SSH private keys
- API tokens / PATs
- Passwords
- `~/.config/gh/` directory

**What's synced:**
- ✅ Configuration files (Fish, git, SSH config)
- ✅ Scripts and functions

**What's NOT synced:**
- ❌ Secrets, credentials, tokens
- ❌ SSH keys
- ❌ Authentication state
- ❌ Cache files

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

### GitHub CLI not authenticated

```fish
# Check status
gh auth status

# Re-authenticate
config secrets  # Refreshes token from 1Password
```

## Requirements

### Prerequisites (install manually)
- **git** - For cloning the repo
- **1Password app** - For secrets management

### Auto-installed by bootstrap
- 1Password CLI (`op`)
- Fish shell
- GitHub CLI (`gh`)
- Node.js (via `n` version manager)
- jq (JSON parsing)
- neofetch (system info)
- Powerline fonts (for Fish theme)

## License

Personal use only.
