# Dev Environment Source of Truth — Design

**Date:** 2026-03-09
**Status:** Approved

---

## Goals

Create a single source of truth for a local macOS development environment that enables:

- **Disaster recovery** — back up and running on a fresh Mac in under 2 hours
- **Documentation** — a record of what's installed and why
- **Drift prevention** — the repo is the system; if it's not here, it's not canonical
- **Semi-automated setup** — scripts handle the heavy lifting, pausing at key decisions

**Scope:** Single machine (Apple Silicon Mac), medium depth.

---

## Repo Structure

```
dotfiles/
├── Makefile                  # Entry point for all operations
├── README.md                 # Setup guide, SSH/GPG instructions, post-install checklist
│
├── scripts/
│   ├── bootstrap.sh          # Fresh Mac: Xcode CLT → Homebrew → stow
│   ├── install.sh            # Install all tools (brew, language managers, globals)
│   ├── link.sh               # Run stow on all topic packages
│   └── update.sh             # Update Homebrew, managers, global packages
│
├── homebrew/
│   └── Brewfile              # Curated, categorized, audited package list with comments
│
├── zsh/
│   ├── .zshrc
│   └── .zshenv
│
├── git/
│   └── .gitconfig
│
├── ssh/
│   └── .ssh/
│       └── config            # SSH host aliases and key paths (no private keys)
│
└── lang/
    ├── .tool-versions        # Canonical version pins (human-readable record)
    ├── node-globals.sh       # Global npm packages
    ├── ruby-globals.sh       # Global gems
    ├── python-globals.sh     # Global pip packages
    └── rust-globals.sh       # cargo installs + rustup components
```

---

## Dotfile Management

**Tool:** GNU Stow
**Pattern:** Each top-level directory is a stow package. Files inside mirror the structure of `~`.

```bash
# Link a single package
stow -d ~/dotfiles -t ~ zsh

# Link all packages
make link
```

Edits to live dotfiles (e.g., `~/.zshrc`) are immediately reflected in the repo because they are symlinks — no manual sync required.

**Rule:** Private keys, tokens, and secrets never enter the repo.

---

## Makefile Interface

| Command | Description |
|---|---|
| `make install` | Full fresh-Mac setup: bootstrap → install → link |
| `make link` | Re-run stow to sync symlinks (safe to run anytime) |
| `make update` | Update Homebrew, language managers, global packages |
| `make backup` | Snapshot current state before making changes |
| `make doctor` | Check for broken symlinks, missing tools, SSH/GPG config |
| `make help` | List all commands with descriptions |

`make install` pauses at key decision points (e.g., "Install Java via SDKMAN? [y/N]") for semi-automated control. All scripts are idempotent — safe to run multiple times.

---

## Language Version Management

Managers installed via Homebrew, in dependency order:

| Manager | Language | Version file |
|---|---|---|
| fnm | Node | `.node-version` |
| rbenv | Ruby | `.ruby-version` |
| pyenv | Python | `.python-version` |
| rustup | Rust | (stable toolchain) |
| SDKMAN | Java | (Temurin LTS) |

`lang/.tool-versions` serves as the single human-readable record of canonical versions across all managers.

Global packages are tracked per manager in dedicated shell scripts (`lang/*-globals.sh`) and installed by `make install`. `make update` re-runs them to stay current.

**Note:** `make update` does NOT auto-upgrade language versions — those are explicit decisions, committed to the repo.

---

## Bootstrap Sequence (Fresh Mac)

```
bootstrap.sh
  1. Install Xcode Command Line Tools (skip if present)
  2. Install Homebrew (skip if present)
  3. Install stow via Homebrew

install.sh
  4. brew bundle --file homebrew/Brewfile
  5. Install language managers (fnm, rbenv, pyenv, rustup, SDKMAN)
     → pause at each for confirmation
  6. Run globals scripts for each manager

link.sh
  7. stow all topic packages into ~
```

---

## SSH/GPG & Manual Steps

SSH and GPG keys are machine-specific and sensitive — setup is documented but not automated.

**Tracked in repo:**
- `ssh/.ssh/config` — SSH host config, aliases, key paths

**Documented in README:**
- How to generate an SSH key and add to GitHub/GitLab
- How to generate a GPG key and configure git commit signing
- SSH directory permissions (`chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/*`)

**Post-Install Checklist (README):**
- [ ] Generate SSH key and add to GitHub
- [ ] Generate GPG key and configure git signing
- [ ] Sign into iCloud / App Store
- [ ] Set macOS system preferences
- [ ] Any other one-time steps

`make doctor` verifies SSH key exists, GPG key configured, git signing enabled — without automating the sensitive parts.

---

## Day-to-Day Workflow

**Fresh Mac:**
```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
make install
# Work through README post-install checklist
```

**Adding a dotfile:**
```bash
mv ~/.config/foo ~/dotfiles/editors/.config/foo
make link
git add -p && git commit
```

**Adding a Brew package:**
```bash
brew install <package>
# Add to Brewfile with a comment explaining why
git add -p && git commit
```

**Keeping current:**
```bash
make update    # regular maintenance
make doctor    # when something feels off
```

---

## Documentation Strategy

- **README.md** — high-level orientation, fresh Mac setup steps, SSH/GPG instructions, post-install checklist
- **Inline comments** — Brewfile categories and explanations, script logic documented where non-obvious
- **The repo is the system** — if it's not committed, it's not part of the environment
