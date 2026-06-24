---
name: reefidle-godot-acceptance
description: ReefIdle / CoralReefDesk Godot prototype acceptance workflow. Use when validating visual UI behavior, Godot runtime behavior, screenshots, Output, Debugger evidence, or M11 acceptance criteria.
---

# reefidle-godot-acceptance

用途：ReefIdle / CoralReefDesk Godot 原型任务的人工可见验收。

## 验收原则

- 不能只相信文字报告。
- 必须以 Godot 实际运行、截图、Output、Debugger 或用户截图作为事实源。

## M11 当前可见验收点

需要重点检查：

- 左侧 UI 是否裁切。
- 舒适度指标是否显示。
- RP 显示是否正常。
- 设备 ON/OFF 文案是否正常。
- 维护按钮成本和冷却是否显示。
- 生物数量、生物负载、舒适度、收益倍率是否可见。
- RP 增长是否能体现收益倍率影响。
- 动态确认日志是否显示关键因果反馈。

## 输出格式

完成验收后输出：

```text
Godot 可见验收：
- 运行方式：
- 截图/观察依据：
- 通过项：
- 未通过项：
- 是否阻塞：
```

## 禁止

- 禁止只写“已修复”。
- 禁止没有截图或运行依据就宣布通过。
- 禁止把 Godot 编辑器实际显示问题归咎于用户观察错误。
