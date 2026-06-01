# Language Runtime Migration: fnm/pyenv/rbenv/SDKMAN → mise

**Date:** 2026-06-01  
**Status:** Reviewed & corrected — plan only (no code changes in this pass)

---

## Review Corrections (mise 2026.5.18 installed and queried, 2026-06-01)

The original draft asserted several mise specifics as "verified," but mise was **not installed** when it was written — those were model knowledge, not machine facts. mise has since been installed and the claims checked directly. Results:

| Original claim | Verified result | Action |
|---|---|---|
| `disable_tools` setting | **Real** (`mise settings get disable_tools` → `[]`) | Keep — but scope to `["pnpm"]`, see below |
| mise has `rust` + `pnpm` registry entries | **Real** (`rust core:rust …`, `pnpm aqua:pnpm/pnpm npm:pnpm`) | Confirms mise *would* try to manage them if listed |
| `mise env -s bash` | **Real** (`-s, --shell <SHELL>`) | Keep |
| `java.shorthand_vendor = "temurin"` setting | **Does not exist** | **Removed** — vendor lives in the version string |
| Java pin `temurin-21.0.11` | **Invalid** — real id is `temurin-21.0.11+10.0.LTS` (from `mise ls-remote java`) | **Pin corrected** (note: SDKMAN `21.0.11-tem` ≠ mise id — no clean map; take the exact string from `ls-remote`) |

**Structural corrections applied below:**
1. **rust is commented out in `.tool-versions`** so mise never sees it — simpler than disabling, and removes a fresh-install ordering hazard. `disable_tools` is therefore **`["pnpm"]` only** (pnpm's line is rewritten live by `record_pnpm_version`, so it can't just be commented).
2. **Ordering gap fixed:** `disable_tools` lives in `~/.config/mise/config.toml`, which is only present **after `make link`** — but `install.sh` runs `mise install` **before** link on a fresh Mac. The settings must be readable from the repo at install time (e.g. a `lang/mise.toml`/local config that `cd lang` picks up), or pnpm must be commented like rust. Verify in Phase 0.
3. **Phase 1 + Phase 2 merged** into one atomic cutover — the old Phase 1 deliberately left `make doctor` red, which is not an independently-verifiable state.
4. **`brew uninstall` dependency order:** `pyenv`/`ruby-build` are not `brew leaves` (pulled as deps); uninstall dependents first or use `--ignore-dependencies`.

---

## 0. Locked Decisions (resolved with maintainer + machine inspection)

