#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="$HOME/dotfiles/pkglist"
mkdir -p "$OUT_DIR"

pacman -Qqe > "$OUT_DIR/official.txt"
pacman -Qqm > "$OUT_DIR/foreign.txt"
