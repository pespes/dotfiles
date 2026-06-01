#!/usr/bin/env bash
#
# python-globals.sh — Global pip packages (pyenv-managed Python).
#
# Invoked by:  scripts/install.sh, scripts/update.sh (after pyenv global)
# Not stowed:  Repo only — see lang/.stow-local-ignore.
#
set -euo pipefail

pip install --upgrade \
  pip \
  pipx \
  black \
  ruff
