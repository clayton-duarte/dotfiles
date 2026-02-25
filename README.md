# Dotfiles

Personal development environment configuration synced across machines.

## Features

- **Zsh Shell** with modular config and extensive git workflow functions
- **Oh My Zsh** with **agnoster** powerline theme and custom right prompt
- **Plugins** — autosuggestions, syntax highlighting, history substring search
- **Auto-sync** on terminal startup — automatically pulls/pushes config changes
- **1Password integration** for secrets management (no hardcoded tokens)
- **Cross-platform** — works on macOS and Linux
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
3. Install essential tools (zsh, git, gh, node, etc.)
4. Pull secrets from 1Password vault
5. Authenticate GitHub CLI
6. Symlink all dotfiles
7. Install Oh My Zsh + plugins
8. Configure git with SSH signing
9. Set zsh as default shell

**That's it!** After `bootstrap.sh`, all maintenance is done via zsh functions.

### Maintenance Commands

After bootstrap, use these functions for all operations:

```zsh
# Refresh secrets from 1Password
config secrets

# Reinstall symlinks
config install

# Edit dotfiles in VS Code
config edit

# Manually sync to GitHub
config sync

# Reload zsh config
config reload

# Show git status
config status
```

Or call the functions directly:
```zsh
secrets-refresh      # Refresh secrets from 1Password
dotfiles-install     # Create/recreate symlinks
```

## Repository Structure

```
dotfiles/
├── bootstrap.sh                # ⭐ Single setup script (run once)
├── packages.json               # 📦 All dependencies in one place
├── .config/
│   └── zsh/
│       ├── .zshenv             # Environment variables & PATH
│       ├── .zshrc              # Main Zsh config (Oh My Zsh + agnoster)
│       └── modules/
│           ├── git.zsh         # Git workflow functions
│           ├── dev.zsh         # Development tools
│           ├── ssh.zsh         # SSH management
│           └── dotfiles.zsh    # Dotfiles management & auto-sync
├── .ssh/
│   └── config                  # SSH configuration
├── .gitconfig                  # Git configuration
├── .gitignore                  # Security-critical!
├── scripts/                    # Helper scripts (used by bootstrap only)
│   ├── install.sh              # Creates symlinks + installs Oh My Zsh + plugins
│   ├── secrets.sh              # Fetches secrets & authenticates tools
│   ├── macos.sh                # macOS packages (reads packages.json)
│   └── linux.sh                # Linux packages (reads packages.json)
└── README.md                   # This file
```

**After bootstrap:**
- Use zsh functions for all maintenance (no bash scripts needed)

## Package Management

All dependencies are declared in `packages.json` — one file, one source of truth.

```json
{
  "package-name": {
    "brew": "homebrew-formula",
    "cask": "homebrew-cask",
    "apt": "apt-package",
    "dnf": "dnf-package",
    "pacman": "pacman-package",
    "install_cmd": "fallback shell command for platforms without a native package"
  }
}
```

**Adding a new package:** Add an entry to `packages.json` with the relevant package manager keys. The install scripts will pick it up automatically — no need to edit `macos.sh` or `linux.sh`.

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

### Vault: `Private`

All secrets live in a dedicated `Private` vault. Create it and add these items:

#### 1. SSH Key (type: SSH Key)
SSH key for GitHub authentication and commit signing:
- **private key** — OpenSSH format ed25519
- **public key** — Corresponding public key

#### 2. GitHub CLI (type: API Credential)
Personal Access Token for gh CLI:
- **credential** — GitHub PAT
- Get token from: `gh auth token`
- Or create at: https://github.com/settings/tokens/new
- Required scopes: `repo`, `read:org`, `gist`, `admin:public_key`

