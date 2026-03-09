#!/usr/bin/env bash
set -euo pipefail

PASS="\033[32m✓\033[0m"
FAIL="\033[31m✗\033[0m"
WARN="\033[33m!\033[0m"
errors=0

check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo -e " $PASS $label"
  else
    echo -e " $FAIL $label"
    ((errors++)) || true
  fi
}

warn() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo -e " $PASS $label"
  else
    echo -e " $WARN $label (optional)"
  fi
}

echo "==> Doctor: checking environment health"
echo ""
echo "--- Core Tools ---"
check "Homebrew installed"     "command -v brew"
check "stow installed"         "command -v stow"
check "git installed"          "command -v git"

echo ""
echo "--- Language Managers ---"
check "fnm installed"          "command -v fnm"
check "rbenv installed"        "command -v rbenv"
check "pyenv installed"        "command -v pyenv"
check "rustup installed"       "command -v rustup"
warn  "SDKMAN installed"       "[ -d \"$HOME/.sdkman\" ]"

echo ""
echo "--- Dotfile Symlinks ---"
check "~/.zshrc is symlinked"      "[ -L \"$HOME/.zshrc\" ]"
check "~/.gitconfig is symlinked"  "[ -L \"$HOME/.gitconfig\" ]"
warn  "~/.ssh/config is symlinked" "[ -L \"$HOME/.ssh/config\" ]"

echo ""
echo "--- SSH & GPG ---"
warn  "SSH key exists"           "ls \"$HOME\"/.ssh/id_*.pub 2>/dev/null | head -1 | grep -q ."
warn  "GPG key configured"       "git config --global user.signingkey 2>/dev/null | grep -q ."
warn  "GPG signing enabled"      "[ \"\$(git config --global commit.gpgsign 2>/dev/null)\" = 'true' ]"

echo ""
echo "--- Broken Symlinks in ~ ---"
broken=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
if [ -z "$broken" ]; then
  echo -e " $PASS No broken symlinks in ~"
else
  echo -e " $FAIL Broken symlinks found:"
  echo "$broken"
  ((errors++)) || true
fi

echo ""
if [ "$errors" -eq 0 ]; then
  echo "==> All checks passed."
else
  echo "==> $errors check(s) failed. Review output above."
  exit 1
fi
