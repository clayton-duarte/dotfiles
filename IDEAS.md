# Simplification Ideas

Potential improvements to make the dotfiles more efficient and maintainable.

## 1. Consolidate git signing config

**Problem:** Both `bootstrap.sh` (lines 182-200) and `secrets.sh` (lines 113-125) have identical logic for setting up git signing (~20 lines duplicated).

**Fix:** Extract to a function in `secrets.sh` and remove from `bootstrap.sh` (since `bootstrap.sh` already sources `secrets.sh`).

---

## 2. Move jq bootstrap to bootstrap.sh

**Problem:** Both `macos.sh` and `linux.sh` install jq before parsing `packages.json`.

**Fix:** Install jq once in `bootstrap.sh` before calling the platform script.

---

## 3. Use subshells in config function

**Problem:** Repetitive `cd` pattern in `config` function (dotfiles.zsh):
```zsh
local prev_dir="$PWD"
cd ~/dotfiles
# ... do stuff ...
cd "$prev_dir"
```

**Fix:** Use subshells:
```zsh
(cd ~/dotfiles && git status)  # simpler, auto-restores dir
```

---

## 4. Extract timeout helper for dotfiles sync

**Problem:** Timeout detection + execution pattern is copy-pasted for fetch, pull, and push in `__dotfiles_sync`.

**Fix:** Extract a helper:
```zsh
__git_with_timeout() {
    local timeout_secs="$1"
    shift
    if [[ -n "$TIMEOUT_CMD" ]]; then
        $TIMEOUT_CMD "${timeout_secs}s" git "$@"
    else
        git "$@"
    fi
}
```

---

## 5. Convert simple git wrappers to aliases

**Problem:** Simple functions that just call git:
```zsh
fetch() { command git fetch }
pull()  { command git pull }
list()  { command git branch }
```

**Fix:** Use aliases instead:
```zsh
alias fetch='git fetch'
alias pull='git pull' 
alias list='git branch'
```

---

## 6. Remove excessive `command` prefix

**Problem:** Every git call uses `command git`. Only needed when shadowing is a concern (like the `ssh()` wrapper).

**Fix:** Remove `command` prefix from internal git calls where there's no shadowing risk.

---

## 7. Lazy ssh-agent startup

**Problem:** The Linux ssh-agent setup in `.zshenv` runs `ssh-add -l` which makes a network round-trip on every shell startup.

**Fix:** Only check/start if socket doesn't exist:
```zsh
if [[ ! -S "$SSH_AGENT_SOCK" ]]; then
    eval "$(ssh-agent -a "$SSH_AGENT_SOCK")"
fi
```

---

## 8. Adopt Homebrew as single package manager

**Problem:** Currently maintaining `packages.json` with 4 package manager keys (brew/apt/dnf/pacman) plus separate `macos.sh` (~55 lines) and `linux.sh` (~100 lines) scripts with distro detection.

**Fix:** Homebrew works on Linux (Linuxbrew). Replace everything with a single `Brewfile`:

```ruby
# Brewfile
brew "git"
brew "gh"
brew "zsh"
brew "jq"
brew "curl"
brew "neofetch"
brew "htop"
brew "n"
brew "tmux"
brew "docker"
brew "docker-compose"

# macOS only
cask "font-meslo-lg-nerd-font" if OS.mac?
cask "1password-cli" if OS.mac?
```

**Bootstrap becomes:**
```bash
# Install Homebrew (works on both macOS and Linux)
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname)" == "Linux" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
brew bundle --file=~/dotfiles/Brewfile
```

**Changes:**
- Delete `packages.json`
- Delete `linux.sh`
- Simplify `macos.sh` → `packages.sh` (just `brew bundle`)

**Tradeoffs:**
| Pro | Con |
|-----|-----|
| Single package manager | Requires build-essential on Linux |
| ~150 fewer lines | Slower installs on Linux (compiles more) |
| No distro detection | Extra ~3-5GB disk for Homebrew |
| Consistent versions | Docker better via native package manager |

---

## 9. Consider chezmoi migration

