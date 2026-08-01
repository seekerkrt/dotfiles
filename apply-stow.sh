#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET_DIR="$HOME"
CODEX_RULES_IGNORE='^/\.codex/rules(/.*)?$'
# CLIの--ignoreはpackage相対pathを先頭slashなしで照合する
CODEX_RULES_CLI_IGNORE="^${CODEX_RULES_IGNORE#^/}"

# stow対象から外したいパッケージ名（必要なら増やす）
SKIP_PACKAGES="
"

# パッケージ別の追加オプション
stow_one() {
  pkg="$1"
  case "$pkg" in
    codex)
      stow -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$CODEX_RULES_IGNORE" \
        --ignore="$CODEX_RULES_CLI_IGNORE" \
        "$pkg"
      ;;
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

materialize_codex_rules() {
  src_dir="$STOW_DIR/codex/.codex/rules"
  codex_dir="$TARGET_DIR/.codex"
  dst_dir="$TARGET_DIR/.codex/rules"

  if [ ! -d "$src_dir" ]; then
    echo "[copy] Codex rules source not found: $src_dir" >&2
    return 1
  fi

  found_rule=0
  for src in "$src_dir"/*.rules; do
    [ -f "$src" ] || continue
    found_rule=1
  done

  if [ "$found_rule" -eq 0 ]; then
    echo "[copy] no Codex rule files found under: $src_dir" >&2
    return 1
  fi

  # 親directoryのtree foldingが残っている場合はSSOT自身を上書きしかねないため停止する
  if [ -e "$dst_dir" ] && [ ! -L "$dst_dir" ] && [ "$src_dir" -ef "$dst_dir" ]; then
    echo "[copy] refusing to materialize Codex rules: source and destination resolve to the same directory" >&2
    echo "[copy] source: $src_dir" >&2
    echo "[copy] destination: $dst_dir" >&2
    echo "[copy] $codex_dir may still be a Stow tree-folding symlink; unstow the old codex package first" >&2
    return 1
  fi

  if [ -L "$codex_dir" ]; then
    echo "[copy] refusing to use symlinked Codex directory: $codex_dir" >&2
    return 1
  fi
  if [ -e "$codex_dir" ] && [ ! -d "$codex_dir" ]; then
    echo "[copy] refusing to replace non-directory Codex path: $codex_dir" >&2
    return 1
  fi

  # 過去にStowが作ったディレクトリsymlinkを実ディレクトリへ変換
  if [ -L "$dst_dir" ]; then
    unlink -- "$dst_dir"
  elif [ -e "$dst_dir" ] && [ ! -d "$dst_dir" ]; then
    echo "[copy] refusing to replace non-directory rules path: $dst_dir" >&2
    return 1
  fi
  mkdir -p -- "$dst_dir"

  # すべてのコピー先を確認してから書き込みを始める
  for src in "$src_dir"/*.rules; do
    [ -f "$src" ] || continue

    dst="$dst_dir/$(basename -- "$src")"

    if [ -e "$dst" ] && [ ! -L "$dst" ] && [ "$src" -ef "$dst" ]; then
      echo "[copy] refusing to overwrite Codex rule: source and destination are the same file" >&2
      echo "[copy] source: $src" >&2
      echo "[copy] destination: $dst" >&2
      return 1
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ] && [ ! -f "$dst" ]; then
      echo "[copy] refusing to replace unexpected destination: $dst" >&2
      return 1
    fi
  done

  for src in "$src_dir"/*.rules; do
    [ -f "$src" ] || continue

    dst="$dst_dir/$(basename -- "$src")"

    # ファイル単体のsymlinkも実ファイルへ変換
    if [ -L "$dst" ]; then
      unlink -- "$dst"
    fi

    install -m 0644 -- "$src" "$dst"
    echo "[copy] Codex rule: $dst"
  done
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

  if [ "$pkg" = "codex" ]; then
    materialize_codex_rules
  fi
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
