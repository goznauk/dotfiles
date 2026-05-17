# Keep prompt setup near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="powerlevel10k/powerlevel10k"

HISTSIZE=100000
SAVEHIST=100000
HIST_STAMPS="yyyy-mm-dd"
setopt hist_ignore_dups
setopt share_history

plugins=(git common-aliases ssh-agent docker docker-compose dotenv)
plugins+=(zsh-syntax-highlighting zsh-autosuggestions zsh-completions)

fpath=("${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/zsh-completions/src" $fpath)

path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/bin"
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $path
)
typeset -U path

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=vim
export VISUAL=vim
export GPG_TTY="$(tty)"

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
[[ -n "${terminfo[kcuu1]:-}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n "${terminfo[kcud1]:-}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# Destructive commands stay unaliased for scripts and automation.
alias rmi='rm -i'
alias rmri='rm -ri'
alias cpi='cp -i'
alias mvi='mv -i'
alias cpr='rsync -ah --info=progress2'

alias cd..='cd ..'

alias l='ls -F'
alias la='ls -AF'
alias ll='ls -alF'
alias lal='ls -alF'

alias ta='tmux attach -t'
alias ta0='tmux attach -t 0'
alias tls='tmux list-sessions'
alias tn='tmux new -s'

alias dc='docker compose'
alias dcrs='docker compose down && docker compose build && docker compose up'

alias zshrc='vim ~/.zshrc'
alias zshrc_apply='source ~/.zshrc'

ports() {
  lsof -iTCP -sTCP:LISTEN -n -P "$@"
}

ipb() {
  ip -brief addr "$@"
}

pathls() {
  printf "%s\n" "${path[@]}"
}

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
