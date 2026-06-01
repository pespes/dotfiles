# dotfiles/Makefile

DOTFILES_DIR := $(shell pwd)
# Keep in sync with PACKAGES in scripts/link.sh
STOW_PACKAGES := zsh git ssh lang claude

.PHONY: help install link update backup doctor audit editors bootstrap install-tools lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Xcode CLT, Homebrew, and stow (fresh Mac first step)
	@bash scripts/bootstrap.sh

install-tools: ## Brewfile + optional languages (no symlinks/editors)
	@bash scripts/install.sh

install: ## Full fresh-Mac setup: bootstrap → tools → link → editors
	@echo "==> Starting full install..."
	@set -e; \
	bash scripts/bootstrap.sh; \
	bash scripts/install.sh; \
	bash scripts/link.sh; \
	bash scripts/vscode-setup.sh; \
	echo ""; \
	echo "==> Install complete."; \
	echo "    Open a new terminal, then: make audit"; \
	echo "    Work through README post-install checklist."

link: ## Sync dotfile symlinks via stow + audit launchd job (safe anytime)
	@bash scripts/link.sh

update: ## Upgrade Brewfile packages, globals, and editor extensions
	@echo "==> Updating..."
	@bash scripts/update.sh
	@echo "==> Done."

backup: ## Snapshot all Homebrew packages to Brewfile.backup (gitignored)
	@bash scripts/backup.sh

doctor: ## Health check: tools, symlinks, Brewfile (exit 1 if required checks fail)
	@bash scripts/doctor.sh

audit: ## Show drift vs repo (exit 1 when issues found)
	@echo "==> Auditing environment drift..."
	@bash scripts/audit.sh

lint: ## Shellcheck all bash scripts at warning level (zsh/.zshrc excluded — it's zsh)
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found — run: make install-tools"; exit 1; }
	@shellcheck -x -S warning scripts/*.sh scripts/lib/common.sh editors/*.sh lang/*.sh && echo "✓ shellcheck clean (warning level)"

editors: ## Install curated VS Code and Cursor extensions
	@echo "==> Installing editor extensions..."
	@bash scripts/vscode-setup.sh
