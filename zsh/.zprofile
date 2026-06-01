# ~/.zprofile — login shell (macOS Terminal / iTerm)
# Managed by dotfiles — edit in ~/dotfiles/zsh/.zprofile

eval "$(/opt/homebrew/bin/brew shellenv)"

# Java via SDKMAN (also re-sourced at end of ~/.zshrc for interactive shells)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
