#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Audit: checking for environment drift"
echo ""

# 1. Homebrew: installed but not in Brewfile
echo "--- Brew packages installed but NOT in Brewfile ---"
echo "    (these would be removed if you ran: brew bundle cleanup)"
brew bundle cleanup --file="$DOTFILES_DIR/homebrew/Brewfile" --dry-run 2>/dev/null || echo "    (Brewfile not found — create it with: make backup)"
echo ""

# 2. Homebrew: in Brewfile but not installed
echo "--- Brew packages in Brewfile but NOT installed ---"
if [ -f "$DOTFILES_DIR/homebrew/Brewfile" ]; then
  brew bundle check --file="$DOTFILES_DIR/homebrew/Brewfile" 2>&1 | grep -v "The Brewfile's dependencies are satisfied" || true
  brew bundle check --file="$DOTFILES_DIR/homebrew/Brewfile" &>/dev/null && echo "    All Brewfile packages are installed." || true
else
  echo "    (Brewfile not found)"
fi
echo ""

# 3. Global Node packages not in node-globals.sh
if command -v npm &>/dev/null && [ -f "$DOTFILES_DIR/lang/node-globals.sh" ]; then
  echo "--- Global npm packages not tracked in node-globals.sh ---"
  installed_npm=$(npm list -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -I{} basename {} | sort)
  tracked_npm=$(grep -oE '[a-z@][a-z0-9@/_-]+' "$DOTFILES_DIR/lang/node-globals.sh" | grep -v '^npm$\|install\|upgrade' | sort || true)
  untracked=$(comm -13 <(echo "$tracked_npm") <(echo "$installed_npm") 2>/dev/null || true)
  if [ -n "$untracked" ]; then
    echo "$untracked" | sed 's/^/    ! Not tracked: /'
  else
    echo "    All global npm packages appear tracked."
  fi
  echo ""
fi

# 4. Broken symlinks in ~
echo "--- Broken symlinks in ~ ---"
broken=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
if [ -z "$broken" ]; then
  echo "    None found."
else
  echo "$broken" | sed 's/^/    ! /'
fi
echo ""

echo "==> Audit complete."
echo "    Untracked brew package: edit homebrew/Brewfile, then git commit."
echo "    Untracked global package: edit lang/*-globals.sh, then git commit."
echo "    Uninstalled brew package in Brewfile: run 'brew bundle install --file=homebrew/Brewfile' or remove from Brewfile."
