#!/usr/bin/env python3
"""
ReefIdle Codex PreToolUse policy template.

低风险模板：

默认只分析 stdin 中的命令文本。
如果检测到危险 Git / Godot 操作，返回非 0。
当前未自动接入 Codex 全局配置。
"""

import json
import re
import sys


def main() -> int:
    raw = sys.stdin.read()

    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {"raw": raw}

    text = json.dumps(payload, ensure_ascii=False)

    blocked_patterns = [
        r"\bgit\s+checkout\s+main\b",
        r"\bgit\s+switch\s+main\b",
        r"\bgit\s+merge\s+main\b",
        r"\bgit\s+rebase\s+main\b",
        r"\bgit\s+tag\b",
        r"\bgit\s+tag\s+-d\b",
        r"\bgit\s+push\s+.*:refs/tags/",
        r"project\.godot",
    ]

    for pattern in blocked_patterns:
        if re.search(pattern, text, flags=re.IGNORECASE):
            print(f"BLOCKED by ReefIdle policy: {pattern}", file=sys.stderr)
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
