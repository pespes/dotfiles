#!/usr/bin/env bash
#
# backup.sh — Snapshot everything Homebrew has installed (not just the Brewfile).
#
# Usage:     make backup
# Mutates:   Writes homebrew/Brewfile.backup (gitignored via *.backup).
#            Preserves previous dump as Brewfile.backup.previous.
# Exit:      0 BACKUP_STATUS: ok; 1 if Homebrew unavailable.
#
# Note:      Brewfile = curated source of truth. Brewfile.backup = full machine state for diffing.
# Workflow:  diff homebrew/Brewfile homebrew/Brewfile.backup → copy wanted lines → make audit → commit
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/homebrew/Brewfile"
BACKUP_FILE="$DOTFILES_DIR/homebrew/Brewfile.backup"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/scripts/lib/common.sh"

echo "==> Backing up Homebrew state"
echo "    Repo: $DOTFILES_DIR"

if ! ensure_brew_path; then
  echo "    ✗ Homebrew not found. Run: make bootstrap"
  echo ""
  echo "BACKUP_STATUS: failed"
  exit 1
fi

mkdir -p "$(dirname "$BACKUP_FILE")"

if [ -f "$BACKUP_FILE" ]; then
  cp "$BACKUP_FILE" "${BACKUP_FILE}.previous"
  echo "    Previous backup saved as homebrew/Brewfile.backup.previous (gitignored)"
fi

echo "--> Writing brew bundle dump..."
brew bundle dump --file="$BACKUP_FILE" --force

formula_count=$(grep -cE '^brew ' "$BACKUP_FILE" 2>/dev/null || echo 0)
cask_count=$(grep -cE '^cask ' "$BACKUP_FILE" 2>/dev/null || echo 0)
tap_count=$(grep -cE '^tap ' "$BACKUP_FILE" 2>/dev/null || echo 0)

echo ""
echo "==> Summary"
echo "    Saved: homebrew/Brewfile.backup"
echo "    Contents: $formula_count formulae, $cask_count casks, $tap_count taps"
echo ""
echo "    This file is a raw snapshot of everything Homebrew has installed."
echo "    Your curated list remains: homebrew/Brewfile"
echo ""
if [ -f "$BREWFILE" ]; then
  echo "    Compare:"
  echo "      diff homebrew/Brewfile homebrew/Brewfile.backup"
  echo ""
  echo "    To adopt packages from the backup:"
  echo "      1. Copy wanted brew/cask lines into homebrew/Brewfile (with comments)"
  echo "      2. make audit"
  echo "      3. git commit"
else
  echo "    No Brewfile yet — copy lines from the backup into homebrew/Brewfile to start curating."
fi
echo ""
echo "BACKUP_STATUS: ok"
