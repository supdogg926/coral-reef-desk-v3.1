# M14-T03 Cloud Code 任务简报

## 衔接保护声明

Codex 当前 5 小时 usage 余额未释放，本任务由 Cloud Code 先完成，但必须严格保留可衔接性，确保 Codex 余额恢复后可以继续复核、接管或二次验收。

本简报即为衔接保护文件——Cloud Code 必须严格按照本文档执行，不得越界。

---

## 1. 项目信息

- **项目名称**：《桌面海缸放置》/ CoralReefDesk / ReefIdle
- **项目路径**：`C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01`
- **当前任务**：M14-T03_RescueCore_BlindPlaytest_UX_And_Pacing_Hardening

---

## 2. 已完成阶段

### M14-T01 — PASS
| 字段 | 值 |
|------|-----|
| branch | `m14-t01-rescue-core` |
| base tag | `v3.1-m13-30day-progression-economy` |
| commit | `c8751b6f8458a8493f014a4e12f6b500de705614` |
| tag | `v3.2-m14-t01-rescue-datamodel` |
| result | `M14_T01_RESCUE_CORE_DATAMODEL_RESULT=PASS` |

### M14-T02 — PASS
| 字段 | 值 |
|------|-----|
| branch | `m14-t02-rescue-first-playable-ui` |
| base tag | `v3.2-m14-t01-rescue-datamodel` |
| commit | `05777a9df10cb59d46ef76d38862470ca3bfed5f` |
| tag | `v3.2-m14-t02-rescue-first-playable-ui` |
| result | `M14_T02_RESCUE_FIRST_PLAYABLE_UI_RESULT=PASS` |
| M13 regression | PASS |
| M14-T01 regression | PASS |
| T02 UI | 30/30 PASS |
| screenshots | 7 张 PASS |
| first loop duration | 840 seconds |

### T02 参考文件
- **报告**：`reports/m14/M14_T02_RESCUE_FIRST_PLAYABLE_UI_REPORT.md`
- **receipt**：`reports/m14/M14_T02_RESCUE_FIRST_PLAYABLE_UI_RECEIPT.json`
- **截图**：`reports/m14/screenshots/`

---

## 3. 本次任务

### 任务名
`M14-T03_RescueCore_BlindPlaytest_UX_And_Pacing_Hardening`

### 任务目标
只做 M14 救助放归核心体验的玩家视角验收、文案硬化、状态反馈硬化和节奏微调。

**本任务不是新增玩法，不允许打开新系统。**

### 起步要求

必须从以下 tag 起步：
```
v3.2-m14-t02-rescue-first-playable-ui
```

新建分支：
```
m14-t03-rescue-ux-pacing-hardening
```

### 开工前必须执行

```bash
git status
git branch --show-current
git tag --list "v3.2-m14*"
git checkout v3.2-m14-t02-rescue-first-playable-ui
git checkout -b m14-t03-rescue-ux-pacing-hardening
```

然后：
1. 读取 T02 report 和 receipt
2. 运行 T02 acceptance，确认当前基线仍 PASS

---

## 4. 硬性禁止范围

以下操作**绝对禁止**，触碰即视为任务失败：

- 禁止做海域系统
- 禁止做大海图鉴
- 禁止做多救助位
- 禁止做伤情分支
- 禁止做护理操作
- 禁止做繁殖
- 禁止接入鱼类 / 珊瑚卡牌美术
- 禁止做复杂动画
- 禁止做声望商店
- 禁止做声望等级
- 禁止新增经济资源
- 禁止修改 `species_master.json`
- 禁止重构 M11 水质 / 舒适度核心计算链
- 禁止破坏 M13、M14-T01、M14-T02 既有验收
- 禁止为了"顺手优化"改无关 UI

---

## 5. 允许范围

### 文档
- 新增 `reports/m14/M14_T03_BLIND_PLAYTEST_CHECKLIST.md`
- 新增 `reports/m14/M14_T03_BLIND_PLAYTEST_REPORT.md`

### 文案微调（仅限以下位置）
- 码头入口提示
- 待救助生物状态描述
- 带回按钮文案
- 救助位状态文案
- 恢复进度提示
- 可放归提示
- 放归结算文案
- 生态声望说明
- 图鉴已救助标记说明

### rescue_config 微调（仅限以下参数）
- 首只生物出现时机
- 首只生物恢复时间
- 带回成本
- 首次放归奖励
- 下一只生物到达提示

### UI 状态反馈补充
- 码头有待救助对象时更清楚
- 救助位恢复中更清楚
- 可放归状态更清楚
- 放归后结算反馈更清楚
- 声望变化更清楚

### 截图证据（重新生成或保存）
- 初次看到码头入口
- 码头有待救助生物
- 带回成功后的救助位
- 恢复中状态
- 可放归状态
- 放归结算
- 声望变化
- 图鉴已救助标记
- 下一只生物等待状态

---

## 6. 人工盲玩问题（必须回答）

1. 是否能在 1 分钟内发现码头入口？
2. 是否能在 3 分钟内理解"带回救助"？
3. 是否能在 5 分钟内理解救助位和恢复进度？
4. 是否能在 10–15 分钟内完成首次放归？
5. 放归结算是否让玩家理解"这是完成救助，不是损失生物"？
6. 生态声望是否有意义感？
7. 图鉴已救助标记是否清楚？
8. 玩家是否知道下一步可以继续救助？
9. 当前最影响体验的 3 个问题是什么？
10. 是否建议进入 M14-T04？