#### 3. Environment (type: Secure Note)
Dynamic environment variables — one field per secret:
- ARTIFACTORY_TOKEN
- NPM_TOKEN
- FONT_AWESOME_TOKEN
- (Add more as fields — they're auto-discovered!)

### Setup Commands
```bash
# Create vault
op vault create dotfiles

# Add SSH key
op item create --vault dotfiles --category 'SSH Key' --title 'SSH Key'

# Add GitHub CLI token
op item create --vault dotfiles --category 'API Credential' --title 'GitHub CLI' \
  'credential=ghp_your_token_here'

# Add environment secrets
op item create --vault dotfiles --category 'Secure Note' --title 'Environment' \
  'ARTIFACTORY_TOKEN=your_token' \
  'NPM_TOKEN=your_token'
```

### Dynamic Secret Discovery

**No code changes needed when adding secrets!**

The secrets script automatically fetches ALL fields from the "Environment" item. Just add a new field in 1Password, and it's available on your next terminal open.

```bash
# Add OPENAI_API_KEY as a field in dotfiles/Environment
# Open new terminal → automatically loaded!
echo $OPENAI_API_KEY  # Works immediately
```

### Per-Project Environments (op-env)

For project-specific secrets, create a `.env.op` file with `op://` references:
```bash
# .env.op (safe to commit — contains references, not values)
DATABASE_URL=op://Private/Environment/DATABASE_URL
STRIPE_KEY=op://Private/Environment/STRIPE_KEY
```

```bash
op-env npm start       # Secrets injected at runtime, never on disk
op-env .env.staging    # Use a different env file
```

### Refreshing Secrets

Secrets are cached on disk for performance. Refresh when:
- Adding new tokens to 1Password
- Secrets stop working
- Setting up a new machine

```zsh
config secrets      # Refresh from 1Password
# or
secrets-refresh    # Direct function call
```

This will:
- Re-authenticate with 1Password if needed
- Fetch all env vars from `dotfiles/Environment`
- Fetch SSH keys from `Private/SSH Key`
- Authenticate GitHub CLI from `dotfiles/GitHub CLI`
- Update `~/.config/zsh/secrets.zsh`

## Config Management

### Available Commands

```zsh
config edit     # Pull latest, open in VS Code
config sync     # Manually commit and push changes
config reload   # Reload zsh config
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
- `restore <file>` - Restore file from base branch (aliases: `revert`, `reset`)
- `nuke` - Clean untracked files (with confirmation)

## Development Tools

- `ios` - Run npm iOS simulator
- `android` - Run npm Android emulator
- `kill-port <port>` - Kill process on specified port
- `npm deps` - Check dependencies with depcheck and npm-check-updates

## SSH Management

SSH configuration is managed in `.ssh/config` with all hosts pre-configured.

All connections use 1Password SSH agent automatically via `SSH_AUTH_SOCK`.

### SSH Functions

```zsh
ssh tunnel  # Creates SOCKS proxy on port 8015
ssh test    # Test GitHub SSH connection
```

## Platform-Specific Notes

### macOS
- Uses Homebrew for package management
- 1Password agent: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- Latest Zsh installed via Homebrew (macOS ships with older version)

### Linux
- Uses apt/dnf/pacman depending on distro
- 1Password agent: `~/.1password/agent.sock`
- Oh My Zsh + plugins installed via git clone

## Security

**CRITICAL:** This repo contains references to secrets via 1Password CLI.

- All secrets stored in the `Private` vault in 1Password, never in git
- `secrets.zsh` is auto-generated and gitignored
- SSH keys are fetched from 1Password, never committed
- GitHub CLI auth via 1Password shell plugin or token from vault
- `.gitignore` prevents accidental secret commits
- Headless servers require interactive `op signin` (one-time, secrets persist on disk)

**Never commit:**
- `~/.config/zsh/secrets.zsh`
- `.env` files (`.env.op` with `op://` references are safe)
- SSH private keys
- API tokens / PATs

## Customization

### Adding New Tools

Edit `scripts/macos.sh` or `scripts/linux.sh`:

```bash
brew "your-package"
```

### Adding Secrets

1. Add a field to the "Environment" item in the `Private` vault
2. Open new terminal → automatically loaded!

### Adding Zsh Functions

Add to the appropriate module in `.config/zsh/modules/`:
- Git functions → `git.zsh`
- Dev tools → `dev.zsh`
- SSH → `ssh.zsh`
- Dotfiles management → `dotfiles.zsh`

Then run `config sync` to push changes.

## Troubleshooting

### Auto-sync not working

```bash
cd ~/dotfiles && git status
git remote -v
```

### Secrets not loading

```bash
cat ~/.config/zsh/secrets.zsh
~/dotfiles/scripts/secrets.sh
```

### SSH keys not working

```bash
ssh-add -l
ssh -T git@github.com
```

### Diverged configs

```bash
cd ~/dotfiles
git log --oneline --graph --all -10
git pull --rebase
```

### GitHub CLI not authenticated

```zsh
gh auth status
config secrets  # Refreshes token from 1Password
```

### Oh My Zsh plugins not working

```bash
# Check custom plugins are installed
ls ~/.oh-my-zsh/custom/plugins/
# Reinstall if missing
config install
```

### Prompt not rendering correctly

Make sure your terminal is using a Powerline-compatible font (e.g., MesloLGS NF).
The agnoster theme requires powerline glyphs for the arrow segments.

## Requirements

### Prerequisites (install manually)
- **git** — For cloning the repo
- **1Password app** — For secrets management

### Auto-installed by bootstrap
- 1Password CLI (`op`)
- Zsh (latest via Homebrew on macOS)
- Oh My Zsh (framework + agnoster theme)
- zsh-autosuggestions, zsh-syntax-highlighting (custom plugins)
- GitHub CLI (`gh`)
- Node.js (via `n` version manager)
- jq (JSON parsing)
- neofetch (system info)
- Powerline fonts (for agnoster prompt)

## License

Personal use only.
