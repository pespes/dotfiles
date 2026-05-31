#!/usr/bin/env bash
# Compare installed tools vs dotfiles repo. Read-only — makes no changes.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/homebrew/Brewfile"

ISSUE_COUNT=0
declare -a ACTIONS=()

# Extensions listed here are installed but intentionally omitted from install scripts.
CURSOR_EXTENSION_IGNORE=(
  anysphere.cursorpyright
)
NPM_GLOBAL_IGNORE=(npm corepack)

section() {
  echo "--- $1 ---"
}

ok() {
  echo "    ✓ $1"
}

issue() {
  echo "    ! $1"
  ISSUE_COUNT=$((ISSUE_COUNT + 1))
}

action() {
  ACTIONS+=("$1")
}

# Compare two sorted lists; print lines only in $2 (installed \ tracked).
# Lines in $2 that are not in $1 (e.g. installed minus tracked).
list_extra() {
  comm -13 <(echo "$1") <(echo "$2") 2>/dev/null || true
}

# Lines in $1 that are not in $2 (e.g. tracked minus installed).
list_missing() {
  comm -23 <(echo "$1") <(echo "$2") 2>/dev/null || true
}

audit_homebrew() {
  if ! command -v brew &>/dev/null; then
    section "Homebrew"
    echo "    (brew not installed — skipped)"
    echo ""
    return
  fi

  if [ ! -f "$BREWFILE" ]; then
    section "Homebrew"
    issue "Brewfile missing at homebrew/Brewfile"
    action "Create a Brewfile: make backup, then curate and commit."
    echo ""
    return
  fi

  local tracked_formulae tracked_casks installed_formulae installed_casks
  tracked_formulae=$(brew bundle list --file="$BREWFILE" --formula 2>/dev/null | sort)
  tracked_casks=$(brew bundle list --file="$BREWFILE" --cask 2>/dev/null | sort)
  installed_formulae=$(brew leaves 2>/dev/null | sort)
  installed_casks=$(brew list --cask 2>/dev/null | sort)

  section "Homebrew formulae installed but NOT in Brewfile"
  echo "    (top-level only — transitive deps are ignored)"
  local untracked_formulae
  untracked_formulae=$(list_extra "$tracked_formulae" "$installed_formulae")
  if [ -n "$untracked_formulae" ]; then
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && issue "formula: $pkg"
    done <<<"$untracked_formulae"
    action "Homebrew formula untracked: add brew \"<name>\" to homebrew/Brewfile and commit, or brew uninstall <name>."
  else
    ok "All top-level formulae are in the Brewfile."
  fi
  echo ""

  section "Homebrew casks installed but NOT in Brewfile"
  local untracked_casks
  untracked_casks=$(list_extra "$tracked_casks" "$installed_casks")
  if [ -n "$untracked_casks" ]; then
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && issue "cask: $pkg"
    done <<<"$untracked_casks"
    action "Homebrew cask untracked: add cask \"<name>\" to homebrew/Brewfile and commit, or brew uninstall --cask <name>."
  else
    ok "All casks are in the Brewfile."
  fi
  echo ""

  section "Homebrew packages in Brewfile but NOT installed"
  local missing_formulae missing_casks pkg
  missing_formulae=""
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! brew list --formula "$pkg" &>/dev/null; then
      missing_formulae+="${missing_formulae:+$'\n'}$pkg"
      issue "formula not installed: $pkg"
    fi
  done <<<"$tracked_formulae"

  missing_casks=""
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! brew list --cask "$pkg" &>/dev/null; then
      missing_casks+="${missing_casks:+$'\n'}$pkg"
      issue "cask not installed: $pkg"
    fi
  done <<<"$tracked_casks"

  if [ -z "$missing_formulae" ] && [ -z "$missing_casks" ]; then
    ok "All Brewfile packages are installed."
  else
    action "Install Brewfile packages: brew bundle install --file=\"$BREWFILE\""
    action "Or remove unused entries from homebrew/Brewfile and commit."
  fi
  echo ""
}

