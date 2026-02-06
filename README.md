# dotfiles

Personal configuration for shell, editor, and tooling on macOS.

## Current workflow

This repo now uses `chezmoi` as the distribution mechanism instead of manual symlinks.

The chezmoi source state is in `chezmoi/`.

## What is managed

- `~/.zshrc`
- `~/.gitconfig`
- `~/.markdownlint-cli2.jsonc`
- `~/.Brewfile.base`
- `~/.Brewfile.personal`
- `~/.Brewfile.work`
- `~/.config/ghostty/config`
- `~/.config/opencode/opencode.jsonc`
- `~/.config/zsh/functions/extra_shell_functions.zsh`
- `~/.config/zsh/git_identity.zsh` (generated from profile data)
- `~/.config/zsh/secrets.zsh` (generated from templates + local machine data)
- `~/.config/nvim/**` (AstroNvim config)

## Setup

1. Install `chezmoi` and `1password-cli`.
2. Initialize from this repo:

```sh
chezmoi init /Users/tomgoren/dev/dotfiles/chezmoi
```

3. Create local per-machine data at `~/.config/chezmoi/chezmoi.toml`.

You can start from `chezmoi/chezmoi.toml.example`:

```toml
sourceDir = "/Users/your-user/dev/dotfiles/chezmoi"

[data]
profile = "personal"

[data.linearMcpPathByProfile]
personal = "/Users/your-user/dev/linear-mcp/build/index.js"
work = "/Users/your-user/work/linear-mcp/build/index.js"

[data.gitIdentityByProfile.personal]
name = "Your Name"
email = "you@example.com"

[data.gitIdentityByProfile.work]
name = "Your Name"
email = "you@work.example.com"

[data.secretEnvByProfile.personal]
# EXAMPLE_TOKEN = "op://Personal Engineering/shell EXAMPLE_TOKEN/credential"

[data.secretEnvByProfile.work]
# EXAMPLE_TOKEN = "op://Work Engineering/shell EXAMPLE_TOKEN/credential"
```

4. Apply config:

```sh
chezmoi apply
```

## Secrets and profiles

- `data.profile` controls which profile-specific values are rendered.
- Git identity exports are generated from `data.gitIdentityByProfile.<profile>`.
- Secrets are read at apply-time via `op read op://...` references.
- Each machine can point at different 1Password accounts/vaults/orgs by setting local data differently.

## Bootstrap

On first apply, chezmoi runs `chezmoi/run_once_after_10_bootstrap.sh` which:

- runs `brew bundle --file ~/.Brewfile.base` when Homebrew is installed
- runs `brew bundle --file ~/.Brewfile.<profile>` where profile is from `data.profile`
- runs a Neovim headless smoke check (`nvim --headless '+qa'`) when Neovim is installed
