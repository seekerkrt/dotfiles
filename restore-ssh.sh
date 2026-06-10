#!/usr/bin/env sh
set -eu

BACKUP_NAME="ssh-backup.tar.gz.gpg"

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Restore ~/.ssh from an encrypted GPG archive.

arguments:
  BACKUP_DIR  Directory containing ${BACKUP_NAME}.

example:
  $0 /linuxshare/Backup

input:
  BACKUP_DIR/${BACKUP_NAME}
USAGE
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

BACKUP_DIR="$1"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
TARGET_DIR="$HOME/.ssh"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[ssh] error: backup directory not found: $BACKUP_DIR" >&2
  usage
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "[ssh] error: backup file not found: $BACKUP_FILE" >&2
  usage
  exit 1
fi

if [ -L "$TARGET_DIR" ]; then
  echo "[ssh] error: $TARGET_DIR is a symlink. Refusing to overwrite." >&2
  echo "[ssh] remove or fix it manually first." >&2
  exit 1
fi

if [ -e "$TARGET_DIR" ] && [ "$(find "$TARGET_DIR" -mindepth 1 -print -quit)" ]; then
  echo "[ssh] error: $TARGET_DIR already exists and is not empty." >&2
  echo "[ssh] refusing to overwrite existing SSH files." >&2
  echo "[ssh] move it manually first if you really want to restore." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d --tmpdir ssh-restore.XXXXXX)"

cleanup() {
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

echo "[ssh] restore from: $BACKUP_FILE"
echo "[ssh] restore to:   $TARGET_DIR"

gpg -d "$BACKUP_FILE" | tar -C "$TMP_DIR" -xzf -

if [ ! -d "$TMP_DIR/.ssh" ]; then
  echo "[ssh] error: archive does not contain .ssh directory." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
rsync -aHAX "$TMP_DIR/.ssh"/ "$TARGET_DIR"/

chmod 700 "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 700 {} +
find "$TARGET_DIR" -type f -name "*.pub" -exec chmod 644 {} +
find "$TARGET_DIR" -type f ! -name "*.pub" -exec chmod 600 {} +

echo "[ssh] done."
echo "[ssh] check with: ssh -T git@github.com"
