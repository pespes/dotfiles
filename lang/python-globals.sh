#!/usr/bin/env bash
#
# python-globals.sh — Global Python tools (uv-managed).
#
# Invoked by:  scripts/install.sh, scripts/update.sh
# Not stowed:  Repo only — see lang/.stow-local-ignore.
#
set -euo pipefail

uv tool install black
uv tool install ruff
