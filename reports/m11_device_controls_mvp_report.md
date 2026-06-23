# M11 Device Controls MVP Report

## 本轮实现内容
- 将控制区的水泵、造浪泵、主灯、预留按钮接入 runtime-only prototype 设备状态。
- 设备按钮运行时显示 ON/OFF，点击后立即切换并刷新 HUD。
- GameState 增加设备查询与切换接口：`toggle_device`、`set_device_enabled`、`get_device_state`、`get_device_effect_summary`。
- 设备影响接入收益倍率、稳定度、水质评分惩罚以及 NO3/PO4 趋势提示。
- StatusPanel 增加紧凑设备状态/收益倍率/风险显示。

## 修改文件列表
- `scripts/systems/GameState.gd`
- `scripts/systems/WaterChemistrySystem.gd`
- `scenes/main/Main.gd`
- `scenes/ui/StatusPanel.gd`
- `tests/m11_water_maintenance_smoke_test.gd`
- `reports/m11_device_controls_mvp_report.md`

## 设备列表
- 水泵 `return_pump`：默认 ON
- 造浪泵 `wave_pump`：默认 ON
- 主灯 `main_light`：默认 ON
- 预留 `reserve`：默认 OFF，暂无效果

## 每个设备 ON/OFF 效果
- 水泵 OFF：收益 x0.85，稳定 -8，水质 -10，NO3/PO4 漂移变差，风险提示“水泵关闭，过滤循环不足”。
- 造浪泵 OFF：收益 x0.90，稳定 -5，水质 -3，风险提示“造浪不足，生物舒适度下降”。
- 主灯 OFF：收益 x0.65，稳定 -2，风险提示“主灯关闭，光照不足，收益降低”。
- 预留 OFF/ON：仅显示状态，暂无数值效果。

## 收益影响说明
- 收益影响在 `GameState._update_livestock_and_economy` 中以设备倍率叠加到现有生物收益计算结果。
- 多个设备关闭时倍率相乘，并 clamp 到最低 0.10。
- 未新增复杂电费、购买、升级或正式设备经济系统。

## 水质/稳定性影响说明
- 水质评分通过 `WaterChemistrySystem.device_water_quality_penalty` 轻量扣分。
- 水泵关闭时额外增加 NO3/PO4 每日漂移，体现过滤循环不足。
- 造浪/主灯主要作为稳定性、舒适度和收益反馈，不做生物死亡或疾病。

## 为什么这是 prototype
- 设备状态仅为 GameState runtime 字段，不写入存档。
- 未接入正式设备购买、升级、耐久、电费、自动化控制或存档迁移。
- UI 为运行时按钮和状态文字，不做正式美术。
- 正式版需要接入 SaveSystem 和统一设备系统后再固化。

## 没有做哪些系统
- 没有修改 SaveSystem。
- 没有修改 data。
- 没有修改 `.tscn` scene。
- 没有修改 `project.godot`。
- 没有做设备购买/升级系统。
- 没有做复杂电费系统。
- 没有做生物死亡或疾病系统。

## 测试结果
- PASS：`git diff --check`
- PASS：Godot 4.7 headless smoke test，输出 `M11_WATER_MAINTENANCE_SMOKE_RESULT=PASS`
- PASS：Godot 4.7 headless `Main.tscn --quit-after 3`，无红色错误输出

## 手动验收清单
- 控制区显示水泵/造浪/主灯/预留 ON/OFF。
- 点击水泵可切换 OFF，StatusPanel 显示过滤循环风险。
- 点击造浪可切换 OFF，StatusPanel 显示舒适度/稳定性风险。
- 点击主灯可切换 OFF，收益倍率明显下降。
- 再次点击同一按钮可恢复 ON。
- 生物商店 / 我的生物入口正常。
- 水质维护按钮、冷却、RP 扣款仍正常。
- Output / Debugger 无红色错误。

## 风险点
- 设备状态未存档，重开游戏会恢复默认值，这是本轮刻意保持的 prototype 边界。
- 水质/收益影响为轻量数值反馈，不是正式设备模拟。
- 状态栏新增一行设备风险，1280x720 仍需用户人工确认可读性。

## 是否建议保留到正式 M11
YES。建议作为正式设备系统的交互验证原型保留，但正式版应接入统一设备状态、存档和数值表。
