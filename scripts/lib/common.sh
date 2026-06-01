# shellcheck shell=bash
# lib/common.sh — Shared helpers for dotfiles scripts.
#
# Usage:  source "$DOTFILES_DIR/scripts/lib/common.sh"   (never execute directly)
# Used by: install.sh, update.sh, audit.sh, doctor.sh, backup.sh
#
# Functions:
#   tool_version TOOL FILE   — Read version pin from lang/.tool-versions (e.g. node, python)
#   java_sdkman_id PIN       — Map friendly pins (e.g. temurin-21) to SDKMAN identifiers
#   source_sdkman            — Load SDKMAN in the current shell (nounset-safe)
#   version_is_pinned VER    — True if VER is a real pin (not unknown / not-managed-by-rbenv)
#   ensure_brew_path         — Put Homebrew on PATH in the current shell (Apple Silicon / Intel)

tool_version() {
  local tool="$1" file="${2:-}"
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 1
  fi
  grep -E "^${tool}[[:space:]]+" "$file" 2>/dev/null | awk '{print $2}' | head -1
}

version_is_pinned() {
  local version="$1"
  [[ -n "$version" && "$version" != "unknown" && "$version" != "not-managed-by-rbenv" ]]
}

# SDKMAN uses vendor-specific ids (e.g. 21.0.11-tem), not aliases like temurin-21.
java_sdkman_id() {
  local pin="$1"
  case "$pin" in
    temurin-21 | 21) echo "21.0.11-tem" ;;
    *) echo "$pin" ;;
  esac
}

# SDKMAN scripts are not nounset-safe — callers should use set +u around sdk commands.
source_sdkman() {
  if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    return 1
  fi
  # shellcheck source=/dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"
}

ensure_brew_path() {
  if command -v brew &>/dev/null; then
    return 0
  fi
  if [ -f /opt/homebrew/bin/brew ]; then
    # shellcheck source=/dev/null
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    # shellcheck source=/dev/null
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew &>/dev/null
}
