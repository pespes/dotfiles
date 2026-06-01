#!/usr/bin/env bash
#
# notify-audit.sh — Weekly drift check with a macOS notification (launchd).
#
# Invoked by:  ~/Library/LaunchAgents/com.pespes.dotfiles-audit.plist (installed via make link)
# Schedule:    Mondays at 9:00 (see macos/Library/LaunchAgents/com.pespes.dotfiles-audit.plist)
# Mutates:     Nothing. Sends notification only when audit reports drift.
# Depends on:  terminal-notifier (in Brewfile), scripts/audit.sh
#
# Logs:        /tmp/dotfiles-audit.log and /tmp/dotfiles-audit.err (configured in plist)
#
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_OUTPUT=$(bash "$DOTFILES_DIR/scripts/audit.sh" 2>&1) || true

if echo "$AUDIT_OUTPUT" | grep -q 'AUDIT_STATUS: drift'; then
  terminal-notifier \
    -title "dotfiles audit" \
    -message "Environment drift detected. Run 'make audit' to review." \
    -sound default \
    -group dotfiles-audit
fi
