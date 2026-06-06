# Migrate Python Tooling to uv

**Date:** 2026-06-06
**Status:** Approved

## Summary

Replace pyenv + pip with [uv](https://docs.astral.sh/uv/) as the single tool for Python version management and global tool installation. uv is 10–100x faster than pip, replaces pyenv for version management, and replaces pipx for isolated global tools.

## Approach

Full cutover (Approach B): remove pyenv entirely, replace with uv. Add a `uv()` shell wrapper in `.zshrc` that auto-tracks `uv tool install <pkg>` to `python-globals.sh`, consistent with the existing auto-tracking wrappers for npm, gem, and cargo.

## Files Changed

### homebrew/Brewfile

Remove `pyenv` and `pyenv-virtualenv`. Add `uv` in the Language Version Managers section.

```
brew "uv"             # Python version manager and package tool
```

### lang/python-globals.sh

Replace the single `pip install --upgrade` block with individual `uv tool install` lines. Drop `pip` (uv manages itself) and `pipx` (replaced by `uv tool`).

```bash
uv tool install black
uv tool install ruff
```

New tools auto-appended as `uv tool install <pkg>` lines (flat, like rust-globals.sh).

### zsh/.zshrc

- Remove pyenv init block (PYENV_ROOT export + `pyenv init - zsh`)
- Remove `pip()` tracking wrapper
- Add `uv()` tracking wrapper that intercepts `uv tool install <pkg>` and appends to `python-globals.sh`

`~/.local/bin` (already in PATH) is where uv tool shims live — no PATH change needed.

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

### scripts/install.sh

Replace `install_python()` — use `uv python install <version>` from `.tool-versions`, then run `python-globals.sh`.

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

Update section header in `main` to `"Python (optional)"` with label `"Set up Python via uv?"`.

### scripts/update.sh

Replace `update_python()` — use `uv python install <version>` to sync pin, then `uv tool upgrade --all` to upgrade installed tools.

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

Update section header in `main` from `"Python (pyenv + global pip)"` to `"Python (uv + global tools)"`.

### scripts/doctor.sh

Three changes:

1. **Language managers section:** replace `pyenv installed` check with `uv installed`.

2. **Language versions section:** replace pyenv init + call block with:
   ```bash
   if command -v uv &>/dev/null; then
     check_python_pin
   fi
   ```

3. **`check_python_pin()` function:** check `uv python list` instead of `python --version` (uv-managed Python is not on the shell PATH by default):
   ```bash
   check_python_pin() {
     local pinned
     pinned=$(tool_version python "$TOOL_VERSIONS" 2>/dev/null || true)
     version_is_pinned "$pinned" || return 0
     if uv python list 2>/dev/null | grep -q "$pinned"; then
       pass "Python version ($pinned installed via uv)"
     else
       warn "Python version (pinned $pinned not installed — run: uv python install $pinned)"
     fi
   }
   ```

## What Is NOT Changed

- `lang/.tool-versions` — Python version pin stays as-is (`python 3.13.12`)
- No new `.python-version` file — uv scripts receive the version explicitly from `.tool-versions`
- All other language stacks (Node/fnm, Ruby/rbenv, Rust/rustup, Java/SDKMAN) unchanged

## Migration Notes

After implementing:
1. Run `brew bundle install --file=homebrew/Brewfile` to install uv and remove pyenv
2. Run `make install` (Python section) or manually: `uv python install 3.13.12 && bash lang/python-globals.sh`
3. Run `make doctor` to verify all checks pass
4. Open a new terminal — pyenv init is gone from `.zshrc`
