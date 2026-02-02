# dotfiles

Personal configuration for shell, editor, and tooling on macOS.

## Contents

- `zshrc` and `extra_shell_functions.sh`: shell setup and helper functions
- `gitconfig`: git defaults and aliases
- `ghostty_config`: Ghostty terminal configuration
- `astronvim/`: AstroNvim config (Neovim)
- `brew_packages`: list of Homebrew packages to install
- `markdownlint-cli2.jsonc`: markdown lint config
- `links`: lightweight notes for symlinks
- `opencode`: CLI configuration

## Usage

1. Review files and update machine-specific values as needed.
2. Symlink files into place (example):

```sh
ln -s /Users/tomgoren/dev/dotfiles/zshrc ~/.zshrc
```

3. Install Homebrew packages from `brew_packages` as needed.

## Notes

- This repo is intentionally minimal and tailored to one user.
- The AstroNvim config lives under `astronvim/`.
