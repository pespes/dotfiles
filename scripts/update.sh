#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating development environment..."

# Homebrew
echo "--> Updating Homebrew packages..."
brew update && brew upgrade && brew cleanup

# fnm self-update + global Node packages
if command -v fnm &>/dev/null; then
  echo "--> Updating fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
  eval "$(fnm env)"
  echo "--> Updating global Node packages..."
  bash "$DOTFILES_DIR/lang/node-globals.sh"
fi

# Global gems
if command -v rbenv &>/dev/null; then
  echo "--> Updating global gems..."
  eval "$(rbenv init -)"
  bash "$DOTFILES_DIR/lang/ruby-globals.sh"
fi

# Global Python packages
if command -v pyenv &>/dev/null; then
  echo "--> Updating global Python packages..."
  eval "$(pyenv init -)"
  bash "$DOTFILES_DIR/lang/python-globals.sh"
fi

# Rust toolchain
if command -v rustup &>/dev/null; then
  echo "--> Updating Rust toolchain..."
  rustup update
  bash "$DOTFILES_DIR/lang/rust-globals.sh"
fi

# SDKMAN
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  echo "--> Updating SDKMAN..."
  # shellcheck source=/dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk selfupdate
fi

echo "==> Update complete."
echo "    Note: Language runtime versions are NOT auto-upgraded."
echo "    To upgrade a runtime, edit lang/.tool-versions and reinstall."
