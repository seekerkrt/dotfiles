#!/usr/bin/env sh
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STOWDIR="$DOTFILES/stow"
TARGET="$HOME"

stow -D -d "$STOWDIR" -t "$TARGET" nvim
stow -D -d "$STOWDIR" -t "$TARGET" ssh
stow -D -d "$STOWDIR" -t "$TARGET" zsh
stow -D -d "$STOWDIR" -t "$TARGET" vim
stow -D -d "$STOWDIR" -t "$TARGET" zsh-functions
stow -D -d "$STOWDIR" -t "$TARGET" git
stow -D -d "$STOWDIR" -t "$TARGET" scripts
stow -D -d "$STOWDIR" -t "$TARGET" clang-format
stow -D -d "$STOWDIR" -t "$TARGET" alacritty
stow -D -d "$STOWDIR" -t "$TARGET" tmux
stow -D -d "$STOWDIR" -t "$TARGET" tmuxp
stow -D -d "$STOWDIR" -t "$TARGET" xorg
stow -D -d "$STOWDIR" -t "$TARGET" wezterm
stow -D -d "$STOWDIR" -t "$TARGET" --no-folding vscode
stow -D -d "$STOWDIR" -t "$TARGET" conky
stow -D -d "$STOWDIR" -t "$TARGET" sway
stow -D -d "$STOWDIR" -t "$TARGET" waybar
stow -D -d "$STOWDIR" -t "$TARGET" mako
stow -D -d "$STOWDIR" -t "$TARGET" foot
stow -D -d "$STOWDIR" -t "$TARGET" fcitx5
stow -D -d "$STOWDIR" -t "$TARGET" emacs


# ~/.ssh は消さない（消すなら空のときだけ）
rmdir "$HOME/.ssh" 2>/dev/null || true
