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
stow --no-folding vscode
stow conky
stow sway
stow waybar
stow mako
stow foot
stow fcitx5

# sshディレクトリのパーミッションを適切にする
chmod -v 700 ~/.ssh
chmod -v 600 ~/.ssh/*
