#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# 責務:
#   dotfiles内のシステム設定をroot所有ファイルとして配置する。
#
# POLICY:
#   - $HOME向け設定はapply-stow.shに任せる。
#   - Secure Boot鍵の作成・登録・復元は自動実行しない。
#   - ユーザー所有ファイルへのroot実行symlinkを作らない。
# -----------------------------------------------------------------------------

readonly DOTFILES_DIR="$(
  CDPATH= cd -- "$(dirname -- "$0")" &&
    pwd
)"

readonly SECUREBOOT_SRC="${DOTFILES_DIR}/system/secureboot"

[[ -d "$SECUREBOOT_SRC" ]] || {
  echo "[setup-system] missing: ${SECUREBOOT_SRC}" >&2
  exit 1
}

echo "[setup-system] installing required packages"
sudo pacman -S --needed sbctl grub efibootmgr

echo "[setup-system] installing sbctl configuration"
sudo install -d -m 755 /etc/sbctl
sudo install -o root -g root -m 644 \
  "${SECUREBOOT_SRC}/sbctl.conf" \
  /etc/sbctl/sbctl.conf

echo "[setup-system] installing Secure Boot scripts"
sudo install -d -m 755 /usr/local/sbin

sudo install -o root -g root -m 755 \
  "${SECUREBOOT_SRC}/secureboot-refresh-grub" \
  /usr/local/sbin/secureboot-refresh-grub

sudo install -o root -g root -m 755 \
  "${SECUREBOOT_SRC}/secureboot-backup" \
  /usr/local/sbin/secureboot-backup

sudo install -o root -g root -m 755 \
  "${SECUREBOOT_SRC}/secureboot-restore" \
  /usr/local/sbin/secureboot-restore

echo "[setup-system] installing pacman hook"
sudo install -d -m 755 /etc/pacman.d/hooks
sudo install -o root -g root -m 644 \
  "${SECUREBOOT_SRC}/secureboot-grub.hook" \
  /etc/pacman.d/hooks/95-secureboot-grub.hook

echo
echo "[setup-system] installed"
echo
echo "Current system check:"
echo "  sudo /usr/local/sbin/secureboot-refresh-grub"
echo "  sudo sbctl verify"
echo
echo "Backup:"
echo "  sudo secureboot-backup /path/to/backup-directory"
echo
echo "Restore:"
echo "  sudo secureboot-restore /path/to/sbctl-state-YYYYMMDD-HHMMSS.tar.gz"
echo
echo "NOTE: UEFI鍵登録とSecure Boot設定変更は手動で行うこと。"

