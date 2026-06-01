#!/usr/bin/env bash
#
# link.sh — Symlink dotfile packages into $HOME (GNU stow) and install audit launchd job.
#
# Usage:     make link   (safe to re-run after editing tracked dotfiles)
# Mutates:   Symlinks under ~; ~/Library/LaunchAgents/com.pespes.dotfiles-audit.plist
# Exit:      0 LINK_STATUS: ok; 1 if stow or verification failed.
#
# Packages:  zsh git ssh lang claude — keep in sync with Makefile STOW_PACKAGES.
#            zsh/ includes .zshrc and .zprofile (login shell + SDKMAN early).
# lang/:     Only .tool-versions is stowed; *-globals.sh stay in repo (lang/.stow-local-ignore).
#            Removes stale ~/node-globals.sh-style symlinks from older layouts.
#
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep in sync with Makefile STOW_PACKAGES
PACKAGES=(zsh git ssh lang claude)

# lang/*.sh are install scripts — not stowed (see lang/.stow-local-ignore)
LANG_INSTALL_SCRIPTS=(
  node-globals.sh
  ruby-globals.sh
  python-globals.sh
  rust-globals.sh
  java-globals.sh
)

STEP_FAILURES=0
declare -a FAILED_STEPS=()
LINKED_PACKAGES=()

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

require_stow() {
  if command -v stow &>/dev/null; then
    return 0
  fi
  echo "    stow not found. Install with: brew install stow (or make bootstrap)"
  return 1
}

# --- Stow, launchd, and verification ---

link_package() {
  local package="$1"
  if [ ! -d "$DOTFILES_DIR/$package" ]; then
    echo "    (skipped — $package/ not found)"
    return 0
  fi
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$package"
  LINKED_PACKAGES+=("$package")
}

remove_stale_lang_symlinks() {
  local script path
  local removed=0
  for script in "${LANG_INSTALL_SCRIPTS[@]}"; do
    path="$HOME/$script"
    if [ -L "$path" ] && readlink "$path" 2>/dev/null | grep -q 'dotfiles'; then
      rm "$path"
      echo "    Removed stale ~/$script (install scripts stay in repo only)"
      removed=$((removed + 1))
    fi
  done
  if [ "$removed" -eq 0 ]; then
    echo "    No stale lang install-script symlinks in ~"
  fi
}

install_launchd_audit_job() {
  local template="$DOTFILES_DIR/macos/Library/LaunchAgents/com.pespes.dotfiles-audit.plist"
  local dst="$HOME/Library/LaunchAgents/com.pespes.dotfiles-audit.plist"
  local escaped_dir

  if [ ! -f "$template" ]; then
    echo "    (skipped — plist template not found)"
    return 0
  fi

  mkdir -p "$HOME/Library/LaunchAgents"
  escaped_dir=$(printf '%s' "$DOTFILES_DIR" | sed 's/[&|\\]/\\&/g')
  sed "s|__DOTFILES_DIR__|$escaped_dir|g" "$template" > "$dst"

  launchctl bootout "gui/$(id -u)/com.pespes.dotfiles-audit" 2>/dev/null || \
    launchctl unload "$dst" 2>/dev/null || true

  if launchctl bootstrap "gui/$(id -u)" "$dst" 2>/dev/null; then
    return 0
  fi
  if launchctl load "$dst" 2>/dev/null; then
    return 0
  fi
  echo "    Plist written to $dst but launchctl failed to load it."
  return 1
}

verify_symlinks() {
  local -a required=(
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.tool-versions"
  )
  local path target
  local failed=0

  for path in "${required[@]}"; do
    if [ ! -L "$path" ] || [ ! -e "$path" ]; then
      fail "Missing or broken: ${path/#$HOME\//~/}"
      failed=$((failed + 1))
      continue
    fi
    target=$(readlink "$path" 2>/dev/null || true)
    if [[ "$target" != *"dotfiles"* ]]; then
      fail "${path/#$HOME\//~/} does not point into dotfiles ($target)"
      failed=$((failed + 1))
    fi
  done

  if [ "$failed" -eq 0 ]; then
    ok "Core dotfile symlinks (~/.zshrc, ~/.gitconfig, ~/.tool-versions)"
    return 0
  fi
  return 1
}

print_summary() {
  echo ""
  echo "==> Summary"
  if [ "${#LINKED_PACKAGES[@]}" -gt 0 ]; then
    echo "    Stowed: ${LINKED_PACKAGES[*]}"
  fi
  if [ "$STEP_FAILURES" -eq 0 ]; then
    echo "    Symlinks are in sync with the repo."
    echo ""
    echo "    Reload shell: exec zsh"
    echo "    Verify:       make doctor && make audit"
    echo ""
    echo "LINK_STATUS: ok"
    return 0
  fi
  echo "    $STEP_FAILURES step(s) failed:"
  local step
  for step in "${FAILED_STEPS[@]}"; do
    echo "      - $step"
  done
  echo ""
  echo "LINK_STATUS: failed ($STEP_FAILURES step(s))"
  return 1
}

# --- main ---
echo "==> Linking dotfiles via stow"
echo "    Repo: $DOTFILES_DIR"
echo "    Target: $HOME"

section "Prerequisites"
run_step "stow available" require_stow || { print_summary; exit 1; }

section "Stow packages"
for package in "${PACKAGES[@]}"; do
  run_step "stow $package" link_package "$package"
done

section "Cleanup"
run_step "Remove stale lang symlinks in ~" remove_stale_lang_symlinks

section "Background jobs"
run_step "launchd audit job" install_launchd_audit_job

section "Verify"
run_step "Core symlinks" verify_symlinks

print_summary
exit $?
