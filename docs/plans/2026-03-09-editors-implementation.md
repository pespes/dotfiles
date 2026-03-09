# Editors Package Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a curated editors/ package to the dotfiles repo that tracks VS Code and Cursor extensions, integrates with make install and make audit, and documents Settings Sync setup for fresh Macs.

**Architecture:** `editors/` directory (not a stow package) contains curated extension install scripts for VS Code and Cursor. `scripts/vscode-setup.sh` is the entry point called by `make install`. `scripts/audit.sh` gains extension drift detection. `docs/editors.md` documents Settings Sync re-enable steps.

**Tech Stack:** Bash, VS Code CLI (`code`), Cursor CLI (`/Applications/Cursor.app/Contents/Resources/app/bin/cursor`), GNU Make

**Design doc:** `docs/plans/2026-03-09-vscode-editors-design.md`

---

## Task 1: VS Code Extension Script

**Files:**
- Create: `editors/vscode-extensions.sh`

**Step 1: Create editors/ directory**

```bash
mkdir -p /Users/peteresveld/Documents/GitHub/dotfiles/editors
```

**Step 2: Create `editors/vscode-extensions.sh`**

```bash
#!/usr/bin/env bash
# Curated VS Code extensions
# Run: bash editors/vscode-extensions.sh
# Or:  make editors
#
# Auto-installed dependencies are NOT listed (e.g. redhat.vscode-yaml auto-installs
# with atlassian.atlascode, intellicode-api-usage-examples with vscodeintellicode).
# VS Code-specific extensions (not in Cursor) are marked with [VS Code only].

set -euo pipefail

code --install-extension anthropic.claude-code                          # Claude Code AI assistant [VS Code only]

# -----------------------------------------------------------------------------
# AI & IntelliSense
# -----------------------------------------------------------------------------
code --install-extension google.geminicodeassist                        # Gemini AI code assist
code --install-extension visualstudioexptteam.vscodeintellicode         # AI-assisted IntelliSense
code --install-extension github.copilot-chat                            # GitHub Copilot AI chat [VS Code only]

# -----------------------------------------------------------------------------
# Git & Version Control
# -----------------------------------------------------------------------------
code --install-extension eamodio.gitlens                                # Advanced git history, blame, and insights
code --install-extension github.vscode-github-actions                   # GitHub Actions workflow support
code --install-extension atlassian.atlascode                            # Jira & Confluence integration

# -----------------------------------------------------------------------------
# JavaScript / TypeScript / React / React Native
# -----------------------------------------------------------------------------
code --install-extension dsznajder.es7-react-js-snippets                # ES7+ React/Redux snippets
code --install-extension msjsdiag.vscode-react-native                   # React Native tools
code --install-extension leizongmin.node-module-intellisense            # Node module name autocomplete

# -----------------------------------------------------------------------------
# Web / CSS / HTML
# -----------------------------------------------------------------------------
code --install-extension bradlc.vscode-tailwindcss                      # Tailwind CSS IntelliSense
code --install-extension ecmel.vscode-html-css                          # CSS class name completion for HTML
code --install-extension formulahendry.auto-close-tag                   # Auto-close HTML/XML tags
code --install-extension formulahendry.auto-rename-tag                  # Auto-rename paired HTML tags
code --install-extension astro-build.astro-vscode                       # Astro framework support
code --install-extension svelte.svelte-vscode                           # Svelte framework support

# -----------------------------------------------------------------------------
# Formatting & Linting
# -----------------------------------------------------------------------------
code --install-extension esbenp.prettier-vscode                         # Prettier code formatter
code --install-extension dbaeumer.vscode-eslint                         # ESLint JS/TS linting
code --install-extension wmaurer.change-case                             # Change variable case (camel, snake, etc.)
code --install-extension formulahendry.code-runner                      # Run code snippets directly

# -----------------------------------------------------------------------------
# Python & Jupyter
# -----------------------------------------------------------------------------
code --install-extension ms-python.python                               # Python language support
code --install-extension ms-python.debugpy                              # Python debugger
code --install-extension ms-python.isort                                # Python import sorting
code --install-extension ms-toolsai.jupyter                             # Jupyter notebook support

# -----------------------------------------------------------------------------
# Java
# -----------------------------------------------------------------------------
code --install-extension redhat.java                                    # Java language support
code --install-extension vscjava.vscode-java-debug                      # Java debugger
code --install-extension vscjava.vscode-java-dependency                 # Java dependency viewer
code --install-extension vscjava.vscode-java-test                       # Java test runner
code --install-extension vscjava.vscode-maven                           # Maven support

# -----------------------------------------------------------------------------
# Rust
# -----------------------------------------------------------------------------
code --install-extension rust-lang.rust-analyzer                        # Rust language server

# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
code --install-extension golang.go                                       # Go language support

# -----------------------------------------------------------------------------
# Dart / Flutter
# -----------------------------------------------------------------------------
code --install-extension dart-code.dart-code                            # Dart language support
code --install-extension dart-code.flutter                              # Flutter framework support

# -----------------------------------------------------------------------------
# Remote Development & Containers
# -----------------------------------------------------------------------------
code --install-extension ms-vscode-remote.remote-ssh                    # SSH remote development
code --install-extension ms-vscode-remote.remote-ssh-edit               # Edit SSH config files
code --install-extension ms-vscode-remote.remote-containers             # Dev Containers support
code --install-extension ms-vscode.remote-explorer                      # Remote Explorer panel
code --install-extension ms-azuretools.vscode-docker                    # Docker support
code --install-extension ms-azuretools.vscode-containers                # Container tools
code --install-extension gitpod.gitpod-desktop                          # Gitpod integration

# -----------------------------------------------------------------------------
# Markdown
# -----------------------------------------------------------------------------
code --install-extension yzhang.markdown-all-in-one                     # Markdown preview, TOC, shortcuts
code --install-extension davidanson.vscode-markdownlint                 # Markdown linting

# -----------------------------------------------------------------------------
# Themes & UI
# -----------------------------------------------------------------------------
code --install-extension pkief.material-icon-theme                      # Material file icons
code --install-extension vscode-icons-team.vscode-icons                 # VS Code icons
code --install-extension zhuangtongfa.material-theme                    # One Dark Pro theme
code --install-extension github.github-vscode-theme                     # GitHub theme [VS Code only]
code --install-extension benjaminbenais.copilot-theme                   # Copilot theme

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
code --install-extension mechatroner.rainbow-csv                        # Colorized CSV viewer
code --install-extension christian-kohler.path-intellisense             # File path autocomplete
code --install-extension christian-kohler.npm-intellisense              # npm package autocomplete
code --install-extension figma.figma-vscode-extension                   # Figma design integration
code --install-extension expo.vscode-expo-tools                         # Expo (React Native) tools
```

