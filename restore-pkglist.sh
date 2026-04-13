#!/usr/bin/env bash
set -euo pipefail

# restore-pkglist.sh
# dotfiles ルートで実行する前提
#
# 使い方:
#   ./restore-pkglist.sh
#   ./restore-pkglist.sh --official-only
#   ./restore-pkglist.sh --foreign-only
#   ./restore-pkglist.sh --dry-run
#
# 前提:
#   pkglist/official.txt ... pacman -Qqen で作成
#   pkglist/foreign.txt  ... pacman -Qqem で作成

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST_DIR="${ROOT_DIR}/pkglist"

OFFICIAL_LIST="${PKGLIST_DIR}/official.txt"
FOREIGN_LIST="${PKGLIST_DIR}/foreign.txt"

RESTORE_OFFICIAL=1
RESTORE_FOREIGN=1
DRY_RUN=0

log() {
    printf '[restore-pkglist] %s\n' "$*"
}

die() {
    printf '[restore-pkglist] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
使い方:
  ./restore-pkglist.sh
  ./restore-pkglist.sh --official-only
  ./restore-pkglist.sh --foreign-only
  ./restore-pkglist.sh --dry-run
EOF
}

require_file_if_enabled() {
    local enabled="$1"
    local file="$2"
    local name="$3"

    if [[ "$enabled" -eq 1 && ! -f "$file" ]]; then
        die "${name} が見つからない: ${file}"
    fi
}

read_pkglist() {
    local file="$1"
    grep -vE '^[[:space:]]*(#|$)' "$file" || true
}

detect_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        printf 'yay'
        return 0
    fi

    if command -v paru >/dev/null 2>&1; then
        printf 'paru'
        return 0
    fi

    return 1
}

install_official() {
    local pkgs=()

    mapfile -t pkgs < <(read_pkglist "$OFFICIAL_LIST")

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        log "official.txt は空。スキップ。"
        return 0
    fi

    log "公式repoパッケージを復旧する (${#pkgs[@]}件)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'sudo pacman -S --needed'
        printf ' %q' "${pkgs[@]}"
        printf '\n'
        return 0
    fi

    sudo pacman -S --needed "${pkgs[@]}"
}

install_foreign() {
    local pkgs=()
    local aur_helper

    mapfile -t pkgs < <(read_pkglist "$FOREIGN_LIST")

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        log "foreign.txt は空。スキップ。"
        return 0
    fi

    if ! aur_helper="$(detect_aur_helper)"; then
        log "yay/paru が見つからないので foreign/AUR は自動復旧できない。"
        log "以下を手動で入れて:"
        printf '  %s\n' "${pkgs[@]}"
        return 0
    fi

    log "foreign/AUR パッケージを ${aur_helper} で復旧する (${#pkgs[@]}件)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '%s -S --needed' "$aur_helper"
        printf ' %q' "${pkgs[@]}"
        printf '\n'
        return 0
    fi

    "${aur_helper}" -S --needed "${pkgs[@]}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --official-only)
            RESTORE_OFFICIAL=1
            RESTORE_FOREIGN=0
            shift
            ;;
        --foreign-only)
            RESTORE_OFFICIAL=0
            RESTORE_FOREIGN=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            die "不明な引数: $1"
            ;;
    esac
done

require_file_if_enabled "$RESTORE_OFFICIAL" "$OFFICIAL_LIST" "official.txt"
require_file_if_enabled "$RESTORE_FOREIGN" "$FOREIGN_LIST" "foreign.txt"

log "dotfiles ルート: ${ROOT_DIR}"

if [[ "$RESTORE_OFFICIAL" -eq 1 ]]; then
    install_official
fi

if [[ "$RESTORE_FOREIGN" -eq 1 ]]; then
    install_foreign
fi

log "完了"
