# Scripts

Shell entry points for this dotfiles repo. Prefer **`make <target>`** from the repo root; each target runs a script here.

## Workflow (fresh Mac)

```text
make bootstrap    →  scripts/bootstrap.sh     Xcode CLT, Homebrew, stow
make install      →  bootstrap + install.sh + link.sh + vscode-setup.sh
make link         →  scripts/link.sh            Symlinks only (safe anytime)
```

## Ongoing maintenance

| Make target | Script | Purpose |
|-------------|--------|---------|
| `make update` | `update.sh` | Upgrade Brewfile packages, sync language pins/globals (fnm, rbenv, pyenv, SDKMAN, rustup), editor extensions |
| `make audit` | `audit.sh` | Compare machine vs repo (drift report, read-only) |
| `make doctor` | `doctor.sh` | Health check: tools, symlinks, Brewfile installs, version pins (including Java via SDKMAN) |
| `make backup` | `backup.sh` | Dump all Homebrew packages to `homebrew/Brewfile.backup` |
| `make editors` | `vscode-setup.sh` | Install curated VS Code / Cursor extensions |

## Background automation

| Script | Trigger |
|--------|---------|
| `notify-audit.sh` | macOS launchd (Mondays 9am), installed by `link.sh` |

## Shared library

| File | Role |
|------|------|
| `lib/common.sh` | Sourced by other scripts — not run directly. Brew PATH, `lang/.tool-versions` parsing. |

## Related scripts outside `scripts/`

| Path | Invoked by | Role |
|------|------------|------|
| `lang/*-globals.sh` | `install.sh`, `update.sh` | Install global npm/gem/pip/Rust tools; optional `sdk install` lines in `java-globals.sh` |
| `lang/.tool-versions` | `install.sh`, `update.sh`, `doctor.sh` | Version pins; Java uses SDKMAN ids (`21.0.11-tem`) via `lib/common.sh` `java_sdkman_id` |
| `editors/*-extensions.sh` | `vscode-setup.sh` | Curated extension IDs per editor |

## Status lines (for automation)

Scripts that can fail print a machine-readable status at the end:

- `AUDIT_STATUS: clean` / `drift (N issue(s))`
- `UPDATE_STATUS: ok` / `failed (N step(s))`
- `INSTALL_STATUS: ok` / `failed (N step(s))`
- `LINK_STATUS: ok` / `failed (N step(s))`
- `DOCTOR_STATUS: ok` / `ok_with_warnings` / `failed`
- `BACKUP_STATUS: ok` / `failed`

`notify-audit.sh` greps `audit.sh` output for `AUDIT_STATUS: drift`.

## Environment variables

| Variable | Scripts | Effect |
|----------|---------|--------|
| `DOTFILES_ASSUME_YES=1` | `install.sh` | Accept all optional setup prompts (non-interactive install) |
