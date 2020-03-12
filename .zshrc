# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="powerlevel10k/powerlevel10k"

HISTSIZE=100000
HIST_STAMPS="mm/dd/yyyy"

plugins=(git git-flow autojump common-aliases)
plugins+=(zsh-syntax-highlighting zsh-autosuggestions zsh-completions vi-mode)
plugins+=(ssh-agent docker docker-compose dotenv)

# User configuration
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.yarn/bin:$HOME/.local/bin"
fpath=(~/.zsh/completion $fpath)
source $ZSH/oh-my-zsh.sh

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=vim
export GPG_TTY=$(tty)

bindkey 'OA' history-beginning-search-backward
bindkey 'OB' history-beginning-search-forward

# Play safe!
alias 'rm=rm -i'
alias 'rmdir=rm -rfi'
alias 'mv=mv -i'
alias 'cp=cp -i'

# Typing errors...
alias 'cd..=cd ..'

# ls
alias 'l=ls -F'
alias 'la=ls -AF'
alias 'lal=ls -alF'

# tmux
alias ta='tmux attach -t '
alias mux='tmuxinator'

# Docker-compose
alias 'dc=docker-compose'
alias 'dcrs=docker-compose down && docker-compose build && docker-compose up'

# Zsh Configuration
alias 'zshrc=vi ~/.zshrc'
alias 'zshrc_apply=source ~/.zshrc'

# etc. aliases
alias 'listOpenPorts=lsof -i tcp | grep -i "listen"'
alias 'nvsmi=nvidia-smi'

autoload -U compinit && compinit

zplugin ice wait"0" blockf
zplugin light "zsh-users/zsh-completions"
zplugin ice wait"!0" atload"_zsh_autosuggest_start"
zplugin light "zsh-users/zsh-autosuggestions"
zplugin light "mafredri/zsh-async"
#zplugin light "sindresorhus/pure"
#zplugin light "intelfx/pure"
zplugin light "marzocchi/zsh-notify"
zplugin ice wait'!0'
zplugin light "vintersnow/anyframe"
zplugin ice wait'!0'
zplugin light "b4b4r07/enhancd"
zplugin ice wait'!0'
zplugin light "lukechilds/zsh-nvm"
zplugin ice wait'!0'
zplugin light "greymd/tmux-xpanes"
zplugin ice wait"0" atinit"zpcompinit; zpcdreplay"
zplugin light "zdharma/fast-syntax-highlighting"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
