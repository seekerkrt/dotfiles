#!/usr/bin/env sh

set -u

# RESPONSIBILITY:
# npmでグローバル導入しているAI CLIをまとめて最新版へ更新する。
# AUR/pacman管理のAI CLIはこのスクリプトでは扱わない。
#
# NOTE:
# npmはinstall scriptを持つグローバルパッケージに対して、
# allow-scripts未承認の警告を表示する場合がある。
# 現在のnpm approve-scriptsはプロジェクトのpackage.json向けであり、
# npm install -gの承認状態を管理できないため、警告はそのまま扱う。

log() {
    printf '%s\n' "$*"
}

show_version() {
    label="$1"
    cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        version="$("$cmd" --version 2>/dev/null || true)"

        if [ -n "$version" ]; then
            log "    ${label}: ${version}"
        else
            log "    ${label}: installed (version unknown)"
        fi
    else
        log "    ${label}: not installed"
    fi
}

run_step() {
    name="$1"
    shift

    log ""
    log "==> ${name}"
    log "    command: $*"

    if "$@"; then
        log "==> ${name}: OK"
    else
        status=$?
        log "==> ${name}: FAILED (exit=${status})"
        exit "${status}"
    fi
}

log "AI CLI update script"
log "start: $(date '+%Y-%m-%d %H:%M:%S')"

log ""
log "Current versions (before update)"
show_version "codex" "codex"
show_version "claude" "claude"

run_step "Update OpenAI Codex CLI" \
    npm install -g @openai/codex@latest

run_step "Update Claude Code CLI" \
    npm install -g @anthropic-ai/claude-code@latest

log ""
log "Versions after update"
show_version "codex" "codex"
show_version "claude" "claude"

log ""
log "All updates completed successfully."
log "end: $(date '+%Y-%m-%d %H:%M:%S')"
