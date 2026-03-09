# Dotfiles Source of Truth Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a topic-based dotfiles repo that serves as a single source of truth for a macOS development environment, enabling semi-automated fresh Mac setup and ongoing maintenance.

**Architecture:** Topic-based GNU Stow packages (each top-level directory is a package that mirrors `~`). A Makefile provides the user interface, backed by shell scripts in `scripts/`. All scripts are idempotent.

**Tech Stack:** GNU Stow, Bash/Zsh, Make, Homebrew, fnm, rbenv, pyenv, rustup, SDKMAN

**Design doc:** `docs/plans/2026-03-09-dev-environment-source-of-truth-design.md`

---

## Task 1: Repo Scaffolding

**Files:**
- Create: `.gitignore`
- Create: `README.md` (skeleton)
- Create: `scripts/` directory placeholder

**Step 1: Create .gitignore**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/.gitignore << 'EOF'
# macOS
.DS_Store
.DS_Store?
._*

# Secrets — never commit these
.ssh/id_*
.ssh/known_hosts
.env
*.pem
*.key

# Homebrew caches
.bundle/

# Editor artifacts
*.swp
*.swo
EOF
```

**Step 2: Create README skeleton**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/README.md << 'EOF'
# dotfiles

Personal macOS development environment — source of truth.

## Quick Start (Fresh Mac)

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
make install
```

