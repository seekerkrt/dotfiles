#!/usr/bin/env bash
# codex-rules-gate.py の回帰テスト。
# none = stdout 空 かつ exit 0。各 command はJSONの文字列として渡すだけ。
set -uo pipefail

GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/codex-rules-gate.py"
RULES_FIXTURE="$(dirname "$GATE")/fixtures/rules"

# 入力コマンドをゲートへ流し、"allow" / "deny" / "ask" / "none" / "error:N" を返す。
run_gate_payload() {
    local out status
    out=$(CODEX_RULES_DIR="$RULES_FIXTURE" python3 "$GATE")
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

run_gate() {
    printf '%s' "$1" \
        | python3 -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"command":sys.stdin.read()}}))' "$2" \
        | run_gate_payload
}

CASES=(
    $'make\nunapproved-command|none'
    $'make\r\nunapproved-command|none'
    $'make\runapproved-command|none'
    'make && unapproved-command|none'
    'make; unapproved-command|none'
    'make test|allow'
    'unapproved-command|none'
    $'make "quoted\nargument"|none'
    $'make \\\n test|none'
    $'make test\n|none'
    'make; make test|none'
    'make &&|none'
    "make '|' make|none"
    'gh pr list --limit 5|allow'
    'gh pr list --state all --limit 3 2>&1|none'
    'git status --short|none'
    'git log -p -1|none'
    'git diff --check|none'
    'git branch|none'
    'git branch --list|none'
    'git branch --list topic|none'
    'git branch --show-current|none'
    'git branch -av|none'
    'git status && git log -1|none'
    'git diff --output=report|ask'
    'git diff --ext-diff|ask'
    'git branch topic|ask'
    'git branch -m topic|ask'
    'git branch -Dtopic|ask'
    'git branch --set-upstream-to origin/main|ask'
    'git add -- file|ask'
    'git commit -m "test"|ask'
    'git push|ask'
    'git reset --hard|ask'
    'git clean -fd|ask'
    'git tag new-tag|ask'
    'git remote set-url origin example.test|ask'
    'git -C . branch topic|ask'
    '/usr/bin/git branch topic|ask'
    'command git branch topic|ask'
    'GIT_OPTION=value git branch topic|ask'
    "sh -c 'git branch topic'|ask"
    'unapproved-command && git branch topic|ask'
    'make && git add -- file|ask'
    $'make\ngit branch topic|ask'
    'git branch "unterminated|ask'
    'git branch topic >/dev/null|ask'
    'git status $(git branch topic)|ask'
    "git status; 'git' branch topic|ask"
    'env -u MAKEFLAGS -u MFLAGS make test|allow'
    'make 2>/dev/null|none'
    'gh issue create --title x|none'
    'make && rm -rf disposable|ask'
    '/usr/bin/rm disposable|ask'
    'make $(unknown-command)|none'
    'make > output.log|none'
    'make $TARGET|none'
    'make target*|none'
    'review-command --fast|ask'
    'restricted-command --fast|deny'
    'unknown-command && restricted-command|deny'
    'review-command && restricted-command|deny'
    'git push && restricted-command|deny'
)

