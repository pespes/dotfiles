# Migrate Python Tooling to uv Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace pyenv + pip with uv as the single tool for Python version management and global tool installation.

**Architecture:** Six files are edited in sequence. Brewfile and python-globals.sh are data files — straightforward replacements. .zshrc, install.sh, update.sh, and doctor.sh are shell scripts — each has one function/block swapped. No new files are created. The Python version pin in lang/.tool-versions is unchanged.

**Tech Stack:** Bash, Zsh, uv (via Homebrew), shellcheck, GNU stow.

**Spec:** `docs/superpowers/specs/2026-06-06-migrate-python-to-uv-design.md`

---

## File Map

| File | Change |
|------|--------|
| `homebrew/Brewfile` | Remove `pyenv` + `pyenv-virtualenv`, add `uv` |
| `lang/python-globals.sh` | Rewrite: `uv tool install black/ruff` replaces `pip install` block |
| `zsh/.zshrc` | Remove pyenv init block + `pip()` wrapper; add `uv()` wrapper |
| `scripts/install.sh` | Replace `install_python()` |
| `scripts/update.sh` | Replace `update_python()` + section header |
| `scripts/doctor.sh` | Replace `check_python_pin()`, pyenv manager check, pyenv init block |

---

## Task 1: Verify baseline lint is clean

**Files:**
- Read: `scripts/*.sh`, `lang/*.sh` (via shellcheck)

- [ ] **Step 1: Run make lint and confirm it passes**

```bash
make lint
```

Expected output:
```
✓ shellcheck clean (warning level)
```

If lint fails, stop — do not proceed until the repo is clean.

---

## Task 2: Update homebrew/Brewfile

**Files:**
- Modify: `homebrew/Brewfile:28-29`

- [ ] **Step 1: Remove pyenv lines and add uv**

In `homebrew/Brewfile`, replace lines 28–29:

```
brew "pyenv"          # Python version manager
brew "pyenv-virtualenv" # pyenv plugin: manage virtualenvs
```

With:

```
brew "uv"             # Python version manager and package tool
```

The section header `# Language Version Managers` stays. The surrounding lines (`brew "fnm"`, `brew "rbenv"`, etc.) are untouched.

- [ ] **Step 2: Verify the file looks correct**

```bash
grep -n "pyenv\|uv" homebrew/Brewfile
```

Expected: only `brew "uv"` line — no pyenv lines remain.

- [ ] **Step 3: Commit**

```bash
git add homebrew/Brewfile
git commit -m "feat: replace pyenv with uv in Brewfile"
```

---

## Task 3: Rewrite lang/python-globals.sh

**Files:**
- Modify: `lang/python-globals.sh`

- [ ] **Step 1: Replace the file contents**

Overwrite `lang/python-globals.sh` with:

```bash
#!/usr/bin/env bash
#
# python-globals.sh — Global Python tools (uv-managed).
#
# Invoked by:  scripts/install.sh, scripts/update.sh
# Not stowed:  Repo only — see lang/.stow-local-ignore.
#
set -euo pipefail

uv tool install black
uv tool install ruff
```

- [ ] **Step 2: Run lint to confirm shellcheck is clean**

```bash
make lint
```

Expected: `✓ shellcheck clean (warning level)`

- [ ] **Step 3: Commit**

```bash
git add lang/python-globals.sh
git commit -m "feat: rewrite python-globals.sh to use uv tool install"
```

---

## Task 4: Update zsh/.zshrc

**Files:**
- Modify: `zsh/.zshrc:26-29` (remove pyenv init), `zsh/.zshrc:93-103` (replace pip wrapper)

Note: `.zshrc` uses zsh-only syntax and is intentionally excluded from shellcheck. Validate by opening a new shell after the change instead.

- [ ] **Step 1: Remove the pyenv init block**

In `zsh/.zshrc`, delete these four lines (currently lines 26–29):

```zsh
# pyenv (Python)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
```

Leave the blank line above (`# fnm (Node)` block) and below (`# rbenv (Ruby)` block) intact.

- [ ] **Step 2: Replace the pip() wrapper with the uv() wrapper**

In `zsh/.zshrc`, find and remove this block (currently around lines 93–103):

```zsh
pip() {
  command pip "$@"
  if [[ "$1" == "install" && -n "$2" && "$2" != "--upgrade" && "$2" != -* ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/python-globals.sh"
    if ! _dotfiles_tracked "$pkg" "$globals"; then
      _dotfiles_track_continuation "$globals" '^pip install --upgrade' "$pkg"
      echo "dotfiles → Added '$pkg' to python-globals.sh. Commit when ready."
    fi
  fi
}
```

