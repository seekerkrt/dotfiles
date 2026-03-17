#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PS1='[\u@\h \W]\$ '

complete -cf sudo

export EDITOR=nvim
export VISUAL=nvim
export LANG=ja_JP.UTF-8
export TERMINAL=wezterm

### User specific aliases and functions
### Aliases
alias ls="ls -F --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias cat='bat --paging=never --style=plain'
alias ccat='command cat'
alias eza='eza -F'


### others

### for PAGER(less) source-highlight
export PAGER=less
export OUTPUT_CHARSET=utf-8
export LESSOPEN='| /usr/bin/src-hilite-lesspipe.sh %s'
#export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export LESS='-R '
export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')
