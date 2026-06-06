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
| `make install` | Full fresh-Mac setup (stops on first failed step) |
| `make bootstrap` | Xcode CLT + Homebrew + stow only |
| `make install-tools` | Brewfile + optional languages (no symlinks/editors) |
| `make link` | Stow dotfiles into ~ + weekly audit job (safe anytime) |
| `make update` | Upgrade Brewfile packages, language globals, and editor extensions |
| `make editors` | Install curated VS Code + Cursor extensions |
| `make backup` | Dump all Homebrew packages to `homebrew/Brewfile.backup` (compare with Brewfile) |
| `make doctor` | Health check: tools, symlinks, Brewfile installs (exit 1 on failure) |
| `make audit` | Show environment drift (exits 1 if issues found) |
| `make lint` | Shellcheck all bash scripts at warning level (`zsh/.zshrc` is zsh, not linted) |
| `make help` | Show all commands |

## Scripts

See [scripts/README.md](scripts/README.md) for what each `scripts/*.sh` file does and how they fit together.

## What's Managed

- Homebrew packages (`homebrew/Brewfile`)
- Shell config (`zsh/`)
- Git config (`git/`)
- SSH config (`ssh/`)
- Language version managers + global packages (`lang/`)

### Language versions

Pins live in `lang/.tool-versions`. `make install` / `make update` sync each manager; `make doctor` checks active versions.

| Language | Manager | Pin example |
|----------|---------|-------------|
| Node | fnm | `v24.14.0` |
| Ruby | rbenv | `3.3.10` |
| Python | uv | `3.13.12` |
| Rust | rustup | `stable-aarch64-apple-darwin` |
| Java | SDKMAN (Temurin) | `21.0.11-tem` — use `sdk list java` when bumping |

Java is **not** in the Brewfile. Dev shells get `java` / `JAVA_HOME` from SDKMAN (end of `zsh/.zshrc`). After removing system JDKs, `/usr/libexec/java_home` may report “no runtime”; that is expected — use a terminal with dotfiles loaded. `make update` syncs the pin via `sdk install` / `sdk default` only (not `sdk upgrade`, which prompts for SDKMAN channel defaults).

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
| Daily/weekly | `make update` (Brewfile-only Homebrew — not every formula on your Mac) |
| After installing anything | `make audit` |
| After adding a dotfile | `make link && git commit` |
| After editing a script | `make lint` before committing |
| Something feels broken | `make doctor`, then `make audit` |
| Before major Brewfile changes | `make backup`, then diff against `homebrew/Brewfile` |
