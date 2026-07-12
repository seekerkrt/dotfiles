#!/usr/bin/env sh

set -u

# RESPONSIBILITY:
# npmでグローバル導入しているAI CLIをまとめて最新版へ更新する。
# AUR/pacman管理のAI CLIはこのスクリプトでは扱わない。
#
# NOTE:
# Claude Codeはpostinstallでプラットフォーム固有のネイティブ
# バイナリを導入するため、このパッケージに限ってinstall scriptを
# 明示的に許可する。
#
# npm installが終了コード0を返してもCLI本体が実行不能な場合があるため、
# 更新後に各CLIの --version を実行し、正常動作を検証する。

log() {
    printf '%s\n' "$*"
}

indent_output() {
    printf '%s\n' "$1" | sed 's/^/    /'
}

show_version() {
    label="$1"
    cmd="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "    ${label}: not installed"
        return 0
    fi

    version_output="$("$cmd" --version 2>&1)"
    version_status=$?

    if [ "$version_status" -ne 0 ]; then
        log "    ${label}: installed but not runnable (exit=${version_status})"

        if [ -n "$version_output" ]; then
            indent_output "$version_output"
        fi

        return 0
    fi

    if [ -n "$version_output" ]; then
        log "    ${label}: ${version_output}"
    else
        log "    ${label}: installed (version unknown)"
    fi
}

verify_version() {
    label="$1"
    cmd="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "    ${label}: FAILED (command not found)"
        return 127
    fi

    version_output="$("$cmd" --version 2>&1)"
    version_status=$?

    if [ "$version_status" -ne 0 ]; then
        log "    ${label}: FAILED (--version exit=${version_status})"

        if [ -n "$version_output" ]; then
            indent_output "$version_output"
        fi

        return "$version_status"
    fi

    if [ -z "$version_output" ]; then
        log "    ${label}: FAILED (--version returned no output)"
        return 1
    fi

    log "    ${label}: ${version_output}"
    return 0
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
        exit "$status"
    fi
}

log "AI CLI update script"
log "start: $(date '+%Y-%m-%d %H:%M:%S')"

log ""
log "Current versions (before update)"
show_version "codex" "codex"
show_version "claude" "claude"

run_step "Update OpenAI Codex CLI" \
    npm install -g \
    @openai/codex@latest

run_step "Update Claude Code CLI" \
    npm install -g \
    --allow-scripts=@anthropic-ai/claude-code \
    @anthropic-ai/claude-code@latest

# シェルがコマンドパスをキャッシュしている場合に備えて更新する。
hash -r 2>/dev/null || true

log ""
log "Versions after update"

if ! verify_version "codex" "codex"; then
    log ""
    log "AI CLI update verification failed."
    exit 1
fi

if ! verify_version "claude" "claude"; then
    log ""
    log "AI CLI update verification failed."
    exit 1
fi

log ""
log "All updates completed and verified successfully."
log "end: $(date '+%Y-%m-%d %H:%M:%S')"
