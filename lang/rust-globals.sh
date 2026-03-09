#!/usr/bin/env bash
# Rust components and cargo installs — run by make install and make update

rustup component add \
  clippy  \  # Rust linter
  rustfmt    # Rust code formatter

# cargo installs (add packages here as you install them globally)
# cargo install cargo-watch