**Step 3: Make executable**

```bash
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/editors/vscode-extensions.sh
```

**Step 4: Verify syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/editors/vscode-extensions.sh
# Expected: no output
```

**Step 5: Commit**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles
git add editors/vscode-extensions.sh
git commit -m "feat: add curated VS Code extension install script"
```

---

## Task 2: Cursor Extension Script

**Files:**
- Create: `editors/cursor-extensions.sh`

**Step 1: Create `editors/cursor-extensions.sh`**

```bash
#!/usr/bin/env bash
# Curated Cursor extensions
# Run: bash editors/cursor-extensions.sh
# Or:  make editors
#
# Cursor has built-in AI (no need for copilot-chat, claude-code).
# Cursor uses its own Pyright — ms-python.vscode-pylance not listed.
# redhat.vscode-yaml auto-installs with atlassian.atlascode — not listed separately.

set -euo pipefail

CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor

# -----------------------------------------------------------------------------
# AI & IntelliSense
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension google.geminicodeassist                    # Gemini AI code assist
"$CURSOR" --install-extension visualstudioexptteam.vscodeintellicode    # AI-assisted IntelliSense

# -----------------------------------------------------------------------------
# Git & Version Control
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension eamodio.gitlens                            # Advanced git history, blame, and insights
"$CURSOR" --install-extension github.vscode-github-actions               # GitHub Actions workflow support
"$CURSOR" --install-extension atlassian.atlascode                        # Jira & Confluence integration

# -----------------------------------------------------------------------------
# JavaScript / TypeScript / React / React Native
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension dsznajder.es7-react-js-snippets            # ES7+ React/Redux snippets
"$CURSOR" --install-extension msjsdiag.vscode-react-native               # React Native tools
"$CURSOR" --install-extension leizongmin.node-module-intellisense        # Node module name autocomplete

# -----------------------------------------------------------------------------
# Web / CSS / HTML
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension bradlc.vscode-tailwindcss                  # Tailwind CSS IntelliSense
"$CURSOR" --install-extension ecmel.vscode-html-css                      # CSS class name completion for HTML
"$CURSOR" --install-extension formulahendry.auto-close-tag               # Auto-close HTML/XML tags
"$CURSOR" --install-extension formulahendry.auto-rename-tag              # Auto-rename paired HTML tags
"$CURSOR" --install-extension astro-build.astro-vscode                   # Astro framework support
"$CURSOR" --install-extension svelte.svelte-vscode                       # Svelte framework support

# -----------------------------------------------------------------------------
# Formatting & Linting
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension esbenp.prettier-vscode                     # Prettier code formatter
"$CURSOR" --install-extension dbaeumer.vscode-eslint                     # ESLint JS/TS linting
"$CURSOR" --install-extension wmaurer.change-case                        # Change variable case (camel, snake, etc.)
"$CURSOR" --install-extension formulahendry.code-runner                  # Run code snippets directly

# -----------------------------------------------------------------------------
# Python & Jupyter
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension ms-python.python                           # Python language support
"$CURSOR" --install-extension ms-python.debugpy                          # Python debugger
"$CURSOR" --install-extension ms-python.isort                            # Python import sorting
"$CURSOR" --install-extension ms-toolsai.jupyter                         # Jupyter notebook support

# -----------------------------------------------------------------------------
# Java
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension redhat.java                                # Java language support
"$CURSOR" --install-extension vscjava.vscode-java-debug                  # Java debugger
"$CURSOR" --install-extension vscjava.vscode-java-dependency             # Java dependency viewer
"$CURSOR" --install-extension vscjava.vscode-java-test                   # Java test runner
"$CURSOR" --install-extension vscjava.vscode-maven                       # Maven support

# -----------------------------------------------------------------------------
# Rust
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension rust-lang.rust-analyzer                    # Rust language server

# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension golang.go                                   # Go language support

# -----------------------------------------------------------------------------
# Dart / Flutter
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension dart-code.dart-code                        # Dart language support
"$CURSOR" --install-extension dart-code.flutter                          # Flutter framework support

# -----------------------------------------------------------------------------
# Remote Development & Containers
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension ms-vscode-remote.remote-ssh                # SSH remote development
"$CURSOR" --install-extension ms-vscode-remote.remote-ssh-edit           # Edit SSH config files
"$CURSOR" --install-extension ms-vscode-remote.remote-containers         # Dev Containers support
"$CURSOR" --install-extension ms-vscode.remote-explorer                  # Remote Explorer panel
"$CURSOR" --install-extension ms-azuretools.vscode-docker                # Docker support
"$CURSOR" --install-extension ms-azuretools.vscode-containers            # Container tools
"$CURSOR" --install-extension gitpod.gitpod-desktop                      # Gitpod integration

# -----------------------------------------------------------------------------
# Markdown
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension yzhang.markdown-all-in-one                 # Markdown preview, TOC, shortcuts
"$CURSOR" --install-extension davidanson.vscode-markdownlint             # Markdown linting

# -----------------------------------------------------------------------------
# Themes & UI
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension pkief.material-icon-theme                  # Material file icons
"$CURSOR" --install-extension vscode-icons-team.vscode-icons             # VS Code icons
"$CURSOR" --install-extension zhuangtongfa.material-theme                # One Dark Pro theme
"$CURSOR" --install-extension benjaminbenais.copilot-theme               # Copilot theme

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension mechatroner.rainbow-csv                    # Colorized CSV viewer
"$CURSOR" --install-extension christian-kohler.path-intellisense         # File path autocomplete
"$CURSOR" --install-extension christian-kohler.npm-intellisense          # npm package autocomplete
"$CURSOR" --install-extension figma.figma-vscode-extension               # Figma design integration
"$CURSOR" --install-extension expo.vscode-expo-tools                     # Expo (React Native) tools
```

