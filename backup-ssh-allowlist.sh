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

file_timestamp() {
  FILE="$1"

  # GNU stat:
  #   %W = birth time as seconds since Epoch; 0 or -1 if unknown
  #   %Y = modification time as seconds since Epoch
  #
  # Some filesystems / mount options do not expose birth time.
  # In that case, fall back to mtime.
  EPOCH="$(stat -c '%W' -- "$FILE" 2>/dev/null || printf '0')"

  case "$EPOCH" in
    ''|0|-1)
      EPOCH="$(stat -c '%Y' -- "$FILE")"
      ;;
  esac

  date -d "@$EPOCH" +%Y%m%d-%H%M%S
}

archived_backup_path() {
  FILE="$1"
  TS="$(file_timestamp "$FILE")"

  CANDIDATE="$FILE.$TS.bak"
  if [ ! -e "$CANDIDATE" ]; then
    printf '%s\n' "$CANDIDATE"
    return 0
  fi

  N=1
  while :; do
    CANDIDATE="$FILE.$TS.$N.bak"
    if [ ! -e "$CANDIDATE" ]; then
      printf '%s\n' "$CANDIDATE"
      return 0
    fi
    N=$((N + 1))
  done
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

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-backup.XXXXXX)"
TMP_TAR="$TMP_DIR/ssh-backup.tar.gz"
TMP_LIST="$TMP_DIR/include.txt"
TMP_BACKUP_FILE="$(mktemp "$BACKUP_DIR/.${BACKUP_NAME}.XXXXXX")"

cleanup() {
  rm -rf -- "$TMP_DIR"
  rm -f -- "$TMP_BACKUP_FILE"
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

# mktemp creates the file first.
# Remove it so gpg can create it cleanly without overwrite prompts.
rm -f -- "$TMP_BACKUP_FILE"
gpg -c --output "$TMP_BACKUP_FILE" "$TMP_TAR"

chmod 600 "$TMP_BACKUP_FILE" 2>/dev/null || true

# Rotate the existing backup only after the new encrypted backup was created.
if [ -e "$BACKUP_FILE" ]; then
  OLD_FILE="$(archived_backup_path "$BACKUP_FILE")"
  echo "[ssh] notice: existing backup found."
  echo "[ssh] move old backup to: $OLD_FILE"
  mv -- "$BACKUP_FILE" "$OLD_FILE"
fi

mv -- "$TMP_BACKUP_FILE" "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE" 2>/dev/null || true

# Prevent cleanup from removing the final backup after mv.
TMP_BACKUP_FILE=""

echo "[ssh] done."
echo "[ssh] encrypted backup: $BACKUP_FILE"
