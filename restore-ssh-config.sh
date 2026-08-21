#!/usr/bin/env sh
set -eu

BACKUP_NAME="ssh-config.tar.gz.gpg"
RESTORE_FILE="$HOME/.ssh/config"

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Restore ~/.ssh/config from a GPG-encrypted archive.

arguments:
  BACKUP_DIR  Directory containing ${BACKUP_NAME}.

example:
  $0 /linuxshare/Backup

input:
  BACKUP_DIR/${BACKUP_NAME}

restore:
  ~/.ssh/config

note:
  If ~/.ssh/config already exists, it is moved to a timestamped
  backup before the restored file is installed.
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
  echo "[ssh-config] error: backup directory not found: $BACKUP_DIR" >&2
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "[ssh-config] error: backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

if [ -L "$TARGET_DIR" ]; then
  echo "[ssh-config] error: $TARGET_DIR is a symlink. Refusing to restore." >&2
  echo "[ssh-config] fix ~/.ssh as a real directory first." >&2
  exit 1
fi

if [ -L "$RESTORE_FILE" ]; then
  echo "[ssh-config] error: $RESTORE_FILE is a symlink. Refusing to overwrite." >&2
  exit 1
fi

if [ -e "$RESTORE_FILE" ] && [ ! -f "$RESTORE_FILE" ]; then
  echo "[ssh-config] error: unexpected path exists: $RESTORE_FILE" >&2
  exit 1
fi

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-config-restore.XXXXXX)"
TMP_TAR="$TMP_DIR/ssh-config.tar.gz"
TMP_CONFIG="$TMP_DIR/config"
TMP_LIST="$TMP_DIR/archive-list.txt"

cleanup() {
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

echo "[ssh-config] restore from: $BACKUP_FILE"
echo "[ssh-config] restore to:   $RESTORE_FILE"

# Decrypt to a private temporary archive first.
gpg -d --output "$TMP_TAR" "$BACKUP_FILE"

# Validate the archive before extracting anything.
tar -tzf "$TMP_TAR" > "$TMP_LIST"

if [ ! -s "$TMP_LIST" ]; then
  echo "[ssh-config] error: archive is empty." >&2
  exit 1
fi

EXPECTED_COUNT=0

while IFS= read -r ARCHIVE_PATH; do
  case "$ARCHIVE_PATH" in
    .ssh/config)
      EXPECTED_COUNT=$((EXPECTED_COUNT + 1))
      ;;
    *)
      echo "[ssh-config] error: unexpected file in archive: $ARCHIVE_PATH" >&2
      echo "[ssh-config] archive must contain only .ssh/config" >&2
      exit 1
      ;;
  esac
done < "$TMP_LIST"

if [ "$EXPECTED_COUNT" -ne 1 ]; then
  echo "[ssh-config] error: archive does not contain exactly one .ssh/config" >&2
  exit 1
fi

# Extract only the expected file to a private temporary path.
tar -xOzf "$TMP_TAR" .ssh/config > "$TMP_CONFIG"
chmod 600 "$TMP_CONFIG"

mkdir -p -- "$TARGET_DIR"
chmod 700 "$TARGET_DIR"

if [ -e "$RESTORE_FILE" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  OLD_FILE="$RESTORE_FILE.$TS.bak"

  # Avoid overwriting an existing backup created in the same second.
  N=1
  while [ -e "$OLD_FILE" ]; do
    OLD_FILE="$RESTORE_FILE.$TS.$N.bak"
    N=$((N + 1))
  done

  echo "[ssh-config] notice: existing config found."
  echo "[ssh-config] move old config to: $OLD_FILE"
  mv -- "$RESTORE_FILE" "$OLD_FILE"
fi

install -m 600 -- "$TMP_CONFIG" "$RESTORE_FILE"

echo "[ssh-config] done."
echo "[ssh-config] restored: $RESTORE_FILE"
