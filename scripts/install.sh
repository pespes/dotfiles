#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

echo "==> Installing tools..."

# 1. Homebrew packages
echo "--> Installing Homebrew packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/homebrew/Brewfile"

# 2. fnm (Node)
if confirm "--> Set up Node via fnm?"; then
  if ! command -v fnm &>/dev/null; then
    echo "    Installing fnm via bash..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    export PATH="$HOME/.local/bin:$PATH"
  fi
  eval "$(fnm env)"
  fnm install --lts
  fnm use lts-latest
  echo "    Enabling pnpm via corepack..."
  corepack enable pnpm
  echo "    Installing global Node packages..."
  bash "$DOTFILES_DIR/lang/node-globals.sh"
fi

# 3. rbenv (Ruby)
if confirm "--> Set up Ruby via rbenv?"; then
  if ! command -v rbenv &>/dev/null; then brew install rbenv ruby-build; fi
  eval "$(rbenv init -)"
  RUBY_VERSION=$(grep '^ruby' "$DOTFILES_DIR/lang/.tool-versions" | awk '{print $2}')
  if [[ "$RUBY_VERSION" == "not-managed-by-rbenv" || "$RUBY_VERSION" == "unknown" || -z "$RUBY_VERSION" ]]; then
    echo "    No Ruby version pinned in lang/.tool-versions — skipping rbenv install."
    echo "    Edit lang/.tool-versions to set a version, then re-run."
  else
    rbenv install -s "$RUBY_VERSION"
    rbenv global "$RUBY_VERSION"
    echo "    Installing global gems..."
    bash "$DOTFILES_DIR/lang/ruby-globals.sh"
  fi
fi

# 4. pyenv (Python)
if confirm "--> Set up Python via pyenv?"; then
  if ! command -v pyenv &>/dev/null; then brew install pyenv; fi
  eval "$(pyenv init -)"
  PYTHON_VERSION=$(grep '^python' "$DOTFILES_DIR/lang/.tool-versions" | awk '{print $2}')
  if [[ "$PYTHON_VERSION" == "unknown" || -z "$PYTHON_VERSION" ]]; then
    echo "    No Python version pinned in lang/.tool-versions — skipping pyenv install."
    echo "    Edit lang/.tool-versions to set a version, then re-run."
  else
    pyenv install -s "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    echo "    Installing global pip packages..."
    bash "$DOTFILES_DIR/lang/python-globals.sh"
  fi
fi

# 5. rustup (Rust)
if confirm "--> Set up Rust via rustup?"; then
  if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
  rustup update stable
  bash "$DOTFILES_DIR/lang/rust-globals.sh"
fi

# 6. SDKMAN (Java)
if confirm "--> Set up Java via SDKMAN?"; then
  if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
  fi
  # shellcheck source=/dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java
  if [ -f "$DOTFILES_DIR/lang/java-globals.sh" ]; then
    echo "    Installing global Java tools..."
    bash "$DOTFILES_DIR/lang/java-globals.sh"
  fi
fi

echo "==> Install complete."
