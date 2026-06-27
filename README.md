# dotfiles

Personal configuration for shell, editor, and tooling on macOS.

## Current Workflow

This repo uses `chezmoi` as the distribution mechanism. The source state is in `chezmoi/`.

## What is managed

- `~/.zshrc`
- `~/.gitconfig`
- `~/.markdownlint-cli2.jsonc`
- `~/.Brewfile.base`
- `~/.Brewfile.personal`
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

- runs `brew bundle --file ~/.Brewfile.base` when Homebrew is installed
- runs `brew bundle --file ~/.Brewfile.<profile>` where profile is from `data.profile`
- runs a Neovim headless smoke check (`nvim --headless '+qa'`) when Neovim is installed

## OpenCode mode switching

Use `opencode-mode` to switch which OpenCode config new shells use:

- `opencode-mode pro` uses `~/.config/opencode/opencode.pro.jsonc` (OpenAI-only, no `opencode/*` models)
- `opencode-mode fallback` uses `~/.config/opencode/opencode.jsonc` (current fallback profile)
- `opencode-mode status` shows the currently configured mode

The mode is stored in `~/.config/opencode/mode`. Open a new terminal after switching.
