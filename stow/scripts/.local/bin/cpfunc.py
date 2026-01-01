#!/usr/bin/env python3
# cpfunc.py
#  - Extract a C/C++ function/method definition block by name.
#  - Robust-ish brace matcher:
#     * ignores // /* */ comments
#     * ignores "..." / '...' / R"(...)"
#     * tries to avoid braced-init like member{1} (not a body)
#     * filters obvious call-sites (obj->Func( / obj.Func( / if(Foo() && ...) { )
#
# usage: cpfunc.py <FuncNameOrQualified> <file>
#
import re
import sys
from pathlib import Path
from typing import Optional, Tuple

IDENT_CH = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")

def is_ident(ch: str) -> bool:
    return ch in IDENT_CH

def line_start(s: str, i: int) -> int:
    return s.rfind("\n", 0, i) + 1

def line_no(s: str, i: int) -> int:
    return s.count("\n", 0, i) + 1

def skip_ws(s: str, i: int) -> int:
    n = len(s)
    while i < n and s[i].isspace():
        i += 1
    return i

def skip_ws_and_comments(s: str, i: int) -> int:
    n = len(s)
    while i < n:
        ch = s[i]
        if ch.isspace():
            i += 1
            continue

        # line comment //
        if ch == "/" and i + 1 < n and s[i + 1] == "/":
            i += 2
            while i < n and s[i] != "\n":
                i += 1
            continue

        # block comment /* ... */
        if ch == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i = min(n, i + 2)
            continue

        break
    return i

def skip_string_like(s: str, i: int) -> int:
    """Assumes s[i] begins a string/char/raw-string; returns index after it."""
    n = len(s)
    ch = s[i]

    # raw string: R"delim( ... )delim"
    if ch == "R" and i + 1 < n and s[i + 1] == '"':
        j = i + 2
        while j < n and s[j] != "(":
            j += 1
        if j >= n:
            return n
        delim = s[i + 2 : j]  # may be empty
        end_seq = ")" + delim + '"'
        k = s.find(end_seq, j + 1)
        if k == -1:
            return n
        return k + len(end_seq)

    # normal string / char literal
    quote = ch  # " or '
    i += 1
    while i < n:
        c = s[i]
        if c == "\\":
            i += 2
            continue
        if c == quote:
            return i + 1
        i += 1
    return n

