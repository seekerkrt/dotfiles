#!/usr/bin/env sh
set -eu

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
TARGET_DIR="$HOME"
CODEX_RULES_IGNORE='^/\.codex/rules(/.*)?$'
CODEX_CONFIG_IGNORE='^/\.codex(/.*)?$'
CODEX_SKILLS_IGNORE='^/\.agents(/.*)?$'
# CLIの--ignoreはpackage相対pathを先頭slashなしで照合する
CODEX_RULES_CLI_IGNORE="^${CODEX_RULES_IGNORE#^/}"
CODEX_CONFIG_CLI_IGNORE="^${CODEX_CONFIG_IGNORE#^/}"
CODEX_SKILLS_CLI_IGNORE="^${CODEX_SKILLS_IGNORE#^/}"

# Grok CLIはconfig.tomlを自動で正規化・追記するため、Stow symlinkではなくseed用実ファイルとして扱う
GROK_CONFIG_IGNORE='^/\.grok/config\.toml$'
GROK_CONFIG_CLI_IGNORE="^${GROK_CONFIG_IGNORE#^/}"

# remove対象から外したいパッケージ名（必要なら増やす）
SKIP_PACKAGES="
"

stow_remove_one() {
  pkg="$1"
  case "$pkg" in
    codex)
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$CODEX_CONFIG_IGNORE" \
        --ignore="$CODEX_CONFIG_CLI_IGNORE" \
        "$pkg"
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$CODEX_RULES_IGNORE" \
        --ignore="$CODEX_RULES_CLI_IGNORE" \
        --ignore="$CODEX_SKILLS_IGNORE" \
        --ignore="$CODEX_SKILLS_CLI_IGNORE" \
        "$pkg"
      ;;
    grok)
      # config.tomlはlive実ファイルとして残し、それ以外のmanaged symlinkだけを解除する
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$GROK_CONFIG_IGNORE" \
        --ignore="$GROK_CONFIG_CLI_IGNORE" \
        "$pkg"
      remove_grok_config_symlink
      ;;
    vscode|gemini|antigravity)
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" --no-folding "$pkg"
      ;;
    *)
      stow -D -d "$STOW_DIR" -t "$TARGET_DIR" "$pkg"
      ;;
  esac
}

remove_grok_config_symlink() {
  src="$STOW_DIR/grok/.grok/config.toml"
  dst="$TARGET_DIR/.grok/config.toml"

  # 新方式ではconfig.tomlは実ファイルなので何もしない。
  # 旧Stow方式のmanaged symlinkが残っている場合だけ解除する。
  if [ -L "$dst" ]; then
    if [ -e "$src" ] && [ -e "$dst" ] && [ "$src" -ef "$dst" ]; then
      unlink -- "$dst"
      echo "[remove] old Grok config symlink: $dst"
    else
      echo "[remove] unmanaged Grok config symlink left unchanged: $dst" >&2
    fi
  fi
}

remove_codex_skill_dirs() {
  src_dir="$STOW_DIR/codex/.agents/skills"
  dst_dir="$TARGET_DIR/.agents/skills"

  if [ -d "$src_dir" ]; then
    for src in "$src_dir"/*; do
      [ -d "$src" ] || continue
      rmdir -- "$dst_dir/$(basename -- "$src")" 2>/dev/null || true
    done
  fi

  rmdir -- "$dst_dir" 2>/dev/null || true
  rmdir -- "$TARGET_DIR/.agents" 2>/dev/null || true
}

is_skipped() {
  pkg="$1"
  for s in $SKIP_PACKAGES; do
    [ "$pkg" = "$s" ] && return 0
  done
  return 1
}

remove_codex_rules() {
  src_dir="$STOW_DIR/codex/.codex/rules"
  dst_dir="$TARGET_DIR/.codex/rules"

  if [ ! -d "$src_dir" ]; then
    echo "[remove] Codex rules source not found; deployed rules left unchanged: $src_dir" >&2
    return 0
  fi

  if [ -L "$dst_dir" ]; then
    echo "[remove] Codex rules path is a symlink; left unchanged: $dst_dir" >&2
    return 0
  fi
  if [ ! -e "$dst_dir" ]; then
    return 0
  fi
  if [ ! -d "$dst_dir" ]; then
    echo "[remove] unexpected Codex rules path left unchanged: $dst_dir" >&2
    return 0
  fi

  if [ "$src_dir" -ef "$dst_dir" ]; then
    echo "[remove] refusing to remove Codex rules: source and destination resolve to the same directory" >&2
    echo "[remove] source: $src_dir" >&2
    echo "[remove] destination: $dst_dir" >&2
    return 1
  fi

  for src in "$src_dir"/*.rules; do
    [ -f "$src" ] || continue

    dst="$dst_dir/$(basename -- "$src")"
    if [ -L "$dst" ]; then
      echo "[remove] Codex rule is a symlink; left unchanged: $dst" >&2
    elif [ -f "$dst" ]; then
      if [ "$src" -ef "$dst" ]; then
        echo "[remove] Codex rule aliases its SSOT; left unchanged: $dst" >&2
      elif cmp -s -- "$src" "$dst"; then
        rm -- "$dst"
        echo "[remove] Codex rule: $dst"
      else
        echo "[remove] Codex rule was modified after deployment; left unchanged: $dst" >&2
      fi
    elif [ -e "$dst" ]; then
      echo "[remove] unexpected Codex rule path left unchanged: $dst" >&2
    fi
  done

  if rmdir -- "$dst_dir" 2>/dev/null; then
    echo "[remove] empty Codex rules directory: $dst_dir"
  fi
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

  if [ "$pkg" = "codex" ]; then
    remove_codex_skill_dirs
    remove_codex_rules
  fi
done

if [ "$found_any" -eq 0 ]; then
  echo "[stow] no packages found under: $STOW_DIR" >&2
fi

# ~/.ssh は消さない（消すなら空のときだけ）
rmdir "$HOME/.ssh" 2>/dev/null || true