C1_CASES=(
    'legacy-restricted-command 2>&1|deny'
    'legacy-restricted-command >/dev/null|deny'
    'restricted-command --fast 2>&1|deny'
    'restricted-command > output.log|deny'
    'restricted-command > "$OUTPUT"|deny'
    'review-command --fast 2>&1|ask'
    'review-command &>> output.log|ask'
    'unknown-command | restricted-command 2>&1|deny'
    'review-command 2>&1 && restricted-command </dev/null|deny'
    '> output.log restricted-command|deny'
    '> "$OUTPUT" restricted-command|deny'
    'restricted-command 2>&1 --fast|deny'
    'make test >> output.log|none'
    'make test < input.txt|none'
    'make test <<EOF|none'
    'make >| output.log|none'
    'make 2>&1 && make test|none'
    "printf %s ';' restricted-command|none"
    'printf %s "&&" restricted-command|none'
    'printf %s ">" restricted-command|none'
    "printf %s ';' && restricted-command|deny"
    "git diff -- '*.md'|none"
    'git diff -- "*.md"|none'
    'git diff -- "*.md" > output.log|none'
    'git diff -- "$(unknown-command)"|ask'
    "git diff -- ':(glob)**/*.py'|none"
    'git -C . status --short|none'
    'git -C . branch fixture 2>&1|ask'
    'git push > output.log|ask'
    'git add -- file 2>&-|ask'
    'git diff $(unknown-command)|ask'
    'git diff -- "*.md" && git clean -fd|ask'
    'git -C . -c test.option=value status|ask'
)

C2_CASES=(
    '>/dev/null; legacy-restricted-command|deny'
    '>/dev/null && review-command|ask'
    'make test; >/dev/null; restricted-command|deny'
    '>/dev/null | review-command|ask'
    '>/dev/null; make test|none'
    'make test && >/dev/null|none'
    '>; restricted-command|none'
    '>/dev/null && ; restricted-command|none'
    'literal-restricted-command red\ blue >/dev/null|deny'
    'literal-restricted-command "red blue" >/dev/null|deny'
    'literal-review-command red\ blue|ask'
    "literal-review-command 'red blue'|ask"
    'literal-restricted-command "red\"blue"|deny'
    'literal-restricted-command "\$label"|deny'
    'literal-restricted-command "\q"|deny'
    'literal-restricted-command "$label"|none'
    'literal-restricted-command red\|none'
    'printf %s \; restricted-command|none'
    'make red\ blue|none'
    'g\it branch fixture|ask'
)

pass=0
fail=0

check() {
    local display_cmd expect actual mark
    display_cmd=$1
    expect=$2
    actual=$3
    if [ "$actual" = "$expect" ]; then
        mark='PASS'
        pass=$((pass + 1))
    else
        mark='FAIL'
        fail=$((fail + 1))
    fi
    printf '%-6s %-42s %-8s %-8s\n' "$mark" "$display_cmd" "$expect" "$actual"
}

printf '%-6s %-42s %-8s %-8s\n' 'RESULT' 'COMMAND' 'EXPECT' 'ACTUAL'
printf '%.0s-' {1..70}; printf '\n'

for entry in "${CASES[@]}" "${C1_CASES[@]}" "${C2_CASES[@]}"; do
    cmd="${entry%|*}"
    expect="${entry##*|}"
    printf -v display_cmd '%q' "$cmd"
    check "$display_cmd" "$expect" "$(run_gate "$cmd" Bash)"
done
check 'Monitor: git branch topic' ask "$(run_gate 'git branch topic' Monitor)"
check 'Monitor: restricted-command 2>&1' deny "$(run_gate 'restricted-command 2>&1' Monitor)"
check 'Monitor: WebSocket delegated' none "$(run_gate_payload <<< '{"tool_name":"Monitor","tool_input":{"ws":{"url":"ws://example.test"}}}')"
check 'Read: ignored' none "$(run_gate 'git branch topic' Read)"
check 'invalid JSON' deny "$(run_gate_payload <<< '{')"
check 'invalid Bash payload' deny "$(run_gate_payload <<< '{"tool_name":"Bash","tool_input":[]}')"

printf '%.0s-' {1..70}; printf '\n'
printf '%d/%d passed\n' "$pass" "$((pass + fail))"

# 読込失敗用のfixtureはStowの配布treeやlive rulesへ書かない。
python3 - "$GATE" "$RULES_FIXTURE" <<'PY' || exit 1
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory

gate, fixture = sys.argv[1:]