---

## 7. 验收脚本

必须新增或更新：
```
tests/run_m14_t03_acceptance.ps1
```

### 验收内容

| 检查项 | 要求 |
|--------|------|
| M13 全量回归 | PASS |
| M14-T01 全量回归 | PASS |
| M14-T02 全量回归 | PASS |
| M14-T03 新增检查 | PASS |
| 首次救助闭环 | 10–15 分钟 |
| UI 状态绑定 | PASS |
| 存档重启 UI 一致性 | PASS |
| 截图证据 | 完整 |
| 文案 key / UI 节点检查 | PASS |
| 禁止范围检查 | PASS |

---

## 8. PASS 标准

**以下全部满足，才允许标记 PASS：**

- [ ] M13 回归 PASS
- [ ] M14-T01 回归 PASS
- [ ] M14-T02 回归 PASS
- [ ] M14-T03 自动验收 PASS
- [ ] 人工盲玩报告完成
- [ ] 首次闭环仍在 10–15 分钟
- [ ] 玩家流程无阻断
- [ ] 放归意义表达清楚
- [ ] 禁止范围未被触碰
- [ ] 截图证据齐全
- [ ] 生成完整报告
- [ ] 生成 receipt
- [ ] 工作区 clean
- [ ] 提交 commit
- [ ] 打 tag

---

## 9. 交付物清单

### 分支与标签
- **分支**：`m14-t03-rescue-ux-pacing-hardening`
- **建议 tag**：`v3.2-m14-t03-rescue-ux-pacing`

### 报告文件
| 文件 | 路径 |
|------|------|
| 任务报告 | `reports/m14/M14_T03_RESCUE_UX_PACING_REPORT.md` |
| 人工盲玩报告 | `reports/m14/M14_T03_BLIND_PLAYTEST_REPORT.md` |
| receipt | `reports/m14/M14_T03_RESCUE_UX_PACING_RECEIPT.json` |
| Codex 复核交接 | `reports/m14/M14_T03_CODEX_HANDOFF.md` |

### receipt 必须包含字段
```json
{
  "task_name": "M14-T03_RescueCore_BlindPlaytest_UX_And_Pacing_Hardening",
  "branch": "m14-t03-rescue-ux-pacing-hardening",
  "base_tag": "v3.2-m14-t02-rescue-first-playable-ui",
  "commit_hash": "",
  "result": "",
  "m13_regression_result": "",
  "m14_t01_regression_result": "",
  "m14_t02_regression_result": "",
  "m14_t03_acceptance_result": "",
  "first_loop_duration": "",
  "blind_playtest_result": "",
  "top_ux_issues": [],
  "screenshots": [],
  "modified_files": [],
  "forbidden_files_touched": [],
  "report_path": "",
  "blind_playtest_report_path": "",
  "receipt_path": "",
  "tag": "",
  "recommendation_for_m14_t04": "",
  "codex_handoff_ready": true
}
```

---

## 10. Codex 复核交接文件模板

必须额外生成 `reports/m14/M14_T03_CODEX_HANDOFF.md`，内容包含：

```markdown
# M14-T03 Codex 复核交接文件

## 基本信息
- 当前分支：
- base tag：
- commit hash：
- 新 tag：

## 任务概要
- 本次任务目标：
- 本次实际修改文件：
- 本次未做内容：
- 禁止范围是否触碰：

## 验收
- 所有验收命令：
- 所有验收结果：
- M13 回归：
- M14-T01 回归：
- M14-T02 回归：
- M14-T03 验收：
- 首次救助闭环耗时：

## 证据
- 截图路径：
- 报告路径：
- receipt 路径：

## Codex 复核指南
- 需要 Codex 复核的重点：
- 建议 Codex 复核命令：
- 如果 Codex 接手下一步，建议从哪里开始：
```

---

## 11. 最终交付清单

Cloud Code 完成时必须返回以下全部信息：

1. 当前分支名
2. base tag
3. commit hash
4. 新 tag
5. 修改文件清单
6. 禁止范围是否被触碰
7. 所有验收命令与输出摘要
8. M13 回归是否 PASS
9. M14-T01 回归是否 PASS
10. M14-T02 回归是否 PASS
11. M14-T03 是否 PASS
12. 首次救助闭环实测耗时
13. 人工盲玩结论
14. 当前最影响体验的 3 个问题
15. 截图文件路径
16. 报告完整路径
17. 人工盲玩报告完整路径
18. receipt 完整路径
19. Codex handoff 文件路径
20. 下一步是否建议进入 M14-T04

---

## 12. 失败处理

**如果任一验收失败，不允许打 PASS，不允许进入 T04。**

必须明确输出：
- 失败原因
- 失败日志
- 已修改文件
- 是否需要回滚

---

## 附录：Fable 诊断结论（M13 后战略诊断摘要）

> M14 方向裁决：**缩小**。保留"码头→带回→救助位恢复→放归→声望/RP/图鉴"单线闭环，砍掉海域解锁、多救助位、伤情类型分支。
>
> M14 真正要回答的不是"能不能做出救助系统"，而是"玩家把一条鱼养好之后，愿不愿意松手"。
>
> 放归那一下的感受，是整条蓝色守护战略的试金石。

---

*本简报由人工编写，作为 Cloud Code M14-T03 任务的唯一执行依据。Cloud Code 不得超出本简报范围。*
