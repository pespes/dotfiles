# ~/.zshrc
# Managed by dotfiles — edit in ~/dotfiles/zsh/.zshrc

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Load spaceship theme
[[ -f /opt/homebrew/opt/spaceship/spaceship.zsh ]] && source "/opt/homebrew/opt/spaceship/spaceship.zsh"

# Which plugins would you like to load?
plugins=(brew git zsh-autosuggestions zsh-syntax-highlighting)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Language Manager Initialization
# =============================================================================

# fnm (Node)
eval "$(fnm env --use-on-cd)"

# rustup
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# pyenv (Python)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# rbenv (Ruby)
eval "$(rbenv init - zsh)"

# =============================================================================
# Dotfiles install tracking wrappers
# Auto-appends to tracking files when you install packages.
# Uninstalls are NOT auto-removed (too risky) — run `make audit` to catch drift.
# =============================================================================

# Repo root — works for ~/dotfiles or any clone path (e.g. ~/Documents/GitHub/dotfiles)
DOTFILES_DIR="${${(%):-%x}:A:h:h}"
export DOTFILES_DIR

brew() {
  command brew "$@"
  if [[ "$1" == "install" && -n "$2" ]]; then
    local pkg="$2"
    local brewfile="$DOTFILES_DIR/homebrew/Brewfile"
    if ! grep -q "\"$pkg\"" "$brewfile" 2>/dev/null; then
      echo "brew \"$pkg\"  # added $(date +%Y-%m-%d) — add a comment explaining why" >> "$brewfile"
      echo "dotfiles → Added '$pkg' to Brewfile. Edit the comment, then git commit."
    fi
  fi
}

# Insert a package as a continuation line right after the install command's head
# line (which ends with "\"). Appending at EOF would orphan it after the list's
# final, backslash-less line and break the script under `set -e`.
_dotfiles_track_continuation() {
  local globals="$1" head_regex="$2" pkg="$3"
  awk -v pkg="$pkg" -v head="$head_regex" '
    { print }
    $0 ~ head && !ins { print "  " pkg " \\"; ins = 1 }
  ' "$globals" >"$globals.tmp" && mv "$globals.tmp" "$globals"
}

# Already listed? Fixed-string match avoids treating package names as regexes.
_dotfiles_tracked() { grep -qF -- "$1" "$2" 2>/dev/null; }

npm() {
  command npm "$@"
  if [[ "$1" == "install" && "$2" == "-g" && -n "$3" ]]; then
    local pkg="$3"
    local globals="$DOTFILES_DIR/lang/node-globals.sh"
    if ! _dotfiles_tracked "$pkg" "$globals"; then
      _dotfiles_track_continuation "$globals" '^npm install -g' "$pkg"
      echo "dotfiles → Added '$pkg' to node-globals.sh. Commit when ready."
    fi
  fi
}

pip() {
  command pip "$@"
  if [[ "$1" == "install" && -n "$2" && "$2" != "--upgrade" && "$2" != -* ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/python-globals.sh"
    if ! _dotfiles_tracked "$pkg" "$globals"; then
      _dotfiles_track_continuation "$globals" '^pip install --upgrade' "$pkg"
      echo "dotfiles → Added '$pkg' to python-globals.sh. Commit when ready."
    fi
  fi
}

gem() {
  command gem "$@"
  if [[ "$1" == "install" && -n "$2" ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/ruby-globals.sh"
    if ! _dotfiles_tracked "$pkg" "$globals"; then
      _dotfiles_track_continuation "$globals" '^gem install' "$pkg"
      echo "dotfiles → Added '$pkg' to ruby-globals.sh. Commit when ready."
    fi
  fi
}

cargo() {
  command cargo "$@"
  if [[ "$1" == "install" && -n "$2" ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/rust-globals.sh"
    if ! grep -q "$pkg" "$globals" 2>/dev/null; then
      echo "cargo install $pkg" >> "$globals"
      echo "dotfiles → Added '$pkg' to rust-globals.sh. Commit when ready."
    fi
  fi
}

# =============================================================================
# PATH additions
# =============================================================================

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# pnpm — via fnm Node + lang/node-globals.sh (npm install -g pnpm). No ~/Library/pnpm PATH.

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# SDKMAN (Java) — must be at end of file (sets JAVA_HOME; not /usr/libexec/java_home)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
# Fallback if this session started before SDKMAN existed, or init did not set JAVA_HOME
if [[ -x "$SDKMAN_DIR/candidates/java/current/bin/java" ]]; then
  [[ -z "$JAVA_HOME" ]] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
  case ":$PATH:" in
    *":$JAVA_HOME/bin:"*) ;;
    *) export PATH="$JAVA_HOME/bin:$PATH" ;;
  esac
fi
