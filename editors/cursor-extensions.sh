#!/usr/bin/env bash
# Curated Cursor extensions
# Run: bash editors/cursor-extensions.sh
# Or:  make editors
#
# Cursor has built-in AI (no need for copilot-chat, claude-code).
# Cursor uses its own Pyright — ms-python.vscode-pylance not listed.
# redhat.vscode-yaml auto-installs with atlassian.atlascode — not listed separately.

set -euo pipefail

CURSOR=/Applications/Cursor.app/Contents/Resources/app/bin/cursor

# -----------------------------------------------------------------------------
# AI & IntelliSense
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension google.geminicodeassist                    # Gemini AI code assist
"$CURSOR" --install-extension visualstudioexptteam.vscodeintellicode    # AI-assisted IntelliSense

# -----------------------------------------------------------------------------
# Git & Version Control
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension eamodio.gitlens                            # Advanced git history, blame, and insights
"$CURSOR" --install-extension github.vscode-github-actions               # GitHub Actions workflow support
"$CURSOR" --install-extension atlassian.atlascode                        # Jira & Confluence integration

# -----------------------------------------------------------------------------
# JavaScript / TypeScript / React / React Native
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension dsznajder.es7-react-js-snippets            # ES7+ React/Redux snippets
"$CURSOR" --install-extension msjsdiag.vscode-react-native               # React Native tools
"$CURSOR" --install-extension leizongmin.node-module-intellisense        # Node module name autocomplete

# -----------------------------------------------------------------------------
# Web / CSS / HTML
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension bradlc.vscode-tailwindcss                  # Tailwind CSS IntelliSense
"$CURSOR" --install-extension ecmel.vscode-html-css                      # CSS class name completion for HTML
"$CURSOR" --install-extension formulahendry.auto-close-tag               # Auto-close HTML/XML tags
"$CURSOR" --install-extension formulahendry.auto-rename-tag              # Auto-rename paired HTML tags
"$CURSOR" --install-extension astro-build.astro-vscode                   # Astro framework support
"$CURSOR" --install-extension svelte.svelte-vscode                       # Svelte framework support

# -----------------------------------------------------------------------------
# Formatting & Linting
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension esbenp.prettier-vscode                     # Prettier code formatter
"$CURSOR" --install-extension dbaeumer.vscode-eslint                     # ESLint JS/TS linting
"$CURSOR" --install-extension wmaurer.change-case                        # Change variable case (camel, snake, etc.)
"$CURSOR" --install-extension formulahendry.code-runner                  # Run code snippets directly

# -----------------------------------------------------------------------------
# Python & Jupyter
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension ms-python.python                           # Python language support
"$CURSOR" --install-extension ms-python.debugpy                          # Python debugger
"$CURSOR" --install-extension ms-python.isort                            # Python import sorting
"$CURSOR" --install-extension ms-toolsai.jupyter                         # Jupyter notebook support

# -----------------------------------------------------------------------------
# Java
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension redhat.java                                # Java language support
"$CURSOR" --install-extension vscjava.vscode-java-debug                  # Java debugger
"$CURSOR" --install-extension vscjava.vscode-java-dependency             # Java dependency viewer
"$CURSOR" --install-extension vscjava.vscode-java-test                   # Java test runner
"$CURSOR" --install-extension vscjava.vscode-maven                       # Maven support

# -----------------------------------------------------------------------------
# Rust
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension rust-lang.rust-analyzer                    # Rust language server

# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension golang.go                                   # Go language support

# -----------------------------------------------------------------------------
# Dart / Flutter
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension dart-code.dart-code                        # Dart language support
"$CURSOR" --install-extension dart-code.flutter                          # Flutter framework support

# -----------------------------------------------------------------------------
# Remote Development & Containers
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension ms-vscode-remote.remote-ssh                # SSH remote development
"$CURSOR" --install-extension ms-vscode-remote.remote-ssh-edit           # Edit SSH config files
"$CURSOR" --install-extension ms-vscode-remote.remote-containers         # Dev Containers support
"$CURSOR" --install-extension ms-vscode.remote-explorer                  # Remote Explorer panel
"$CURSOR" --install-extension ms-azuretools.vscode-docker                # Docker support
"$CURSOR" --install-extension ms-azuretools.vscode-containers            # Container tools
"$CURSOR" --install-extension gitpod.gitpod-desktop                      # Gitpod integration

# -----------------------------------------------------------------------------
# Markdown
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension yzhang.markdown-all-in-one                 # Markdown preview, TOC, shortcuts
"$CURSOR" --install-extension davidanson.vscode-markdownlint             # Markdown linting

# -----------------------------------------------------------------------------
# Themes & UI
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension pkief.material-icon-theme                  # Material file icons
"$CURSOR" --install-extension vscode-icons-team.vscode-icons             # VS Code icons
"$CURSOR" --install-extension zhuangtongfa.material-theme                # One Dark Pro theme
"$CURSOR" --install-extension benjaminbenais.copilot-theme               # Copilot theme

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
"$CURSOR" --install-extension mechatroner.rainbow-csv                    # Colorized CSV viewer
"$CURSOR" --install-extension christian-kohler.path-intellisense         # File path autocomplete
"$CURSOR" --install-extension christian-kohler.npm-intellisense          # npm package autocomplete
"$CURSOR" --install-extension figma.figma-vscode-extension               # Figma design integration
"$CURSOR" --install-extension expo.vscode-expo-tools                     # Expo (React Native) tools
