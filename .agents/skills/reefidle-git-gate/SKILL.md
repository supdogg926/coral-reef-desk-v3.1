---
name: reefidle-git-gate
description: ReefIdle / CoralReefDesk Git safety gate. Use before any code-writing task in this repository to verify branch, clean working tree, task baseline HEAD, M10 tag presence, and prohibited Git operations.
---

# reefidle-git-gate

用途：ReefIdle / CoralReefDesk 每次开工前的 Git 安全门禁。

## 执行命令

```powershell
cd "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
git branch --show-current
git status --short
git log -8 --oneline
git rev-parse HEAD
git tag --list "v3.1-m10-livestock-core"
```

## 通过条件

- 当前分支必须是 `prototype/m11-biomanage-vertical-slice`。
- `git status --short` 必须为空。
- `v3.1-m10-livestock-core` 必须存在。
- HEAD 必须匹配当前任务指定基线。
- `main` 不允许被改动。
- 不允许自动 merge、tag、rebase。

## 失败处理

只要任何一项不一致：

- 立即停止。
- 不写代码。
- 不修复。
- 不切分支。
- 只回传 Git 状态等待用户判断。
