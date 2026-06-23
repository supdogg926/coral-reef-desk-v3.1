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
M10 livestock core
```

Status:

```text
M10 已封版。
```

Final tag:

```text
v3.1-m10-livestock-core
```

Final commit:

```text
1a4c334eb67090d2df66039bb519876376506e0e
```

Runtime regression:

```text
PASS 20 / FAIL 0 / NOT_TESTED 0
```

## 当前允许事项

- M10 完成报告整理
- M11 规划
- 工具接管只读核验
- 文档归档

## 当前禁止事项

在 M11 规划明确前，禁止直接开发：

- 放归系统
- 大海系统
- 蓝色守护远征
- 新设备系统
- 图鉴成就
- 复杂生物死亡
- 繁殖系统
- 多页面正式 UI 美术化

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

未通过前禁止修改代码。