def find_matching(s: str, open_i: int, open_ch: str, close_ch: str) -> Optional[int]:
    """Find matching close for open at open_i, ignoring comments/strings."""
    n = len(s)
    depth = 0
    i = open_i
    while i < n:
        c = s[i]

        # comments
        if c == "/" and i + 1 < n and s[i + 1] == "/":
            i += 2
            while i < n and s[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i += 2
            continue

        # strings
        if c == '"' or c == "'" or (c == "R" and i + 1 < n and s[i + 1] == '"'):
            i = skip_string_like(s, i)
            continue

        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i

        i += 1
    return None

def prev_non_ws(s: str, i: int) -> int:
    j = i - 1
    while j >= 0 and s[j].isspace():
        j -= 1
    return j

def read_ident(s: str, i: int) -> Tuple[str, int]:
    """Read identifier at i (if any)."""
    n = len(s)
    j = i
    if j < n and (s[j].isalpha() or s[j] == "_"):
        j += 1
        while j < n and (s[j].isalnum() or s[j] == "_"):
            j += 1
        return s[i:j], j
    return "", i

def skip_requires_clause(s: str, i: int) -> int:
    """
    Very small subset:
      - if next token is '(' then skip balanced parentheses
      - else just return i (best effort)
    """
    i = skip_ws_and_comments(s, i)
    if i < len(s) and s[i] == "(":
        close = find_matching(s, i, "(", ")")
        if close is None:
            return len(s)
        return close + 1
    return i

def find_body_brace(s: str, i_after_params: int) -> Optional[int]:
    """
    From index right after ')', find the '{' that starts the function body.
    Heuristics:
      - if we hit ';' before '{' => declaration only
      - ignore braced-init like 'member{1}' (identifier immediately before '{')
      - reject common call-site patterns:
          * if immediately sees top-level '&&' or '||' before '{' (outside requires)
          * if sees an extra ')' very soon (handled elsewhere too)
      - allow 'requires(...)' (skip its parentheses)
    """
    n = len(s)
    i = skip_ws_and_comments(s, i_after_params)

    paren_depth = 0
    bracket_depth = 0
    in_requires = False

    while i < n:
        c = s[i]

        # comments
        if c == "/" and i + 1 < n and s[i + 1] == "/":
            i += 2
            while i < n and s[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i += 2
            continue

        # strings
        if c == '"' or c == "'" or (c == "R" and i + 1 < n and s[i + 1] == '"'):
            i = skip_string_like(s, i)
            continue

        # declaration ends
        if c == ";" and paren_depth == 0 and bracket_depth == 0:
            return None

        # track () []
        if c == "(":
            paren_depth += 1
            i += 1
            continue
        if c == ")":
            paren_depth = max(0, paren_depth - 1)
            i += 1
            continue
        if c == "[":
            bracket_depth += 1
            i += 1
            continue
        if c == "]":
            bracket_depth = max(0, bracket_depth - 1)
            i += 1
            continue

        # skip requires(...)
        if paren_depth == 0 and bracket_depth == 0:
            ident, j = read_ident(s, i)
            if ident == "requires":
                i = skip_requires_clause(s, j)
                continue

        # reject call-like condition chains: Foo() && Bar() { ... } / Foo() || Bar() { ... }
        if paren_depth == 0 and bracket_depth == 0 and i + 1 < n:
            if s[i:i+2] in ("&&", "||"):
                return None

        if c == "{":
            prev = s[i - 1] if i - 1 >= 0 else "\n"
            # reject identifier immediately before '{' (e.g., member{1})
            if is_ident(prev):
                i += 1
                continue
            return i

        i += 1

    return None

def include_template_lines(s: str, start: int) -> int:
    """
    If directly above start there are template / attribute lines, include them.
      template<...>
      [[...]]
      __attribute__((...))  (best effort: line starts with __attribute__)
    """
    cur = start
    while cur > 0:
        prev_nl = s.rfind("\n", 0, cur - 1)
        prev_line_start = 0 if prev_nl < 0 else prev_nl + 1
        line = s[prev_line_start:cur].rstrip("\n")
        stripped = line.strip()

        if stripped.startswith("template") or stripped.startswith("[[") or stripped.startswith("__attribute__"):
            cur = prev_line_start
            continue
        break
    return cur

def is_obvious_call_site(s: str, name_start: int) -> bool:
    """
    Reject common call-sites:
      obj.Func( / obj->Func(
    """
    j = prev_non_ws(s, name_start)
    if j >= 0 and s[j] == ".":
        return True
    if j >= 1 and s[j] == ">" and s[j - 1] == "-":
        return True
    return False

def extract(s: str, name: str) -> Optional[Tuple[int, int]]:
    # match name(
    if "::" in name:
        pat = re.compile(re.escape(name) + r"\s*\(")
    else:
        pat = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(name) + r"\s*\(")

    for m in pat.finditer(s):
        if is_obvious_call_site(s, m.start()):
            continue

        open_paren = s.find("(", m.start(), m.end())
        if open_paren == -1:
            continue

        close_paren = find_matching(s, open_paren, "(", ")")
        if close_paren is None:
            continue

        # if (Foo()) { ... } の "外側の )" を踏んでる可能性を潰す
        j = skip_ws_and_comments(s, close_paren + 1)
        if j < len(s) and s[j] == ")":
            continue

        body_start = find_body_brace(s, close_paren + 1)
        if body_start is None:
            continue

        body_end = find_matching(s, body_start, "{", "}")
        if body_end is None:
            continue

        start = line_start(s, m.start())
        start = include_template_lines(s, start)
        return start, body_end + 1

    return None

def usage(code: int = 0) -> int:
    print("usage: cpfunc.py <FuncNameOrQualified> <file>", file=sys.stderr)
    print("  example: cpfunc.py Window::Resize src/gui/wm/Window.cpp", file=sys.stderr)
    print("  note: pass qualified name if ambiguous (e.g. Window::Resize)", file=sys.stderr)
    return code

def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] in ("-h", "--help"):
        return usage(0)

    if len(sys.argv) != 3:
        return usage(2)

    name = sys.argv[1]
    path = Path(sys.argv[2])

    try:
        data = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        print(f"[cpfunc] failed to read: {path} ({e})", file=sys.stderr)
        return 1

    res = extract(data, name)
    if res is None:
        print(f"[cpfunc] not found: {name} in {path}", file=sys.stderr)
        return 1

    a, b = res
    sys.stdout.write(data[a:b].rstrip() + "\n")
    la = line_no(data, a)
    lb = line_no(data, b)
    print(f"[cpfunc] {path}:{la}-{lb}", file=sys.stderr)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
