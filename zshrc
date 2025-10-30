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

[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

source "${HOME}/dev/dotfiles/extra_shell_functions.sh"

if [[ -d ${HOME}/work ]]; then
  for script in $(/bin/ls -d ${HOME}/work/shell/*sh); do
    source ${script}
  done
fi

autoload -Uz compinit && compinit

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

eval "$(starship init zsh)"

alias kubectl=kubecolor
