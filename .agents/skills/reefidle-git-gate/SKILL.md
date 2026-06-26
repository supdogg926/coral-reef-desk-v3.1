---
name: reefidle-git-gate
description: ReefIdle / CoralReefDesk Git safety gate. Use before any code-writing task in this repository to verify branch, clean working tree, task baseline HEAD, M11 tag presence, and prohibited Git operations.
---

# reefidle-git-gate

用途：ReefIdle / CoralReefDesk 每次开工前的 Git 安全门禁。

## 执行命令

```powershell
cd "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
git fetch --all --tags
git checkout prototype/m11-biomanage-vertical-slice
git status
git rev-parse HEAD
git tag --points-at HEAD
```

## 通过条件

- 当前分支必须是 `prototype/m11-biomanage-vertical-slice`。
- `git status` 必须 clean。
- `v3.1-m11-acceptance-harness` tag 必须存在于 HEAD。
- HEAD 必须为 `c2f1a05` 或其 parent 为 functional baseline `8741282`。
- `main` 不允许被改动。
- 不允许自动 merge、tag、rebase。

## 验收门槛

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m11_acceptance.ps1
```

必须输出 `M11_ACCEPTANCE_RESULT=PASS`。

## 失败处理

只要任何一项不一致：

- 立即停止。
- 不写代码。
- 不修复。
- 不切分支。
- 只回传 Git 状态等待用户判断。
