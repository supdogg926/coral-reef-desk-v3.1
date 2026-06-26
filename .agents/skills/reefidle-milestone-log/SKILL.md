---
name: reefidle-milestone-log
description: ReefIdle / CoralReefDesk milestone and daily closeout logging workflow. Use when writing end-of-day reports, milestone logs, handoff notes, or task closeout summaries for this repository.
---

# reefidle-milestone-log

用途：封装 ReefIdle / CoralReefDesk 每日工作日志。

## 必须包含

每日收工日志必须包含：

- 今天提出了哪些想法。
- 今天实际完成了哪些内容。
- 遇到了哪些问题。
- 每个问题是如何解决的。
- 哪些问题暂时没有解决。
- 当前 Git 分支。
- 当前 commit hash。
- 是否 push。
- 工作区是否 clean。
- 下一次开工第一条只读核验命令。
- 明确禁止项，例如不合并 `main`、不打 tag、不改 M11 tag。

## 当前基线

- Tag: `v3.1-m11-acceptance-harness`
- 验收: `M11_ACCEPTANCE_RESULT=PASS`

## 输出风格

- 中文。
- 简报式。
- 以事实为准。
- 不夸大。
- 不把未验收内容写成已完成。
- 自治执行任务使用 `docs/tech/FINAL_REPORT_TEMPLATE.md` 格式。
