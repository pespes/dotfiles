#!/usr/bin/env bash
#
# ruby-globals.sh — Global Ruby gems (rbenv-managed Ruby).
#
# Invoked by:  scripts/install.sh, scripts/update.sh (after rbenv global)
# Not stowed:  Repo only — see lang/.stow-local-ignore.
#
set -euo pipefail

gem install \
  bundler       # Dependency manager for Ruby projects
