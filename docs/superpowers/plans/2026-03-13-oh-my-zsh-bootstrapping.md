# oh-my-zsh Bootstrapping Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a prompted oh-my-zsh installation step (including zsh-autosuggestions and zsh-syntax-highlighting plugins) to `scripts/install.sh`.

**Architecture:** A single new `confirm`-gated section is inserted into `install.sh` before the language manager sections. Each step is idempotent — it checks for existence before acting. Existing section comment numbers are updated to stay sequential.

**Tech Stack:** Bash, GNU Stow, oh-my-zsh (curl installer), git clone

---

## Chunk 1: Add oh-my-zsh section to install.sh

**Files:**
- Modify: `scripts/install.sh`

### Task 1: Insert oh-my-zsh section

- [ ] **Step 1: Open `scripts/install.sh` and locate the existing section 2**

  Find the line `# 2. fnm (Node)`. The new oh-my-zsh section goes immediately before it, after the closing `fi` of section 1 (Homebrew packages).

- [ ] **Step 2: Insert the oh-my-zsh section**

  Add the following block immediately before `# 2. fnm (Node)`:

  ```bash
  # 2. oh-my-zsh + plugins
  if confirm "--> Set up oh-my-zsh?"; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
      echo "--> Installing oh-my-zsh..."
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
      echo "    oh-my-zsh already installed. Skipping."
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
      echo "    Installing zsh-autosuggestions..."
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
      echo "    zsh-autosuggestions already installed. Skipping."
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
      echo "    Installing zsh-syntax-highlighting..."
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
      echo "    zsh-syntax-highlighting already installed. Skipping."
    fi
  fi
  ```

- [ ] **Step 3: Update existing section comment numbers**

  Update the five existing section comments to shift up by one:

  | Find | Replace with |
  |------|-------------|
  | `# 2. fnm (Node)` | `# 3. fnm (Node)` |
  | `# 3. rbenv (Ruby)` | `# 4. rbenv (Ruby)` |
  | `# 4. pyenv (Python)` | `# 5. pyenv (Python)` |
  | `# 5. rustup (Rust)` | `# 6. rustup (Rust)` |
  | `# 6. SDKMAN (Java)` | `# 7. SDKMAN (Java)` |

- [ ] **Step 4: Verify the file looks correct**

  Read through `scripts/install.sh` and confirm:
  - New section 2 appears after the Homebrew packages block and before fnm
  - All section numbers are sequential (1 through 7)
  - The `confirm` call, directory checks, and `echo` messages match the pattern of other sections

- [ ] **Step 5: Verify idempotency manually**

  If oh-my-zsh is already installed at `~/.oh-my-zsh`, run the section in isolation and confirm it prints "oh-my-zsh already installed. Skipping." and proceeds to check plugins without error.

  To test without running the full install:
  ```bash
  # Temporarily source just the confirm helper and the new block
  bash -c '
    confirm() { read -r -p "$1 [y/N] " r; [[ "$r" =~ ^[Yy]$ ]]; }
    HOME="$HOME"
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
      echo "Would install oh-my-zsh"
    else
      echo "oh-my-zsh already installed. Skipping."
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
      echo "Would clone zsh-autosuggestions"
    else
      echo "zsh-autosuggestions already installed. Skipping."
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
      echo "Would clone zsh-syntax-highlighting"
    else
      echo "zsh-syntax-highlighting already installed. Skipping."
    fi
  '
  ```
  Expected output (if all three are already installed):
  ```
  oh-my-zsh already installed. Skipping.
  zsh-autosuggestions already installed. Skipping.
  zsh-syntax-highlighting already installed. Skipping.
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add scripts/install.sh
  git commit -m "feat: add prompted oh-my-zsh and plugin installation to install.sh"
  ```

---

> **Stow symlink note (for re-runs only):** If `make link` has already been run in this environment before running `install.sh`, the oh-my-zsh installer will replace the `~/.zshrc` Stow symlink with a generated file. Run `make link` afterward to restore it. This does not affect a fresh `make install` (bootstrap → install → link order is safe).
