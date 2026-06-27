# AGENTS Guide for `dotfiles`

This file is for coding agents working in this repository.
It captures practical commands and style conventions observed in the codebase.

## Repo Scope

- This is a personal dotfiles repo for macOS shell/editor/tooling setup.
- Main areas:
  - `chezmoi/dot_zshrc.tmpl`, `chezmoi/dot_config/zsh/functions/extra_shell_functions.zsh`
  - `chezmoi/dot_gitconfig.tmpl`
  - `chezmoi/dot_config/ghostty/config`
  - `chezmoi/dot_config/opencode/`
  - `chezmoi/dot_config/nvim/` (native Neovim + mini.nvim config)
- There is no app build pipeline in this repository.
- There is no formal automated test suite in this repository.

## Rule Files Check

- Checked for Cursor rules:
  - `.cursorrules` (not present)
  - `.cursor/rules/` (not present)
- Checked for Copilot rules:
  - `.github/copilot-instructions.md` (not present)
- Action: no extra agent rule files need to be merged beyond this document.

## Environment and Tooling

- Primary language in `chezmoi/dot_config/nvim/`: Lua.
- Shell files: POSIX shell + zsh usage.
- Formatting/lint config files: `.stylua.toml`, `chezmoi/dot_markdownlint-cli2.jsonc`.
- Neovim uses native `vim.pack`, mini.nvim modules, built-in LSP, and Mason-managed language servers.

## Setup / Bootstrap Commands

- Install Homebrew packages via split Brewfiles when using chezmoi:
  - `brew bundle --file ~/.Brewfile.base`
  - `brew bundle --file ~/.Brewfile.personal`
- Start Neovim once to bootstrap plugins: `nvim`.

### Chezmoi-based Setup

- Preferred distribution path uses `chezmoi` source state in `chezmoi/`.
- Initialize chezmoi with this source:
  - `chezmoi init /path/to/dotfiles/chezmoi`
- Apply managed config:
  - `eval "$(op signin --account my.1password.com)" && chezmoi apply` (required when templates resolve `op://` secrets)
- Bootstrap script run by chezmoi (once):
  - `chezmoi/run_once_after_10_bootstrap.sh.tmpl`
- Homebrew package sets are stored as:
  - `chezmoi/dot_Brewfile.base`, `chezmoi/dot_Brewfile.personal`

## Build / Lint / Test Commands

Because this is a dotfiles repo, prefer validation + lint over "build".

### Build-like / Validation Commands

- Validate Neovim config can start headless:
  - `nvim --headless '+qa'`

### Lint / Format Commands

- Lua formatting:
  - `stylua chezmoi/dot_config/nvim/init.lua`
- Shell lint:
  - `shellcheck chezmoi/run_once_after_10_bootstrap.sh.tmpl chezmoi/dot_zshrc.tmpl chezmoi/dot_config/zsh/functions/extra_shell_functions.zsh`
- Markdown lint:
  - `markdownlint-cli2 '**/*.md'`

### Single-file / Targeted Lint Commands

- Single Lua file format:
  - `stylua chezmoi/dot_config/nvim/init.lua`
- Single shell file lint:
  - `shellcheck chezmoi/dot_zshrc.tmpl`
- Single markdown file lint:
  - `markdownlint-cli2 README.md`

### Test Commands (Current State)

- There is no dedicated test runner (no `pytest`, `go test`, `cargo test`, etc.).
- "Run a single test" is currently not applicable.
- Closest equivalent for targeted verification is single-file lint/format commands above.
- For behavioral checks, use Neovim headless startup as smoke test (`nvim --headless '+qa'`).

## Code Style Guidelines

Follow existing local patterns first; these are repository conventions.

### Global Principles

- Keep changes minimal and specific to requested behavior.
- Preserve existing file structure and plugin organization.
- Prefer readability and explicit intent over clever abstractions.
- Do not introduce new frameworks or tooling without strong reason.

### Lua Style (Neovim)

- Use 2-space indentation.
- Keep line length around 120 columns.
- Use Unix line endings.
- Follow the existing direct `init.lua` style unless the config grows enough to justify splitting files.

### Imports / Module Loading (Lua)

- Prefer `local x = require('module')` when reused multiple times.
- Inline `require("module").fn()` is acceptable for one-off calls.
- Do not reorder imports/spec entries unless behavior depends on it.

### Naming Conventions

- File names: lowercase and descriptive if the Neovim config is split later.
- Locals: short but meaningful (`lint`, `md`, `cfg`, `opts`).
- Keymaps: include clear `desc` values.
- Keep naming consistent with upstream Neovim and plugin APIs.

### Error Handling

- For startup-critical operations, show explicit errors instead of swallowing failures silently.
- Prefer defensive checks before mutating optional plugin config fields.
- Avoid swallowing failures silently.

### Configuration Patterns

- Respect disabled template guards:
  - `if true then return {} end`
  - `if true then return end`
- If enabling a template file, remove guard and prune unused examples.
- Extend defaults instead of replacing when possible (e.g., deep-extend/list-insert patterns).

### Shell Style (`chezmoi/dot_zshrc.tmpl`, `extra_shell_functions.zsh`)

- Use `[[ ... ]]` for shell conditionals.
- Quote variable expansions and command substitutions unless intentional globbing is required.
- Keep helper functions small and task-focused.
- Preserve safe-guard behavior on risky git flows (e.g., branch checks before push).

### Markdown Style

- Repository markdown lint config disables only `MD013` (line length).
- Keep headings and bullets simple and readable.
- Prefer fenced code blocks with language tags where useful.

## Agent Workflow Recommendations

- Before edits, read nearby files for local conventions.
- After edits, run targeted lint for touched files first.
- For Neovim changes, run headless Neovim smoke check.
- Avoid touching unrelated dotfiles in the same change.
- If adding new tools/commands, document them in this file.
