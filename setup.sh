#! /usr/bin/env sh
set -u
stow fonts
stow ssh
stow zsh
stow vim
stow git
stow scripts
stow clang-format
stow alacritty
stow tmux
stow xorg
stow wezterm
stow vscode
stow conky
# sshディレクトリのパーミッションを適切にする
chmod -v 700 ~/.ssh
chmod -v 600 ~/.ssh/*
