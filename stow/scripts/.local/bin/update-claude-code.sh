#!/usr/bin/env sh

set -eu

# RESPONSIBILITY:
# Claude Code CLIをnpmでグローバル導入し、正常に実行できることを確認する。
#
# NOTE:
# Claude Codeはpostinstallでプラットフォーム固有のネイティブ
# バイナリを導入するため、このパッケージに限ってinstall scriptを
# 明示的に許可する。

printf '%s\n' 'Installing Claude Code CLI...'

npm install -g \
    --allow-scripts=@anthropic-ai/claude-code \
    @anthropic-ai/claude-code@latest

npm i -g ccstatusline@latest

# シェルがコマンドパスをキャッシュしている場合に備えて更新する。
hash -r 2>/dev/null || true

if version_output="$(claude --version 2>&1)"; then
    if [ -z "$version_output" ]; then
        printf '%s\n' 'Claude Code installation verification failed: --version returned no output.' >&2
        exit 1
    fi
else
    version_status=$?
    printf 'Claude Code installation verification failed: --version exited with %s.\n' \
        "$version_status" >&2

    if [ -n "$version_output" ]; then
        printf '%s\n' "$version_output" >&2
    fi

    exit "$version_status"
fi

printf 'Claude Code CLI installed: %s\n' "$version_output"
