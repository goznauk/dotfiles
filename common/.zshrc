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

zsh_custom_dir="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
zsh_completions_dir="$zsh_custom_dir/plugins/zsh-completions/src"
[[ -d "$zsh_completions_dir" ]] && fpath=("$zsh_completions_dir" $fpath)
unset zsh_completions_dir

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "WARN: Oh My Zsh not found at $ZSH/oh-my-zsh.sh"
  zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  mkdir -p "$zsh_cache_dir"
  autoload -Uz compinit
  compinit -d "$zsh_cache_dir/zcompdump"
  unset zsh_cache_dir
fi

zsh_autosuggestions_file="$zsh_custom_dir/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$zsh_autosuggestions_file" ]] && source "$zsh_autosuggestions_file"
unset zsh_autosuggestions_file

zsh_syntax_highlighting_file="$zsh_custom_dir/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$zsh_syntax_highlighting_file" ]] && source "$zsh_syntax_highlighting_file"
unset zsh_syntax_highlighting_file zsh_custom_dir

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

_tmux_required() {
  command -v tmux >/dev/null 2>&1 || {
    printf 'tmux is not installed.\n' >&2
    return 1
  }
}

_dotfiles_tmux_session_names() {
  _tmux_required >/dev/null 2>&1 || return 0
  tmux list-sessions -F '#S' 2>/dev/null || true
}

_dotfiles_tmux_sessions() {
  local -a sessions
  sessions=("${(@f)$(_dotfiles_tmux_session_names)}")
  (( ${#sessions[@]} )) && _describe 'tmux sessions' sessions
}

if (( $+functions[compdef] )); then
  compdef _dotfiles_tmux_sessions ta tk
fi

_tmux_valid_session_name() {
  local session="$1"
  if [[ -z "$session" ]]; then
    printf 'Session name is required.\n' >&2
    return 1
  fi
  if [[ "$session" == -* ]]; then
    printf 'Session name must not start with -.\n' >&2
    return 1
  fi
}

_tmux_default_session() {
  local -a sessions
  sessions=("${(@f)$(_dotfiles_tmux_session_names)}")

  if (( ${#sessions[@]} == 1 )); then
    printf '%s\n' "$sessions[1]"
  elif (( ${#sessions[@]} == 0 )); then
    printf 'main\n'
  else
    printf 'Multiple tmux sessions exist. Run ta <session>.\n' >&2
    printf 'Existing sessions:\n' >&2
    printf '  %s\n' "${sessions[@]}" >&2
    return 1
  fi
}

tmux_switch_or_new() {
  _tmux_required || return $?
  if [[ "$#" -gt 1 ]]; then
    printf 'Usage: ta [session]\n' >&2
    return 2
  fi

  local session="${1:-}"
  if [[ -z "$session" ]]; then
    session="$(_tmux_default_session)" || return $?
  fi
  _tmux_valid_session_name "$session" || return $?

  if tmux has-session -t "=$session" 2>/dev/null; then
    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "=$session"
    else
      tmux attach-session -t "=$session"
    fi
  elif [[ -n "${TMUX:-}" ]]; then
    tmux new-session -d -s "$session"
    tmux switch-client -t "=$session"
  else
    tmux new-session -s "$session"
  fi
}

ta() {
  tmux_switch_or_new "$@"
}

tl() {
  _tmux_required || return $?
  tmux list-sessions "$@"
}

tn() {
  _tmux_required || return $?
  if [[ "$#" -ne 1 ]]; then
    printf 'Usage: tn <session>\n' >&2
    return 2
  fi
  local session="$1"
  _tmux_valid_session_name "$session" || return $?
  tmux new-session -s "$session"
}

tk() {
  _tmux_required || return $?
  local session="$1"
  if [[ -z "$session" ]]; then
    printf 'Usage: tk <session>\n' >&2
    return 2
  fi
  _tmux_valid_session_name "$session" || return $?
  printf 'Kill tmux session %s? [y/N] ' "$session"
  local answer
  read -r answer || return 1
  [[ "$answer" == [Yy] || "$answer" == [Yy][Ee][Ss] ]] || return 1
  tmux kill-session -t "=$session"
}

trn() {
  _tmux_required || return $?
  if [[ "$#" -ne 2 ]]; then
    printf 'Usage: trn <old> <new>\n' >&2
    return 2
  fi
  local old_session="$1"
  local new_session="$2"
  _tmux_valid_session_name "$old_session" || return $?
  _tmux_valid_session_name "$new_session" || return $?
  tmux rename-session -t "=$old_session" "$new_session"
}

td() {
  _tmux_required || return $?
  tmux detach-client
}

tksv() {
  _tmux_required || return $?
  printf 'Kill the entire tmux server and all sessions? [y/N] '
  local answer
  read -r answer || return 1
  [[ "$answer" == [Yy] || "$answer" == [Yy][Ee][Ss] ]] || return 1
  tmux kill-server
}

tmain() {
  tmux_switch_or_new main
}

tmux_prefix() {
  _tmux_required || return $?
  tmux show-option -gqv prefix 2>/dev/null
}

ta0() {
  tmux_switch_or_new 0
}

tls() {
  tl "$@"
}

alias tmuxrc='vim ~/.tmux.conf'
alias tmuxrc_local='vim ~/.tmux.conf.local'

tmuxrc_apply() {
  _tmux_required || return $?
  tmux source-file ~/.tmux.conf
}

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