with TemporaryDirectory(prefix="codex-rules-gate.") as temp:
    root = Path(temp)
    empty = root / "empty"
    empty.mkdir()
    invalid = root / "invalid"
    invalid.mkdir()
    invalid_rule = invalid / "broken.rules"
    invalid_rule.write_text("prefix_rule(", encoding="utf-8")
    partial = root / "partial"
    partial.mkdir()
    (partial / "a.rules").write_text('prefix_rule(pattern=["make"])', encoding="utf-8")
    (partial / "z.rules").write_text('prefix_rule(pattern=unknown)', encoding="utf-8")
    unreadable = root / "unreadable"
    unreadable.mkdir()
    (unreadable / "broken.rules").symlink_to(root / "absent")
    dangling = root / "dangling"
    dangling.symlink_to(root / "absent", target_is_directory=True)

    cases = [
        ("default directory absent", None, "make test", "none"),
        ("empty override uses default", "", "make test", "none"),
        ("explicit directory absent", root / "absent", "make test", "deny"),
        ("explicit empty directory", empty, "make test", "none"),
        ("valid rules without a match", fixture, "unknown-command", "none"),
        ("invalid directory type", invalid_rule, "make test", "deny"),
        ("dangling directory", dangling, "make test", "deny"),
        ("unreadable rules", unreadable, "make test", "deny"),
        ("syntax error", invalid, "make test", "deny"),
        ("partial load cannot allow", partial, "make test", "deny"),
        ("partial load cannot fall back", partial, "unknown-command", "deny"),
        ("unsupported command still checks policy", partial, "make $(unknown-command)", "deny"),
    ]
    def check_rules(label, directory, command, expected, home=root):
        env = {**os.environ, "HOME": str(home)}
        env.pop("CODEX_RULES_DIR", None)
        if directory is not None:
            env["CODEX_RULES_DIR"] = str(directory)
        payload = {"tool_name": "Bash", "tool_input": {"command": command}}
        run = subprocess.run(
            [sys.executable, gate], input=json.dumps(payload), env=env,
            capture_output=True, text=True, check=True,
        )
        verdict = json.loads(run.stdout)["hookSpecificOutput"] if run.stdout else {}
        actual = verdict.get("permissionDecision", "none")
        assert actual == expected, (label, expected, actual)
        if actual == "deny":
            assert "Codex rules" in verdict["permissionDecisionReason"], label
        print(f"PASS   rules load: {label} ({actual})")

    for case in cases:
        check_rules(*case)
    print(f"{len(cases)}/{len(cases)} rules-load cases passed")

    default_empty = root / "default-empty"
    (default_empty / ".codex/rules").mkdir(parents=True)
    shared = root / "shared"
    shared.mkdir()
    (shared / "rules").symlink_to(fixture, target_is_directory=True)
    good_parent = root / "good-parent"
    good_parent.mkdir()
    (good_parent / ".codex").symlink_to(shared, target_is_directory=True)
    parent_no_rules = root / "parent-no-rules"
    parent_no_rules.mkdir()
    (parent_no_rules / ".codex").symlink_to(empty, target_is_directory=True)
    broken_rules = root / "broken-rules"
    (broken_rules / ".codex").mkdir(parents=True)
    (broken_rules / ".codex/rules").symlink_to(root / "absent", target_is_directory=True)
    broken_parent = root / "broken-parent"
    broken_parent.mkdir()
    (broken_parent / ".codex").symlink_to(root / "absent", target_is_directory=True)

    c2_cases = [
        ("default empty directory", None, "make test", "none", default_empty),
        ("valid parent link with rules", None, "make test", "allow", good_parent),
        ("valid parent link without rules", None, "make test", "none", parent_no_rules),
        ("broken default rules link", None, "make test", "deny", broken_rules),
        ("broken default parent link", None, "make test", "deny", broken_parent),
    ]
    for case in c2_cases:
        check_rules(*case)
    print(f"{len(c2_cases)}/{len(c2_cases)} C2 rules-path cases passed")
PY

[ "$fail" -eq 0 ]
