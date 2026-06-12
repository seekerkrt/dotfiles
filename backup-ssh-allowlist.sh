#!/usr/bin/env sh
set -eu

BACKUP_NAME="ssh-backup.tar.gz.gpg"

# Allowlist:
# Only these files are included in the encrypted backup.
# authorized_keys / known_hosts / known_hosts.old are intentionally excluded.
INCLUDE_PATHS='
.ssh/config
.ssh/id_ed25519
.ssh/id_ed25519.pub
'

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Backup selected ~/.ssh files as an encrypted GPG archive.

arguments:
  BACKUP_DIR  Directory where ${BACKUP_NAME} will be created.

example:
  $0 /linuxshare/Backup

output:
  BACKUP_DIR/${BACKUP_NAME}

included files:
  ~/.ssh/config
  ~/.ssh/id_ed25519
  ~/.ssh/id_ed25519.pub

excluded files:
  ~/.ssh/authorized_keys
  ~/.ssh/known_hosts
  ~/.ssh/known_hosts.old
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

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-backup.XXXXXX)"
TMP_TAR="$TMP_DIR/ssh-backup.tar.gz"
TMP_LIST="$TMP_DIR/include.txt"

cleanup() {
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

: > "$TMP_LIST"
FOUND=0

for REL_PATH in $INCLUDE_PATHS; do
  SRC_PATH="$HOME/$REL_PATH"

  if [ ! -e "$SRC_PATH" ]; then
    echo "[ssh] notice: skip missing file: ~/$REL_PATH"
    continue
  fi

  if [ ! -f "$SRC_PATH" ]; then
    echo "[ssh] warning: skip non-regular file: ~/$REL_PATH" >&2
    continue
  fi

  printf '%s\n' "$REL_PATH" >> "$TMP_LIST"
  FOUND=1
done

if [ "$FOUND" -ne 1 ]; then
  echo "[ssh] error: no allowlisted SSH files were found." >&2
  exit 1
fi

echo "[ssh] backup from: $SOURCE_DIR"
echo "[ssh] backup to:   $BACKUP_FILE"
echo "[ssh] include:"
sed 's/^/[ssh]   ~\//' "$TMP_LIST"

tar -C "$HOME" -czf "$TMP_TAR" -T "$TMP_LIST"
gpg -c --output "$BACKUP_FILE" "$TMP_TAR"

chmod 600 "$BACKUP_FILE" 2>/dev/null || true

echo "[ssh] done."
echo "[ssh] encrypted backup: $BACKUP_FILE"
