# ReefIdle 最终报告模板 v1.0

## 用途

Codex / Claude Code 完成自治执行任务后，按此模板输出最终报告。报告面向用户（人工审查者），不含执行层内部细节。

---

# [任务代号] 完成报告

**任务**: [任务名称和代号]
**执行时间**: [开始] → [结束]
**执行模式**: 自治执行 (Level 1) / 人工确认
**基线**: `v3.1-m11-acceptance-harness` @ `c2f1a05`

---

## 1. 验收结果

| 验收层 | 结果 |
|--------|------|
| M11 Acceptance | PASS / FAIL |
| M12 Acceptance (如适用) | PASS / FAIL |
| Visual QA | [N] issues found, [M] resolved |

**Gate 状态**: 允许提交 / 禁止提交

---

## 2. 修改文件清单

```
[file path]          [+N / -N]  [简短说明]
...
```

**总计**: N files changed, +X / -Y lines

---

## 3. 功能变更摘要

- [变更点 1]
- [变更点 2]
- ...

---

## 4. Godot 运行验证

| 验证项 | 方式 | 结果 |
|--------|------|------|
| Smoke test | headless | PASS/FAIL |
| Acceptance suite | headless | PASS/FAIL |
| Visual check | Editor + 截图 | PASS/FAIL |
| Output/Debugger | Editor | 无错误 / 有错误 |

---

## 5. Visual QA 摘要

- 本轮收集可见问题: [N]
- 已修复: [M]
- 遗留（非阻塞）: [K]
- 详情: `reports/visual_qa/round_N/`

---

## 6. Git 状态

```
Branch:   prototype/m11-biomanage-vertical-slice
HEAD:     [commit hash]
Status:   clean / [N] modified
Tag:      v3.1-m11-acceptance-harness
Pushed:   yes / no
```

---

## 7. 风险评估

| 风险项 | 等级 | 说明 |
|--------|------|------|
| Save 兼容 | NONE / LOW / HIGH | ... |
| UI 回归 | NONE / LOW / HIGH | ... |
| 性能退化 | NONE / LOW / HIGH | ... |
| 分支偏离 | NONE / LOW / HIGH | ... |

---

## 8. 下一轮建议

- [建议的下一步操作]
- [需要用户注意的事项]

---

## 版本历史

- v1.0 (2026-06-26): 初始报告模板，8 个必要章节
