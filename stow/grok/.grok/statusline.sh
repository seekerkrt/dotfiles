#!/usr/bin/env python3
"""Status row: model, cwd, branch, context, cost, session name.

Missing fields are omitted. Cost under $0.005 is omitted, matching the
built-in cost item. Branch comes from workspace.branch and is absent on a
detached HEAD.
"""

import json
import os
import sys

AMBER = "\033[33m"
RESET = "\033[0m"


def elide(text, limit):
    if len(text) <= limit:
        return text
    if limit <= 1:
        return text[:limit]
    return text[: limit - 1] + "…"


def basename(path):
    trimmed = path.rstrip("/")
    name = os.path.basename(trimmed)
    return name or trimmed


def as_number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return value


def format_cost(value):
    amount = as_number(value)
    if amount is None or amount < 0.005:
        return None
    if amount >= 1:
        return f"${amount:.2f}"
    return f"${amount:.3f}"


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 1
    if not isinstance(data, dict):
        return 1

    workspace = data.get("workspace")
    if not isinstance(workspace, dict):
        workspace = {}
    context = data.get("context_window")
    if not isinstance(context, dict):
        context = {}
    model = data.get("model")
    if not isinstance(model, dict):
        model = {}
    cost = data.get("cost")
    if not isinstance(cost, dict):
        cost = {}

    parts = []

    model_name = model.get("display_name")
    if isinstance(model_name, str) and model_name:
        parts.append(elide(model_name, 30))

    directory = data.get("cwd")
    if not isinstance(directory, str) or not directory:
        directory = workspace.get("current_dir")
    if isinstance(directory, str) and directory:
        parts.append(elide(basename(directory), 40))

    branch = workspace.get("branch")
    if isinstance(branch, str) and branch:
        parts.append(elide(branch, 40))

    percent = as_number(context.get("used_percentage"))
    if percent is not None:
        label = f"{int(round(percent))}% ctx"
        threshold = as_number(context.get("auto_compact_threshold_percent"))
        warn_at = 80 if threshold is None else threshold
        if percent >= warn_at:
            label = f"{AMBER}{label}{RESET}"
        parts.append(label)

    cost_label = format_cost(cost.get("total_cost_usd"))
    if cost_label is not None:
        parts.append(cost_label)

    session_name = data.get("session_name")
    if isinstance(session_name, str) and session_name:
        parts.append(elide(session_name, 40))

    if parts:
        sys.stdout.write(" │ ".join(parts) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
