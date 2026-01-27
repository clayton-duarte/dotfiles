# Setup Summary

This document shows what's configured in your dotfiles.

## 1Password Integration ✅

### Secrets Configured
All secrets are **dynamically fetched** from your personal 1Password account (`my.1password.com`, Private vault):

From "Development API Tokens" item (ALL fields auto-discovered):
- ✅ `ARTIFACTORY_TOKEN`
- ✅ `NPM_TOKEN`
- ✅ **Any new tokens you add** (no code changes needed!)

### SSH Keys Configured
- ✅ `GH SSH Key` → `~/.ssh/id_ed25519` (private key)
- ✅ `GH SSH Key` → `~/.ssh/id_ed25519.pub` (public key)

### How Secrets Are Loaded

**Automatic on every terminal open:**
- Secrets are fetched fresh from 1Password
- Always up-to-date, never stale
- If 1Password is unavailable, uses cached values

**Manual refresh (optional):**
```fish
config secrets
# or
secrets-refresh
```

**Adding new secrets:**
1. Add field to "Development API Tokens" in 1Password
2. Open new terminal → automatically loaded!
3. No code changes or commits needed

**Reinstall symlinks:**
```fish
config install
# or
dotfiles-install
```

## Git Configuration ✅

### User Identity
```
user.email = cpd@duck.com
user.name = cpd
```

### SSH Signing
```
gpg.format = ssh
gpg.ssh.program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
commit.gpgsign = true
user.signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzlrKAQzna6inWC0rg3wCXgL0i0MzYHLxzt+s2Zf+wW
```

Commits are automatically signed using your SSH key from 1Password.

### Other Settings
- Auto-setup remote on push
- Rebase on pull
- Auto-stash on rebase
- VS Code as editor

## SSH Configuration ✅

All SSH connections use 1Password agent automatically.

### Configured Hosts
```
homeserver → 192.168.3.3 (user: clayton)
fedora     → 192.168.3.4 (user: clayton)
ml         → 192.168.3.100 (user: clayton.duarte)
_ml        → 10.0.0.100 (user: clayton.duarte)
```

### SSH Config Location
- **Managed in:** `~/dotfiles/.ssh/config`
- **Symlinked to:** `~/.ssh/config`

### 1Password SSH Agent Path
```
macOS: ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
Linux: ~/.1password/agent.sock
```

## Fish Shell Configuration ✅

### Auto-Sync Behavior
Every time you open a new terminal:
1. Fetches from remote
2. Pulls if behind (auto-updates)
3. Pushes if ahead (auto-saves changes)
4. Warns if diverged

### Environment Variables
```fish
ANDROID_HOME=$HOME/Library/Android/sdk
BASE_BRANCH=main
```

Plus secrets from `~/.config/fish/secrets.fish`:
- ARTIFACTORY_TOKEN
- FONT_AWESOME_TOKEN
- NPM_TOKEN
- SARDINE_NPM_TOKEN

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
- `restore <file>` - Restore from base
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
- `config reload` - Reload fish config
- `config status` - Show git status

### SSH Functions
- `ssh tunnel` - Create SOCKS proxy on port 8015
- `ssh test` - Test GitHub connection

### Other Functions
- HAL 9000 greeting on startup
- Right prompt shows: `user@hostname`

## Directory Structure

```
~/dotfiles/
├── .config/
│   └── fish/
│       └── config.fish          ✅ Fish configuration
├── .ssh/
│   └── config                   ✅ SSH hosts configuration
├── scripts/
│   ├── macos.sh                ✅ macOS setup script
│   ├── linux.sh                ✅ Linux setup script
│   └── secrets.sh              ✅ 1Password secrets loader
├── bootstrap.sh                ✅ Fresh machine setup
├── install.sh                  ✅ Symlink creator
├── .gitconfig                  ✅ Git configuration
├── .gitignore                  ✅ Security rules
└── README.md                   ✅ Full documentation
```

## Symlinks Created

When you run `install.sh`:
```
~/.config/fish/config.fish → ~/dotfiles/.config/fish/config.fish
~/.ssh/config → ~/dotfiles/.ssh/config
~/.gitconfig → ~/dotfiles/.gitconfig
```

## Files NOT in Git (Security)

These are auto-generated and gitignored:
- `~/.config/fish/secrets.fish` - Contains actual token values
- `~/.ssh/id_ed25519` - Your private SSH key
- `~/.ssh/id_ed25519.pub` - Your public SSH key
- `~/.ssh/allowed_signers` - For commit verification

## Testing the Setup

### 1. Test 1Password Authentication
```bash
op account list
```

### 2. Test Secrets Loading
```fish
secrets-refresh
cat ~/.config/fish/secrets.fish  # Should show your tokens
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

### 5. Test Fish Config
```bash
exec fish
# Should show HAL 9000 greeting
# Should auto-sync dotfiles
```

## Next Steps

1. **Initialize Git Repo**
   ```bash
   cd ~/dotfiles
   git init
   git add .
   git commit -m "Initial dotfiles setup"
   ```

2. **Create Private GitHub Repo**
   ```bash
   gh repo create dotfiles --private --source=. --push
   ```

3. **Test Locally**
   ```bash
   cd ~/dotfiles
   ./install.sh
   exec fish
   ```

4. **On Fresh Machine**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./bootstrap.sh
   ```

## Troubleshooting

### Secrets Not Loading
```bash
# Check 1Password authentication
op account list

# Re-authenticate
eval $(op signin --account my.1password.com)
```

```fish
# Reload secrets
secrets-refresh
```

### SSH Not Working
```bash
# Check SSH key exists
ls -la ~/.ssh/id_ed25519

# Check 1Password agent
ssh-add -l

# Test GitHub
ssh -T git@github.com
```

### Git Signing Failing
```bash
# Check signing config
git config --list | grep sign

# Check allowed_signers
cat ~/.ssh/allowed_signers

# Test commit
git commit --allow-empty -m "Test" -S
```

### Auto-Sync Not Working
```bash
# Check if repo is initialized
cd ~/dotfiles && git status

# Check remote
git remote -v

# Manual sync
cd ~/dotfiles
git fetch
git pull
```