**Context:** This repo is essentially a custom implementation of what [chezmoi](https://chezmoi.io) already does — cross-platform dotfiles with 1Password integration.

**Chezmoi provides:**
- Built-in 1Password support: `{{ onepasswordRead "op://Private/SSH Key/private key" }}`
- Cross-platform templates with OS detection
- Auto-diff before applying changes
- Encrypted secrets in git (alternative to 1Password-only)
- One-line bootstrap: `chezmoi init --apply username`

**When to consider:**
- If adding more machine-specific logic
- If maintenance becomes a burden
- If you want encrypted secrets in git

**When to keep current approach:**
- Full control over every line
- No external Go binary dependency
- Learning value
- Current ~500 lines is manageable

---

## 10. Use Makefile as entry point

**Problem:** `bootstrap.sh` is ~250 lines with manual dependency ordering. The `config` function duplicates some of this. No way to run partial setup or see what will happen.

**Fix:** Replace `bootstrap.sh` with a Makefile:

```makefile
# Makefile
.PHONY: all install secrets packages sync clean help

SHELL := /bin/bash
OS := $(shell uname)

all: packages secrets install ## Full setup

install: ## Create symlinks + Oh My Zsh
	@./scripts/install.sh

secrets: ## Fetch secrets from 1Password
	@./scripts/secrets.sh

packages: homebrew ## Install packages via Homebrew
	brew bundle --file=Brewfile

homebrew: ## Install Homebrew if missing
ifeq (,$(shell which brew))
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ifeq ($(OS),Linux)
	eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
endif
endif

sync: ## Commit and push changes
	git add .
	git commit -m "Sync from $$(hostname) at $$(date +%Y-%m-%d-%H-%M-%S)"
	git push

clean: ## Remove generated files
	rm -f ~/.config/zsh/secrets.zsh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
```

**Benefits over bash:**
| Feature | Current (`bootstrap.sh`) | Make |
|---------|--------------------------|------|
| Dependency tracking | Manual ordering | Automatic |
| Parallel execution | No | `make -j4` |
| Self-documenting | Comments | `make help` |
| Dry run | No | `make -n` |
| Partial runs | Re-run everything | `make secrets` only |
| Industry standard | Custom | Universal |

**Usage:**
```bash
make          # Full setup (replaces ./bootstrap.sh)
make install  # Just symlinks
make secrets  # Just 1Password fetch
make help     # Show all targets
make -n       # Dry run — see what would happen
```

**Pairs with idea #8:** Combined with Homebrew-only, structure becomes:
```
dotfiles/
├── Makefile           # Entry point (~40 lines)
├── Brewfile           # All packages
├── scripts/
│   ├── install.sh     # Symlinks + Oh My Zsh
│   └── secrets.sh     # 1Password fetch
└── .config/zsh/...    # Actual dotfiles
```

---

## 11. Improve SSH configuration

**Problems:**
- No connection multiplexing (slow reconnects)
- No keepalive (connections drop on idle networks)
- Hardcoded LAN IPs (break when DHCP changes)
- `ssh()` wrapper shadows the command (`ssh test` runs GitHub test instead of `ssh test-server`)

**Improved ~/.ssh/config:**
```ssh-config
Host *
    # Connection multiplexing — reuse connections
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    
    # Keep connections alive
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
    # Security
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    
    # macOS-specific (ignored on Linux)
    IgnoreUnknown UseKeychain
    UseKeychain yes

# Use mDNS instead of hardcoded IPs
Host homeserver
    HostName homeserver.local
    User clayton

Host bazzite
    HostName bazzite.local
    User clayton
```

**Improved ssh.zsh (don't shadow ssh command):**
```zsh
# Rename functions to avoid shadowing
ssh-test() { ssh -T git@github.com }
ssh-tunnel() { ssh -f -N -D 8015 ml && echo "SOCKS proxy on localhost:8015" }
ssh-kill-tunnels() { pkill -f "ssh -f -N" }
ssh-list() { ls -la ~/.ssh/sockets/ 2>/dev/null || echo "No active connections" }
```

**Required setup:**
```bash
mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets
```

**Benefits:**
| Issue | Fix |
|-------|-----|
| Slow connections | `ControlMaster` multiplexing |
| Dropped connections | `ServerAliveInterval 60` |
| Hardcoded LAN IPs | Use `.local` mDNS names |
| ssh() shadows command | Rename to `ssh-test`, `ssh-tunnel` |
| Security | `IdentitiesOnly yes` prevents agent enumeration |

---

## 12. Better 1Password integration

**Current approach:** `secrets.sh` writes secrets to `~/.config/zsh/secrets.zsh` on disk.

**Better approaches:**

### A. Never write secrets to disk — use `op inject`

```zsh
# Create template file (committed to git, safe):
# ~/.config/zsh/secrets.zsh.tpl
export STRIPE_KEY="{{ op://Private/Environment/STRIPE_KEY }}"
export DATABASE_URL="{{ op://Private/Environment/DATABASE_URL }}"

# In .zshrc (replaces `source secrets.zsh`):
if command -v op &>/dev/null && op whoami &>/dev/null; then
    eval "$(op inject -i "${ZDOTDIR}/secrets.zsh.tpl" 2>/dev/null)"
fi
```

### B. Use `op run` for commands that need secrets

```zsh
# Wrap commands — secrets only exist in process memory:
alias dev='op run --env-file=.env.op -- npm run dev'

# Or a smart wrapper:
run() {
    if [[ -f .env.op ]]; then
        op run --env-file=.env.op -- "$@"
    else
        "$@"
    fi
}
```

### C. Use 1Password SSH Agent

If you **generate** the key inside 1Password (not import), you avoid the PKCS#8 format issue:

```bash
# 1Password app: New Item → SSH Key → Generate
# Enable: Settings → Developer → SSH Agent

# In .zshenv (macOS):
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

Benefits: No private key on disk, Touch ID unlock, works with `op-ssh-sign`.

### D. More shell plugins

```bash
op plugin init gh       # Already have this
op plugin init aws      # AWS CLI
op plugin init kubectl  # Kubernetes
op plugin init gcloud   # Google Cloud
op plugin init stripe   # Stripe CLI
```

### E. Enable biometric unlock

```bash
# 1Password app: Settings → Security → Touch ID
# Then `op` commands use Touch ID instead of password
```

**Comparison:**
| Approach | Pro | Con |
|----------|-----|-----|
| Current (disk) | Works offline, fast | Secrets on disk |
| `op inject` | No disk secrets | Auth each session |
| `op run` per-command | Maximum security | Slight latency |
| 1Password SSH Agent | No key on disk | macOS-focused |

**Simplified flow:**
```
Current:  1Password → secrets.sh → secrets.zsh (disk) → source
Better:   1Password → op inject → process env (memory only)
```

---

## Summary

| Change | Lines Saved | Benefit |
|--------|-------------|---------|
| Consolidate git signing | ~25 | Single source of truth |
| Homebrew-only | ~150 | One tool, delete linux.sh |
| chezmoi migration | ~400 | Framework handles complexity |
| **Makefile** | ~200 | Dependency tracking, `make help` |
| Move jq install to bootstrap | ~8 | Cleaner separation |
| Subshell for `cd` | ~12 | Simpler, no state to track |
| Timeout helper | ~30 | DRY, easier to maintain |
| Git aliases | ~12 | Idiomatic zsh |
| Remove `command` prefix | ~20 | Cleaner code |
| Lazy ssh-agent | ~5 | Faster shell startup |
| **SSH improvements** | ~0 | Faster connections, no shadowing |
| **1Password improvements** | ~50 | No secrets on disk, better security |

---

# Analysis

## Conflicts & Incompatibilities

| Conflict | Ideas | Resolution |
|----------|-------|------------|
| **Chezmoi negates custom work** | #9 vs #8, #10, #1-7 | If you adopt chezmoi, skip all other refactoring — it handles everything |
| **Homebrew-only makes jq bootstrap obsolete** | #8 vs #2 | If adopting Brewfile, no packages.json to parse → #2 is unnecessary |
| **1Password SSH Agent vs standard agent** | #12C vs #7 | Choose one: 1Password agent (no key on disk) OR optimize standard agent |
| **op inject vs secrets.sh** | #12A vs #1 | If using `op inject`, no `secrets.zsh` exists → #1 consolidation is moot |
| **Makefile assumes keeping bootstrap.sh** | #10 vs #9 | Makefile replaces bootstrap.sh; chezmoi replaces both |

---

## Prioritization Matrix

| # | Idea | Urgency | Effort | Impact | Score | Notes |
|---|------|:-------:|:------:|:------:|:-----:|-------|
| **11** | SSH improvements | Low | Low | High | **A** | Quick win, no dependencies, immediate benefit |
| **5** | Git aliases | Low | Low | Low | **B** | 5 min change, cleaner code |
| **6** | Remove `command` prefix | Low | Low | Low | **B** | Trivial cleanup |
| **3** | Subshells in config | Low | Low | Medium | **B** | Simple, reduces bugs |
| **7** | Lazy ssh-agent | Medium | Low | Medium | **B** | Faster shell startup |
| **4** | Timeout helper | Low | Low | Medium | **B** | DRY improvement |
| **1** | Consolidate git signing | Low | Low | Medium | **B** | Only if keeping secrets.sh |
| **8** | Homebrew-only | Low | Medium | High | **C** | Big simplification, but changes workflow |
| **10** | Makefile | Low | Medium | High | **C** | Pairs well with #8 |
| **12** | 1Password improvements | Medium | Medium | High | **C** | Security uplift, requires decision |
| **2** | Move jq to bootstrap | Low | Low | Low | **D** | Skip if doing #8 |
| **9** | Chezmoi migration | Low | High | High | **E** | Nuclear option — replaces everything |

**Scoring:**
- **A** = Do first (high impact, low effort)
- **B** = Quick wins (batch together)
- **C** = Strategic (plan carefully)
- **D** = Skip/defer
- **E** = Major decision (evaluate separately)

---

## Recommended Execution Order

### Phase 1: Quick Wins (~1 hour)
```
#11 → #5 → #6 → #3 → #7 → #4
```
No conflicts, immediate improvements, can do all in one session.

### Phase 2: Decision Point

Choose ONE path:

| Path | Do | Skip |
|------|-----|------|
| **A: Keep custom** | #8 + #10 + #12 | #9, #2 |
| **B: Migrate to chezmoi** | #9 | #1-8, #10 |

### Phase 3: If Path A
```
#8 (Homebrew-only) → #10 (Makefile) → #12 (1Password)
```
These build on each other. Do #12 last since it requires choosing between `op inject` vs disk secrets.

---

## Decision Tree

```
Start
  │
  ├─► Do you want full control? 
  │     │
  │     ├─ Yes → Path A (keep custom, do #8 + #10 + #12)
  │     │
  │     └─ No → Path B (chezmoi, skip everything else)
  │
  └─► Either way, do Phase 1 quick wins first
```
