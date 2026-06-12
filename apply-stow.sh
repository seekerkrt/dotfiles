#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET_DIR="$HOME"

# stow対象から外したいパッケージ名（必要なら増やす）
SKIP_PACKAGES="
"

# パッケージ別の追加オプション
stow_one() {
  pkg="$1"
  case "$pkg" in
    vscode)
      stow -d "$STOW_DIR" -t "$TARGET_DIR" --no-folding "$pkg"
      ;;
    *)
      stow -d "$STOW_DIR" -t "$TARGET_DIR" "$pkg"
      ;;
  esac
}

is_skipped() {
  pkg="$1"
  for s in $SKIP_PACKAGES; do
    [ "$pkg" = "$s" ] && return 0
  done
  return 1
}

# stow/配下のディレクトリを自動列挙して実行
# - globが空の時にそのまま "*" が残るのを避けるため、存在チェックを入れる
found_any=0
for path in "$STOW_DIR"/*; do
  [ -d "$path" ] || continue
  found_any=1

  pkg="$(basename -- "$path")"
  if is_skipped "$pkg"; then
    echo "[stow] skip: $pkg"
    continue
  fi

  echo "[stow] apply: $pkg"
  stow_one "$pkg"
done

if [ "$found_any" -eq 0 ]; then
  echo "[stow] no packages found under: $STOW_DIR" >&2
fi

# sshディレクトリのパーミッションを適切にする（鍵を含む場合に安全寄り）
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} +
  find "$HOME/.ssh" -type f ! -name "*.pub" -exec chmod 600 {} +
fi
