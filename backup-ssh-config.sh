#!/usr/bin/env sh
set -eu

BACKUP_REL_PATH="encrypted/ssh-config.tar.gz.gpg"
SOURCE_FILE="$HOME/.ssh/config"

usage() {
  cat >&2 <<USAGE
usage:
  $0 [BACKUP_FILE]

description:
  Backup ~/.ssh/config as an encrypted GPG archive.

default:
  BACKUP_FILE = ./encrypted/ssh-config.tar.gz.gpg
USAGE
}

script_dir() {
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd
}

if [ "$#" -gt 1 ]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(script_dir)"
BACKUP_FILE="${1:-$SCRIPT_DIR/$BACKUP_REL_PATH}"
BACKUP_DIR="$(dirname -- "$BACKUP_FILE")"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "[ssh-config] error: source file not found: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p -- "$BACKUP_DIR"

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-config-backup.XXXXXX)"
TMP_OUT="$(mktemp "$BACKUP_DIR/.ssh-config.tar.gz.gpg.XXXXXX")"

cleanup() {
  rm -rf -- "$TMP_DIR"
  rm -f -- "$TMP_OUT"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_DIR/.ssh"
cp -- "$SOURCE_FILE" "$TMP_DIR/.ssh/config"
chmod 600 "$TMP_DIR/.ssh/config"

rm -f -- "$TMP_OUT"

echo "[ssh-config] backup from: $SOURCE_FILE"
echo "[ssh-config] backup to:   $BACKUP_FILE"

tar -C "$TMP_DIR" -czf - .ssh/config \
  | gpg -c --output "$TMP_OUT"

chmod 600 "$TMP_OUT" 2>/dev/null || true
mv -- "$TMP_OUT" "$BACKUP_FILE"
TMP_OUT=""

echo "[ssh-config] done."
echo "[ssh-config] encrypted backup: $BACKUP_FILE"
