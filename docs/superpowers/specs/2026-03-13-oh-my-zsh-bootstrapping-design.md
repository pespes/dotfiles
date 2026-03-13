# oh-my-zsh Bootstrapping Design

**Date:** 2026-03-13
**Status:** Approved

## Summary

Add prompted oh-my-zsh installation (plus required plugins) to `scripts/install.sh`, following the existing pattern for language managers.

## Changes

### `scripts/install.sh`

Insert a new section 2 before the language managers:

```bash
# 2. oh-my-zsh + plugins
if confirm "--> Set up oh-my-zsh?"; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "    oh-my-zsh already installed. Skipping."
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
fi
```

Existing section comment numbers also update: `# 2. fnm` → `# 3. fnm`, `# 3. rbenv` → `# 4. rbenv`, `# 4. pyenv` → `# 5. pyenv`, `# 5. rustup` → `# 6. rustup`, `# 6. SDKMAN` → `# 7. SDKMAN`.

## Design Decisions

- **Placement:** `install.sh` (not `bootstrap.sh`) — consistent with other optional tools; bootstrap stays minimal and automatic.
- **Prompted:** Uses existing `confirm` helper, matching language manager UX.
- **`--unattended` flag:** Prevents oh-my-zsh installer from spawning a new shell mid-script, which would stall `make install`.
- **Idempotent:** Each step checks for existence before acting — safe to re-run.
- **Plugins included:** `zsh-autosuggestions` and `zsh-syntax-highlighting` are already referenced in `zsh/.zshrc` and must be present for the shell to load cleanly. They are cloned into `$ZSH_CUSTOM/plugins/` as oh-my-zsh custom plugins.

## Stow Symlink Warning

The oh-my-zsh installer (even with `--unattended`) backs up any existing `~/.zshrc` to `~/.zshrc.pre-oh-my-zsh` and writes a new one. During a fresh `make install`, this is safe because `install.sh` runs before `link.sh` (Makefile order: bootstrap → install → link → editors), so no Stow symlink exists yet.

**Re-run risk:** If `link.sh` has already been run in this environment (i.e., `~/.zshrc` is already a Stow symlink), running `install.sh` again and accepting the oh-my-zsh prompt will replace that symlink with a generated file. Run `make link` afterward to restore it.

## No Other Files Changed

- `zsh/.zshrc` already references oh-my-zsh and both plugins correctly — no changes needed.
- `homebrew/Brewfile` unchanged — oh-my-zsh is not a Homebrew package.
- `scripts/doctor.sh` unchanged — out of scope for this change.