Replace it with:

```zsh
uv() {
  command uv "$@"
  if [[ "$1" == "tool" && "$2" == "install" && -n "$3" ]]; then
    local pkg="$3"
    local globals="$DOTFILES_DIR/lang/python-globals.sh"
    if ! _dotfiles_tracked "$pkg" "$globals"; then
      echo "uv tool install $pkg" >> "$globals"
      echo "dotfiles → Added '$pkg' to python-globals.sh. Commit when ready."
    fi
  fi
}
```

- [ ] **Step 3: Verify the file has no remaining pyenv or pip() references**

```bash
grep -n "pyenv\|^pip()" zsh/.zshrc
```

Expected: no output (zero matches).

- [ ] **Step 4: Commit**

```bash
git add zsh/.zshrc
git commit -m "feat: replace pyenv init and pip() wrapper with uv() wrapper in .zshrc"
```

---

## Task 5: Update scripts/install.sh

**Files:**
- Modify: `scripts/install.sh` — `install_python()` function

- [ ] **Step 1: Replace install_python()**

In `scripts/install.sh`, find and replace the entire `install_python()` function:

**Remove:**
```bash
install_python() {
  if ! confirm "Set up Python via pyenv?"; then
    skip "Python/pyenv (declined)"
    return 0
  fi
  if ! command -v pyenv &>/dev/null; then
    echo "    pyenv not found — ensure Homebrew step succeeded."
    return 1
  fi
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  local version
  version=$(tool_version python "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    skip "Python (no version in lang/.tool-versions)"
    return 0
  fi
  pyenv install -s "$version"
  pyenv global "$version"
  ok "Python $(python --version 2>/dev/null | awk '{print $2}')"
  run_globals_script "$DOTFILES_DIR/lang/python-globals.sh"
}
```

**Replace with:**
```bash
install_python() {
  if ! confirm "Set up Python via uv?"; then
    skip "Python/uv (declined)"
    return 0
  fi
  if ! command -v uv &>/dev/null; then
    echo "    uv not found — ensure Homebrew step succeeded."
    return 1
  fi
  local version
  version=$(tool_version python "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    skip "Python (no version in lang/.tool-versions)"
    return 0
  fi
  uv python install "$version"
  ok "Python $version"
  run_globals_script "$DOTFILES_DIR/lang/python-globals.sh"
}
```

- [ ] **Step 2: Run lint**

```bash
make lint
```

Expected: `✓ shellcheck clean (warning level)`

- [ ] **Step 3: Commit**

```bash
git add scripts/install.sh
git commit -m "feat: replace pyenv-based install_python() with uv in install.sh"
```

---

## Task 6: Update scripts/update.sh

**Files:**
- Modify: `scripts/update.sh` — `update_python()` function and section header in `main`

- [ ] **Step 1: Replace update_python()**

In `scripts/update.sh`, find and replace the entire `update_python()` function:

**Remove:**
```bash
update_python() {
  if ! command -v pyenv &>/dev/null; then
    echo "    (skipped — pyenv not installed)"
    return 0
  fi
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  local version
  version=$(tool_version python "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    echo "    (skipped — Python not pinned in lang/.tool-versions)"
    return 0
  fi
  pyenv install -s "$version"
  pyenv global "$version"
  ok "Python $(python --version 2>/dev/null | awk '{print $2}')"
  run_globals_script "$DOTFILES_DIR/lang/python-globals.sh"
}
```

**Replace with:**
```bash
update_python() {
  if ! command -v uv &>/dev/null; then
    echo "    (skipped — uv not installed)"
    return 0
  fi
  local version
  version=$(tool_version python "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    echo "    (skipped — Python not pinned in lang/.tool-versions)"
    return 0
  fi
  uv python install "$version"
  ok "Python $version"
  uv tool upgrade --all
  ok "uv tools upgraded"
}
```

- [ ] **Step 2: Update the section header in main**

In the `# --- main ---` section, find:

```bash
section "Python (pyenv + global pip)"
run_step "Python" update_python
```

Replace with:

```bash
section "Python (uv + global tools)"
run_step "Python" update_python
```

- [ ] **Step 3: Run lint**

```bash
make lint
```

Expected: `✓ shellcheck clean (warning level)`

- [ ] **Step 4: Commit**

```bash
git add scripts/update.sh
git commit -m "feat: replace pyenv-based update_python() with uv in update.sh"
```

