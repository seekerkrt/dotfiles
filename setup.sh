#!/usr/bin/env sh
set -eu

# dotfiles repo root (= directory where this script lives)
DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET_DIR="$HOME"

# Always stow into $HOME (not into the dotfiles repo)
# -d: stow directory (where packages live)
# -t: target directory (where symlinks are created)

stow -d "$STOW_DIR" -t "$TARGET_DIR" nvim
stow -d "$STOW_DIR" -t "$TARGET_DIR" ssh
stow -d "$STOW_DIR" -t "$TARGET_DIR" zsh
stow -d "$STOW_DIR" -t "$TARGET_DIR" zsh-functions
stow -d "$STOW_DIR" -t "$TARGET_DIR" vim
stow -d "$STOW_DIR" -t "$TARGET_DIR" git
stow -d "$STOW_DIR" -t "$TARGET_DIR" scripts
stow -d "$STOW_DIR" -t "$TARGET_DIR" clang-format
stow -d "$STOW_DIR" -t "$TARGET_DIR" alacritty
stow -d "$STOW_DIR" -t "$TARGET_DIR" tmux
stow -d "$STOW_DIR" -t "$TARGET_DIR" tmuxp
stow -d "$STOW_DIR" -t "$TARGET_DIR" xorg
stow -d "$STOW_DIR" -t "$TARGET_DIR" wezterm
stow -d "$STOW_DIR" -t "$TARGET_DIR" --no-folding vscode
stow -d "$STOW_DIR" -t "$TARGET_DIR" conky
stow -d "$STOW_DIR" -t "$TARGET_DIR" sway
stow -d "$STOW_DIR" -t "$TARGET_DIR" waybar
stow -d "$STOW_DIR" -t "$TARGET_DIR" mako
stow -d "$STOW_DIR" -t "$TARGET_DIR" foot
stow -d "$STOW_DIR" -t "$TARGET_DIR" fcitx5
stow -d "$STOW_DIR" -t "$TARGET_DIR" emacs


# sshディレクトリのパーミッションを適切にする（鍵を含む場合に安全寄り）
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} +
  find "$HOME/.ssh" -type f ! -name "*.pub" -exec chmod 600 {} +
fi