| Topic | Decision |
|---|---|
| pnpm | **Stays an npm global** (`node-globals.sh` + `record_pnpm_version`). mise ignores it via `disable_tools = ["pnpm"]` (its line is rewritten live, so it can't be commented out). |
| rust | **Stays rustup.** Its `.tool-versions` line is **commented out** so mise never sees it (simpler than `disable_tools`; also avoids the fresh-install ordering hazard). |
| `disable_tools` | `["pnpm"]` in mise settings — **verified real** (`mise settings get disable_tools`). Must be in effect *before* the first `mise install` (see ordering fix in Review Corrections). |
| Java pin | `temurin-21.0.11+10.0.LTS` — exact id from `mise ls-remote java` (`temurin-21.0.11` alone is **not** valid). Stay on 21 LTS; 21→25 is a separate later decision (see §3.4). |
| install.sh prompts | **Single** "Set up mise runtimes (node/ruby/python/java)?" prompt. `DOTFILES_ASSUME_YES=1` unchanged. |
| Old-manager cleanup | Brew **formulae uninstalled in Phase 1** (audit-green). **Data dirs** (`~/.fnm`, `~/.pyenv`, `~/.rbenv`, `~/.sdkman`) kept ~2 weeks as rollback, removed in a later cleanup commit (Phase 3b). |
| pyenv-virtualenv | **Remove** — confirmed zero named virtualenvs on this machine. |
| SDKMAN | **Java-only** on this machine (only `java` candidate) → fully removed after cutover. |
| Config | Keep `.tool-versions` (pins) + stowed `~/.config/mise/config.toml` (settings only). |
| Shell | `mise activate zsh`. |
| Globals | Keep `*-globals.sh` (Phase 4 backend migration skipped unless requested). |
| doctor scope | **No new** pnpm/rust pin checks — preserve current parity. |
| Install ordering | Scripts run `(cd "$DOTFILES_DIR/lang" && mise install)` / `mise env` — **never depend on the `~/.tool-versions` symlink.** |
| mise trust | Phase 0 verification gate (confirm no non-interactive hang). |

**Machine inspection findings (2026-06-01):** No pyenv virtualenvs. SDKMAN candidates = `java` only, with **two** JDKs installed (`21.0.11-tem` pinned + a stray `25.0.3-tem`). No crontab; no LaunchAgent references any manager. Only the repo's own files reference fnm/pyenv/rbenv/SDKMAN.

---

## 1. Summary + Recommendation

### Recommendation: **Proceed — in phased, reversible steps**

The current multi-manager setup works (`make doctor` is green). The migration is justified only by **consolidation** (four version managers + SDKMAN curl bootstrap → one Brew formula) and a **cleaner fresh-Mac story** (`brew bundle` + `mise install` instead of five separate install paths). It is **not** justified by fixing broken behavior or by chasing marginal performance wins.

Proceed: ~4 focused commits touching shell init and four scripts, plus a deferred data-dir cleanup commit. **Do not** bundle optional work (globals migration to mise backends, rust pin enforcement, pyenv-virtualenv replacement, 21→25 Java bump) into the initial cutover — that adds complexity without proportional payoff.

If the maintainer primarily uses this machine as-is and rarely reprovisions, **defer** the migration; the status quo is low-friction.

### Verified repo corrections (brief vs reality)

| Brief claim | Actual state |
|---|---|
| Java pin is `temurin-21` / stale `21.0.11-tem` mapping | Pin is already `21.0.11-tem` (SDKMAN id) in `lang/.tool-versions`. `java_sdkman_id` in `common.sh` still maps `temurin-21` \| `21` → `21.0.11-tem` for backward compat. |
| Per-manager files (`.node-version`, etc.) | **Not used.** Only `lang/.tool-versions` → stowed to `~/.tool-versions` (`link.sh` verifies). |
| `pyenv-virtualenv` is part of the workflow | **Installed via Brewfile only.** No init in `zsh/.zshrc`, no scripts reference it. Dead weight today. |
| `zsh/.zshenv` exists | **Does not exist.** Only `zsh/.zshrc` and `zsh/.zprofile`. |
| Doctor checks all pins in `.tool-versions` | Checks **node, ruby, python, java** only. **Rust** and **pnpm** pins are documentation / update-side effects, not doctor-checked. |
| Rust pin drives install/update | `install_rust` / `update_rust` call `rustup update stable` and ignore the `rust` line in `.tool-versions`. |
| pnpm is a mise-adjacent npm global | Correct: `lang/node-globals.sh` installs `pnpm@latest`; `update.sh` `record_pnpm_version` writes back to `.tool-versions`. |

---

## 2. What Changes vs What Stays

### Changes (by file)

| File | Change |
|---|---|
| `homebrew/Brewfile` | **Remove:** `fnm`, `pyenv`, `pyenv-virtualenv`, `rbenv`, `ruby-build`. **Add:** `mise`. **Keep:** `rustup`, everything else. |
| `lang/.tool-versions` | Update header comments; **java** pin → `temurin-21.0.11+10.0.LTS` (see §3.4); normalize `node` to no `v` prefix. **rust line commented out** (mise must not see it). `pnpm` line stays (rewritten by `record_pnpm_version`) and is disabled in mise. |
| `lang/.config/mise/config.toml` | **New** (stowed): mise settings only — `disable_tools = ["pnpm"]`. No `java.shorthand_vendor` (not a real setting; vendor is in the version string). Pins stay in `.tool-versions`. |
| `lang/.stow-local-ignore` | Allow stowing `.config/mise/config.toml`; keep ignoring `*-globals.sh`. |
| `zsh/.zshrc` | Replace fnm/pyenv/rbenv/SDKMAN blocks with `mise activate zsh`. Keep rustup PATH, install-tracking wrappers, oh-my-zsh. |
| `zsh/.zprofile` | Remove SDKMAN init; keep `brew shellenv` only. |
| `scripts/lib/common.sh` | Remove `java_sdkman_id`, `source_sdkman`. Add `source_mise` (eval `mise env` scoped to `$DOTFILES_DIR/lang`). Keep `tool_version`, `version_is_pinned`, `ensure_brew_path`. |
| `scripts/install.sh` | Replace per-manager install functions with one `(cd lang && mise install)` step (+ rustup/globals unchanged). Single runtime prompt. |
| `scripts/update.sh` | Replace fnm/rbenv/pyenv/SDKMAN sections with `mise install`. Keep `record_pnpm_version` (pnpm stays npm-global, §3.1). |
| `scripts/doctor.sh` | Check `mise` instead of fnm/rbenv/pyenv/SDKMAN; version checks via mise-active env (`mise current <tool>`). No new pnpm/rust checks. |
| `scripts/audit.sh` | npm-globals audit unchanged (globals scripts kept). Stale manager formulae handled by explicit uninstall in Phase 1, not audit logic. |
| `README.md`, `scripts/README.md` | Manager table, bootstrap notes, Java PATH story. |

### Unchanged

| Area | Files / behavior |
|---|---|
| Makefile command surface | All targets unchanged. |
| Stow topology | `zsh git ssh lang claude`; `make link` workflow. |
| `scripts/bootstrap.sh`, `link.sh`, `backup.sh`, `notify-audit.sh`, `vscode-setup.sh` | No structural changes (`link.sh` may note new stow path under `lang/.config/`). |
| `lang/*-globals.sh` | **Recommended:** keep through initial cutover (§3.3). |
| Rust | `rustup` in Brewfile; `lang/rust-globals.sh`; rustup PATH in `.zshrc`. |
| Status conventions | `DOCTOR_STATUS`, `AUDIT_STATUS`, `UPDATE_STATUS`, `INSTALL_STATUS`, `LINK_STATUS` + section/ok/fail/warn/run_step/print_summary helpers preserved. |
| Launchd weekly audit | `macos/Library/LaunchAgents/com.pespes.dotfiles-audit.plist` |
| git/, ssh/, claude/, editors/ | Untouched. |
| Install-tracking wrappers | `brew`/`npm`/`pip`/`gem`/`cargo` wrappers in `.zshrc` (§3.2). |

---

## 3. Decisions — Recommendations

### 3.1 Config format: keep `lang/.tool-versions` vs migrate to `mise.toml`

**Recommendation: Keep `lang/.tool-versions` as the pin file; add a small stowed `lang/.config/mise/config.toml` for settings only.**

| | `.tool-versions` (recommended) | Full `mise.toml` migration |
|---|---|---|
| Stow story | Already symlinked to `~/.tool-versions`; zero new top-level dotfiles | Would stow `~/.config/mise/config.toml` or project `mise.toml`; either splits pins from today's single file or duplicates |
| mise compatibility | Native asdf format; `mise install` reads `~/.tool-versions` | Richer (tool options, backends) but unnecessary for pins-only |
| pnpm “latest + record-back” | **LOCKED: keep `pnpm` line + `record_pnpm_version` in `update.sh`** — same git-diff workflow; pnpm stays an npm global on mise's node. mise ignores it via `disable_tools = ["pnpm"]`. (See pnpm rationale below.) | Same, but `[tools] pnpm = "latest"` in one file |
| rust line | mise **will** try to manage `rust` if present → `disable_tools` required | Same, or omit rust from `[tools]` and document in README only |

**Why handle rust and pnpm at all:** mise's registry has shorthands for **both** (`rust → core:rust …`, `pnpm → aqua:pnpm/pnpm npm:pnpm` — both verified against `mise registry`). Because `lang/.tool-versions` is stowed to `~/.tool-versions` (mise's **global** config), any unmanaged-but-listed tool makes mise try to install it. **But the two are not symmetric:**

