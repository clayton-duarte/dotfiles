# Setup Summary

This document shows what's configured in your dotfiles.

## 1Password Integration

### Vault: `Private`

All secrets live in the default Private vault:

| Item | Type | Fields | `op://` reference |
|---|---|---|---|
| SSH Key | Secure Note | private key, public key | `op://Private/SSH Key/{field}` |
| Environment | Password | one field per env var (incl. GH_TOKEN) | `op://Private/Environment/{FIELD}` |

> **Why Secure Note for SSH Key?** 1Password's SSH Key category exports private keys
> in PKCS#8 PEM format via `op read`, which is incompatible with OpenSSH. Storing as
> a Secure Note ensures `op read` returns raw OpenSSH format directly.

### Authentication
- Interactive `op signin` only (no service accounts — they can't access Personal/Private vault)
- After first signin, secrets persist on disk and don't require re-auth until refreshed

### Secrets Loaded
From the "Environment" item (all fields auto-discovered):
- `ARTIFACTORY_TOKEN`
- `SARDINE_NPM_TOKEN`
- `FONT_AWESOME_TOKEN`
- `NPM_TOKEN`
- `GEMINI_API_KEY`
- `GH_TOKEN` (used for headless GitHub CLI auth)
- **Any new fields you add** (no code changes needed!)

### SSH Keys
- `SSH Key` → `~/.ssh/id_ed25519` (private key)
- `SSH Key` → `~/.ssh/id_ed25519.pub` (public key)

### How Secrets Are Loaded

**Automatic on every terminal open:**
- Secrets loaded from cached `~/.config/zsh/secrets.zsh`
- Refresh with `config secrets` or `secrets-refresh`

**Adding new secrets:**
1. Add a field to the "Environment" item in the `Private` vault
2. Open new terminal → automatically loaded!
3. No code changes or commits needed

**Per-project secrets (never written to disk):**
1. Create a `.env.op` file with `op://Private/Environment/FIELD` references
2. Run `op-env npm start` → secrets injected at runtime

## Git Configuration

### User Identity
```
user.email = cpd@duck.com
user.name = cpd
```

### SSH Signing
```
gpg.format = ssh
commit.gpgsign = true
user.signingkey = ssh-ed25519 AAAAC3...
gpg.ssh.allowedSignersFile = ~/.ssh/allowed_signers
```

Commits are automatically signed using your SSH key (key-file based, no `op-ssh-sign`).
The signing key in `.gitconfig` is the public key string — `bootstrap.sh` updates it.

### Other Settings
- Auto-setup remote on push
- Rebase on pull
- Auto-stash on rebase
- VS Code as editor (headless: vim)
- Credential helper: `!gh auth git-credential` (path-independent, works on all platforms)
- No merge fast-forward (explicit merge commits)

## SSH Configuration

SSH uses a standard ssh-agent (not 1Password SSH agent):
- **macOS**: System default ssh-agent (Keychain integration)
- **Linux**: Persistent agent via `~/.ssh/agent.sock` (set in `.zshenv`)

The SSH key is loaded into the agent automatically on shell startup (in `.zshrc`).

### SSH Key
- Generated via `ssh-keygen -t ed25519`
- Stored in 1Password as a **Secure Note** (not SSH Key category) so `op read` returns raw OpenSSH format
- Deployed to `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub` by `secrets.sh`

## Zsh Shell Configuration

### Architecture
Modular config split across focused files:
- `packages.json` — Single source of truth for all dependencies (parsed by `jq`)
- `.zshenv` — Environment variables & PATH (loaded first)
- `.zshrc` — Main entrypoint: plugins, prompt, options, module loading
- `modules/git.zsh` — Git workflow functions
- `modules/dev.zsh` — Development tools
- `modules/ssh.zsh` — SSH management
- `modules/dotfiles.zsh` — Dotfiles management & auto-sync

### Plugin Stack
- **Oh My Zsh** — Framework with agnoster theme (powerline-style, requires Nerd Font)
- **zsh-autosuggestions** — Fish-like inline suggestions (custom plugin)
- **zsh-syntax-highlighting** — Fish-like command coloring (custom plugin)
- **history-substring-search** — Fish-like history search with arrow keys (OMZ bundled)
- **git** — Git aliases and functions (OMZ bundled)
- **1Password Shell Plugins** — `gh` (and others) authenticate via `~/.config/op/plugins.sh`

### Auto-Sync Behavior
Every time you open a new terminal:
1. Fetches from remote
2. Pulls if behind (auto-updates)
3. Pushes if ahead (auto-saves changes)
4. Warns if diverged

### Environment Variables
```zsh
ANDROID_HOME=$HOME/Library/Android/sdk
BASE_BRANCH=main
# SSH_AUTH_SOCK — Linux: ~/.ssh/agent.sock, macOS: system default
```

Plus secrets from `~/.config/zsh/secrets.zsh`.

### Git Workflow Functions
- `fetch` - Git fetch
- `push` - Force push current branch
- `pull` - Git pull
- `commit "<message>"` - Add all and commit
- `amend ["<message>"]` - Amend last commit
- `branch <name>` - Create new branch from base
- `base` - Switch to base branch
- `main` - Set base to main
- `master` - Set base to master
- `clean` - Remove merged branches
- `rebase [branch]` - Rebase utilities
- `checkout <branch>` - Checkout and rebase
- `restore <file>` - Restore from base (aliases: `revert`, `reset`)
- `nuke` - Clean untracked files (with confirmation)
- `pr` - Create draft PR

### Development Tools
- `ios` - Run npm iOS
- `android` - Run npm Android
- `kill-port <port>` - Kill process on port
- `npm deps` - Check dependencies

### Config Management
- `config edit` - Open in VS Code
- `config sync` - Manually push changes
- `config reload` - Reload zsh config
- `config status` - Show git status
- `config install` - Reinstall symlinks
- `config secrets` - Refresh from 1Password

### SSH Functions
- `ssh tunnel` - Create SOCKS proxy on port 8015
- `ssh test` - Test GitHub connection

## Directory Structure

```
~/dotfiles/
├── bootstrap.sh                Setup script (run once)
├── .config/
│   └── zsh/
│       ├── .zshenv             Environment variables & PATH
│       ├── .zshrc              Main Zsh config (Oh My Zsh + agnoster)
│       └── modules/
│           ├── git.zsh         Git workflow functions
│           ├── dev.zsh         Development tools
│           ├── ssh.zsh         SSH management
│           └── dotfiles.zsh    # Dotfiles management & auto-sync
├── .ssh/
│   └── config                  SSH hosts configuration
├── .gitconfig                  Git configuration
├── .gitignore                  Security rules
├── scripts/
│   ├── install.sh              Symlink creator + Oh My Zsh setup
│   ├── secrets.sh              1Password secrets loader
│   ├── macos.sh                macOS setup script
│   └── linux.sh                Linux setup script
├── README.md                   Full documentation
└── SETUP.md                    This file
```

## Symlinks Created

When you run `install.sh`:
```
~/.zshenv                       → ~/dotfiles/.config/zsh/.zshenv
~/.config/zsh/.zshenv           → ~/dotfiles/.config/zsh/.zshenv
~/.config/zsh/.zshrc            → ~/dotfiles/.config/zsh/.zshrc
~/.config/zsh/modules/*.zsh     → ~/dotfiles/.config/zsh/modules/*.zsh
~/.ssh/config                   → ~/dotfiles/.ssh/config
~/.gitconfig                    → ~/dotfiles/.gitconfig
```

## Files NOT in Git (Security)

These are auto-generated and gitignored:
- `~/.config/zsh/secrets.zsh` - Contains actual token values
- `~/.ssh/id_ed25519` - Your private SSH key
- `~/.ssh/id_ed25519.pub` - Your public SSH key
- `~/.ssh/allowed_signers` - For commit verification

## Testing the Setup

### 1. Test 1Password Authentication
```bash
op account list
```

### 2. Test Secrets Loading
```zsh
secrets-refresh
cat ~/.config/zsh/secrets.zsh  # Should show your tokens
```

### 3. Test SSH Key
```bash
ls -la ~/.ssh/id_ed25519
ssh -T git@github.com
```

### 4. Test Git Signing
```bash
cd ~/dotfiles
git commit --allow-empty -m "Test signed commit"
git log --show-signature -1
```

### 5. Test Zsh Config
```bash
exec zsh
# Should show neofetch
# Should auto-sync dotfiles
```

### 6. Test Prompt
```bash
# Should show powerline-style agnoster prompt with git info
# Right prompt should show user@hostname
```

### 7. Test Plugins
```bash
# Type a command slowly — autosuggestions should appear in grey
# Mistyped commands should appear in red (syntax highlighting)
# Up arrow should search history by substring
```

## Troubleshooting

### Secrets Not Loading
```bash
op account list
eval "$(op signin)"
```

```zsh
secrets-refresh
```

### SSH Not Working
```bash
ls -la ~/.ssh/id_ed25519
ssh-add -l
ssh -T git@github.com
```

### Git Signing Failing
```bash
git config --list | grep sign
cat ~/.ssh/allowed_signers
git commit --allow-empty -m "Test" -S
```

### Auto-Sync Not Working
```bash
cd ~/dotfiles && git status
git remote -v
git fetch && git pull
```

### Oh My Zsh Plugins Not Loading
```bash
# Check custom plugins are installed
ls ~/.oh-my-zsh/custom/plugins/
# Reinstall
config install
```

### Prompt Not Rendering
```bash
# Ensure a Powerline-compatible font is set in your terminal (e.g., MesloLGS NF)
echo "\ue0b0"  # Should show a powerline arrow
```
