#!/usr/bin/env python3
"""Codex の prefix_rule を Claude Code の Bash / Monitor PreToolUse 判定に流用する。

~/.codex/rules/*.rules のリテラルを読み取り、ファイルは実行しない。
Codex の allow は単純な非 Git コマンドに限る。Git の変更と削除は
Claude 側で承認を求め、その他の未判定は Claude 本体の権限評価へ渡す。

環境変数:
  CODEX_RULES_DIR  ルールディレクトリ（未設定・空なら ~/.codex/rules）
  CODEX_RULES_DEBUG  1 なら判定理由を stderr に出す
"""

from __future__ import annotations

import ast
import json
import os
import re
import sys
from pathlib import Path
from typing import NoReturn

RULES_OVERRIDE = os.environ.get("CODEX_RULES_DIR")
RULES_DIR = Path(RULES_OVERRIDE) if RULES_OVERRIDE else Path.home() / ".codex" / "rules"
DEBUG = os.environ.get("CODEX_RULES_DEBUG") == "1"

# allow の入力範囲は従来どおり絞る。字句解析で認識したリダイレクトを
# 除いて照合するのは deny / ask のためで、書き込み先は Claude 本体が評価する。
SHELL_SYNTAX_BLOCKS_ALLOW = re.compile(r"[\r\n\\$\x60()<>{}\[\]*?~#!;&|]")
SHELL_QUOTING = re.compile(r"""'[^'\r\n]*'|"(?:[^"\\$\x60\r\n]|\\[^\r\n])*"|\\[^\r\n]""")
SHELL_TOKEN = re.compile(
    r"(?P<space>[ \t]+)"
    r"|(?P<redirect>&>>?|[0-9]*(?:>>|>\||>&|<&|<>|>|<(?!<)))"
    r"|(?P<separator>&&|\|\||\|&|[;&|])"
    rf"""|(?P<word>(?:{SHELL_QUOTING.pattern}|[^ \t\r\n'"\\$\x60(){{}}\[\]*?~#!;&|<>])+)"""
)
REDIRECT_VARIABLE = r"\$(?:[a-zA-Z_][a-zA-Z_0-9]*|\{[a-zA-Z_][a-zA-Z_0-9]*\})"
REDIRECT_TARGET = re.compile(rf'(?P<word>"{REDIRECT_VARIABLE}"|{REDIRECT_VARIABLE})')
WORD_END = " \t\r\n;&|<>"
NEEDS_NEXT_COMMAND = {"&&", "||", "|", "|&"}
PROTECTED_COMMAND = re.compile(r"(?<![\w.-])(?:git|rm|rmdir|unlink)(?![\w.-])")
DESTRUCTIVE_COMMANDS = {"rm", "rmdir", "unlink"}
GIT_READ_COMMANDS = {
    "status", "log", "diff", "show", "rev-parse", "rev-list", "ls-files",
    "ls-tree", "ls-remote", "for-each-ref", "merge-base", "blame", "grep",
}
BRANCH_LIST_FLAGS = {
    "--list", "--show-current", "--all", "--remotes", "--verbose", "--no-color",
}
WRAPPERS = {
    "bash", "sh", "dash", "zsh", "fish", "command", "builtin", "exec",
    "env", "time", "timeout", "nice", "nohup", "xargs", "find", "sudo",
    "if", "then", "elif", "else", "while", "until", "do",
}
DECISIONS = {"allow": "allow", "prompt": "ask", "forbidden": "deny", "ask": "ask", "deny": "deny"}
PRIORITY = {"allow": 0, "ask": 1, "deny": 2}
APPROVAL_REASON = "Git の変更・不明な操作や削除は明示承認が必要です。"


def normalize(pattern):
    """各引数位置の文字列または候補リストを集合にする。"""
    if not isinstance(pattern, (list, tuple)):
        return None
    slots = []
    for elem in pattern:
        if isinstance(elem, str):
            slots.append(frozenset({elem}))
        elif isinstance(elem, (list, tuple)) and elem and all(isinstance(x, str) for x in elem):
            slots.append(frozenset(elem))
        else:
            return None
    return slots or None


def load_rules():
    """すべてのルールが読めたときだけ、判定に使うスナップショットを返す。"""
    try:
        paths = sorted(RULES_DIR.iterdir())
    except FileNotFoundError:
        # Codex を未配置の環境でも使える。明示指定やリンク切れは設定異常。
        if RULES_OVERRIDE or RULES_DIR.is_symlink():
            raise
        parent = RULES_DIR.parent
        if parent.is_symlink():
            parent.stat()  # 親のリンク切れと、有効な親に rules がない状態を区別する。
        return []

    rules = []
    for path in paths:
        if not path.name.endswith(".rules"):
            continue
        try:
            if not path.is_file():
                raise ValueError("通常ファイルではありません")
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
            rules.extend(parse_rule(statement, path.name) for statement in tree.body)
        except (OSError, SyntaxError, ValueError, TypeError) as error:
            raise ValueError(f"{path.name}: {type(error).__name__}") from error
    return rules


