#!/usr/bin/env bash
set -euo pipefail

echo "==> Bootstrap: Xcode CLT, Homebrew, stow"

# 1. Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "--> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Waiting for Xcode CLT install to complete..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  echo "    Done."
else
  echo "--> Xcode CLT already installed. Skipping."
fi

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "--> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "--> Homebrew already installed. Skipping."
fi

# 3. stow
if ! command -v stow &>/dev/null; then
  echo "--> Installing stow..."
  brew install stow
else
  echo "--> stow already installed. Skipping."
fi

echo "==> Bootstrap complete."
