#!/usr/bin/env bash
# Global pip packages — installed/updated by make install and make update

pip install --upgrade \
  pip   \  # Upgrade pip itself
  pipx  \  # Install Python CLI tools in isolated envs
  black \  # Opinionated code formatter
  ruff     # Fast Python linter