**Step 2: Make executable**

```bash
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/editors/cursor-extensions.sh
```

**Step 3: Verify syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/editors/cursor-extensions.sh
```

**Step 4: Commit**

```bash
git add editors/cursor-extensions.sh
git commit -m "feat: add curated Cursor extension install script"
```

---

## Task 3: vscode-setup.sh Entry Point

**Files:**
- Create: `scripts/vscode-setup.sh`

**Step 1: Create `scripts/vscode-setup.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Setting up editors..."

# VS Code extensions
if command -v code &>/dev/null; then
  echo "--> Installing VS Code extensions..."
  bash "$DOTFILES_DIR/editors/vscode-extensions.sh"
else
  echo "--> VS Code not found (code CLI missing). Skipping."
  echo "    Install VS Code, then run: bash editors/vscode-extensions.sh"
fi

# Cursor extensions
CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
if [ -f "$CURSOR" ]; then
  echo "--> Installing Cursor extensions..."
  bash "$DOTFILES_DIR/editors/cursor-extensions.sh"
else
  echo "--> Cursor not found. Skipping."
  echo "    Install Cursor, then run: bash editors/cursor-extensions.sh"
fi

echo ""
echo "==> Editor extensions installed."
echo ""
echo "    IMPORTANT: Re-enable Settings Sync to restore settings and keybindings."
echo "    See docs/editors.md for step-by-step instructions."
```

**Step 2: Make executable and verify syntax**

```bash
chmod +x /Users/peteresveld/Documents/GitHub/dotfiles/scripts/vscode-setup.sh
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/vscode-setup.sh
```

**Step 3: Commit**

```bash
git add scripts/vscode-setup.sh
git commit -m "feat: add vscode-setup.sh entry point for editor extension install"
```

---

## Task 4: Makefile — Add editors Target and Wire into install

**Files:**
- Modify: `Makefile`

**Step 1: Read current Makefile**

```bash
cat /Users/peteresveld/Documents/GitHub/dotfiles/Makefile
```

**Step 2: Add `editors` target**

Add after the `audit` target:

```makefile
editors: ## Install curated VS Code and Cursor extensions
	@echo "==> Installing editor extensions..."
	@bash scripts/vscode-setup.sh
