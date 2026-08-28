# dotfiles

Personal configuration for shell, editor, and tooling on macOS.

## Current Workflow

This repo uses `chezmoi` as the distribution mechanism. The source state is in `chezmoi/`.

## What is managed

- `~/.zshrc`
- `~/.gitconfig`
- `~/.markdownlint-cli2.jsonc`
- `~/.Brewfile`
- `~/.config/ghostty/config`
- `~/.config/opencode/opencode.jsonc`
- `~/.config/opencode/opencode.pro.jsonc`
- `~/.local/bin/opencode-mode`
- `~/.config/zsh/functions/extra_shell_functions.zsh`
- `~/.config/zsh/git_identity.zsh` (generated from profile data)
- `~/.config/zsh/secrets.zsh` (generated from templates + local machine data)
- `~/.config/nvim/**` (native Neovim + mini.nvim config)

## Setup

1. Install `chezmoi` and `1password-cli`.
2. Initialize from this repo:

```sh
chezmoi init /path/to/dotfiles/chezmoi
```

3. Create local per-machine data at `~/.config/chezmoi/chezmoi.toml`.

You can start from `chezmoi.toml.example` (kept in the repo root as documentation, not managed by chezmoi):

```toml
sourceDir = "/path/to/dotfiles/chezmoi"

[data]
profile = "personal"

[data.gitIdentityByProfile.personal]
name = "Your Name"
email = "you@example.com"

[data.secretEnvByProfile.personal]
# EXAMPLE_TOKEN = "op://Private Vault/example item/credential"
```

4. Apply config:

```sh
eval "$(op signin --account my.1password.com)"
chezmoi apply
```

## Secrets and profiles

- `data.profile` controls which profile-specific values are rendered.
- Git identity exports are generated from `data.gitIdentityByProfile.<profile>`.
- Secrets are read at apply-time via `op read op://...` references.
- Each machine can point at different 1Password accounts/vaults/orgs by setting local data differently.
- If `chezmoi apply` renders templates that call `op read`, sign in to 1Password first (for example: `eval "$(op signin --account my.1password.com)"`).

## Bootstrap

On first apply, chezmoi runs `chezmoi/run_once_after_10_bootstrap.sh` which:

- runs `brew bundle --global` when Homebrew is installed
- installs the persisted Mason tool inventory with headless Neovim when Neovim is installed

## Mason maintenance

Mason tools are declared in `chezmoi/dot_config/nvim/init.lua`. Interactive Neovim starts check for
missing packages and updates at most once every 24 hours. Run `mise run mason:update` to install or
update the full inventory immediately.

## Brewfile maintenance

A single `chezmoi/dot_Brewfile` is shared by every machine and applied to `~/.Brewfile`, which is
Homebrew's global Brewfile location. Install everything with `brew bundle --global`.

Run `mise run brew:sync` to fold the packages installed on the current machine into that file. The
task unions rather than replaces, so syncing on one machine never drops packages that only another
machine has installed. Removing a package from the inventory is a manual edit.

## OpenCode mode switching

Use `opencode-mode` to switch which OpenCode config new shells use:

- `opencode-mode pro` uses `~/.config/opencode/opencode.pro.jsonc` (OpenAI-only, no `opencode/*` models)
- `opencode-mode fallback` uses `~/.config/opencode/opencode.jsonc` (current fallback profile)
- `opencode-mode status` shows the currently configured mode

The mode is stored in `~/.config/opencode/mode`. Open a new terminal after switching.
