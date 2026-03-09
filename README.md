# dotfiles

Personal macOS development environment — source of truth.

## Quick Start (Fresh Mac)

```bash
git clone git@github.com:pespes/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
```

Then work through the [Post-Install Checklist](#post-install-checklist).

## Commands

| Command | Description |
|---|---|
| `make install` | Full fresh-Mac setup |
| `make link` | Sync symlinks (safe anytime) |
| `make update` | Update all tools |
| `make backup` | Snapshot current state |
| `make doctor` | Check environment health |
| `make audit` | Show environment drift |
| `make help` | Show all commands |

## What's Managed

- Homebrew packages (`homebrew/Brewfile`)
- Shell config (`zsh/`)
- Git config (`git/`)
- SSH config (`ssh/`)
- Language version managers + global packages (`lang/`)

## SSH Setup

1. Generate a new SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ```
2. Add to ssh-agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```
3. Copy public key and add to GitHub → Settings → SSH Keys:
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```
4. Set permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/*
   chmod 644 ~/.ssh/*.pub
   ```

## Post-Install Checklist

- [ ] Generate SSH key and add to GitHub (see [SSH Setup](#ssh-setup))
- [ ] Sign into iCloud
- [ ] Set macOS system preferences (keyboard repeat rate, dock, etc.)
- [ ] Open apps that require license activation
- [ ] Configure any app-specific settings not captured here

## Ongoing Maintenance

| When | Command |
|---|---|
| Daily/weekly | `make update` |
| After installing anything | `make audit` |
| After adding a dotfile | `make link && git commit` |
| Something feels broken | `make doctor` |
| Before major changes | `make backup` |