Then work through the [Post-Install Checklist](#post-install-checklist).

## Commands

| Command | Description |
|---|---|
| `make install` | Full fresh-Mac setup |
| `make link` | Sync symlinks (safe anytime) |
| `make update` | Update all tools |
| `make backup` | Snapshot current state |
| `make doctor` | Check environment health |
| `make help` | Show all commands |

## What's Managed

- Homebrew packages (`homebrew/Brewfile`)
- Shell config (`zsh/`)
- Git config (`git/`)
- SSH config (`ssh/`)
- Language version managers + global packages (`lang/`)

## SSH Setup

1. Generate a new SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ```
2. Add to ssh-agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```
3. Copy public key and add to GitHub → Settings → SSH Keys:
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```
4. Set permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/*
   chmod 644 ~/.ssh/*.pub
   ```

## GPG Setup

1. Install GPG (via Brewfile):
   ```bash
   brew install gnupg pinentry-mac
   ```
2. Generate a key:
   ```bash
   gpg --full-generate-key
   # Choose: RSA, 4096 bits, your name and email
   ```
3. Get your key ID:
   ```bash
   gpg --list-secret-keys --keyid-format=long
   # Copy the ID after "sec rsa4096/"
   ```
4. Configure git to use it (already in .gitconfig template — fill in your key ID):
   ```bash
   git config --global user.signingkey YOUR_KEY_ID
   ```
5. Add public key to GitHub → Settings → GPG Keys:
   ```bash
   gpg --armor --export YOUR_KEY_ID | pbcopy
   ```

## Post-Install Checklist

- [ ] Generate SSH key and add to GitHub (see [SSH Setup](#ssh-setup))
- [ ] Generate GPG key and configure git signing (see [GPG Setup](#gpg-setup))
- [ ] Sign into iCloud
- [ ] Set macOS system preferences (keyboard repeat rate, dock, etc.)
- [ ] Open apps that require license activation
- [ ] Configure any app-specific settings not captured here
EOF
```

**Step 3: Create scripts placeholder**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/scripts
touch /Users/peteresveld/Documents/GitHub/dotfiles/scripts/.keep
```

**Step 4: Verify**

```bash
ls /Users/peteresveld/Documents/GitHub/dotfiles/
# Expected: .gitignore  README.md  docs/  scripts/
```

**Step 5: Commit**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles
git add .gitignore README.md scripts/
git commit -m "feat: add repo scaffolding, README, and .gitignore"
```

---

## Task 2: Makefile

**Files:**
- Create: `Makefile`

**Step 1: Write the Makefile**

```makefile
# dotfiles/Makefile

DOTFILES_DIR := $(shell pwd)
STOW_PACKAGES := zsh git ssh lang

.PHONY: help install link update backup doctor

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full fresh-Mac setup: bootstrap → install → link
	@echo "==> Starting full install..."
	@bash scripts/bootstrap.sh
	@bash scripts/install.sh
	@bash scripts/link.sh
	@echo "==> Install complete. Work through README post-install checklist."

link: ## Sync all dotfile symlinks (safe to run anytime)
	@echo "==> Linking dotfiles..."
	@bash scripts/link.sh
	@echo "==> Done."

update: ## Update Homebrew, language managers, and global packages
	@echo "==> Updating..."
	@bash scripts/update.sh
	@echo "==> Done."

backup: ## Snapshot current Homebrew state
	@echo "==> Backing up..."
	@brew bundle dump --file=homebrew/Brewfile.backup --force
	@echo "==> Backup saved to homebrew/Brewfile.backup"

doctor: ## Check for broken symlinks, missing tools, SSH/GPG config
	@echo "==> Running doctor checks..."
	@bash scripts/doctor.sh
```

**Step 2: Verify Makefile parses correctly**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles && make help
# Expected: colored table of commands
```

**Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile with install/link/update/backup/doctor targets"
```

---

## Task 3: bootstrap.sh

**Files:**
- Create: `scripts/bootstrap.sh`

**Step 1: Write bootstrap.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/scripts/bootstrap.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Bootstrap: Xcode CLT, Homebrew, stow"

# 1. Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "--> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Waiting for Xcode CLT install to complete..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  echo "    Done."
else
  echo "--> Xcode CLT already installed. Skipping."
fi

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "--> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "--> Homebrew already installed. Skipping."
fi

# 3. stow
if ! command -v stow &>/dev/null; then
  echo "--> Installing stow..."
  brew install stow
else
  echo "--> stow already installed. Skipping."
fi

echo "==> Bootstrap complete."
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/bootstrap.sh
```

**Step 2: Verify script is valid**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/bootstrap.sh
# Expected: no output (no syntax errors)
```

**Step 3: Commit**

```bash
git add scripts/bootstrap.sh
git commit -m "feat: add bootstrap.sh (Xcode CLT, Homebrew, stow)"
```

---

## Task 4: Homebrew Brewfile

**Files:**
- Create: `homebrew/Brewfile`

**Step 1: Generate a reference list of current installs**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/homebrew
brew list --formula > /tmp/brew-current-formulas.txt
brew list --cask > /tmp/brew-current-casks.txt
cat /tmp/brew-current-formulas.txt
cat /tmp/brew-current-casks.txt
```

Review the output. For each package, decide: does it belong in the source of truth? Add only intentional, documented packages.

**Step 2: Write the audited Brewfile**

Create `homebrew/Brewfile` by hand, organized into categories. Template:

```ruby
# homebrew/Brewfile
# Run: brew bundle --file=homebrew/Brewfile

tap "homebrew/bundle"
tap "homebrew/cask"

# -----------------------------------------------------------------------------
# Shell & Terminal
# -----------------------------------------------------------------------------
brew "stow"           # Dotfile symlink manager
brew "zsh"            # Shell (macOS default, kept current)
brew "fzf"            # Fuzzy finder
brew "ripgrep"        # Fast grep (rg)
brew "bat"            # Better cat
brew "eza"            # Better ls
brew "zoxide"         # Smarter cd
brew "starship"       # Shell prompt (or spaceship if preferred)

# -----------------------------------------------------------------------------
# Git & Version Control
# -----------------------------------------------------------------------------
brew "git"
brew "gh"             # GitHub CLI
brew "git-delta"      # Better git diffs

# -----------------------------------------------------------------------------
# Language Version Managers
# -----------------------------------------------------------------------------
brew "fnm"            # Fast Node Manager
brew "rbenv"          # Ruby version manager
brew "ruby-build"     # rbenv plugin: build Ruby versions
brew "pyenv"          # Python version manager
brew "rustup"         # Rust toolchain manager

# -----------------------------------------------------------------------------
# Languages & Runtimes (managed via version managers above)
# SDKMAN handles Java separately — installed by install.sh
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Development Tools
# -----------------------------------------------------------------------------
brew "gnupg"          # GPG encryption
brew "pinentry-mac"   # GPG passphrase entry on macOS
brew "jq"             # JSON processor
brew "httpie"         # HTTP client (or curl)
brew "docker"         # Container runtime

# -----------------------------------------------------------------------------
# Editors & IDEs (add your preferred ones)
# -----------------------------------------------------------------------------
# cask "cursor"
# cask "zed"
# cask "visual-studio-code"

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
# Add your apps here with a comment explaining why
```

Fill in from your reference list, adding comments for anything non-obvious.

**Step 3: Verify Brewfile syntax**

```bash
brew bundle check --file=/Users/peteresveld/Documents/GitHub/dotfiles/homebrew/Brewfile
# Expected: "The Brewfile's dependencies are satisfied."
# (or a list of what would be installed — not an error)
```

**Step 4: Commit**

```bash
git add homebrew/Brewfile
git commit -m "feat: add audited, categorized Brewfile"
```

---

## Task 5: install.sh

**Files:**
- Create: `scripts/install.sh`

**Step 1: Write install.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/scripts/install.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

echo "==> Installing tools..."

# 1. Homebrew packages
echo "--> Installing Homebrew packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/homebrew/Brewfile"

# 2. fnm (Node)
if confirm "--> Set up Node via fnm?"; then
  if ! command -v fnm &>/dev/null; then brew install fnm; fi
  eval "$(fnm env)"
  fnm install --lts
  fnm use lts-latest
  echo "    Installing global Node packages..."
  bash "$DOTFILES_DIR/lang/node-globals.sh"
fi

# 3. rbenv (Ruby)
if confirm "--> Set up Ruby via rbenv?"; then
  if ! command -v rbenv &>/dev/null; then brew install rbenv ruby-build; fi
  eval "$(rbenv init -)"
  RUBY_VERSION=$(cat "$DOTFILES_DIR/lang/.tool-versions" | grep ruby | awk '{print $2}')
  rbenv install -s "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
  echo "    Installing global gems..."
  bash "$DOTFILES_DIR/lang/ruby-globals.sh"
fi

# 4. pyenv (Python)
if confirm "--> Set up Python via pyenv?"; then
  if ! command -v pyenv &>/dev/null; then brew install pyenv; fi
  eval "$(pyenv init -)"
  PYTHON_VERSION=$(cat "$DOTFILES_DIR/lang/.tool-versions" | grep python | awk '{print $2}')
  pyenv install -s "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
  echo "    Installing global pip packages..."
  bash "$DOTFILES_DIR/lang/python-globals.sh"
fi

# 5. rustup (Rust)
if confirm "--> Set up Rust via rustup?"; then
  if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
  rustup update stable
  bash "$DOTFILES_DIR/lang/rust-globals.sh"
fi

# 6. SDKMAN (Java)
if confirm "--> Set up Java via SDKMAN?"; then
  if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
  fi
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java  # installs default (latest LTS Temurin)
fi

echo "==> Install complete."
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/install.sh
```

**Step 2: Verify script syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/install.sh
# Expected: no output
```

**Step 3: Commit**

```bash
git add scripts/install.sh
git commit -m "feat: add install.sh with semi-automated language manager setup"
```

---

## Task 6: link.sh

**Files:**
- Create: `scripts/link.sh`

**Step 1: Write link.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/scripts/link.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(zsh git ssh lang)

echo "==> Linking dotfiles via stow..."

for package in "${PACKAGES[@]}"; do
  if [ -d "$DOTFILES_DIR/$package" ]; then
    echo "--> Linking $package..."
    stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$package"
  else
    echo "--> $package directory not found, skipping."
  fi
done

echo "==> Symlinks created."
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/link.sh
```

**Step 2: Verify syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/link.sh
```

**Step 3: Commit**

```bash
git add scripts/link.sh
git commit -m "feat: add link.sh for stow-based dotfile symlinking"
```

---

## Task 7: update.sh

**Files:**
- Create: `scripts/update.sh`

**Step 1: Write update.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/scripts/update.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating development environment..."

# Homebrew
echo "--> Updating Homebrew packages..."
brew update && brew upgrade && brew cleanup

# Global Node packages
if command -v fnm &>/dev/null; then
  echo "--> Updating global Node packages..."
  eval "$(fnm env)"
  bash "$DOTFILES_DIR/lang/node-globals.sh"
fi

# Global gems
if command -v rbenv &>/dev/null; then
  echo "--> Updating global gems..."
  eval "$(rbenv init -)"
  bash "$DOTFILES_DIR/lang/ruby-globals.sh"
fi

# Global Python packages
if command -v pyenv &>/dev/null; then
  echo "--> Updating global Python packages..."
  eval "$(pyenv init -)"
  bash "$DOTFILES_DIR/lang/python-globals.sh"
fi

# Rust toolchain
if command -v rustup &>/dev/null; then
  echo "--> Updating Rust toolchain..."
  rustup update
  bash "$DOTFILES_DIR/lang/rust-globals.sh"
fi

# SDKMAN
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  echo "--> Updating SDKMAN..."
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk selfupdate
fi

echo "==> Update complete."
echo "    Note: Language runtime versions are NOT auto-upgraded."
echo "    To upgrade a runtime, edit lang/.tool-versions and reinstall."
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/update.sh
```

**Step 2: Verify syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/update.sh
```

**Step 3: Commit**

```bash
git add scripts/update.sh
git commit -m "feat: add update.sh for Homebrew and global package updates"
```

---

## Task 8: doctor.sh

**Files:**
- Create: `scripts/doctor.sh`

**Step 1: Write doctor.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/scripts/doctor.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

PASS="\033[32m✓\033[0m"
FAIL="\033[31m✗\033[0m"
WARN="\033[33m!\033[0m"
errors=0

check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo -e " $PASS $label"
  else
    echo -e " $FAIL $label"
    ((errors++))
  fi
}

warn() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo -e " $PASS $label"
  else
    echo -e " $WARN $label (optional)"
  fi
}

echo "==> Doctor: checking environment health"
echo ""
echo "--- Core Tools ---"
check "Homebrew installed"     "command -v brew"
check "stow installed"         "command -v stow"
check "git installed"          "command -v git"

echo ""
echo "--- Language Managers ---"
check "fnm installed"          "command -v fnm"
check "rbenv installed"        "command -v rbenv"
check "pyenv installed"        "command -v pyenv"
check "rustup installed"       "command -v rustup"
warn  "SDKMAN installed"       "[ -d $HOME/.sdkman ]"

echo ""
echo "--- Dotfile Symlinks ---"
check "~/.zshrc is symlinked"      "[ -L $HOME/.zshrc ]"
check "~/.gitconfig is symlinked"  "[ -L $HOME/.gitconfig ]"
warn  "~/.ssh/config exists"       "[ -f $HOME/.ssh/config ]"

echo ""
echo "--- SSH & GPG ---"
warn  "SSH key exists"           "ls $HOME/.ssh/id_*.pub 2>/dev/null"
warn  "GPG key configured"       "git config --global user.signingkey"
warn  "GPG signing enabled"      "[ \"\$(git config --global commit.gpgsign)\" = 'true' ]"

echo ""
echo "--- Broken Symlinks in ~ ---"
broken=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
if [ -z "$broken" ]; then
  echo -e " $PASS No broken symlinks in ~"
else
  echo -e " $FAIL Broken symlinks found:"
  echo "$broken"
  ((errors++))
fi

echo ""
if [ "$errors" -eq 0 ]; then
  echo "==> All checks passed."
else
  echo "==> $errors check(s) failed. Review output above."
  exit 1
fi
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/doctor.sh
```

**Step 2: Run doctor to verify it works**

```bash
bash /Users/peteresveld/Documents/GitHub/dotfiles/scripts/doctor.sh
# Expected: check results — some may fail until dotfiles are linked (that's ok)
```

**Step 3: Commit**

```bash
git add scripts/doctor.sh
git commit -m "feat: add doctor.sh for environment health checks"
```

---

## Task 9: Zsh Topic Package

**Files:**
- Create: `zsh/.zshrc` (migrated from `~/.zshrc`)
- Create: `zsh/.zshenv` (if exists at `~/.zshenv`)

**Step 1: Copy current zsh config into the package**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/zsh
cp ~/.zshrc /Users/peteresveld/Documents/GitHub/dotfiles/zsh/.zshrc
# Only copy .zshenv if it exists
[ -f ~/.zshenv ] && cp ~/.zshenv /Users/peteresveld/Documents/GitHub/dotfiles/zsh/.zshenv
```

**Step 2: Review and clean up .zshrc**

Open `zsh/.zshrc` and:
- Add a comment at the top: `# Managed by dotfiles — edit in ~/dotfiles/zsh/.zshrc`
- Remove any machine-specific paths that shouldn't be shared
- Add fnm, rbenv, pyenv, rustup initialization if not already present:

```zsh
# fnm (Node)
eval "$(fnm env --use-on-cd)"

# rbenv (Ruby)
eval "$(rbenv init - zsh)"

# pyenv (Python)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# SDKMAN (Java) — must be at end of file
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

**Step 3: Back up and link**

```bash
# Back up existing .zshrc
mv ~/.zshrc ~/.zshrc.backup

# Link
cd /Users/peteresveld/Documents/GitHub/dotfiles
stow -d . -t ~ --restow zsh

# Verify
ls -la ~/.zshrc
# Expected: ~/.zshrc -> /Users/peteresveld/Documents/GitHub/dotfiles/zsh/.zshrc
```

**Step 4: Test shell loads correctly**

```bash
zsh -c 'source ~/.zshrc && echo "ZSH OK"'
# Expected: ZSH OK (no errors)
```

**Step 5: Commit**

```bash
git add zsh/
git commit -m "feat: add zsh topic package with .zshrc and language manager init"
```

---

## Task 10: Git Topic Package

**Files:**
- Create: `git/.gitconfig`

**Step 1: Copy current gitconfig**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/git
cp ~/.gitconfig /Users/peteresveld/Documents/GitHub/dotfiles/git/.gitconfig
```

**Step 2: Review .gitconfig**

Open `git/.gitconfig` and ensure it has sensible defaults. Add GPG signing config template if not present:

```ini
[user]
    name = Your Name
    email = your@email.com
    signingkey = YOUR_GPG_KEY_ID   # fill in after GPG setup

[commit]
    gpgsign = true

[core]
    editor = code --wait          # or your preferred editor

[pull]
    rebase = true

[init]
    defaultBranch = main

[gpg]
    program = gpg
```

**Step 3: Back up and link**

```bash
mv ~/.gitconfig ~/.gitconfig.backup
cd /Users/peteresveld/Documents/GitHub/dotfiles
stow -d . -t ~ --restow git
ls -la ~/.gitconfig
# Expected: ~/.gitconfig -> .../dotfiles/git/.gitconfig
```

**Step 4: Verify git works**

```bash
git config --list | head -10
# Expected: your config values
```

**Step 5: Commit**

```bash
git add git/
git commit -m "feat: add git topic package with .gitconfig"
```

---

## Task 11: SSH Topic Package

**Files:**
- Create: `ssh/.ssh/config`

**Step 1: Create the package structure**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/ssh/.ssh
```

**Step 2: Copy SSH config (not keys)**

```bash
# Copy only the config file — never copy private keys
[ -f ~/.ssh/config ] && cp ~/.ssh/config /Users/peteresveld/Documents/GitHub/dotfiles/ssh/.ssh/config

# If no config exists yet, create a starter
if [ ! -f /Users/peteresveld/Documents/GitHub/dotfiles/ssh/.ssh/config ]; then
cat > /Users/peteresveld/Documents/GitHub/dotfiles/ssh/.ssh/config << 'SSHEOF'
# SSH Config — managed by dotfiles
# Private keys live in ~/.ssh/ and are NOT committed to the repo

Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes
SSHEOF
fi
```

**Step 3: Verify .gitignore covers SSH keys**

```bash
grep 'id_' /Users/peteresveld/Documents/GitHub/dotfiles/.gitignore
# Expected: .ssh/id_* line present
```

**Step 4: Link**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles
stow -d . -t ~ --restow ssh
ls -la ~/.ssh/config
# Expected: symlink to dotfiles/ssh/.ssh/config
```

**Step 5: Commit**

```bash
git add ssh/
git commit -m "feat: add ssh topic package with config template"
```

---

## Task 12: Lang Topic Package

**Files:**
- Create: `lang/.tool-versions`
- Create: `lang/node-globals.sh`
- Create: `lang/ruby-globals.sh`
- Create: `lang/python-globals.sh`
- Create: `lang/rust-globals.sh`

**Step 1: Create .tool-versions with current pinned versions**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/lang

# Get current versions
node_ver=$(fnm current 2>/dev/null || echo "lts-latest")
ruby_ver=$(rbenv version-name 2>/dev/null || echo "3.3.0")
python_ver=$(pyenv version-name 2>/dev/null || echo "3.12.0")
rust_ver=$(rustup show active-toolchain 2>/dev/null | awk '{print $1}' || echo "stable")

cat > /Users/peteresveld/Documents/GitHub/dotfiles/lang/.tool-versions << EOF
# Canonical language version pins
# These are human-readable records — each manager uses its own format natively
node    $node_ver
ruby    $ruby_ver
python  $python_ver
rust    $rust_ver
java    temurin-21  # SDKMAN — update after SDKMAN install
EOF
```

**Step 2: Create node-globals.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/lang/node-globals.sh << 'EOF'
#!/usr/bin/env bash
# Global npm packages
# Add packages you want available globally, with a comment explaining why

npm install -g \
  pnpm \           # Fast package manager
  typescript \     # TypeScript compiler
  ts-node          # Run TypeScript directly
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/lang/node-globals.sh
```

Edit to add your actual global packages.

**Step 3: Create ruby-globals.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/lang/ruby-globals.sh << 'EOF'
#!/usr/bin/env bash
# Global gems
gem install \
  bundler \
  rails   # Remove if not needed
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/lang/ruby-globals.sh
```

**Step 4: Create python-globals.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/lang/python-globals.sh << 'EOF'
#!/usr/bin/env bash
# Global pip packages
pip install --upgrade \
  pip \
  pipx \
  black \
  ruff
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/lang/python-globals.sh
```

**Step 5: Create rust-globals.sh**

```bash
cat > /Users/peteresveld/Documents/GitHub/dotfiles/lang/rust-globals.sh << 'EOF'
#!/usr/bin/env bash
# Rust global installs and components
rustup component add \
  clippy \
  rustfmt

# cargo installs
cargo install \
  cargo-watch \
  cargo-edit
EOF
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/lang/rust-globals.sh
```

**Step 6: Link lang package**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles
stow -d . -t ~ --restow lang
ls -la ~/.tool-versions
# Expected: symlink to dotfiles/lang/.tool-versions
```

**Step 7: Commit**

```bash
git add lang/
git commit -m "feat: add lang topic package with version pins and global package scripts"
```

---

## Task 13: Full Integration Verification

**Step 1: Run make doctor**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles && make doctor
# Expected: all installed tools check green, symlinks verified
```

**Step 2: Verify all symlinks**

```bash
ls -la ~/.zshrc ~/.gitconfig ~/.ssh/config ~/.tool-versions
# Expected: all are symlinks pointing into ~/dotfiles/
```

**Step 3: Verify make help works**

```bash
make help
# Expected: formatted table of all commands
```

**Step 4: Open a new terminal and verify shell loads cleanly**

Open a new terminal tab. Expected: no errors, prompt loads, all version managers initialized.

**Step 5: Commit final state**

```bash
git add -A
git status
# Expected: clean working tree (nothing to commit, or only untracked files)
```

---

## Task 14: Push to Remote

**Step 1: Create a GitHub repo**

```bash
gh repo create dotfiles --private --description "Personal macOS dev environment source of truth"
```

**Step 2: Push**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles
git remote add origin git@github.com:peteresveld/dotfiles.git
git push -u origin main
```

**Step 3: Update README with clone URL**

Edit `README.md` — replace `<your-repo-url>` with the actual GitHub URL.

```bash
git add README.md
git commit -m "docs: add actual repo URL to README"
git push
```

---

## Ongoing Maintenance

| When | Command |
|---|---|
| Daily/weekly | `make update` |
| After adding a dotfile | `make link && git commit` |
| After installing a brew package | Edit Brewfile + `git commit` |
| Something feels broken | `make doctor` |
| Before major changes | `make backup` |
