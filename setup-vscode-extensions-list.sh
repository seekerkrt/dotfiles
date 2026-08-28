#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LIST="$DOTFILES/vscode/extensions-list.txt"

if ! command -v code >/dev/null 2>&1; then
    echo "error: 'code' command not found" >&2
    exit 1
fi

if [[ ! -f "$LIST" ]]; then
    echo "error: extension list not found: $LIST" >&2
    exit 1
fi

declare -A installed_extensions=()

while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    installed_extensions["$extension"]=1
done < <(code --list-extensions)

installed_count=0
skipped_count=0

while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    [[ "$extension" == \#* ]] && continue

    if [[ -n "${installed_extensions[$extension]:-}" ]]; then
        echo ":: Already installed: $extension"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    echo ":: Installing: $extension"
    code --install-extension "$extension"

    installed_count=$((installed_count + 1))
done < "$LIST"

echo
echo "Done."
echo "Installed: $installed_count"
echo "Already installed: $skipped_count"
