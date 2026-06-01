#!/usr/bin/env bash
#
# node-globals.sh — Global npm packages (fnm-managed Node).
#
# Invoked by:  scripts/install.sh, scripts/update.sh (after fnm use)
# Not stowed:  Lives in repo only (see lang/.stow-local-ignore). Do not symlink into ~.
# Edit:        Add packages to the npm install -g list below, then make update and commit.
# pnpm:        Single install path — global npm on fnm Node (not ~/Library/pnpm or corepack).
#
set -euo pipefail

npm install -g \
  pnpm \
  @anthropic-ai/claude-code
