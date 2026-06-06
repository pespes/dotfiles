#!/usr/bin/env bash
#
# install.sh — Install packages from the Brewfile and optional language stacks.
#
# Usage:     make install-tools   (this script only)
#            make install         (bootstrap → this → link.sh → vscode-setup.sh)
# Mutates:   Homebrew, fnm/rbenv/pyenv/rustup/SDKMAN, global language packages.
# Does NOT:  Symlink dotfiles (make link) or install editor extensions (make editors).
# Exit:      0 INSTALL_STATUS: ok; 1 if a required step failed.
#
# Interactive:  Optional sections prompt [y/N]. Declined sections are listed as skipped.
# Environment:  DOTFILES_ASSUME_YES=1 accepts all optional prompts (for scripting).
#
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/homebrew/Brewfile"
TOOL_VERSIONS="$DOTFILES_DIR/lang/.tool-versions"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/scripts/lib/common.sh"

STEP_FAILURES=0
declare -a FAILED_STEPS=()
SKIPPED_STEPS=()

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

skip() {
  echo "    ○ $1"
  SKIPPED_STEPS+=("$1")
}

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

confirm() {
  local prompt="$1"
  if [[ "${DOTFILES_ASSUME_YES:-}" == "1" ]]; then
    echo "    $prompt → yes (DOTFILES_ASSUME_YES)"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "    $prompt → skipped (non-interactive shell)"
    return 1
  fi
  read -r -p "    $prompt [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

run_globals_script() {
  local script="$1"
  if [ ! -f "$script" ]; then
    echo "    (skipped — $(basename "$script") not found)"
    return 0
  fi
  bash "$script"
}

# --- Install steps ---

install_homebrew() {
  if ! ensure_brew_path; then
    echo "    Homebrew not found. Run scripts/bootstrap.sh first (or open a new terminal)."
    return 1
  fi
  if [ ! -f "$BREWFILE" ]; then
    echo "    Brewfile missing at homebrew/Brewfile"
    return 1
  fi
  brew bundle install --file="$BREWFILE"
}

install_oh_my_zsh() {
  if ! confirm "Set up oh-my-zsh and plugins?"; then
    skip "oh-my-zsh (declined)"
    return 0
  fi
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "    Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "    oh-my-zsh already installed."
  fi

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
    echo "    Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  fi
  if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
    echo "    Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/plugins/zsh-syntax-highlighting"
  fi
}

install_node() {
  if ! confirm "Set up Node via fnm?"; then
    skip "Node/fnm (declined)"
    return 0
  fi
  if ! command -v fnm &>/dev/null; then
    echo "    fnm not found — ensure Homebrew step succeeded (fnm is in the Brewfile)."
    return 1
  fi
  eval "$(fnm env)"
  local version
  version=$(tool_version node "$TOOL_VERSIONS" || true)
  if version_is_pinned "$version"; then
    fnm install "$version"
    fnm use "$version"
    ok "Node $(node --version 2>/dev/null || echo "$version")"
  else
    echo "    No node pin in lang/.tool-versions — installing Node LTS."
    fnm install --lts
    fnm use lts-latest
  fi
  run_globals_script "$DOTFILES_DIR/lang/node-globals.sh"
}

install_ruby() {
  if ! confirm "Set up Ruby via rbenv?"; then
    skip "Ruby/rbenv (declined)"
    return 0
  fi
  if ! command -v rbenv &>/dev/null; then
    echo "    rbenv not found — ensure Homebrew step succeeded."
    return 1
  fi
  eval "$(rbenv init - bash)"
  local version
  version=$(tool_version ruby "$TOOL_VERSIONS" || true)
  if ! version_is_pinned "$version"; then
    skip "Ruby (no version in lang/.tool-versions)"
    return 0
  fi
  rbenv install -s "$version"
  rbenv global "$version"
  ok "Ruby $(ruby --version 2>/dev/null | awk '{print $2}')"
  run_globals_script "$DOTFILES_DIR/lang/ruby-globals.sh"
}

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

install_rust() {
  if ! confirm "Set up Rust via rustup?"; then
    skip "Rust (declined)"
    return 0
  fi
  export PATH="/opt/homebrew/opt/rustup/bin:/usr/local/opt/rustup/bin:$PATH"
  if ! command -v rustup &>/dev/null; then
    echo "    Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  rustup update stable
  run_globals_script "$DOTFILES_DIR/lang/rust-globals.sh"
}

install_java() {
  if ! confirm "Set up Java via SDKMAN?"; then
    skip "Java/SDKMAN (declined)"
    return 0
  fi
  if [ ! -d "$HOME/.sdkman" ]; then
    echo "    Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
  fi
  set +u
  source_sdkman || { set -u; return 1; }
  local version sdk_id
  version=$(tool_version java "$TOOL_VERSIONS" || true)
  if version_is_pinned "$version"; then
    sdk_id=$(java_sdkman_id "$version")
    sdk install java "$sdk_id"
    sdk default java "$sdk_id"
    ok "Java ($sdk_id via SDKMAN)"
  else
    echo "    No java pin in lang/.tool-versions — installing SDKMAN default."
    sdk install java
  fi
  if grep -qE '^\s*sdk install' "$DOTFILES_DIR/lang/java-globals.sh" 2>/dev/null; then
    run_globals_script "$DOTFILES_DIR/lang/java-globals.sh"
  fi
  set -u
}

print_summary() {
  echo ""
  echo "==> Install summary"
  if [ "${#SKIPPED_STEPS[@]}" -gt 0 ]; then
    echo "    Skipped:"
    local s
    for s in "${SKIPPED_STEPS[@]}"; do
      echo "      - $s"
    done
  fi
  if [ "$STEP_FAILURES" -eq 0 ]; then
    echo "    Tool installation finished."
    echo ""
    echo "    Next (make install continues):"
    echo "      1. Symlinks — scripts/link.sh"
    echo "      2. Editor extensions — scripts/vscode-setup.sh"
    echo ""
    echo "    After make install:"
    echo "      - Open a new terminal (or: exec zsh)"
    echo "      - Work through README post-install checklist"
    echo "      - Run: make audit"
    echo ""
    echo "INSTALL_STATUS: ok"
    return 0
  fi
  echo "    $STEP_FAILURES step(s) failed:"
  local step
  for step in "${FAILED_STEPS[@]}"; do
    echo "      - $step"
  done
  echo ""
  echo "    Fix errors above and re-run: bash scripts/install.sh"
  echo ""
  echo "INSTALL_STATUS: failed ($STEP_FAILURES step(s))"
  return 1
}

# --- main ---
echo "==> Installing tools from dotfiles"
echo "    Repo: $DOTFILES_DIR"
echo "    Set DOTFILES_ASSUME_YES=1 to accept all optional setup prompts."

section "Homebrew (Brewfile)"
run_step "Homebrew bundle" install_homebrew

section "Shell (optional)"
run_step "oh-my-zsh" install_oh_my_zsh

section "Node (optional)"
run_step "Node" install_node

section "Ruby (optional)"
run_step "Ruby" install_ruby

section "Python (optional)"
run_step "Python" install_python

section "Rust (optional)"
run_step "Rust" install_rust

section "Java (optional)"
run_step "Java" install_java

print_summary
exit $?
