# M17-T01 Task Card Revision Notes

**Date**: 2026-07-10
**Revision**: v1 → v2 (Fable 裁决修订)

---

## Blockers Resolved

### Blocker 1: Algorithm — Fisher-Yates → One-Draw Bag Draw

| 项目 | v1 (错误) | v2 (修正) |
|------|----------|----------|
| 算法名 | Fisher-Yates shuffle bag | **one-draw bag draw** |
| RNG 消耗/候选 | N-1 (shuffle) | **1** |
| next_arrival 序列 | 会漂移 | **不变** |
| 重填袋 | 消耗 RNG | **不消耗 RNG** |
| M15-T01 兼容 | 破坏 | **Rebaseline Protocol v2** |

### Blocker 2: JSON 预备物种

| 项目 | v1 (错误) | v2 (修正) |
|------|----------|----------|
| pool JSON 内容 | 6 启用 + 3 预备注释 | **6 条启用记录，无注释** |
| 预备物种存在位置 | pool JSON | **仅 reports/m17/** |
| 伪字段 | 无 | **明确禁止 enabled 等伪字段** |

---

## Required Revisions Applied

### Revision 1: Parameter Ranges Tightened

| Field | v1 (过宽) | v2 (实测区间) |
|-------|----------|-------------|
| recovery_rate_base | 20–32 | **22–30** |
| reward_reputation | 4–8 | **5–7** |
| reward_rp | 5–10 | **6–8** |
| water_pressure | 0.04–0.10 | **0.05–0.08** |

### Revision 2: Placeholder SHA Pre-flight Check

v2 加入 Pre-flight Check A：确认 M16-T01 placeholder 使用落盘 PNG SHA，T01 Allowed Files 必须包含 `assets/cards/placeholder/`。

### Revision 3: Known Limitations

v2 加入两条 known limitations：
1. 读档重填袋（不持久化 bag 状态）
2. 周期边界重复（概率 ~1/6，可接受）

时间估计改为区间表述，取消"43 分钟"单一数字。

---

## New Additions

### Rebaseline Protocol v2

因 M15-T01 使用 live pool（`m15_t01_caremodel_verify.gd:222`），pool 3→6 必然改变 event sequence。v2 新增完整的 rebaseline 协议。

### Pre-flight Checks

v2 新增两项前置检查：
- Check A: placeholder SHA 机制确认
- Check B: M14/M15 acceptance scripts 使用 live pool vs fixture pool

### Codex Review Checklist

v2 新增 13 项 Codex 复核检查清单。

### Acceptance Expanded

v1: 24 checks → v2: 31 checks（新增 rebaseline + 前置检查 + known limitations）

---

## Retained from v1

- 方向：RescueSpeciesPoolExpansion
- 6+3 分批
- 物种清单：seahorse / hermit_crab / brain_coral_frag
- Category 配比：fish+1, crustacean+1, coral+1 = 6 total
- schema_version=2 不升版
- T01 不接真实资产，不改 UI
- FlowContainer 留 T03
- 零新增存档字段，save_version=v3
- Codex 复核 required
- Evidence rule: no_self_referential_annotated_tag_closure_v1