---

## Task 7: Update scripts/doctor.sh

**Files:**
- Modify: `scripts/doctor.sh` — `check_python_pin()` function, language managers check, language versions block

- [ ] **Step 1: Replace check_python_pin()**

In `scripts/doctor.sh`, find and replace the entire `check_python_pin()` function:

**Remove:**
```bash
check_python_pin() {
  local pinned current
  pinned=$(tool_version python "$TOOL_VERSIONS" 2>/dev/null || true)
  version_is_pinned "$pinned" || return 0
  current=$(python --version 2>/dev/null | awk '{print $2}' || true)
  if pin_matches "$pinned" "$current"; then
    pass "Python version ($current)"
  else
    warn "Python version (pinned $pinned, active $current)"
  fi
}
```

**Replace with:**
```bash
check_python_pin() {
  local pinned
  pinned=$(tool_version python "$TOOL_VERSIONS" 2>/dev/null || true)
  version_is_pinned "$pinned" || return 0
  if uv python list --only-installed 2>/dev/null | grep -q "$pinned"; then
    pass "Python version ($pinned installed via uv)"
  else
    warn "Python version (pinned $pinned not installed — run: uv python install $pinned)"
  fi
}
```

- [ ] **Step 2: Replace the pyenv manager check**

In the `section "Language managers"` block, find:

```bash
command -v pyenv &>/dev/null && pass "pyenv installed" || fail "pyenv installed"
```

Replace with:

```bash
command -v uv &>/dev/null && pass "uv installed" || fail "uv installed"
```

- [ ] **Step 3: Replace the pyenv init block in the language versions section**

Find:

```bash
  if command -v pyenv &>/dev/null; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - 2>/dev/null)" || true
    check_python_pin
  fi
```

Replace with:

```bash
  if command -v uv &>/dev/null; then
    check_python_pin
  fi
```

- [ ] **Step 4: Run lint**

```bash
make lint
```

Expected: `✓ shellcheck clean (warning level)`

- [ ] **Step 5: Commit**

```bash
git add scripts/doctor.sh
git commit -m "feat: replace pyenv checks with uv in doctor.sh"
```

---

## Task 8: Run the migration

All code changes are committed. Now actually perform the migration on the live system.

- [ ] **Step 1: Install uv via Homebrew**

```bash
brew bundle install --file=homebrew/Brewfile
```

Expected: uv installs. pyenv is NOT removed by this command.

- [ ] **Step 2: Uninstall pyenv**

```bash
brew uninstall pyenv pyenv-virtualenv
```

Expected: both packages uninstalled without errors.

- [ ] **Step 3: Reload the shell**

```bash
exec zsh
```

This reloads `.zshrc`. The pyenv init block is now gone; the `uv()` wrapper is now active.

- [ ] **Step 4: Install the pinned Python version**

```bash
uv python install 3.13.12
```

Expected output includes: `Installed Python 3.13.12` (or `already installed` if it was previously cached).

- [ ] **Step 5: Install global Python tools**

```bash
bash lang/python-globals.sh
```

Expected: installs `black` and `ruff` as isolated uv tools. No errors.

- [ ] **Step 6: Verify tools are callable**

```bash
black --version && ruff --version
```

Expected: version strings for both tools. If these fail, uv's tool bin directory (`~/.local/bin`) is not on PATH — check `echo $PATH` for `~/.local/bin`.

- [ ] **Step 7: Run make doctor**

```bash
make doctor
```

Expected: all required checks pass, including:
```
 ✓ uv installed
 ✓ Python version (3.13.12 installed via uv)
```

If `uv installed` fails: uv is not on PATH — run `which uv` to verify Homebrew installed it.
If Python version warns: run `uv python install 3.13.12` and re-run doctor.

- [ ] **Step 8: Smoke-test the uv() wrapper**

```bash
uv tool install httpie
grep "uv tool install httpie" lang/python-globals.sh
```

Expected: the package is installed AND the line `uv tool install httpie` appears in `python-globals.sh`.

Then clean up the test entry:

```bash
# Remove the test line from python-globals.sh
# Edit the file to delete the "uv tool install httpie" line
uv tool uninstall httpie
```

- [ ] **Step 9: Final commit (if python-globals.sh was modified by the smoke test)**

If you ran the smoke test and need to clean up python-globals.sh:

```bash
git diff lang/python-globals.sh   # verify only the httpie line is removed
git add lang/python-globals.sh
git commit -m "chore: remove smoke-test httpie entry from python-globals.sh"
```
