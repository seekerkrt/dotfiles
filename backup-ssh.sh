#!/usr/bin/env sh
set -eu

BACKUP_NAME="ssh-backup.tar.gz.gpg"

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Backup ~/.ssh as an encrypted GPG archive.

arguments:
  BACKUP_DIR  Directory where ${BACKUP_NAME} will be created.

example:
  $0 /linuxshare/Backup

output:
  BACKUP_DIR/${BACKUP_NAME}
USAGE
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

BACKUP_DIR="$1"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
SOURCE_DIR="$HOME/.ssh"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "[ssh] error: source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ -L "$SOURCE_DIR" ]; then
  echo "[ssh] error: $SOURCE_DIR is a symlink. Refusing to backup." >&2
  echo "[ssh] fix ~/.ssh as a real directory first." >&2
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[ssh] error: backup directory not found: $BACKUP_DIR" >&2
  usage
  exit 1
fi

if [ -e "$BACKUP_FILE" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  OLD_FILE="$BACKUP_FILE.$TS.bak"
  echo "[ssh] notice: existing backup found."
  echo "[ssh] move old backup to: $OLD_FILE"
  mv -- "$BACKUP_FILE" "$OLD_FILE"
fi

TMP_TAR="$(mktemp --tmpdir ssh-backup.XXXXXX.tar.gz)"

cleanup() {
  rm -f -- "$TMP_TAR"
}
trap cleanup EXIT INT TERM

echo "[ssh] backup from: $SOURCE_DIR"
echo "[ssh] backup to:   $BACKUP_FILE"

tar -C "$HOME" -czf "$TMP_TAR" .ssh
gpg -c --output "$BACKUP_FILE" "$TMP_TAR"

chmod 600 "$BACKUP_FILE" 2>/dev/null || true

echo "[ssh] done."
echo "[ssh] encrypted backup: $BACKUP_FILE"
