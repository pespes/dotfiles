#!/usr/bin/env bash
# Curated VS Code extensions
# Run: bash editors/vscode-extensions.sh
# Or:  make editors
#
# Auto-installed dependencies are NOT listed (e.g. redhat.vscode-yaml auto-installs
# with atlassian.atlascode).
# VS Code-specific extensions (not in Cursor) are marked with [VS Code only].

set -euo pipefail

code --install-extension anthropic.claude-code                          # Claude Code AI assistant [VS Code only]

# -----------------------------------------------------------------------------
# AI
# -----------------------------------------------------------------------------
code --install-extension google.geminicodeassist                        # Gemini AI code assist
code --install-extension github.copilot-chat                            # GitHub Copilot AI chat [VS Code only]

# -----------------------------------------------------------------------------
# Git & Version Control
# -----------------------------------------------------------------------------
code --install-extension eamodio.gitlens                                # Advanced git history, blame, and insights
code --install-extension github.vscode-github-actions                   # GitHub Actions workflow support
code --install-extension atlassian.atlascode                            # Jira & Confluence integration

# -----------------------------------------------------------------------------
# JavaScript / TypeScript / React / React Native
# -----------------------------------------------------------------------------
code --install-extension dsznajder.es7-react-js-snippets                # ES7+ React/Redux snippets
code --install-extension msjsdiag.vscode-react-native                   # React Native tools
code --install-extension leizongmin.node-module-intellisense            # Node module name autocomplete

# -----------------------------------------------------------------------------
# Web / CSS / HTML
# -----------------------------------------------------------------------------
code --install-extension bradlc.vscode-tailwindcss                      # Tailwind CSS IntelliSense
code --install-extension ecmel.vscode-html-css                          # CSS class name completion for HTML
code --install-extension formulahendry.auto-close-tag                   # Auto-close HTML/XML tags
code --install-extension formulahendry.auto-rename-tag                  # Auto-rename paired HTML tags
code --install-extension astro-build.astro-vscode                       # Astro framework support
code --install-extension svelte.svelte-vscode                           # Svelte framework support

# -----------------------------------------------------------------------------
# Formatting & Linting
# -----------------------------------------------------------------------------
code --install-extension esbenp.prettier-vscode                         # Prettier code formatter
code --install-extension dbaeumer.vscode-eslint                         # ESLint JS/TS linting
code --install-extension wmaurer.change-case                             # Change variable case (camel, snake, etc.)
code --install-extension formulahendry.code-runner                      # Run code snippets directly

# -----------------------------------------------------------------------------
# Python & Jupyter
# -----------------------------------------------------------------------------
code --install-extension ms-python.python                               # Python language support
code --install-extension ms-python.debugpy                              # Python debugger
code --install-extension ms-python.isort                                # Python import sorting
code --install-extension ms-toolsai.jupyter                             # Jupyter notebook support

# -----------------------------------------------------------------------------
# Java
# -----------------------------------------------------------------------------
code --install-extension redhat.java                                    # Java language support
code --install-extension vscjava.vscode-java-debug                      # Java debugger
code --install-extension vscjava.vscode-java-dependency                 # Java dependency viewer
code --install-extension vscjava.vscode-java-test                       # Java test runner
code --install-extension vscjava.vscode-maven                           # Maven support

# -----------------------------------------------------------------------------
# Rust
# -----------------------------------------------------------------------------
code --install-extension rust-lang.rust-analyzer                        # Rust language server

# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
code --install-extension golang.go                                       # Go language support

# -----------------------------------------------------------------------------
# Dart / Flutter
# -----------------------------------------------------------------------------
code --install-extension dart-code.dart-code                            # Dart language support
code --install-extension dart-code.flutter                              # Flutter framework support

# -----------------------------------------------------------------------------
# Remote Development & Containers
# -----------------------------------------------------------------------------
code --install-extension ms-vscode-remote.remote-ssh                    # SSH remote development
code --install-extension ms-vscode-remote.remote-ssh-edit               # Edit SSH config files
code --install-extension ms-vscode-remote.remote-containers             # Dev Containers support
code --install-extension ms-vscode.remote-explorer                      # Remote Explorer panel
code --install-extension ms-azuretools.vscode-docker                    # Docker support
code --install-extension ms-azuretools.vscode-containers                # Container tools
code --install-extension gitpod.gitpod-desktop                          # Gitpod integration

# -----------------------------------------------------------------------------
# Markdown
# -----------------------------------------------------------------------------
code --install-extension yzhang.markdown-all-in-one                     # Markdown preview, TOC, shortcuts
code --install-extension davidanson.vscode-markdownlint                 # Markdown linting

# -----------------------------------------------------------------------------
# Themes & UI
# -----------------------------------------------------------------------------
code --install-extension pkief.material-icon-theme                      # Material file icons
code --install-extension vscode-icons-team.vscode-icons                 # VS Code icons
code --install-extension zhuangtongfa.material-theme                    # One Dark Pro theme
code --install-extension github.github-vscode-theme                     # GitHub theme [VS Code only]
code --install-extension benjaminbenais.copilot-theme                   # Copilot theme

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
code --install-extension mechatroner.rainbow-csv                        # Colorized CSV viewer
code --install-extension christian-kohler.path-intellisense             # File path autocomplete
code --install-extension christian-kohler.npm-intellisense              # npm package autocomplete
code --install-extension figma.figma-vscode-extension                   # Figma design integration
code --install-extension expo.vscode-expo-tools                         # Expo (React Native) tools
