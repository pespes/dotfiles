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
  # Add brew to PATH — handles both Apple Silicon (/opt/homebrew) and Intel (/usr/local)
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
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
