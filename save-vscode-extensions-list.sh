#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
OUTPUT="$DOTFILES/vscode/extensions-list.txt"

mkdir -p "$(dirname "$OUTPUT")"

code --list-extensions |
    sort -u > "$OUTPUT"

echo "Updated: $OUTPUT"
echo "Extensions: $(wc -l < "$OUTPUT")"
