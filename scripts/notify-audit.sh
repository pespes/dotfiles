#!/usr/bin/env bash
# Run by launchd weekly — checks for environment drift and notifies if found

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_OUTPUT=$(bash "$DOTFILES_DIR/scripts/audit.sh" 2>&1)

# Notify if anything needs attention
if echo "$AUDIT_OUTPUT" | grep -qE "Would uninstall|Not tracked:|!.*symlink"; then
  terminal-notifier \
    -title "dotfiles audit" \
    -message "Environment drift detected. Run 'make audit' to review." \
    -sound default \
    -group dotfiles-audit
fi
