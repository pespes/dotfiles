#!/usr/bin/env bash
#
# doctor.sh — Health check for dotfiles tooling (is the environment wired up?).
#
# Usage:     make doctor
# Mutates:   Nothing.
# Exit:      0 if required checks pass (warnings alone still exit 0); 1 if required checks fail.
#
# Checks:    Core tools, Brewfile packages installed, language managers, version pins,
#            dotfile symlinks, SSH key (optional), launchd job (optional), editors (optional).
# Drift:     Use make audit to compare “installed but not in repo” vs “in repo but missing”.
#
# Status:    DOCTOR_STATUS: ok | ok_with_warnings | failed
#
# Status labels print ~/.foo for readability; they are display strings, not paths
# (all real paths use $HOME). Silence the tilde-in-quotes lint file-wide.
# shellcheck disable=SC2088
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/homebrew/Brewfile"
TOOL_VERSIONS="$DOTFILES_DIR/lang/.tool-versions"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/scripts/lib/common.sh"

PASS=$'\033[32m✓\033[0m'
FAIL=$'\033[31m✗\033[0m'
WARN=$'\033[33m!\033[0m'

ERRORS=0
WARNINGS=0
declare -a FAILED_CHECKS=()
declare -a WARN_CHECKS=()

# --- Check helpers (pass / fail / warn) ---

section() {
  echo ""
  echo "--- $1 ---"
}

pass() {
  echo -e " $PASS $1"
}

fail() {
  echo -e " $FAIL $1"
  ERRORS=$((ERRORS + 1))
  FAILED_CHECKS+=("$1")
}

warn() {
  echo -e " $WARN $1"
  WARNINGS=$((WARNINGS + 1))
  WARN_CHECKS+=("$1")
}

symlink_ok() {
  local path="$1" label="$2"
  if [ ! -L "$path" ]; then
    fail "$label (not a symlink — run: make link)"
    return 1
  fi
  if [ ! -e "$path" ]; then
    fail "$label (broken symlink — run: make link)"
    return 1
  fi
  local target
  target=$(readlink "$path" 2>/dev/null || true)
  if [[ "$target" != *"dotfiles"* ]]; then
    warn "$label (symlink does not point into dotfiles: $target)"
    return 0
  fi
  pass "$label"
}

# --- Brewfile and language pin checks ---

check_brewfile_packages() {
  if [ ! -f "$BREWFILE" ]; then
    fail "homebrew/Brewfile exists"
    return 1
  fi
  pass "homebrew/Brewfile exists"

  local tracked_formulae tracked_casks pkg missing=0
  tracked_formulae=$(brew bundle list --file="$BREWFILE" --formula 2>/dev/null || true)
  tracked_casks=$(brew bundle list --file="$BREWFILE" --cask 2>/dev/null || true)

  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! brew list --formula "$pkg" &>/dev/null; then
      fail "Brewfile formula missing: $pkg (run: brew bundle install --file=homebrew/Brewfile)"
      missing=$((missing + 1))
    fi
  done <<<"$tracked_formulae"

  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! brew list --cask "$pkg" &>/dev/null; then
      fail "Brewfile cask missing: $pkg (run: brew bundle install --file=homebrew/Brewfile)"
      missing=$((missing + 1))
    fi
  done <<<"$tracked_casks"

  if [ "$missing" -eq 0 ]; then
    pass "All Brewfile packages installed"
  fi
}

pin_matches() {
  local pinned="$1" current="$2"
  [[ "$current" == *"$pinned"* ]] || [[ "$pinned" == *"${current#v}"* ]]
}

check_node_pin() {
  local pinned current
  pinned=$(tool_version node "$TOOL_VERSIONS" 2>/dev/null || true)
  version_is_pinned "$pinned" || return 0
  current=$(node --version 2>/dev/null || true)
  if [ -z "$current" ]; then
    warn "Node version (pinned $pinned, active unknown)"
    return 0
  fi
  if pin_matches "$pinned" "$current"; then
    pass "Node version ($current)"
  else
    warn "Node version (pinned $pinned, active $current)"
  fi
}

check_ruby_pin() {
  local pinned current
  pinned=$(tool_version ruby "$TOOL_VERSIONS" 2>/dev/null || true)
  version_is_pinned "$pinned" || return 0
  current=$(ruby --version 2>/dev/null | awk '{print $2}' || true)
  if pin_matches "$pinned" "$current"; then
    pass "Ruby version ($current)"
  else
    warn "Ruby version (pinned $pinned, active $current)"
  fi
}

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

check_java_pin() {
  local pinned sdk_id current
  pinned=$(tool_version java "$TOOL_VERSIONS" 2>/dev/null || true)
  version_is_pinned "$pinned" || return 0
  sdk_id=$(java_sdkman_id "$pinned")
  if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    warn "Java version (pinned $sdk_id, SDKMAN not installed)"
    return 0
  fi
  set +u
  if ! source_sdkman; then
    set -u
    warn "Java version (pinned $sdk_id, SDKMAN init failed)"
    return 0
  fi
  current=$(sdk current java 2>/dev/null | awk '{print $NF}')
  set -u
  if [ "$current" = "$sdk_id" ]; then
    pass "Java version ($sdk_id)"
  else
    warn "Java version (pinned $sdk_id, active ${current:-none})"
  fi
}

