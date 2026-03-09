#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Setting up editors..."

# VS Code extensions
if command -v code &>/dev/null; then
  echo "--> Installing VS Code extensions..."
  bash "$DOTFILES_DIR/editors/vscode-extensions.sh"
else
  echo "--> VS Code not found (code CLI missing). Skipping."
  echo "    Install VS Code, then run: bash editors/vscode-extensions.sh"
fi

# Cursor extensions
CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
if [ -f "$CURSOR" ]; then
  echo "--> Installing Cursor extensions..."
  bash "$DOTFILES_DIR/editors/cursor-extensions.sh"
else
  echo "--> Cursor not found. Skipping."
  echo "    Install Cursor, then run: bash editors/cursor-extensions.sh"
fi

echo ""
echo "==> Editor extensions installed."
echo ""
echo "    IMPORTANT: Re-enable Settings Sync to restore settings and keybindings."
echo "    See docs/editors.md for step-by-step instructions."
