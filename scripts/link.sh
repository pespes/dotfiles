#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(zsh git ssh lang)

echo "==> Linking dotfiles via stow..."

for package in "${PACKAGES[@]}"; do
  if [ -d "$DOTFILES_DIR/$package" ]; then
    echo "--> Linking $package..."
    stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$package"
  else
    echo "--> $package directory not found, skipping."
  fi
done

# Install launchd audit job (not handled by stow — path is too deep)
PLIST_SRC="$DOTFILES_DIR/macos/Library/LaunchAgents/com.peteresveld.dotfiles-audit.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.peteresveld.dotfiles-audit.plist"
if [ -f "$PLIST_SRC" ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cp "$PLIST_SRC" "$PLIST_DST"
  launchctl unload "$PLIST_DST" 2>/dev/null || true
  launchctl load "$PLIST_DST"
  echo "--> launchd audit job installed (runs Mondays at 9am)."
fi

echo "==> Symlinks created."
