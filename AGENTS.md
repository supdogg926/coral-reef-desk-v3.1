# ReefIdle / CoralReefDesk Codex 工作规则

本仓库当前用于 CoralReefIdleV3 / 桌面海缸 v3.0 的原型开发。

## 当前任务背景

当前主工作分支：

```text
prototype/m11-biomanage-vertical-slice
```

当前 M11 已通过验收的基线：

```text
13605421f05048c2682e33ea0cec04891ea4824d
Add M11 bioload comfort revenue loop
```

已确认内容：

- 左侧安全边距修复通过。
- 舒适度指标显示通过。
- RP 位置显示通过。
- 设备反馈文案显示通过。
- M11_BioLoad_Comfort_Revenue_Loop_v1 已完成并通过 smoke / headless 运行验收。
- 工作区 clean。
- `v3.1-m10-livestock-core` tag 存在。

## 硬性禁止

除非用户明确解除，否则禁止：

- 切换 `main` 进行开发。
- merge `main`。
- rebase `main`。
- 删除或移动 tag。
- 修改 `v3.1-m10-livestock-core`。
- 打新 tag。
- 修改 `project.godot`。
- 大规模重构。
- 修改 `SaveSystem`，除非先停止并汇报原因。
- 修改 M10 生物商店核心链路，除非任务明确要求。
- 在当前任务未验收前加入新任务。
- 用文字报告代替 Godot 实际运行或截图验收。

## 每次开工门禁

任何写代码前，必须先执行只读核验：

```powershell
cd "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
git branch --show-current
git status --short
git log -8 --oneline
git rev-parse HEAD
git tag --list "v3.1-m10-livestock-core"
```

必须满足：

- branch 是 `prototype/m11-biomanage-vertical-slice`。
- `git status --short` 为空，即 clean。
- `v3.1-m10-livestock-core` tag 存在。
- 当前任务基线 HEAD 与用户指定一致。

不一致则停止，不继续开发。

## 每次完成必须输出

完成任务后必须输出：

- 修改文件列表。
- `git diff` 摘要。
- 关键逻辑说明。
- Godot 运行或人工可见验收说明。
- 是否影响 `main`。
- 是否影响 `v3.1-m10-livestock-core`。
- commit hash。
- 是否 push 到 `origin/prototype/m11-biomanage-vertical-slice`。
- 最终 `git status --short` 结果。

## M11 当前下一任务方向

M11 已完成：

- `M11_BioLoad_Comfort_Revenue_Loop_v1`

后续任务必须由用户指定新的任务名和基线 HEAD 后再开工。

禁止未经用户明确要求扩展到疾病、死亡、繁殖、复杂 AI 行为、正式数值平衡。