```

Also add `editors` to the `.PHONY` line.

**Step 3: Wire into `install` target**

Update the `install` target to call `vscode-setup.sh` after `install.sh`:

```makefile
install: ## Full fresh-Mac setup: bootstrap → install → link → editors
	@echo "==> Starting full install..."
	@bash scripts/bootstrap.sh
	@bash scripts/install.sh
	@bash scripts/link.sh
	@bash scripts/vscode-setup.sh
	@echo "==> Install complete. Work through README post-install checklist."
```

**Step 4: Verify Makefile**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles && make help
# Expected: editors target appears in the list
```

**Step 5: Commit**

```bash
git add Makefile
git commit -m "feat: add editors Makefile target, wire vscode-setup into make install"
```

---

## Task 5: Extend audit.sh with Extension Drift Detection

**Files:**
- Modify: `scripts/audit.sh`

**Step 1: Read current audit.sh**

```bash
cat /Users/peteresveld/Documents/GitHub/dotfiles/scripts/audit.sh
```

**Step 2: Add extension drift checks before the final echo lines**

Add this block before `echo "==> Audit complete."`:

```bash
# VS Code extension drift
if command -v code &>/dev/null && [ -f "$DOTFILES_DIR/editors/vscode-extensions.sh" ]; then
  echo "--- VS Code extensions installed but NOT in vscode-extensions.sh ---"
  tracked_vscode=$(grep -oE '[a-z0-9_-]+\.[a-z0-9_-]+' "$DOTFILES_DIR/editors/vscode-extensions.sh" | sort)
  installed_vscode=$(code --list-extensions 2>/dev/null | sort)
  untracked_vscode=$(comm -13 <(echo "$tracked_vscode") <(echo "$installed_vscode") 2>/dev/null || true)
  if [ -n "$untracked_vscode" ]; then
    echo "$untracked_vscode" | sed 's/^/    ! Not tracked: /'
  else
    echo "    All VS Code extensions are tracked."
  fi
  echo ""

  echo "--- VS Code extensions in vscode-extensions.sh but NOT installed ---"
  missing_vscode=$(comm -23 <(echo "$tracked_vscode") <(echo "$installed_vscode") 2>/dev/null || true)
  if [ -n "$missing_vscode" ]; then
    echo "$missing_vscode" | sed 's/^/    ! Not installed: /'
    echo "    Run: make editors"
  else
    echo "    All tracked extensions are installed."
  fi
  echo ""
fi

# Cursor extension drift
CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
if [ -f "$CURSOR" ] && [ -f "$DOTFILES_DIR/editors/cursor-extensions.sh" ]; then
  echo "--- Cursor extensions installed but NOT in cursor-extensions.sh ---"
  tracked_cursor=$(grep -oE '[a-z0-9_-]+\.[a-z0-9_-]+' "$DOTFILES_DIR/editors/cursor-extensions.sh" | sort)
  installed_cursor=$("$CURSOR" --list-extensions 2>/dev/null | sort)
  untracked_cursor=$(comm -13 <(echo "$tracked_cursor") <(echo "$installed_cursor") 2>/dev/null || true)
  if [ -n "$untracked_cursor" ]; then
    echo "$untracked_cursor" | sed 's/^/    ! Not tracked: /'
  else
    echo "    All Cursor extensions are tracked."
  fi
  echo ""

  echo "--- Cursor extensions in cursor-extensions.sh but NOT installed ---"
  missing_cursor=$(comm -23 <(echo "$tracked_cursor") <(echo "$installed_cursor") 2>/dev/null || true)
  if [ -n "$missing_cursor" ]; then
    echo "$missing_cursor" | sed 's/^/    ! Not installed: /'
    echo "    Run: make editors"
  else
    echo "    All tracked Cursor extensions are installed."
  fi
  echo ""
fi
```

