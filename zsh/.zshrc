# ~/.zshrc
# Managed by dotfiles — edit in ~/dotfiles/zsh/.zshrc

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Load spaceship theme
source "/opt/homebrew/opt/spaceship/spaceship.zsh"

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

DOTFILES_DIR="$HOME/dotfiles"

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

npm() {
  command npm "$@"
  if [[ "$1" == "install" && "$2" == "-g" && -n "$3" ]]; then
    local pkg="$3"
    local globals="$DOTFILES_DIR/lang/node-globals.sh"
    if ! grep -q "$pkg" "$globals" 2>/dev/null; then
      echo "  $pkg \\" >> "$globals"
      echo "dotfiles → Added '$pkg' to node-globals.sh. Commit when ready."
    fi
  fi
}

pip() {
  command pip "$@"
  if [[ "$1" == "install" && -n "$2" && "$2" != "--upgrade" ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/python-globals.sh"
    if ! grep -q "$pkg" "$globals" 2>/dev/null; then
      echo "  $pkg \\" >> "$globals"
      echo "dotfiles → Added '$pkg' to python-globals.sh. Commit when ready."
    fi
  fi
}

gem() {
  command gem "$@"
  if [[ "$1" == "install" && -n "$2" ]]; then
    local pkg="$2"
    local globals="$DOTFILES_DIR/lang/ruby-globals.sh"
    if ! grep -q "$pkg" "$globals" 2>/dev/null; then
      echo "  $pkg \\" >> "$globals"
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

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# SDKMAN (Java) — must be at end of file
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