audit_npm_globals() {
  if ! command -v npm &>/dev/null; then
    return
  fi
  if [ ! -f "$DOTFILES_DIR/lang/node-globals.sh" ]; then
    return
  fi
  if ! command -v node &>/dev/null; then
    section "Global npm packages"
    echo "    (node not found — skipped)"
    echo ""
    return
  fi

  section "Global npm packages not tracked in lang/node-globals.sh"
  local ignore_json installed_npm tracked_npm untracked
  ignore_json=$(printf '%s\n' "${NPM_GLOBAL_IGNORE[@]}" | node -e "
    const names = require('fs').readFileSync(0, 'utf8').trim().split('\n').filter(Boolean);
    process.stdout.write(JSON.stringify(names));
  ")
  installed_npm=$(
    npm list -g --depth=0 --json 2>/dev/null | node -e "
      const ignore = new Set($ignore_json);
      const j = JSON.parse(require('fs').readFileSync(0, 'utf8') || '{}');
      Object.keys(j.dependencies || {})
        .filter((name) => !ignore.has(name))
        .sort()
        .forEach((name) => console.log(name));
    " 2>/dev/null || true
  )
  tracked_npm=$(
    awk '/npm install -g/ {next} /^[[:space:]]/ {
      gsub(/\\$/, ""); gsub(/^[[:space:]]+/, "");
      if ($1 != "") print $1
    }' "$DOTFILES_DIR/lang/node-globals.sh" | sort
  )
  untracked=$(list_extra "$tracked_npm" "$installed_npm")
  if [ -n "$untracked" ]; then
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && issue "not tracked: $pkg"
    done <<<"$untracked"
    action "npm untracked: add package to lang/node-globals.sh, run make update, then commit."
    action "Or uninstall: npm uninstall -g <package>"
  else
    ok "All global npm packages are tracked."
  fi
  echo ""
}

audit_broken_symlinks() {
  section "Broken symlinks in ~"
  local broken
  broken=$(find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
  if [ -z "$broken" ]; then
    ok "None found."
  else
    while IFS= read -r link; do
      [ -n "$link" ] && issue "broken: $link"
    done <<<"$broken"
    action "Broken symlink: run make link, or rm the stale link and make link again."
  fi
  echo ""
}

# $1 = editor label, $2 = install script, $3 = list-extensions command, $4+ = ignore IDs
audit_editor_extensions() {
  local label="$1" script="$2" list_cmd="$3"
  shift 3
  local -a ignore=("$@")

  if [ ! -f "$script" ]; then
    return
  fi

  local tracked installed ignore_filter untracked missing
  tracked=$(
    grep -- '--install-extension' "$script" |
      sed 's/.*--install-extension[[:space:]]*//' |
      sed 's/[[:space:]].*//' |
      sort
  )
  installed=$(bash -c "$list_cmd" 2>/dev/null | sort)
  ignore_filter=$(printf '%s\n' "${ignore[@]}" | sed '/^$/d')
  if [ -n "$ignore_filter" ]; then
    installed=$(echo "$installed" | grep -vFf <(echo "$ignore_filter") || true)
  fi

  section "$label extensions installed but NOT in $(basename "$script")"
  untracked=$(list_extra "$tracked" "$installed")
  if [ -n "$untracked" ]; then
    while IFS= read -r ext; do
      [ -n "$ext" ] && issue "not tracked: $ext"
    done <<<"$untracked"
    action "$label untracked: add --install-extension <id> to $(basename "$script"), then commit."
    action "$label untracked: or uninstall with --uninstall-extension <id>"
  else
    ok "All installed extensions are tracked."
  fi
  echo ""

  section "$label extensions in $(basename "$script") but NOT installed"
  missing=$(list_missing "$tracked" "$installed")
  if [ -n "$missing" ]; then
    while IFS= read -r ext; do
      [ -n "$ext" ] && issue "not installed: $ext"
    done <<<"$missing"
    action "$label missing: run make editors (or bash $script)."
    action "Or remove the extension line from $(basename "$script") and commit."
  else
    ok "All tracked extensions are installed."
  fi
  echo ""
}

print_summary() {
  echo "==> Summary"
  if [ "$ISSUE_COUNT" -eq 0 ]; then
    echo "    No drift detected. Environment matches the repo."
    echo ""
    echo "AUDIT_STATUS: clean"
    return 0
  fi

  echo "    Found $ISSUE_COUNT issue(s). Review sections marked with ! above."
  echo ""
  echo "    Next steps (by category):"
  local i=1 seen="" line
  for line in "${ACTIONS[@]}"; do
    if [[ " $seen " != *" $line "* ]]; then
      echo "    $i. $line"
      seen+="$line "
      i=$((i + 1))
    fi
  done
  echo ""
  echo "AUDIT_STATUS: drift ($ISSUE_COUNT issue(s))"
  return 1
}

# --- main ---
echo "==> Audit: checking for environment drift"
echo "    Repo: $DOTFILES_DIR"
echo ""

audit_homebrew
audit_npm_globals
audit_broken_symlinks

if command -v code &>/dev/null; then
  audit_editor_extensions "VS Code" \
    "$DOTFILES_DIR/editors/vscode-extensions.sh" \
    "code --list-extensions"
fi

CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor
if [ -x "$CURSOR" ]; then
  audit_editor_extensions "Cursor" \
    "$DOTFILES_DIR/editors/cursor-extensions.sh" \
    "\"$CURSOR\" --list-extensions" \
    "${CURSOR_EXTENSION_IGNORE[@]}"
fi

print_summary
