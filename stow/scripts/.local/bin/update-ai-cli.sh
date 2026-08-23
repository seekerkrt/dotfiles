#!/usr/bin/env bash

set -uo pipefail

failed=0

update_cli() {
    local name="$1"
    local cmd="$2"

    printf '\n=== %s ===\n' "$name"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'status: SKIP (%s not found in PATH)\n' "$cmd"
        return
    fi

    local path before after rc

    path=$(command -v "$cmd")
    before=$("$cmd" --version 2>&1 || true)

    printf 'path:   %s\n' "$path"
    printf 'before: %s\n' "$before"

    printf '%s\n' '--- update ---'

    "$cmd" update
    rc=$?

    printf '%s\n' '--------------'

    # updater が実体を差し替えた場合に備えて shell の command hash を破棄
    hash -r

    after=$("$cmd" --version 2>&1 || true)

    printf 'after:  %s\n' "$after"

    if (( rc != 0 )); then
        printf 'status: FAILED (exit=%d)\n' "$rc"
        failed=1
    elif [[ "$before" == "$after" ]]; then
        printf 'status: OK (already latest / unchanged)\n'
    else
        printf 'status: UPDATED\n'
    fi
}

printf '%s\n' '=== AI CLI updater ==='

update_cli "Codex CLI"       codex
update_cli "Claude Code"     claude
update_cli "Grok CLI"        grok
update_cli "Antigravity CLI" agy

printf '\n=== done ===\n'

exit "$failed"
