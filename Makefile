# dotfiles/Makefile

DOTFILES_DIR := $(shell pwd)
STOW_PACKAGES := zsh git ssh lang gnupg

.PHONY: help install link update backup doctor audit editors

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full fresh-Mac setup: bootstrap → install → link → editors
	@echo "==> Starting full install..."
	@bash scripts/bootstrap.sh
	@bash scripts/install.sh
	@bash scripts/link.sh
	@bash scripts/vscode-setup.sh
	@echo "==> Install complete. Work through README post-install checklist."

link: ## Sync all dotfile symlinks (safe to run anytime)
	@echo "==> Linking dotfiles..."
	@bash scripts/link.sh
	@echo "==> Done."

update: ## Update Homebrew, language managers, and global packages
	@echo "==> Updating..."
	@bash scripts/update.sh
	@echo "==> Done."

backup: ## Snapshot current Homebrew state
	@echo "==> Backing up..."
	@brew bundle dump --file=homebrew/Brewfile.backup --force
	@echo "==> Backup saved to homebrew/Brewfile.backup"

doctor: ## Check for broken symlinks, missing tools, SSH/GPG config
	@echo "==> Running doctor checks..."
	@bash scripts/doctor.sh

audit: ## Show drift: what's installed but not tracked, and vice versa
	@echo "==> Auditing environment drift..."
	@bash scripts/audit.sh

editors: ## Install curated VS Code and Cursor extensions
	@echo "==> Installing editor extensions..."
	@bash scripts/vscode-setup.sh
