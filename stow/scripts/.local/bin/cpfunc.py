def main() -> int:
    def usage(code: int = 0) -> int:
        print("usage: cpfunc.py <FuncNameOrQualified> <file>", file=sys.stderr)
        print("  example: cpfunc.py Window::Resize src/gui/wm/Window.cpp", file=sys.stderr)
        return code

    if len(sys.argv) >= 2 and sys.argv[1] in ("-h", "--help"):
        return usage(0)

    if len(sys.argv) != 3:
        return usage(2)

    name = sys.argv[1]
    path = Path(sys.argv[2])
    data = path.read_text(encoding="utf-8", errors="replace")

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
