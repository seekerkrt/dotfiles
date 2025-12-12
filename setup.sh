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
chmod 700 ~/.ssh
find ~/.ssh -type f -name "*.pub" -exec chmod 644 {} +
find ~/.ssh -type f ! -name "*.pub" -exec chmod 600 {} +
