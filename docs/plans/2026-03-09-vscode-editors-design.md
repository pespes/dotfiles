# VS Code / Cursor Editor Setup Design

**Date:** 2026-03-09
**Status:** Approved

---

## Goals

Add editor configuration management to the dotfiles repo:
- Track a curated list of VS Code and Cursor extensions (fresh-Mac install script)
- Document Settings Sync setup for fresh Mac (settings.json owned by Sync, not dotfiles)
- Extend `make audit` to detect extension drift
- Fix two settings conflicts found during audit (python interpreter, yaml.schemas)

## What's In Scope

- `editors/vscode-extensions.sh` — curated, annotated VS Code extension install script
- `editors/cursor-extensions.sh` — curated, annotated Cursor extension install script
- `scripts/vscode-setup.sh` — called by `make install`, runs both extension scripts
- `docs/editors.md` — Settings Sync re-enable instructions for fresh Mac
- `make editors` Makefile target
- Extended `make audit` — compares installed extensions vs tracked scripts
- Python interpreter conflict fix (remove hardcoded path from settings.json) ✅ done
- yaml.schemas conflict: no action needed (Settings Sync owns settings.json)

## What's NOT In Scope

- `settings.json` / `keybindings.json` — owned by VS Code Settings Sync, not dotfiles
- Snippets — owned by Settings Sync
- Zed config — future addition when needed

---

## Architecture

### Settings Ownership

| Asset | Owner |
|---|---|
| `settings.json` | VS Code Settings Sync (GitHub Gist) |
| `keybindings.json` | VS Code Settings Sync |
| `snippets/` | VS Code Settings Sync |
| Extension list | dotfiles (`editors/*.sh`) |
| Extension install on fresh Mac | `make editors` |

Settings Sync and dotfiles co-exist without conflict because they own different assets.

### Repo Structure

```
dotfiles/
├── editors/
│   ├── vscode-extensions.sh      # Curated VS Code extensions (code --install-extension)
│   └── cursor-extensions.sh      # Curated Cursor extensions (cursor --install-extension)
│
├── scripts/
│   └── vscode-setup.sh           # Entry point: runs extension scripts, prints Sync instructions
│
└── docs/
    └── editors.md                # Settings Sync fresh-Mac setup guide
```

`editors/` is NOT a stow package — nothing symlinks into `~`. VS Code config lives in
`~/Library/Application Support/Code/User/` which is too deep for stow.

### Extension Script Format

Each script follows the same pattern as `lang/*-globals.sh`:

```bash
#!/usr/bin/env bash
# Curated VS Code extensions
# Run: bash editors/vscode-extensions.sh
# Or:  make editors

code --install-extension esbenp.prettier-vscode    # Prettier — code formatter
code --install-extension dbaeumer.vscode-eslint    # ESLint — JS/TS linting
# ... one per line with a comment explaining purpose
```

Scripts are idempotent — `code --install-extension` is a no-op if already installed.

---

## Makefile Changes

```makefile
editors: ## Install curated VS Code and Cursor extensions
	@echo "==> Installing editor extensions..."
	@bash scripts/vscode-setup.sh
	@echo "==> Done."
```

`make install` gains a call to `scripts/vscode-setup.sh` after language managers.

---

## Audit Extension

`scripts/audit.sh` gains two new sections:

```
--- VS Code extensions installed but NOT in vscode-extensions.sh ---
    (install but untracked — add to editors/vscode-extensions.sh)

--- VS Code extensions in vscode-extensions.sh but NOT installed ---
    (in script but missing — run make editors to install)
```

Same pattern repeated for Cursor.

---

## docs/editors.md

Documents:
- How Settings Sync works and what it owns
- Step-by-step: re-enable Settings Sync on a fresh Mac
- Backup Gist ID for reference
- How to run `make editors` for extensions
- Note: python interpreter managed by pyenv, no settings.json override needed

---

## Extension Curation

63 extensions currently installed in Cursor. These will be audited like the Brewfile:
- Keep intentional, actively-used extensions with a comment
- Exclude extensions auto-installed as dependencies by other extensions
- Extensions shared between VS Code and Cursor go in both scripts

---

## Day-to-Day Workflow

```
Install a new extension        → make audit catches it; add to editors/*.sh + git commit
Extension in script not found  → make audit flags it; run make editors or remove from script
Fresh Mac                      → make install runs vscode-setup.sh automatically
                                 then enable Settings Sync for settings/keybindings
```
