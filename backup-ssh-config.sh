#!/usr/bin/env sh
set -eu

SOURCE_FILE="$HOME/.ssh/config"
BACKUP_NAME="ssh-config.tar.gz.gpg"

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Backup ~/.ssh/config as a GPG-encrypted archive.

example:
  $0 /linuxshare/Backup

output:
  BACKUP_DIR/$BACKUP_NAME

note:
  BACKUP_DIR must already exist.
  This script does not create the backup directory automatically.
USAGE
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

BACKUP_DIR="${1%/}"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "[ssh-config] error: source file not found: $SOURCE_FILE" >&2
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[ssh-config] error: backup directory not found: $BACKUP_DIR" >&2
  echo "[ssh-config] refusing to create it automatically." >&2
  exit 1
fi

if [ ! -w "$BACKUP_DIR" ]; then
  echo "[ssh-config] error: backup directory is not writable: $BACKUP_DIR" >&2
  exit 1
fi

# Newly created temporary files must be private.
umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-config-backup.XXXXXX)"
TMP_OUT="$(mktemp "$BACKUP_DIR/.ssh-config.tar.gz.gpg.XXXXXX")"

cleanup() {
  rm -rf -- "$TMP_DIR"
  [ -z "${TMP_OUT:-}" ] || rm -f -- "$TMP_OUT"
}
trap cleanup EXIT INT TERM

mkdir -p -- "$TMP_DIR/.ssh"
cp -- "$SOURCE_FILE" "$TMP_DIR/.ssh/config"
chmod 600 "$TMP_DIR/.ssh/config"

# mktemp creates the destination first, but gpg should create its output itself.
rm -f -- "$TMP_OUT"

echo "[ssh-config] backup from: $SOURCE_FILE"
echo "[ssh-config] backup to:   $BACKUP_FILE"

tar -C "$TMP_DIR" -czf - .ssh/config \
  | gpg -c --output "$TMP_OUT"

chmod 600 "$TMP_OUT"

# Replace the previous backup only after encryption completed successfully.
mv -- "$TMP_OUT" "$BACKUP_FILE"
TMP_OUT=""

echo "[ssh-config] done."
echo "[ssh-config] encrypted backup: $BACKUP_FILE"
