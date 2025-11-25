#! /usr/bin/env sh
set -u

stow ssh zsh vim git scripts clang-format alacritty tmux xorg wezterm vscode conky
# sshディレクトリのパーミッションを適切にする
chmod -v 700 ~/.ssh
chmod -v 600 ~/.ssh/*
