#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET_DIR="$HOME"

# remove対象から外したいパッケージ名（必要なら増やす）
SKIP_PACKAGES="
"

stow_remove_one() {
  pkg="$1"
  case "$pkg" in
    vscode)
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" --no-folding "$pkg"
      ;;
    *)
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" "$pkg"
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

found_any=0
for path in "$STOW_DIR"/*; do
  [ -d "$path" ] || continue
  found_any=1

  pkg="$(basename -- "$path")"
  if is_skipped "$pkg"; then
    echo "[stow] skip: $pkg"
    continue
  fi

  echo "[stow] remove: $pkg"
  stow_remove_one "$pkg"
done

if [ "$found_any" -eq 0 ]; then
  echo "[stow] no packages found under: $STOW_DIR" >&2
fi

# ~/.ssh は消さない（消すなら空のときだけ）
rmdir "$HOME/.ssh" 2>/dev/null || true
