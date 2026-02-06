# Neovim
alias vim="nvim -O"
alias vi=vim
export GIT_EDITOR="nvim"
export EDITOR="nvim"

# Listing
alias ls="eza"
alias l="ls -lh --group-directories-first"
alias ll="l -T -L2"

# Case insensitive ripgrepping
alias rg="rg -i"

# Make it so one can start a command with `#` and store it in history
setopt interactivecomments
zle_highlight+=(paste:none)

export PATH="${HOME}/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.krew/bin:${PATH}"

export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/local/sbin:${PATH}"
export PATH="${HOME}/.asdf/shims:${PATH}"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}"

# Skip Homebrew shellenv in Codex sandbox to avoid ps permission errors.
if [[ -z "${CODEX_SANDBOX}" ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
fi

source "${HOME}/.config/zsh/functions/extra_shell_functions.zsh"

if [[ -f "${HOME}/.config/zsh/git_identity.zsh" ]]; then
  source "${HOME}/.config/zsh/git_identity.zsh"
fi

if [[ -f "${HOME}/.config/zsh/secrets.zsh" ]]; then
  source "${HOME}/.config/zsh/secrets.zsh"
fi

for script in "${HOME}"/.config/zsh/secrets.d/*.zsh(N); do
  source "${script}"
done

autoload -Uz compinit && compinit

# Set up fzf key bindings and fuzzy completion if available
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

eval "$(starship init zsh)"

alias kubectl=kubecolor