# --- Summary ---

print_summary() {
  echo ""
  echo "==> Summary"
  if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "    All checks passed."
    echo ""
    echo "    For install vs repo drift, run: make audit"
    echo ""
    echo "DOCTOR_STATUS: ok"
    return 0
  fi

  if [ "$ERRORS" -gt 0 ]; then
    echo "    $ERRORS required check(s) failed:"
    local item
    for item in "${FAILED_CHECKS[@]}"; do
      echo "      - $item"
    done
  fi

  if [ "$WARNINGS" -gt 0 ]; then
    echo "    $WARNINGS optional warning(s):"
    for item in "${WARN_CHECKS[@]}"; do
      echo "      - $item"
    done
  fi

  echo ""
  echo "    Next steps:"
  if [ "$ERRORS" -gt 0 ]; then
    echo "      - make link          (symlinks)"
    echo "      - make install-tools (missing Brewfile packages)"
    echo "      - make bootstrap     (no Homebrew)"
  fi
  echo "      - make audit         (full drift report)"
  echo ""
  if [ "$ERRORS" -gt 0 ]; then
    echo "DOCTOR_STATUS: failed ($ERRORS required, $WARNINGS warnings)"
    return 1
  fi
  echo "DOCTOR_STATUS: ok_with_warnings ($WARNINGS warning(s))"
  return 0
}

# --- main ---
echo "==> Doctor: environment health"
echo "    Repo: $DOTFILES_DIR"

section "Core tools"
if ensure_brew_path; then
  pass "Homebrew available"
else
  fail "Homebrew available (run: make bootstrap)"
fi
command -v stow &>/dev/null && pass "stow installed" || fail "stow installed"
command -v git &>/dev/null && pass "git installed" || fail "git installed"

section "Brewfile"
if ensure_brew_path; then
  check_brewfile_packages
else
  warn "Brewfile packages (skipped — no Homebrew)"
fi

section "Language managers"
command -v fnm &>/dev/null && pass "fnm installed" || fail "fnm installed"
command -v rbenv &>/dev/null && pass "rbenv installed" || fail "rbenv installed"
command -v uv &>/dev/null && pass "uv installed" || fail "uv installed"
command -v rustup &>/dev/null && pass "rustup installed" || fail "rustup installed"
[ -d "$HOME/.sdkman" ] && pass "SDKMAN installed" || warn "SDKMAN not installed (optional)"

if [ -f "$TOOL_VERSIONS" ]; then
  section "Language versions (lang/.tool-versions)"
  if command -v fnm &>/dev/null; then
    eval "$(fnm env 2>/dev/null)" || true
    check_node_pin
  fi
  if command -v rbenv &>/dev/null; then
    eval "$(rbenv init - bash 2>/dev/null)" || true
    check_ruby_pin
  fi
  if command -v uv &>/dev/null; then
    check_python_pin
  fi
  check_java_pin
fi

section "Dotfile symlinks"
symlink_ok "$HOME/.zshrc" "~/.zshrc → dotfiles"
symlink_ok "$HOME/.gitconfig" "~/.gitconfig → dotfiles"
if [ -L "$HOME/.ssh/config" ]; then
  if [ -e "$HOME/.ssh/config" ]; then
    pass "~/.ssh/config → dotfiles"
  else
    fail "~/.ssh/config (broken symlink)"
  fi
else
  warn "~/.ssh/config symlinked (optional — run: make link)"
fi

section "SSH"
if compgen -G "$HOME/.ssh/id_*.pub" >/dev/null 2>&1; then
  pass "SSH public key present"
else
  warn "SSH public key (optional — see README SSH Setup)"
fi

section "Background jobs"
if launchctl print "gui/$(id -u)/com.pespes.dotfiles-audit" &>/dev/null; then
  pass "Weekly audit launchd job loaded"
elif [ -f "$HOME/Library/LaunchAgents/com.pespes.dotfiles-audit.plist" ]; then
  warn "Audit launchd plist exists but job not loaded (run: make link)"
else
  warn "Weekly audit launchd job (optional — run: make link)"
fi

section "Editors (optional)"
command -v code &>/dev/null && pass "VS Code CLI (code)" || warn "VS Code CLI (code) — optional"
CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
[ -x "$CURSOR" ] && pass "Cursor CLI" || warn "Cursor CLI — optional"

section "Broken symlinks in ~"
broken=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
if [ -z "$broken" ]; then
  pass "No broken symlinks in ~"
else
  fail "Broken symlinks in ~:"
  echo "$broken" | sed 's/^/        /'
fi

print_summary
exit $?
