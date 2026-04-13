#!/usr/bin/env bash
set -euo pipefail

# update-pkglist.sh
# dotfiles ルートで実行する前提
#
# 出力:
#   pkglist/official.txt  ... 公式repo(native) かつ明示的に入れたもの
#   pkglist/foreign.txt   ... AUR/foreign      かつ明示的に入れたもの

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST_DIR="${ROOT_DIR}/pkglist"

OFFICIAL_LIST="${PKGLIST_DIR}/official.txt"
FOREIGN_LIST="${PKGLIST_DIR}/foreign.txt"

log() {
    printf '[update-pkglist] %s\n' "$*"
}

mkdir -p "$PKGLIST_DIR"

log "dotfiles ルート: ${ROOT_DIR}"
log "pkglist を更新する"

# native(公式repo) + explicit
pacman -Qqen | sort -u > "$OFFICIAL_LIST"

# foreign(AUR/手動導入系) + explicit
pacman -Qqem | sort -u > "$FOREIGN_LIST"

log "更新完了"
log "  official: ${OFFICIAL_LIST} ($(wc -l < "$OFFICIAL_LIST") packages)"
log "  foreign : ${FOREIGN_LIST} ($(wc -l < "$FOREIGN_LIST") packages)"
