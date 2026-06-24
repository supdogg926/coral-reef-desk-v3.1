#!/usr/bin/env python3
"""
ReefIdle Codex PostToolUse review template.

用途：

工具执行后提醒输出 git diff 摘要。
当前未自动接入 Codex 全局配置。
"""

import sys


def main() -> int:
    _ = sys.stdin.read()
    print(
        "ReefIdle reminder: before commit, run git status --short and git diff --stat.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
