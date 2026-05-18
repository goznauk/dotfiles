[[ $- != *i* ]] && return

[[ -r "$HOME/.zshrc.local.pre" ]] && source "$HOME/.zshrc.local.pre"

# Keep prompt setup near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

if [[ "${DOTFILES_POWERLEVEL10K:-1}" == "1" ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  ZSH_THEME="${ZSH_THEME:-robbyrussell}"
fi

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE="${HISTSIZE:-100000}"
SAVEHIST="${SAVEHIST:-100000}"
HIST_STAMPS="yyyy-mm-dd"
setopt append_history
setopt extended_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history
setopt share_history

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

plugins=(git common-aliases ssh-agent dotenv)
if command -v docker >/dev/null 2>&1; then
  plugins+=(docker docker-compose)
fi
plugins+=(zsh-syntax-highlighting zsh-autosuggestions zsh-completions)

zsh_completions_dir="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/zsh-completions/src"
[[ -d "$zsh_completions_dir" ]] && fpath=("$zsh_completions_dir" $fpath)
unset zsh_completions_dir

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  mkdir -p "$zsh_cache_dir"
  autoload -Uz compinit
  compinit -d "$zsh_cache_dir/zcompdump"
  unset zsh_cache_dir
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

export LANG="${LANG:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-$LANG}"
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
if tty -s; then
  export GPG_TTY="$(tty)"
fi

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
  if command -v ip >/dev/null 2>&1; then
    ip -brief addr "$@"
  else
    ifconfig "$@"
  fi
}

pathls() {
  printf "%s\n" "${path[@]}"
}

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
