#!/usr/bin/env sh
set -eu

BACKUP_REL_PATH="encrypted/ssh-config.tar.gz.gpg"
RESTORE_FILE="$HOME/.ssh/config"

usage() {
  cat >&2 <<USAGE
usage:
  $0 [BACKUP_FILE]

description:
  Restore ~/.ssh/config from an encrypted GPG archive.

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

if [ ! -f "$BACKUP_FILE" ]; then
  echo "[ssh-config] error: backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

umask 077

TMP_DIR="$(mktemp -d --tmpdir ssh-config-restore.XXXXXX)"

cleanup() {
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT INT TERM

echo "[ssh-config] restore from: $BACKUP_FILE"

gpg -d "$BACKUP_FILE" | tar -xzf - -C "$TMP_DIR"

if [ ! -f "$TMP_DIR/.ssh/config" ]; then
  echo "[ssh-config] error: archive does not contain .ssh/config" >&2
  exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -e "$RESTORE_FILE" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  OLD_FILE="$RESTORE_FILE.$TS.bak"
  echo "[ssh-config] notice: existing config found."
  echo "[ssh-config] move old config to: $OLD_FILE"
  mv -- "$RESTORE_FILE" "$OLD_FILE"
fi

cp -- "$TMP_DIR/.ssh/config" "$RESTORE_FILE"
chmod 600 "$RESTORE_FILE"

echo "[ssh-config] done."
echo "[ssh-config] restored: $RESTORE_FILE"
