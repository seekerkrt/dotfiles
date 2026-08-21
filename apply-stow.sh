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

# stow対象から外したいパッケージ名（必要なら増やす）
# systemd-user: systemd unit・drop-in・enable状態はsetup-systemd-services.shが管理する。
#   packageは削除済みで、この項目は誤ってStow管理へ戻さないためのguardとして残している。
#   Stowが同じpathへsymlinkを張ると、setup scriptが配置した実ファイルとconflictする。
SKIP_PACKAGES="
systemd-user
"

# パッケージ別の追加オプション
stow_one() {
  pkg="$1"
  case "$pkg" in
    codex)
      # .codexはrulesの実ファイル配置に備えて展開し、Skill subtreeはfold対象に残す
      stow -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$CODEX_RULES_IGNORE" \
        --ignore="$CODEX_RULES_CLI_IGNORE" \
        --ignore="$CODEX_SKILLS_IGNORE" \
        --ignore="$CODEX_SKILLS_CLI_IGNORE" \
        "$pkg"
      stow_codex_skills
      ;;
    grok)
      # ~/.grok配下にはruntime/stateが生成されるためfoldしない。
      # config.tomlはGrok自身が書き換えるためStow対象から外し、存在しない時だけseedする。
      stow -d "$STOW_DIR" -t "$TARGET_DIR" \
        --no-folding \
        --ignore="$GROK_CONFIG_IGNORE" \
        --ignore="$GROK_CONFIG_CLI_IGNORE" \
        "$pkg"
      materialize_grok_config
      ;;
    vscode|gemini|antigravity)
      # runtime/stateを同じtree配下に生成するため、package directoryをfoldしない
      stow -d "$STOW_DIR" -t "$TARGET_DIR" --no-folding "$pkg"
      ;;
    *)
      stow -d "$STOW_DIR" -t "$TARGET_DIR" "$pkg"
      ;;
  esac
}