def parse_rule(statement, filename):
    """実行せずに読めるリテラルの prefix_rule 呼び出しだけを受け付ける。"""
    node = statement.value if isinstance(statement, ast.Expr) else None
    if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Name):
        raise ValueError("prefix_rule 以外の文")
    if node.func.id != "prefix_rule" or node.args:
        raise ValueError("非対応の呼び出し")
    kw = {key.arg: key.value for key in node.keywords}
    if not kw.keys() <= {"pattern", "decision", "justification", "match", "not_match"}:
        raise ValueError("非対応の引数")
    if "pattern" not in kw or len(kw) != len(node.keywords):
        raise ValueError("pattern のないルールまたは重複引数")

    values = {key: ast.literal_eval(value) for key, value in kw.items()}
    slots = normalize(values["pattern"])
    decision = values.get("decision", "allow")
    note = values.get("justification", "")
    if slots is None or not isinstance(decision, str) or decision not in DECISIONS:
        raise ValueError("非対応の pattern または decision")
    if not isinstance(note, str):
        raise ValueError("非対応の justification")
    label = " ".join(sorted(slot)[0] if len(slot) == 1 else "{...}" for slot in slots)
    return slots, DECISIONS[decision], note or f"{filename}: {label}"


def literal_word(word):
    """字句解析で確定した語の引用とリテラルエスケープを解除する。"""
    def unquote(part):
        fragment = part[0]
        if fragment[0] == '"':
            # 二重引用符内では Bash が特別扱いする文字の前だけ外す。
            return re.sub(r'\\(["\\$\x60])', r"\1", fragment[1:-1])
        if fragment[0] == "'":
            return fragment[1:-1]
        return fragment[1:]

    return SHELL_QUOTING.sub(unquote, word)


def split_commands(command):
    """引用を保って字句を読み、リダイレクトを除いた argv を返す。

    対応外の構文に達した場合は、そこまでに確定した引数だけを制限の照合に使う。
    """
    groups, current = [], []
    offset = 0
    pending_redirect = False
    segment_complete = False
    needs_command = False
    while offset < len(command):
        # 単純な変数参照の宛先は値を解決せず、argv の照合からだけ外す。
        token = REDIRECT_TARGET.match(command, offset) if pending_redirect else None
        token = token or SHELL_TOKEN.match(command, offset)
        if token is None:
            break
        kind = token.lastgroup
        if kind == "word":
            # 展開や未完の引用とつながった語の一部分は argv とみなさない。
            if token.end() < len(command) and command[token.end()] not in WORD_END:
                break
            if pending_redirect:
                pending_redirect = False
            else:
                current.append(literal_word(token[0]))
            segment_complete = True
            needs_command = False
        elif kind == "redirect":
            if pending_redirect:
                break
            pending_redirect = True
        elif kind == "separator":
            if pending_redirect or not segment_complete:
                break
            # リダイレクトだけの区間は成立するが、prefix 照合へは渡さない。
            if current:
                groups.append(current)
            current = []
            segment_complete = False
            needs_command = token[0] in NEEDS_NEXT_COMMAND
        offset = token.end()

    if current:
        groups.append(current)
    return groups, offset == len(command) and not pending_redirect and not needs_command


def match(argv, rules):
    """prefix が一致する中で最も厳しい判定を使う。"""
    best = None
    for slots, decision, note in rules:
        if len(slots) <= len(argv) and all(arg in slot for arg, slot in zip(argv, slots)):
            if best is None or PRIORITY[decision] > PRIORITY[best[0]]:
                best = (decision, note)
    return best


def git_can_use_native_permissions(args):
    """一般的な参照形は Claude 本体の引数・パス判定へ渡す。"""
    if args[:2] == ["-C", "."]:
        args = args[2:]
    if not args:
        return True
    subcommand, *options = args
    if subcommand == "branch":
        return all(
            option in BRANCH_LIST_FLAGS
            or re.fullmatch(r"-[arv]+", option)
            or ("--list" in options and not option.startswith("-"))
            for option in options
        )
    if subcommand == "tag":
        return not options or options == ["--list"]
    if subcommand == "remote":
        return not options or options in (["-v"], ["--verbose"])
    if subcommand in GIT_READ_COMMANDS:
        return not any(
            option in {"--ext-diff", "--textconv"} or option.startswith(("--output", "--upload-pack"))
            for option in options
        )
    return subcommand in {"--version", "--help"} and not options


def needs_approval(argv):
    name = Path(argv[0]).name
    if name == "git":
        return not git_can_use_native_permissions(argv[1:])
    if name in DESTRUCTIVE_COMMANDS:
        return True
    if name in WRAPPERS or "=" in argv[0]:
        return any(PROTECTED_COMMAND.search(arg) for arg in argv[1:])
    return False


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
    except (ValueError, UnicodeError):
        emit("deny", "Bash の hook 入力を読めません。")
    if not isinstance(payload, dict):
        emit("deny", "Bash の hook 入力が不正です。")
    tool_name = payload.get("tool_name")
    if tool_name not in ("Bash", "Monitor"):
        bail("not Bash / Monitor")

    tool_input = payload.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if tool_name == "Monitor" and command is None and isinstance(tool_input, dict) and "ws" in tool_input:
        bail("Monitor WebSocket watch")
    if not isinstance(command, str) or not command.strip():
        emit("deny", "シェルコマンドを確認できません。")

    try:
        rules = load_rules()
    except (OSError, ValueError) as error:
        emit("deny", f"Codex rules を読み込めません。{error}")

    groups, complete = split_commands(command)
    hits = [hit for argv in groups if (hit := match(argv, rules)) is not None]
    best = max(hits, key=lambda hit: PRIORITY[hit[0]], default=None)
    if best and best[0] != "allow":
        emit(*best)
    if any(needs_approval(argv) for argv in groups) or (not complete and PROTECTED_COMMAND.search(command)):
        emit("ask", APPROVAL_REASON)

    if not best or not complete or SHELL_SYNTAX_BLOCKS_ALLOW.search(command):
        bail("no matching simple command")
    name = Path(groups[0][0]).name
    if name == "git" or name in WRAPPERS - {"env"}:
        bail("use native permissions for Git and shell wrappers")
    emit(*best)


if __name__ == "__main__":
    main()
