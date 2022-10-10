#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -F --color=auto'
PS1='[\u@\h \W]\$ '

complete -cf sudo
