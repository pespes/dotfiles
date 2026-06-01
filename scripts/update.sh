#!/usr/bin/env bash
#
# update.sh — Upgrade tools declared in this repo.
#
# Usage:     make update
# Mutates:   Homebrew (Brewfile only), fnm/rbenv/pyenv globals, rustup, SDKMAN, extensions.
# Does NOT:  Change pins in lang/.tool-versions (runtime upgrades are explicit edits + reinstall).
# Exit:      0 UPDATE_STATUS: ok; 1 if any step failed (continues through remaining steps).
#
# Homebrew:  brew update → brew bundle install --upgrade (Brewfile) → brew cleanup.
#            Does not run brew upgrade on untracked formulae (see make audit).
# Java:      SDKMAN — sync pin from lang/.tool-versions + sdk selfupdate (no sdk upgrade — prompts in non-TTY).
#
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/homebrew/Brewfile"
TOOL_VERSIONS="$DOTFILES_DIR/lang/.tool-versions"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/scripts/lib/common.sh"

STEP_FAILURES=0
declare -a FAILED_STEPS=()

# --- Output helpers ---

section() {
  echo ""
  echo "--- $1 ---"
}

ok() {
  echo "    ✓ $1"
}

fail() {
  echo "    ✗ $1"
  STEP_FAILURES=$((STEP_FAILURES + 1))
  FAILED_STEPS+=("$1")
}

# Run a step; continue on failure and report at the end.
run_step() {
  local label="$1"
  shift
  echo "--> $label"
  if "$@"; then
    ok "$label"
    return 0
  else
    fail "$label"
    return 1
  fi
}

run_globals_script() {
  local script="$1"
  if [ ! -f "$script" ]; then
    echo "    (skipped — $(basename "$script") not found)"
    return 0
  fi
  bash "$script"
}

# --- Update steps (each called via run_step; failures are collected) ---

update_homebrew() {
  if ! ensure_brew_path; then
    echo "    (skipped — brew not installed)"
    return 0
  fi
  if [ ! -f "$BREWFILE" ]; then
    echo "    ✗ Brewfile missing at homebrew/Brewfile"
    return 1
  fi
  brew update
  # Upgrade only packages listed in the Brewfile (not every formula on the system).
  brew bundle install --file="$BREWFILE" --upgrade
  brew cleanup
  if brew outdated --formula 2>/dev/null | grep -q .; then
    echo "    (other outdated formulae on this Mac are not upgraded — see: make audit)"
  fi
}

update_node() {
  if ! command -v fnm &>/dev/null; then
    echo "    (skipped — fnm not installed)"
    return 0
  fi
  eval "$(fnm env)"
  local version
  version=$(tool_version node "$TOOL_VERSIONS" || true)
  if version_is_pinned "$version"; then
    fnm install "$version"
    fnm use "$version"
    ok "Node $(node --version 2>/dev/null || echo "$version")"
  else
    echo "    (no node pin in lang/.tool-versions — using current fnm default)"
  fi
  run_globals_script "$DOTFILES_DIR/lang/node-globals.sh"
}

update_ruby() {
  if ! command -v rbenv &>/dev/null; then
    echo "    (skipped — rbenv not installed)"
    return 0
  fi
  eval "$(rbenv init - bash)"
  local version
  version=$(tool_version ruby "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    echo "    (skipped — Ruby not managed in lang/.tool-versions)"
    return 0
  fi
  rbenv install -s "$version"
  rbenv global "$version"
  ok "Ruby $(ruby --version 2>/dev/null | awk '{print $2}')"
  run_globals_script "$DOTFILES_DIR/lang/ruby-globals.sh"
}

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

update_rust() {
  if ! command -v rustup &>/dev/null; then
    echo "    (skipped — rustup not installed)"
    return 0
  fi
  rustup update stable
  run_globals_script "$DOTFILES_DIR/lang/rust-globals.sh"
}

update_sdkman() {
  if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "    (skipped — SDKMAN not installed)"
    return 0
  fi
  set +u
  source_sdkman || { set -u; return 1; }
  local version sdk_id
  version=$(tool_version java "$TOOL_VERSIONS" || true)
  if version_is_pinned "$version"; then
    sdk_id=$(java_sdkman_id "$version")
    sdk install java "$sdk_id"
    sdk default java "$sdk_id"
    ok "Java ($sdk_id)"
  else
    echo "    (no java pin in lang/.tool-versions — skipping pin sync)"
  fi
  sdk selfupdate || true
  # Do not run `sdk upgrade java` here — it prompts to adopt SDKMAN channel defaults (e.g. 25.x) and
  # hangs or mis-reads stdin in background/non-interactive shells. Bump Java by editing the pin, then re-run make update.
  if grep -qE '^\s*sdk install' "$DOTFILES_DIR/lang/java-globals.sh" 2>/dev/null; then
    run_globals_script "$DOTFILES_DIR/lang/java-globals.sh"
  else
    echo "    (no sdk install commands in lang/java-globals.sh)"
  fi
  set -u
}

update_editor_extensions() {
  local updated=0
  if command -v code &>/dev/null; then
    code --update-extensions
    updated=1
  else
    echo "    (skipped — VS Code CLI not found)"
  fi
  local cursor=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
  if [ -x "$cursor" ]; then
    "$cursor" --update-extensions
    updated=1
  else
    echo "    (skipped — Cursor not found)"
  fi
  if [ "$updated" -eq 0 ]; then
    return 0
  fi
}

print_summary() {
  echo ""
  echo "==> Summary"
  if [ "$STEP_FAILURES" -eq 0 ]; then
    echo "    All update steps completed."
    echo ""
    echo "    Language runtime versions are not auto-bumped."
    echo "    To change a runtime: edit lang/.tool-versions, reinstall, then commit."
    echo ""
    echo "    After installing new tools: make audit"
    echo "    Java PATH is set in zsh — run: exec zsh   (or open a new tab) if java -version still fails"
    echo ""
    echo "UPDATE_STATUS: ok"
    return 0
  fi
  echo "    $STEP_FAILURES step(s) failed:"
  local step
  for step in "${FAILED_STEPS[@]}"; do
    echo "      - $step"
  done
  echo ""
  echo "    Fix errors above and re-run: make update"
  echo ""
  echo "UPDATE_STATUS: failed ($STEP_FAILURES step(s))"
  return 1
}

# --- main ---
echo "==> Updating development environment"
echo "    Repo: $DOTFILES_DIR"

section "Homebrew (Brewfile only)"
run_step "Homebrew" update_homebrew

section "Node (fnm + global npm)"
run_step "Node" update_node

section "Ruby (rbenv + global gems)"
run_step "Ruby" update_ruby

section "Python (pyenv + global pip)"
run_step "Python" update_python

section "Rust (rustup + components)"
run_step "Rust" update_rust

section "Java (SDKMAN)"
run_step "SDKMAN" update_sdkman

section "Editor extensions"
run_step "Editor extensions" update_editor_extensions

print_summary
exit $?
