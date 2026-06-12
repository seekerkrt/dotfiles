#!/usr/bin/env sh
set -eu

BACKUP_NAME="ssh-backup.tar.gz.gpg"

# Restore allowlist:
# The archive must contain only these files.
# authorized_keys / known_hosts / known_hosts.old are intentionally not restored.
ALLOW_PATHS='
.ssh/config
.ssh/id_ed25519
.ssh/id_ed25519.pub
'

usage() {
  cat >&2 <<USAGE
usage:
  $0 BACKUP_DIR

description:
  Restore selected ~/.ssh files from an encrypted GPG archive.

arguments:
  BACKUP_DIR  Directory containing ${BACKUP_NAME}.

example:
  $0 /linuxshare/Backup

input:
  BACKUP_DIR/${BACKUP_NAME}

restored files:
  ~/.ssh/config
  ~/.ssh/id_ed25519
  ~/.ssh/id_ed25519.pub

not restored:
  ~/.ssh/authorized_keys
  ~/.ssh/known_hosts
  ~/.ssh/known_hosts.old
USAGE
}

is_allowed_path() {
  CHECK_PATH="$1"

  for ALLOW_PATH in $ALLOW_PATHS; do
    if [ "$CHECK_PATH" = "$ALLOW_PATH" ]; then
      return 0
    fi
  done

  return 1
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

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-restore.XXXXXX)"
TMP_TAR="$TMP_DIR/ssh-backup.tar.gz"
TMP_EXTRACT="$TMP_DIR/extract"
TMP_LIST="$TMP_DIR/archive-list.txt"

cleanup() {
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_EXTRACT"

echo "[ssh] restore from: $BACKUP_FILE"
echo "[ssh] restore to:   $TARGET_DIR"

gpg -d --output "$TMP_TAR" "$BACKUP_FILE"
tar -tzf "$TMP_TAR" > "$TMP_LIST"

if [ ! -s "$TMP_LIST" ]; then
  echo "[ssh] error: archive is empty." >&2
  exit 1
fi

while IFS= read -r ARCHIVE_PATH; do
  case "$ARCHIVE_PATH" in
    /*|*../*|../*|.|./*|"")
      echo "[ssh] error: unsafe archive path: $ARCHIVE_PATH" >&2
      exit 1
      ;;
  esac

  if ! is_allowed_path "$ARCHIVE_PATH"; then
    echo "[ssh] error: unexpected file in archive: $ARCHIVE_PATH" >&2
    echo "[ssh] this restore script only accepts allowlisted SSH files." >&2
    exit 1
  fi
done < "$TMP_LIST"

echo "[ssh] archive contains:"
sed 's/^/[ssh]   ~\//' "$TMP_LIST"

tar -C "$TMP_EXTRACT" -xzf "$TMP_TAR"

if [ ! -d "$TMP_EXTRACT/.ssh" ]; then
  echo "[ssh] error: archive does not contain .ssh directory." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

for REL_PATH in $ALLOW_PATHS; do
  SRC_PATH="$TMP_EXTRACT/$REL_PATH"
  DST_PATH="$HOME/$REL_PATH"

  if [ ! -e "$SRC_PATH" ]; then
    continue
  fi

  mkdir -p "$(dirname "$DST_PATH")"
  cp -p -- "$SRC_PATH" "$DST_PATH"
done

chmod 700 "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 700 {} +
find "$TARGET_DIR" -type f -name "*.pub" -exec chmod 644 {} +
find "$TARGET_DIR" -type f ! -name "*.pub" -exec chmod 600 {} +

echo "[ssh] done."
echo "[ssh] check with: ssh -T git@github.com"
