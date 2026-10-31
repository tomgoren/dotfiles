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

   Start from `chezmoi.toml.example` in the repo root:

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

## Global agent workflow

The workflow instructions require task worktrees for repository edits and the `no-slop` skill for prose.
Both profiles default to disabled. To enable them, add these values to the existing `[data]` section in your local chezmoi config:

```toml
agentWorkflowNorms = true
developmentWorkdir = "~/dev"
```

Set `developmentWorkdir` to the checkout root for that machine, such as `~/work`.
When omitted, it defaults to `~/dev`.
Canonical checkouts use `<workdir>/<repo>` and worktrees use `<workdir>/<repo>-<branch>`, with branch-name slashes replaced by hyphens.
Agents use `gco` to enter or create task worktrees and `gupdate` to fast-forward the default branch without cleanup.
For requested cleanup, `gfresh` also runs `gprune`.
Pruning preserves dirty worktrees and branches with commits outside the default branch, including many squash-merged branches.

Chezmoi renders one template, `chezmoi/.chezmoitemplates/agent-workflow.md`, into:

- `~/.config/opencode/AGENTS.md` for OpenCode.
- `~/.claude/rules/workflow.md` for Claude Code.
- `~/.codex/AGENTS.md` for Codex.
- `~/.agents/AGENTS.md` for other agents to load through their global instruction settings.

Other agents need their own configuration to load that shared file. It is not a universal discovery path.

Enabling the workflow also installs the complete `no-slop` skill at `~/.agents/skills/no-slop`.
OpenCode and Codex discover that directory. Claude Code uses a managed symlink at `~/.claude/skills/no-slop`.
Chezmoi downloads the skill from `saschb2b/skills`, pinned by commit and archive checksum in `chezmoi/.chezmoiexternal.toml.tmpl`.

Update that pin after reviewing an upstream version. Use chezmoi to update this skill rather than the Skills CLI.
The bundled linter requires Node.js, which the Brewfile includes.

Work-profile opt-in deploys these instructions while keeping personal OpenCode settings excluded.

Apply just the workflow files and skill:

```sh
mkdir -p ~/.agents/skills ~/.config/opencode ~/.claude/rules ~/.claude/skills ~/.codex
chezmoi apply ~/.agents/AGENTS.md ~/.config/opencode/AGENTS.md \
  ~/.claude/rules/workflow.md ~/.codex/AGENTS.md \
  ~/.agents/skills/no-slop ~/.claude/skills/no-slop
```

Check the installed skill against the pinned source:

```sh
chezmoi verify ~/.agents/skills/no-slop ~/.claude/skills/no-slop
test -f ~/.agents/skills/no-slop/SKILL.md
test -f ~/.agents/skills/no-slop/slop-lint.mjs
```

Setting `agentWorkflowNorms = false` stops managing these files but does not delete previously deployed copies.
To disable active instructions, remove those four files after changing the flag.
The skill and Claude symlink also remain installed until removed.

## Bootstrap

On first apply, chezmoi runs `chezmoi/run_once_after_10_bootstrap.sh` which:

- runs `brew bundle --global` when Homebrew is installed
- installs the persisted Mason tool inventory with headless Neovim when Neovim is installed

## Mason maintenance

Mason tools are declared in `chezmoi/private_dot_config/private_nvim/init.lua`. Interactive Neovim starts check for
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

- `opencode-mode pro` uses `~/.config/opencode/opencode.pro.jsonc` (OpenAI-only)
- `opencode-mode fallback` uses `~/.config/opencode/opencode.jsonc` (uses the OpenCode catalog by default)
- `opencode-mode status` shows the currently configured mode

The mode is stored in `~/.config/opencode/mode`. Open a new terminal after switching.

Both profiles use GPT-6 Astra for coding, GPT-6.1 Sol for planning and review, and GPT-6 Luna for exploration and session maintenance.
Pro uses GPT-6.1 Terra for general tasks and drafts, with medium and low reasoning effort respectively.
Fallback uses Sol for general tasks and Luna for drafts. OpenCode's catalog does not yet list Terra (checked October 28, 2026).

Model choices follow the [available catalog](https://opencode.ai/v2/docs/models) and [Terra release guidance](https://openai.com/index/introducing-gpt-6-1-terra).
Existing sessions retain their selected model. Use `/models` to change it.
