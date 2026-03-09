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
- Python interpreter is managed by pyenv — no `python.defaultInterpreterPath` override needed in settings
