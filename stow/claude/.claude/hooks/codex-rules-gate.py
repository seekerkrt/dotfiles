#!/usr/bin/env python3
"""Codex の prefix_rule を Claude Code の PreToolUse 判定に流用するゲート。

~/.codex/rules/*.rules を ast でパースし（exec はしない）、Bash ツールの
コマンドを argv に分解して prefix 一致を取る。判定できたときだけ
hookSpecificOutput を stdout に出し、それ以外は無出力 exit 0 で
Claude Code 本来の permission 評価にフォールバックする。

環境変数:
  CODEX_RULES_DIR  ルールディレクトリ（既定: ~/.codex/rules）
  CODEX_RULES_DEBUG  1 なら判定理由を stderr に出す
"""

from __future__ import annotations

import ast
import json
import os
import shlex
import sys
from pathlib import Path
from typing import NoReturn

RULES_DIR = Path(os.environ.get("CODEX_RULES_DIR") or Path.home() / ".codex" / "rules")
DEBUG = os.environ.get("CODEX_RULES_DEBUG") == "1"

# シェル演算子。ここでサブコマンドに分割し、全サブコマンドが allow のときだけ allow。
SEPARATORS = {"&&", "||", ";", "|", "|&", "&", "\n"}

# コマンド置換・プロセス置換・リダイレクトが混ざったら判定を放棄する。
# argv の prefix 一致では中身の安全性を保証できないため。
BAILOUT_TOKENS = {"(", ")", "<", "<<", "<<<"}
BAILOUT_SUBSTRINGS = ("$(", "`", "${")

# リダイレクト演算子と、書き込みを伴わない安全な宛先。
REDIRECT_OPS = {">", ">>", ">|", "&>", ">&", "<&"}
SAFE_TARGETS = {"/dev/null", "/dev/stdout", "/dev/stderr", "0", "1", "2", "-"}


def normalize(pattern):
    """["gh", ["issue","pr"], "list"] -> [ {gh}, {issue,pr}, {list} ]"""
    slots = []
    for elem in pattern:
        if isinstance(elem, str):
            slots.append(frozenset({elem}))
        elif isinstance(elem, (list, tuple)) and all(isinstance(x, str) for x in elem):
            slots.append(frozenset(elem))
        else:
            return None
    return slots or None


def load_rules():
    """prefix_rule(...) 呼び出しを静的に拾う。ファイルは評価しない。"""
    rules = []
    if not RULES_DIR.is_dir():
        return rules
    for path in sorted(RULES_DIR.glob("*.rules")):
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (OSError, SyntaxError, UnicodeDecodeError):
            continue
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            if not (isinstance(node.func, ast.Name) and node.func.id == "prefix_rule"):
                continue
            kw = {k.arg: k.value for k in node.keywords if k.arg}
            if "pattern" not in kw:
                continue
            try:
                pattern = ast.literal_eval(kw["pattern"])
                decision = ast.literal_eval(kw["decision"]) if "decision" in kw else "allow"
                note = ast.literal_eval(kw["justification"]) if "justification" in kw else ""
            except (ValueError, TypeError, SyntaxError):
                continue
            slots = normalize(pattern)
            if slots is None or decision not in ("allow", "deny", "ask"):
                continue
            label = " ".join(sorted(s)[0] if len(s) == 1 else "{...}" for s in slots)
            rules.append((slots, decision, note or f"{path.name}: {label}"))
    return rules


def strip_redirects(tokens):
    """リダイレクトを切り落とす。宛先が安全でなければ None。"""
    head, i = [], 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in REDIRECT_OPS:
            if i + 1 >= len(tokens) or tokens[i + 1] not in SAFE_TARGETS:
                return None
            i += 2
            continue
        head.append(tok)
        i += 1
    return head


def tokenize(command: str):
    """コマンド文字列を演算子込みでトークン化。解析不能なら None。"""
    if any(s in command for s in BAILOUT_SUBSTRINGS):
        return None
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:  # クォート不一致など
        return None
    if any(t in BAILOUT_TOKENS for t in tokens):
        return None
    return strip_redirects(tokens)


def split_subcommands(tokens):
    groups, current = [], []
    for tok in tokens:
        if tok in SEPARATORS:
            if current:
                groups.append(current)
            current = []
        else:
            current.append(tok)
    if current:
        groups.append(current)
    return groups


def match(argv, rules):
    """最長 prefix 一致。同じ長さなら先に書かれたルールが勝つ。"""
    best = None
    for slots, decision, note in rules:
        if len(slots) > len(argv):
            continue
        if all(argv[i] in alt for i, alt in enumerate(slots)):
            if best is None or len(slots) > best[0]:
                best = (len(slots), decision, note)
    return best


def emit(decision: str, reason: str) -> NoReturn:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": decision,
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
        ensure_ascii=False,
    )
    sys.stdout.write("\n")
    sys.exit(0)


def bail(why: str) -> NoReturn:
    if DEBUG:
        print(f"[codex-rules-gate] no decision: {why}", file=sys.stderr)
    sys.exit(0)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        bail("invalid stdin")

    if payload.get("tool_name") != "Bash":
        bail("not Bash")

    command = (payload.get("tool_input") or {}).get("command") or ""
    if not command.strip():
        bail("empty command")

    tokens = tokenize(command)
    if tokens is None:
        bail("unparseable / substitution / redirect")

    groups = split_subcommands(tokens)
    if not groups:
        bail("no subcommand")

    rules = load_rules()
    if not rules:
        bail("no rules loaded")

    reasons = []
    for argv in groups:
        hit = match(argv, rules)
        if hit is None:
            bail(f"unmatched: {' '.join(argv[:3])}")
        _, decision, note = hit
        if decision != "allow":
            emit(decision, note)
        reasons.append(note)

    emit("allow", "; ".join(dict.fromkeys(reasons)))


if __name__ == "__main__":
    main()