codex_skill_target_is_owned() {
  src_root="$1"
  dst_root="$2"

  if [ -L "$dst_root" ]; then
    [ "$src_root" -ef "$dst_root" ]
    return
  fi
  if [ ! -e "$dst_root" ]; then
    return 0
  fi
  if [ ! -d "$dst_root" ]; then
    return 1
  fi

  find "$dst_root" -mindepth 1 -exec sh -c '
    src_root="$1"
    dst_root="$2"
    shift 2

    for dst_path do
      relative_path=${dst_path#"$dst_root"/}
      src_path="$src_root/$relative_path"

      if [ -L "$dst_path" ]; then
        [ -e "$src_path" ] && [ "$src_path" -ef "$dst_path" ] || exit 1
      elif [ -d "$dst_path" ]; then
        [ -d "$src_path" ] || exit 1
      else
        exit 1
      fi
    done
  ' sh "$src_root" "$dst_root" {} +
}

stow_codex_skills() {
  src_agents_dir="$STOW_DIR/codex/.agents"
  src_dir="$STOW_DIR/codex/.agents/skills"
  agents_dir="$TARGET_DIR/.agents"
  dst_dir="$agents_dir/skills"

  if [ ! -d "$src_dir" ]; then
    echo "[stow] Codex Skill source not found: $src_dir" >&2
    return 1
  fi

  found_skill=0
  for src in "$src_dir"/*; do
    [ -d "$src" ] || continue
    found_skill=1
  done
  if [ "$found_skill" -eq 0 ]; then
    echo "[stow] no Codex Skill directories found under: $src_dir" >&2
    return 1
  fi

  folded_root=0
  if [ -L "$agents_dir" ]; then
    if [ ! "$src_agents_dir" -ef "$agents_dir" ]; then
      echo "[stow] refusing to replace unmanaged Codex agents symlink: $agents_dir" >&2
      return 1
    fi
    folded_root=1
  elif [ -e "$agents_dir" ] && [ ! -d "$agents_dir" ]; then
    echo "[stow] refusing to replace non-directory Codex agents path: $agents_dir" >&2
    return 1
  fi

  if [ "$folded_root" -eq 0 ]; then
    if [ -L "$dst_dir" ]; then
      if [ ! "$src_dir" -ef "$dst_dir" ]; then
        echo "[stow] refusing to replace unmanaged Codex Skill root symlink: $dst_dir" >&2
        return 1
      fi
      folded_root=1
    elif [ -e "$dst_dir" ] && [ ! -d "$dst_dir" ]; then
      echo "[stow] refusing to replace non-directory Codex Skill root: $dst_dir" >&2
      return 1
    fi
  fi

  if [ "$folded_root" -eq 0 ]; then
    for src in "$src_dir"/*; do
      [ -d "$src" ] || continue

      dst="$dst_dir/$(basename -- "$src")"
      if ! codex_skill_target_is_owned "$src" "$dst"; then
        echo "[stow] Codex Skill target contains unmanaged content: $dst" >&2
        return 1
      fi
    done
  fi

  # 旧--no-folding配置のfile symlinkを外し、Skill directory単位でfoldし直す
  stow -D -d "$STOW_DIR" -t "$TARGET_DIR" \
    --no-folding \
    --ignore="$CODEX_CONFIG_IGNORE" \
    --ignore="$CODEX_CONFIG_CLI_IGNORE" \
    codex

  if [ -L "$agents_dir" ]; then
    echo "[stow] refusing to replace symlinked Codex agents directory: $agents_dir" >&2
    return 1
  fi
  if [ -e "$agents_dir" ] && [ ! -d "$agents_dir" ]; then
    echo "[stow] refusing to replace non-directory Codex agents path: $agents_dir" >&2
    return 1
  fi
  if [ -L "$dst_dir" ]; then
    echo "[stow] refusing to replace symlinked Codex Skill root: $dst_dir" >&2
    return 1
  fi
  if [ -e "$dst_dir" ] && [ ! -d "$dst_dir" ]; then
    echo "[stow] refusing to replace non-directory Codex Skill root: $dst_dir" >&2
    return 1
  fi
  mkdir -p -- "$dst_dir"

  for src in "$src_dir"/*; do
    [ -d "$src" ] || continue

    dst="$dst_dir/$(basename -- "$src")"
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
      find "$dst" -depth -type d -empty -delete
    fi
    if [ -L "$dst" ] || [ -e "$dst" ]; then
      echo "[stow] failed to clear previous Codex Skill target: $dst" >&2
      return 1
    fi
  done

  stow -d "$STOW_DIR" -t "$TARGET_DIR" \
    --ignore="$CODEX_CONFIG_IGNORE" \
    --ignore="$CODEX_CONFIG_CLI_IGNORE" \
    codex
}

materialize_grok_config() {
  src="$STOW_DIR/grok/.grok/config.toml"
  grok_dir="$TARGET_DIR/.grok"
  dst="$grok_dir/config.toml"

  if [ ! -f "$src" ]; then
    echo "[copy] Grok config source not found: $src" >&2
    return 1
  fi

  if [ -L "$grok_dir" ]; then
    echo "[copy] refusing to use symlinked Grok directory: $grok_dir" >&2
    echo "[copy] unstow the old grok package first so ~/.grok can become a real directory" >&2
    return 1
  fi
  if [ -e "$grok_dir" ] && [ ! -d "$grok_dir" ]; then
    echo "[copy] refusing to replace non-directory Grok path: $grok_dir" >&2
    return 1
  fi
  mkdir -p -- "$grok_dir"

  if [ -L "$dst" ]; then
    if [ -e "$dst" ] && [ "$src" -ef "$dst" ]; then
      # 旧Stow配置のmanaged symlinkだけを実ファイルへ変換する
      unlink -- "$dst"
    else
      echo "[copy] refusing to replace unmanaged Grok config symlink: $dst" >&2
      return 1
    fi
  elif [ -f "$dst" ]; then
    if cmp -s -- "$src" "$dst"; then
      return 0
    fi

    # Grok自身が正規化・privacy/state追記を行うため、既存live configは上書きしない
    echo "[copy] Grok live config differs; preserving: $dst" >&2
    return 0
  elif [ -e "$dst" ]; then
    echo "[copy] refusing to replace unexpected Grok config path: $dst" >&2
    return 1
  fi

  install -m 0644 -- "$src" "$dst"
  echo "[copy] Grok config: $dst"
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
