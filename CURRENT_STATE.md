# Current Project State

## 唯一事实源

Repo:

```text
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3
```

Remote:

```text
https://github.com/supdogg926/coral-reef-desk-v3.1.git
```

## 当前里程碑状态

Current milestone:

```text
M11 Stable Acceptance Baseline (已冻结)
↓
M12 Autonomous Execution Protocol (进行中)
```

M11 状态:

```text
M11 已封版并通过稳定验收。
```

M11 Tag:

```text
v3.1-m11-acceptance-harness
```

Actual tag commit:

```text
c2f1a05668473ed5dd30952e92d4309638a0599b
```

Functional baseline:

```text
87412826a6b43d44fe5538fc045838a60912f8e4
```

Delta: `.gitignore` only (1 line: `*.uid`)

Acceptance:

```text
M11_ACCEPTANCE_RESULT=PASS (6/6 suites, 185/185 checks)
```

M10 Final tag:

```text
v3.1-m10-livestock-core
```

## M12 路线图

1. ~~M12_Autonomous_Execution_Protocol_Setup~~ → 进行中
2. M12_Productized_Core_Loop_Package → 下一阶段

## 当前允许事项

- 自治协议文档编写
- 治理文件更新（AGENTS.md / PROJECT_RULES.md / CURRENT_STATE.md）
- M11 acceptance 重复验证
- 工具接管只读核验

## 当前禁止事项

禁止直接开发以下系统（需 M12 产品化包统一规划）：

- 放归系统
- 大海系统
- 蓝色守护远征
- 新设备系统
- 图鉴成就
- 复杂生物死亡
- 繁殖系统
- 多页面正式 UI 美术化

禁止碎修 M11 遗留问题（统一吸收进 M12 产品化包）。

## 换工具规则

任何从 Claude Code 切到 Codex 或从 Codex 切到 Claude Code 的任务，都必须先只读核验：

- pwd
- git root
- branch
- status
- latest commit
- tag
- `CURRENT_STATE.md`
- `PROJECT_RULES.md`
- `AGENTS.md`

未通过前禁止修改代码。
