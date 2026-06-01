#!/usr/bin/env bash
#
# rust-globals.sh — Rust toolchain components and global cargo installs.
#
# Invoked by:  scripts/install.sh, scripts/update.sh (after rustup update)
# Not stowed:  Repo only — see lang/.stow-local-ignore.
# cargo:       Uncomment cargo install lines below as you add global tools.
#
set -euo pipefail

rustup component add \
  clippy \
  rustfmt

# cargo installs (add packages here as you install them globally)
# cargo install cargo-watch
