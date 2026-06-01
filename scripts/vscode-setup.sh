#!/usr/bin/env bash
#
# vscode-setup.sh — Install curated VS Code and Cursor extensions from editors/*.sh
#
# Usage:     make editors  (or last step of make install)
# Mutates:   Installs extensions via editor CLIs (idempotent).
# Does NOT:  Sync settings/keybindings — use Settings Sync (see docs/editors.md).
# Exit:      0 if script completes; editor CLIs may warn on already-installed extensions.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Setting up editors..."
echo "    Repo: $DOTFILES_DIR"

# --- VS Code ---
if command -v code &>/dev/null; then
  echo "--> Installing VS Code extensions..."
  bash "$DOTFILES_DIR/editors/vscode-extensions.sh"
else
  echo "--> VS Code not found (code CLI missing). Skipping."
  echo "    Install VS Code, enable shell command, then: make editors"
fi

# --- Cursor ---
CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
if [ -x "$CURSOR" ]; then
  echo "--> Installing Cursor extensions..."
  bash "$DOTFILES_DIR/editors/cursor-extensions.sh"
else
  echo "--> Cursor not found. Skipping."
  echo "    Install Cursor, then: make editors"
fi

echo ""
echo "==> Editor setup complete."
echo "    Re-enable Settings Sync for settings/keybindings — see docs/editors.md"