**Step 3: Verify syntax**

```bash
bash -n /Users/peteresveld/Documents/GitHub/dotfiles/scripts/audit.sh
```

**Step 4: Run audit to verify it works**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles && make audit
# Expected: extension sections appear, ideally showing "All extensions are tracked"
```

**Step 5: Commit**

```bash
git add scripts/audit.sh
git commit -m "feat: extend audit.sh with VS Code and Cursor extension drift detection"
```

---

## Task 6: docs/editors.md

**Files:**
- Create: `docs/editors.md`

**Step 1: Create `docs/editors.md`**

```markdown
# Editor Setup

## Overview

VS Code and Cursor share a curated extension list managed in this repo.
Settings, keybindings, and snippets are managed by **VS Code Settings Sync** (not dotfiles).

| Asset | Owner |
|---|---|
| Extensions | dotfiles (`editors/*.sh`) |
| `settings.json` | VS Code Settings Sync |
| `keybindings.json` | VS Code Settings Sync |
| `snippets/` | VS Code Settings Sync |

---

## Fresh Mac Setup

### Step 1: Install extensions

Extensions are installed automatically by `make install`. To install manually:

```bash
# VS Code
bash editors/vscode-extensions.sh

# Cursor
bash editors/cursor-extensions.sh

# Or both at once
make editors
```

### Step 2: Re-enable Settings Sync (VS Code)

Settings Sync restores your `settings.json`, `keybindings.json`, and snippets.

1. Open VS Code
2. Click your avatar (bottom-left) → **Turn on Settings Sync...**
3. Sign in with **GitHub**
4. Select all sync categories: Settings, Keybindings, Snippets, Extensions, UI State
5. Choose **Replace Local** if prompted (restores from cloud)

Settings Sync Gist ID (backup reference): `da8dc9a4cbf138a539137d2ca27a07ae`

### Step 3: Re-enable Settings Sync (Cursor)

Cursor has its own Settings Sync, separate from VS Code:

1. Open Cursor
2. `Cmd+Shift+P` → **Cursor Settings Sync: Enable**
3. Sign in with GitHub when prompted

---

## Ongoing Maintenance

### Installing a new extension

```bash
# Install it
code --install-extension some.extension

# Check drift — it will show as untracked
make audit

# Add it to editors/vscode-extensions.sh with a comment
# Then commit
git add editors/vscode-extensions.sh
git commit -m "feat: add some.extension to VS Code extensions"
```

### Removing an extension

```bash
# Uninstall it
code --uninstall-extension some.extension

# Remove the line from editors/vscode-extensions.sh
# Then commit
git add editors/vscode-extensions.sh
git commit -m "chore: remove some.extension from VS Code extensions"
```

### Auditing drift

```bash
make audit
# Shows: extensions installed but not tracked, and tracked but not installed
```

---

## Notes

- `anthropic.claude-code` and `github.copilot-chat` are VS Code only — Cursor has built-in AI
- `github.github-vscode-theme` is VS Code only — theme preference differs per editor
- `redhat.vscode-yaml` is auto-installed by `atlassian.atlascode` — not tracked separately
- `visualstudioexptteam.intellicode-api-usage-examples` is auto-installed by `vscodeintellicode` — not tracked separately
- Python interpreter is managed by pyenv — no `python.defaultInterpreterPath` override needed in settings
```

**Step 2: Commit**

```bash
git add docs/editors.md
git commit -m "docs: add editors.md with Settings Sync setup and maintenance guide"
```

---

## Task 7: Final Verification and Push

**Step 1: Run make help**

```bash
cd /Users/peteresveld/Documents/GitHub/dotfiles && make help
# Expected: editors target visible
```

**Step 2: Run make audit**

```bash
make audit
# Expected: extension sections show "All extensions are tracked" (or minor drift to document)
```

**Step 3: Run make doctor**

```bash
make doctor
# Expected: same as before — rbenv still the only known failure
```

**Step 4: Check git log**

```bash
git log --oneline | head -10
# Expected: all new commits present
```

**Step 5: Push**

```bash
git push
```
