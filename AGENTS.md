# ReefIdle / CoralReefDesk 执行规则

本仓库当前用于 CoralReefIdleV3 / 桌面海缸 v3.0 的开发。

## M11 稳定验收基线

当前工作分支：

```text
prototype/m11-biomanage-vertical-slice
```

M11 Stable Acceptance Baseline：

| 项目 | 值 |
|------|-----|
| Tag | `v3.1-m11-acceptance-harness` |
| Tag commit | `c2f1a05668473ed5dd30952e92d4309638a0599b` |
| Functional baseline | `87412826a6b43d44fe5538fc045838a60912f8e4` |
| Delta | `.gitignore` only (1 line: `*.uid`) |
| Acceptance | `M11_ACCEPTANCE_RESULT=PASS` (6/6 suites, 185/185 checks) |

## 每次开工门禁（闸门检查）

任何写代码前，必须先执行只读核验：

```powershell
cd "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
git fetch --all --tags
git checkout prototype/m11-biomanage-vertical-slice
git status
git rev-parse HEAD
git tag --points-at HEAD
```

必须满足：

1. HEAD = `c2f1a05` 或其 parent 为 `8741282`（functional baseline）
2. tag 含 `v3.1-m11-acceptance-harness`
3. branch = `prototype/m11-biomanage-vertical-slice`
4. working tree clean

然后运行：

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m11_acceptance.ps1
```

必须看到 `M11_ACCEPTANCE_RESULT=PASS` 才允许进入开发。

## 硬性禁止（HARD BLOCK）

以下操作在任何情况下都禁止，不得询问确认：

- 切换 `main` 进行开发
- merge `main`
- rebase `main`
- 删除或移动 tag（除非用户明确指定新基线 commit）
- 修改 `v3.1-m10-livestock-core` tag
- 修改 `project.godot`
- 大规模重构
- 修改 `SaveSystem`，除非先停止并汇报原因
- 修改 M10 生物商店核心链路，除非任务明确要求
- 用文字报告代替 Godot 实际运行或截图验收

## M12 自治执行规则（Autonomous Execution Protocol）

### 核心原则

执行层在以下条件下可以连续执行，不需逐操作确认：

1. **文件写入** — 在 repo 目录内创建/修改 `.gd` `.tscn` `.md` `.ps1` `.py` 文件
2. **Godot headless 运行** — 执行 `--script` 测试或验收脚本
3. **Git 只读查询** — status / log / diff / rev-parse / tag 查询
4. **Python 工具脚本** — 运行 `tools/` 下的验证脚本
5. **PowerShell 验收脚本** — 运行 `tests/run_m*.ps1`
6. **文档编辑** — `docs/` 目录下的 `.md` 文件

### 必须停止并等待用户确认的操作（STOP CONDITIONS）

1. `git commit` — 必须等用户确认后才能提交
2. `git push` — 必须等用户确认后才能推送
3. `git tag` — 打新 tag 或删除现有 tag
4. 删除 `.gd` / `.tscn` 源文件
5. 修改 `SaveSystem` 相关代码
6. 修改 `project.godot`
7. 跨分支操作（checkout 非当前开发分支）

### 禁止询问的冗余确认（NO-ASK LIST）

以下情况执行层不得停下来询问：

- "我可以继续下一步吗？" — 在自治窗口内直接执行
- "我可以运行测试吗？" — 直接运行，失败再汇报
- "我可以读取这个文件吗？" — 直接读取
- "看起来没问题，要继续吗？" — 直接继续
- 单次验收脚本运行 — 结果出来后再汇报
- 工具脚本执行 — 除非失败，否则不单独汇报

### 批量处理规则

- 同一轮次内，连续执行不超过 15 个写操作
- 超出 15 个写操作时，汇报当前进度并等待确认后继续
- 每 10 个 Godsot 测试/验收运行后，强制汇报一次状态
- 视觉 QA 每轮至少聚合 10 个可见问题，禁止逐个提交

### 失败处理

- 单个测试失败 → 停止当前任务，汇报失败详情，等待用户判断
- 验收脚本 FAIL → 立即停止，不回退代码，不自动修复
- Godot 启动失败 → 检查 Godot 路径，重试一次，仍失败则停止

## 硬性禁止

除非用户明确解除，否则禁止：

- 切换 `main` 进行开发
- merge `main`
- rebase `main`
- 删除或移动 tag
- 修改 `v3.1-m10-livestock-core`
- 修改 `project.godot`
- 大规模重构
- 修改 `SaveSystem`，除非先停止并汇报原因
- 修改 M10 生物商店核心链路，除非任务明确要求
- 在当前任务未验收前加入新任务
- 用文字报告代替 Godot 实际运行或截图验收

## 每次完成必须输出

完成任务后必须输出：

- 修改文件列表
- `git diff --stat` 摘要
- 关键逻辑说明
- Godot 运行或人工可见验收说明
- 是否影响 `main`
- 是否影响 `v3.1-m10-livestock-core`
- commit hash
- 是否 push
- 最终 `git status --short` 结果

## 下一任务方向

M11 已完成并通过稳定验收。下一阶段：

1. **M12_Autonomous_Execution_Protocol_Setup** — 自治执行协议包（当前任务）
2. **M12_Productized_Core_Loop_Package** — 产品化主循环大版本包

禁止未经用户明确要求扩展到疾病、死亡、繁殖、复杂 AI 行为、正式数值平衡。
