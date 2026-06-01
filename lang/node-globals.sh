#!/usr/bin/env bash
#
# node-globals.sh — Global npm packages (fnm-managed Node).
#
# Invoked by:  scripts/install.sh, scripts/update.sh (after fnm use)
# Not stowed:  Lives in repo only (see lang/.stow-local-ignore). Do not symlink into ~.
# Edit:        Add packages to the npm install -g list below, then make update and commit.
# pnpm:        Single install path — global npm on fnm Node (not ~/Library/pnpm or corepack).
#              Tracks latest stable (pnpm@latest); make update records the installed
#              version into lang/.tool-versions so each bump shows up in git.
#
set -euo pipefail

npm install -g \
  pnpm@latest \
  @anthropic-ai/claude-code
