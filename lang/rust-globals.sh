#!/usr/bin/env bash
# Rust components and cargo installs — run by make install and make update

rustup component add \
  clippy \
  rustfmt

# cargo installs (add packages here as you install them globally)
# cargo install cargo-watch
