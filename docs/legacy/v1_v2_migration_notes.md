# V1/V2 Migration Notes For CoralReefIdleV3

本文件记录旧工程对 V3 的可用价值和禁止迁移边界。V3 目标目录为：

`C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3`

## 旧工程最大价值

旧工程最大价值不是 UI 或脚本实现，而是已经验证过的一组玩法事实：

- 物种字段、价格、尺寸、成长时间、收入和放归字段。
- 海缸、设备、任务、事件、公式等基础玩法数据。
- Berlin system 海缸模拟中水质、设备衰减、离线收益和维护任务的风险点。
- 已发生事故的修复记录，可作为 V3 数据约束和测试用例来源。

## 禁止直接迁移

V3 必须数据驱动，旧 GDScript 只允许作为数据、字段、公式、测试约束来源。

- 禁止直接迁移 `C:\Users\admin\CoralReefIdle\UI\Main.gd`。
- 禁止直接迁移 `C:\Users\admin\CoralReefIdle\UI\TaskPanel.gd`。
- 禁止复制旧 GDScript 实现到 V3。
- V3 玩法数据必须进入 `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\*.json`。

## 已知事故

### reward 字段事故

旧任务数据使用过 `reward` 字段，后续逻辑容易把维护动作误当作奖励发放。V3 任务 schema 明确允许 `exec_cost`，并禁止 `reward`。任何 `tasks` 数据中出现 `reward` 字段都必须校验失败。

### Main.gd 单体膨胀事故

旧 `Main.gd` 承载过过多 UI、状态、经济和流程逻辑，导致重复结构、难测试和难拆分。V3 不迁移该文件实现，后续 Godot 工程骨架应将 autoload、systems、UI shell 分开。

### 离线收益无上限事故

旧离线收益逻辑存在无上限风险。V3 的公式数据和系统实现必须包含可测试的时间上限、收益上限或衰减约束，避免离线时间被无限兑换为资源。

### 透明窗口兼容性风险

桌面覆盖和透明窗口在不同 Windows 显卡、窗口管理和 Godot 配置中存在兼容性风险。V3 Phase 1 不接桌面叠加层，不做透明窗口；后续必须作为可降级功能处理。

## V3 数据驱动原则

V3 的长期维护目标是让玩法内容先进入 JSON 数据，再由系统读取和模拟。新增物种、设备、任务、事件、公式时，应先更新 `data` 和 schema，再更新系统逻辑和测试。