- **rust** — its line is static, so simply **comment it out** (`# rust …`). asdf `.tool-versions` honors `#` comments, so mise never sees it. No `disable_tools` entry needed, and — importantly — this removes a fresh-install ordering hazard (the `disable_tools` config isn't linked yet when `install.sh` first runs `mise install`; a commented line needs no config to be ignored).
- **pnpm** — `record_pnpm_version` in `update.sh` rewrites an uncommented `pnpm` line on every update, so it can't be commented. Keep it live and set `disable_tools = ["pnpm"]`. Alternatively, move the pnpm version bookkeeping out of `.tool-versions` (it exists only for git visibility) and comment it too — a cleaner end state, but a larger change; deferred.

So the verified-correct setting is **`disable_tools = ["pnpm"]`**, not `["rust", "pnpm"]`. Omitting pnpm handling *would* fork the pnpm workflow (mise's aqua pnpm vs the npm-global pnpm) — that part of the original rationale is correct.

**Tradeoff:** `.tool-versions` cannot express tool options (e.g. Java vendor) — those belong in `config.toml`. Two files instead of one, but the split matches mise's own model (pins vs settings).

**Proposed pin file after migration:**

```text
node    24.14.0                # was v24.14.0 — normalized (mise reads asdf format)
ruby    3.3.10
python  3.13.12
java    temurin-21.0.11+10.0.LTS  # exact mise id (was 21.0.11-tem SDKMAN id); see §3.4
pnpm    11.5.0                 # tracked-latest npm global; auto-recorded by make update; disable_tools=["pnpm"]
# rust  stable-aarch64-apple-darwin  # rustup-managed — COMMENTED so mise never sees it
```

---

### 3.2 Shell integration: `mise activate zsh` vs shims

**Recommendation: `eval "$(mise activate zsh)"` in `zsh/.zshrc` (interactive). Scripts use `eval "$(cd "$DOTFILES_DIR/lang" && mise env -s bash)"` — not shims.**

| Mode | Pros | Cons |
|---|---|---|
| **activate (recommended)** | Official default; PATH points at real binaries; works with existing `npm`/`pip`/`gem` wrappers; directory-aware like fnm `--use-on-cd` | Small per-prompt cost (~few–80 ms depending on machine/plugins); stacks with oh-my-zsh |
| **shims** | Better for non-interactive/IDE-only setups; lower first-prompt lag in some benchmarks | Shim indirection; wrappers call `command npm` which still works but PATH semantics differ; not needed here |

**Impact on install-tracking wrappers:** Wrappers call `command npm` / `command pip` etc. after mise sets PATH — **no change required** if activate mode is used. Wrappers append to `lang/*-globals.sh`, not to mise config; they remain valid.

**Placement in `.zshrc`:** Replace the “Language Manager Initialization” block (fnm, pyenv, rbenv). Keep rustup PATH **before** mise activate. Put mise activate **after** oh-my-zsh (same region as today). Remove SDKMAN block at file end — mise sets `JAVA_HOME` for Java.

**`.zprofile`:** Remove SDKMAN; login shells get Java from interactive `.zshrc` on typical Terminal/iTerm sessions. If a login-only non-interactive job needs Java, document `mise env -s bash` in that job — same class of edge case as today with SDKMAN.

---

### 3.3 Global packages: mise backends vs `*-globals.sh`

**Recommendation: Keep `lang/*-globals.sh` for the initial migration (Phases 0–3). Defer mise backend migration to an optional Phase 4 or skip entirely.**

| | Keep `*-globals.sh` (recommended) | Move to mise `[tools]` backends |
|---|---|---|
| Scope | `install.sh` / `update.sh` already invoke scripts; `audit.sh` npm section unchanged | Rewrite install/update/audit; new source of truth (`npm:pkg`, `pipx:pkg`, `gem:`, `cargo:`) |
| npm wrapper | Continues appending to `node-globals.sh` | Would need wrapper → `mise.toml` / config.toml append, or drop wrapper |
| audit.sh | `audit_npm_globals` parses `node-globals.sh` — no change | Must parse mise config or `mise ls` output |
| Payoff | Zero drift in audit/wrapper behavior | Single config file; `mise install` installs globals with runtimes |

**Tradeoff:** Keeping globals scripts leaves two provisioning paths (`mise install` for runtimes, shell scripts for globals). That is the same shape as today and is **honestly sufficient** for a single-user dotfiles repo. Moving globals to mise is a second migration with real audit/wrapper rework — poor ROI unless the maintainer wants to delete the shell scripts outright.

**If Phase 4 is ever done:** map `node-globals.sh` → `"npm:pnpm" = "latest"`, `"npm:@anthropic-ai/claude-code" = "…"`; retire npm wrapper or retarget it; replace `audit_npm_globals` with mise-tool listing comparison.

---

### 3.4 Java: Temurin selection without SDKMAN

**LOCKED: mise core Java backend; pin `temurin-21.0.11+10.0.LTS` (exact id from `mise ls-remote java`, stay on 21 LTS); keep Java out of Brewfile.** (No `java.shorthand_vendor` setting — it does not exist in mise; the vendor is carried in the version string.)

> **Verified 2026-06-01:** `mise ls-remote java | grep temurin-21.0.11` → `temurin-21.0.11+10.0.LTS`. The bare `temurin-21.0.11` is not a valid version. There is **no clean map** from the SDKMAN id `21.0.11-tem` to the mise id — always copy the exact string from `ls-remote`.

**Why exact patch + stay on 21:** the repo's core principle is reproducible, git-visible, explicit runtime bumps (`update.sh` never auto-bumps runtimes). A major alias (`temurin-21`) would resolve a different patch on a future fresh Mac than what's committed — breaking "the repo is the system." Keeping the migration **behavior-preserving** (21 LTS, same patch) also means a JVM build failure can't be ambiguously blamed on either mise *or* a Java upgrade. **21→25 is a deliberate one-line follow-up commit after the migration is stable, not part of it** (machine already has a stray `25.0.3-tem`; it gets cleaned up in Phase 3b).

| Topic | Detail |
|---|---|
| Replace `java_sdkman_id` | Delete the mapping helper. Pin vendor explicitly: `java temurin-21.0.11+10.0.LTS` in `.tool-versions` (mise id from `ls-remote`). |
| Bump workflow | Edit `.tool-versions` → `make update` runs `mise install` → commit. Same mental model as today; no `sdk upgrade` non-TTY trap. |
| `JAVA_HOME` | mise activate sets it. Remove SDKMAN fallback block from `.zshrc`. Document that `/usr/libexec/java_home` may be empty — unchanged from README today. |
| Brewfile | **Do not** add `openjdk` cask/formula; avoids fighting mise PATH. |
| `java-globals.sh` | Still empty of active `sdk install` lines — no change. |

**Verification after cutover:** `java -version`, `echo $JAVA_HOME`, and `make doctor` Java check compares `mise current java` against the pin (not by parsing `java -version` stderr).

---

### 3.5 pyenv-virtualenv

**LOCKED: Remove `pyenv-virtualenv` from Brewfile; no mise equivalent.**

**Finding (confirmed on machine 2026-06-01):** Zero usage in repo (no `pyenv virtualenv-init`, no `.python-version`) **and** zero named virtualenvs on disk (`~/.pyenv/versions/*/envs` empty). Safe to remove with no workflow impact.

**mise coverage:** mise does not replicate pyenv-virtualenv's named, auto-activated virtualenvs. Standard library `python -m venv` / `uv venv` / project `direnv` covers the same need if ever required.

---

### 3.6 Script rewrites (install / update / doctor / audit)

**Recommendation: Centralize runtime provisioning on `mise install`; keep rust + globals as separate steps; preserve all status helpers.**

**Install ordering — resolved (not an open question):** `mise install` with no args discovers config from **cwd upward + global `~/.config`**. It will *not* pick up `lang/.tool-versions` from the repo root, and during fresh install the `~/.tool-versions` symlink does not exist yet (link runs after install). Therefore **all scripts operate against the repo pin file via a subshell `cd`**, never the `~` symlink:

```bash
( cd "$DOTFILES_DIR/lang" && mise install )
eval "$( cd "$DOTFILES_DIR/lang" && mise env -s bash )"
```

#### `common.sh`

- Add `source_mise()`: if `command -v mise`, `eval "$(cd "$DOTFILES_DIR/lang" && mise env -s bash)"`.
- Remove `java_sdkman_id`, `source_sdkman`.

#### `install.sh`

Replace `install_node`, `install_ruby`, `install_python`, `install_java` with one optional section:

```text
--- Languages (optional) ---
--> mise runtimes
    ( cd "$DOTFILES_DIR/lang" && mise install )   # reads lang/.tool-versions, NOT the ~ symlink
    run_globals for node/python/ruby/java as today
--- Rust (optional) ---   # unchanged
```

Prompts: collapse to a **single** "Set up mise runtimes (node/ruby/python/java)?" prompt plus existing Rust and oh-my-zsh prompts. `DOTFILES_ASSUME_YES=1` unchanged.

Remove the SDKMAN `curl … | bash` install block entirely (also removes a remote-bootstrap from the fresh-Mac path).

#### `update.sh`

Replace `update_node`, `update_ruby`, `update_python`, `update_sdkman` with:

```text
update_mise() {
  ( cd "$DOTFILES_DIR/lang" && mise install )    # idempotent sync to pins
  run_globals for node/python/ruby/java          # node-globals.sh installs pnpm@latest
  record_pnpm_version                            # unchanged — pnpm stays an npm global
}
```

Keep Homebrew, rustup, editor extension sections. Summary text: drop SDKMAN/`exec zsh` Java note.

#### `doctor.sh`

- **Language managers:** `mise` required; `rustup` required; remove fnm/rbenv/pyenv required checks; warn if a legacy `~/.sdkman` dir is still present (cleanup reminder during the bake-in window).
- **Version pins:** `source_mise`, then compare `mise current node|ruby|python|java` against pins via `pin_matches`. **No new pnpm/rust checks** — preserve current parity.

#### `audit.sh`

- **No change required** — globals scripts kept, so `audit_npm_globals` is unchanged.
- Stale manager formulae are handled by the **explicit `brew uninstall` in Phase 1** (below), so audit stays clean rather than needing new logic.

All scripts keep existing `section` / `ok` / `fail` / `warn` / `run_step` / `print_summary` and final `*_STATUS:` lines.

---

## 4. Phased Rollout

Each phase is one commit (or logical PR), independently verifiable, with explicit rollback.

### Phase 0 — Parallel install (mise present, old managers authoritative)

**Goal:** mise installed and pins/settings committed; shell and scripts still use fnm/pyenv/rbenv/SDKMAN.

**Edits:**

- `homebrew/Brewfile`: add `brew "mise"` (keep old managers).
- `lang/.config/mise/config.toml`: `[settings] disable_tools = ["pnpm"]`. (No `java.shorthand_vendor` — not a real setting.)
- `lang/.stow-local-ignore`: ensure `.config/mise/config.toml` is stowed (not matched by the existing `*-globals.sh` ignore rules; verify).
- `lang/.tool-versions`: **leave as-is in Phase 0.** It is still in old-manager formats (`java 21.0.11-tem`, `rust stable-aarch64-apple-darwin`). mise doesn't reject these — it reads them as literal versions, **warns on every shell** that they're "not installed," and would **fail at install time** (verified: `mise ls-remote rust` has no `stable-aarch64-apple-darwin` — only `stable`/`beta`/semver; `21.0.11-tem` is a SDKMAN id, not a mise id). So Phase 0 must NOT `mise install` against this file, and don't add `mise activate` to the shell yet (the warnings would spam). Format conversion (java id, comment rust, drop node `v`) happens in the Phase 1 cutover.
- `README.md`: short "mise migration in progress" note (optional).

**Verification:**

```bash
make link
brew bundle install --file=homebrew/Brewfile
# Trust gate: confirm the repo config does NOT trigger an interactive trust prompt
# (a prompt in a non-interactive make install would hang — same class as the old sdk upgrade trap).
( cd "$DOTFILES_DIR/lang" && mise trust )
# Do NOT `mise install` against lang/.tool-versions yet — it's still SDKMAN/rustup format.
# Instead confirm the TARGET identifiers resolve, using explicit versions:
mise ls-remote java | grep -F 'temurin-21.0.11+10.0.LTS'   # the pin exists
mise install node@24.14.0 && mise exec node@24.14.0 -- node -v
mise install java@temurin-21.0.11+10.0.LTS && mise exec java@temurin-21.0.11+10.0.LTS -- java -version
make doctor                     # still green on old managers
make lint
```

**Rollback:** `git revert` Phase 0 commit; `brew uninstall mise`; `make link`.

**Trust note:** `.tool-versions` (versions-only) is expected to be auto-trusted, and the home/global `config.toml` is trusted by default. If the repo-local `lang/` config ever prompts, add `mise trust "$DOTFILES_DIR/lang"` to `install.sh`/`link.sh`. **Confirm this during Phase 0 before relying on non-interactive `make install`.**

**Commit message:** `lang: add mise alongside existing managers (phase 0)`

---

### Phase 1 — Atomic cutover: shell + Brewfile + scripts (mise authoritative)

**Goal:** One commit that flips everything to mise and lands `make doctor` green. (Originally split into "shell/Brewfile" + "scripts"; that split left a knowingly-red `make doctor` between two commits — not an independently-verifiable state — so they are merged.)

**Edits:**

- `homebrew/Brewfile`: remove fnm, pyenv, pyenv-virtualenv, rbenv, ruby-build; keep mise + rustup.
- `lang/.tool-versions`: `java temurin-21.0.11+10.0.LTS`; drop `v` from node; **comment out the rust line**.
- `zsh/.zshrc`: remove fnm/pyenv/rbenv/SDKMAN blocks; add `eval "$(mise activate zsh)"` (after oh-my-zsh, keep rustup PATH before it).
- `zsh/.zprofile`: remove SDKMAN block.
- `scripts/install.sh`, `scripts/update.sh`, `scripts/doctor.sh`, `scripts/lib/common.sh` per §3.6 (mise-aware; status helpers preserved).

**Critical sequencing — uninstall the old formulae in this phase.** `brew bundle install` does **not** uninstall formulae removed from the Brewfile, so the old managers would linger as `brew leaves` entries not in the Brewfile → `make audit` exits `AUDIT_STATUS: drift`. Uninstall explicitly — **dependents first**, since `pyenv`/`ruby-build` are pulled in as dependencies (not `brew leaves`) and `brew uninstall` refuses to remove a formula another installed formula still needs:

```bash
brew uninstall pyenv-virtualenv   # depends on pyenv — remove first
brew uninstall fnm pyenv rbenv ruby-build
# (or, if order still complains: brew uninstall --ignore-dependencies <formulae>)
```

(Removes **formulae/binaries** only. Data dirs `~/.fnm`, `~/.pyenv`, `~/.rbenv`, `~/.sdkman` are kept for the bake-in rollback window — removed in Phase 3b.)

**Verification (all green in one commit):**

```bash
make link
brew bundle install --file=homebrew/Brewfile
brew uninstall pyenv-virtualenv && brew uninstall fnm pyenv rbenv ruby-build
exec zsh
node -v && ruby -v && python --version && java -version
which node    # under ~/.local/share/mise/..., not fnm
make lint
make doctor   # DOCTOR_STATUS: ok (or ok_with_warnings) — scripts are mise-aware in this same commit
make audit    # AUDIT_STATUS: clean (no stale untracked formulae)
make update   # UPDATE_STATUS: ok
DOTFILES_ASSUME_YES=1 bash scripts/install.sh   # idempotent on existing machine
```

**Rollback:** `git revert` the commit; `brew bundle install` reinstalls the old formulae; data dirs (`~/.fnm`, `~/.pyenv`, `~/.rbenv`, `~/.sdkman`) are still on disk so global versions/JDKs return immediately; `exec zsh`.

**Commit message:** `lang: cut runtime management over from fnm/pyenv/rbenv/SDKMAN to mise`

---

### Phase 2 — *(merged into Phase 1)*

Folded into the atomic cutover above. Keeping the scripts in a separate commit would have shipped a deliberately-red `make doctor`; the script edits (`install.sh`, `update.sh`, `doctor.sh`, `common.sh`) now land together with the shell/Brewfile change so no committed state is broken.

---

### Phase 3 — Docs + audit polish + README bootstrap story

**Goal:** Documentation matches reality; optional audit stale-manager check; remove migration WIP notes.

**Edits:** `README.md`, `scripts/README.md`, optional `audit.sh` stale-formula hint, trim SDKMAN references in design-adjacent docs if desired.

**Verification:**

```bash
make doctor && make audit && make lint
# Fresh-Mac dry run (VM or second user): clone → make install with DOTFILES_ASSUME_YES=1
```

**Rollback:** `git revert` docs-only commit.

**Commit message:** `docs: document mise-based language runtime setup`

---

### Phase 3b — Old-manager data-dir cleanup (deferred ~2 weeks after Phase 1)

**Goal:** After the bake-in window confirms the migration is stable, reclaim disk and remove the rollback safety net. **This is a manual/maintenance step, not a code change** — it does not alter the repo.

**Actions:**

```bash
rm -rf ~/.fnm ~/.pyenv ~/.rbenv ~/.sdkman   # incl. the stray temurin-25.0.3-tem
# Optional: also remove the doctor "legacy ~/.sdkman present" warning once gone
```

**Pre-cleanup gate:** `make doctor` green, `make audit` clean, runtimes resolving via mise for ≥2 weeks.

**Note:** removing `~/.sdkman` is safe — confirmed Java-only on this machine. After this, the `doctor.sh` legacy-SDKMAN warning (added in Phase 2) can be dropped in a follow-up.

**Rollback:** none needed (mise is authoritative); to truly revert the whole migration, follow Phase 1/2 reverts and reinstall managers.

---

### Phase 4 — Optional: globals → mise backends — **SKIPPED (per decision)**

**Goal:** Delete `*-globals.sh` provisioning in favor of mise `[tools]` entries.

**Decision: skip.** Keeping `*-globals.sh` preserves the npm-globals audit and the install-tracking wrappers with zero rework. Documented here only as a future option.

**Verification:** `make update`, `make audit` (rewritten npm audit), manual `npm install -g` wrapper behavior decision.

**Rollback:** revert commit; restore globals scripts.

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **mise auto-manages `pnpm`/`rust`** from `~/.tool-versions` | High if unmitigated | Forks pnpm workflow; rustup conflict; per-prompt nags | **rust line commented out** (mise never sees it); `disable_tools = ["pnpm"]` for pnpm. Note: `disable_tools` config isn't linked until `make link`, but `install.sh` runs `mise install` first — confirm the setting is in effect at install time (Phase 0 trust/`mise install` gate), else pnpm hits the same comment-out treatment |
| **`make audit` red after Brewfile edit** (brew doesn't auto-uninstall) | Certain if skipped | Audit/launchd job fails | Explicit `brew uninstall fnm pyenv pyenv-virtualenv rbenv ruby-build` in Phase 1; `make audit` clean is the phase exit gate |
| **mise trust prompt hangs non-interactive `make install`** | Low | Install hang | Phase 0 trust gate; `mise trust "$DOTFILES_DIR/lang"` in install/link if prompted |
| Shell startup regression (oh-my-zsh + mise) | Medium | Annoyance | Measure with `MISE_TIMINGS=1`; if bad, try `mise activate zsh --quiet`; shims as last resort for interactive |
| `make doctor` red between cutover commits | Resolved | n/a | Phases 1 & 2 merged into one atomic commit — no committed state has a red doctor |
| Java pin mismatch after format change | Medium | Broken builds | Phase 0 `mise install java@temurin-21.0.11+10.0.LTS` + `java -version` before cutover; pin the exact `ls-remote` id |
| Stale PATH from old managers in same session | Medium | Wrong `node` version | `exec zsh` after cutover; old brew formulae uninstalled in Phase 1 so they don't return |
| SDKMAN/Java IDE integrations pointing at old JDK | Low | IDE wrong JDK | Re-point IDE to mise `$JAVA_HOME`; restart IDE |
| `brew uninstall rbenv` while project dirs have `.ruby-version` | Low | Projects still work via mise if version installed | `mise install` covers global pin; per-project `.ruby-version`/`.python-version` are mise-compatible |
| pnpm record-back mutates `.tool-versions` on update | Unchanged | Uncommitted git diff | Same as today — document in update summary |
| Install ordering depends on `~/.tool-versions` symlink (pre-link) | Resolved | n/a | Scripts use `(cd lang && mise install)`; never the symlink (§3.6) |

---

## 6. New-Mac Bootstrap Story (post-migration)

```text
git clone git@github.com:pespes/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
# or stepwise: make bootstrap → make install-tools → make link → make editors
```

**`make bootstrap`** — unchanged: Xcode CLT, Homebrew, stow.

**`make install-tools` (`install.sh`)** — becomes:

1. `brew bundle install --file=homebrew/Brewfile` → installs **mise**, **rustup**, stow, gh, …
2. Optional oh-my-zsh (unchanged).
3. Optional **mise runtimes:** `( cd "$DOTFILES_DIR/lang" && mise install )` — reads the **repo** pin file directly, so it works even though `~/.tool-versions` isn't symlinked until `link.sh` runs later. No dependency on install/link ordering.
4. Optional **Rust:** rustup init + `rust-globals.sh`.
5. Globals scripts for node/python/ruby/java.

**`make link`** — stows `~/.tool-versions`, `~/.config/mise/config.toml`, zsh, git, ssh, claude; launchd audit job.

**`exec zsh`** → `mise activate` loads node/ruby/python/java/pnpm.

**Ongoing:**

```bash
make update    # brew bundle + mise install + globals + rustup + extensions
make doctor    # mise + pins + symlinks
make audit     # brew/npm drift
```

**Single command provisioning (developer ergonomics):** after link, `mise install` installs all pinned runtimes — the main bootstrap win.

---

## 7. Resolved Decision Log

All prior open questions are now answered (see §0 for the locked summary):

1. **Fresh install ordering** — Resolved: scripts use `(cd "$DOTFILES_DIR/lang" && mise install)`; never depend on the `~/.tool-versions` symlink (§3.6, §6).
2. **Local pyenv virtualenvs** — Confirmed none on disk; safe to remove pyenv-virtualenv (§3.5).
3. **Java bump policy** — `temurin-21.0.11+10.0.LTS` (exact `ls-remote` id), stay 21 LTS; 21→25 is a separate later commit (§3.4).
4. **pnpm strategy** — Stays npm global + `record_pnpm_version`; mise-disabled (§3.1).
5. **Phase 4 (globals → mise backends)** — Skipped; keep `*-globals.sh`.
6. **Old-manager data cleanup** — Bake-in: formulae uninstalled in Phase 1, data dirs removed in Phase 3b. SDKMAN confirmed Java-only.
7. **CI / automation** — Confirmed: no crontab, no LaunchAgent references managers by name. Nothing off-stage breaks.
8. **Install prompts** — Single "mise runtimes" prompt.

**Remaining verification gate (not a decision):** confirm during Phase 0 that the repo-local `lang/` config does not trigger an interactive `mise trust` prompt that would hang a non-interactive `make install`.

---

## Appendix: Current vs Target Architecture

```text
CURRENT                          TARGET
───────                          ──────
Brewfile: fnm, pyenv,            Brewfile: mise, rustup
          pyenv-virtualenv,
          rbenv, ruby-build,
          rustup

~/.tool-versions (stowed)        ~/.tool-versions (stowed) + ~/.config/mise/config.toml (stowed)
  → fnm / rbenv / pyenv / SDKMAN   → mise install

~/.zshrc: 4 inits + SDKMAN       ~/.zshrc: mise activate + rustup PATH

install.sh: 4 runtime fns        install.sh: mise install + rust + globals

SDKMAN curl bootstrap            (removed)
```

---

**End of plan.** Implementation order: Phase 0 → 1 → 2 → 3, then Phase 3b after a ~2-week bake-in. Phase 4 is skipped.
