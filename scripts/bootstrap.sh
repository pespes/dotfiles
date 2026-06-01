#!/usr/bin/env bash
#
# bootstrap.sh — First-run macOS prerequisites before the rest of the dotfiles repo.
#
# Usage:     make bootstrap   (first step on a fresh Mac; also first step of make install)
# Mutates:   May install Xcode CLT, Homebrew, and stow.
# Exit:      0 on success; non-zero if a step fails (set -e).
#
# Steps:
#   1. Xcode Command Line Tools (waits until installer finishes)
#   2. Homebrew (official install script; adds brew to PATH for this shell)
#   3. stow (via brew) — required for make link
#
# After:     make install  or  bash scripts/install.sh
#
set -euo pipefail

echo "==> Bootstrap: Xcode CLT, Homebrew, stow"

# --- 1. Xcode Command Line Tools ---
if ! xcode-select -p &>/dev/null; then
  echo "--> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Waiting for Xcode CLT install to complete..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  echo "    Done."
else
  echo "--> Xcode CLT already installed. Skipping."
fi

# --- 2. Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "--> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this script — handles Apple Silicon and Intel prefixes.
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "--> Homebrew already installed. Skipping."
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- 3. stow (symlink manager for make link) ---
if ! command -v stow &>/dev/null; then
  echo "--> Installing stow..."
  brew install stow
else
  echo "--> stow already installed. Skipping."
fi

echo "==> Bootstrap complete."
echo "    Next: make install (or bash scripts/install.sh)"
