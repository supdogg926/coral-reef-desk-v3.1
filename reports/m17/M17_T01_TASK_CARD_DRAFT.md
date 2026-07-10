# M17-T01 任务卡 v2（Fable 裁决修订版）

**任务名**: M17-T01_PoolExpansionDataContract_And_OneDrawBagDraw
**版本**: v2 — Fable 裁决修订
**类型**: 数据层 + 算法层。不接 UI，不接真实美术。
**依赖**: M16 Final (v3.4-m16-final-rescue-visual-identity @ 4b66dbf7)
**状态**: 修订完成，待 Fable 最终确认后下发

---

## Objective

1. 将 rescue species pool 从 3 扩到 6（repo 启用 6；9 物种完整清单仅写入 report）
2. 将候选抽取算法从有放回随机改为 **one-draw bag draw**（每候选 1 次 RNG）
3. 更新 card_manifest placeholder 条目以匹配 6 个启用物种
4. 不接真实美术，不改 UI，不新增存档字段

## Non-goals

- 不接入真实资产（T02 做）
- 不修改图鉴 UI / RescueDockPanel（T03 做）
- 不新增 care_need / 护理动作
- 不启用 injury branching
- 不改变 save system
- **不把 9 个物种全写入启用池**

---

## Pre-flight Checks (T01 执行前必须完成)

### Check A: Placeholder SHA 机制确认

M16-T01 placeholder manifest (v3.4-m16-t01-card-manifest) 的 placeholder 条目均使用**落盘 placeholder PNG 的 SHA256**，非空/null/omitted。

```
data/card_manifest.json (T01 tag):
  source: "placeholder"
  sha256: "1d3ec04c82901473259edc8d8ace79156c47a192e5604b9eefb1e3e93c655829"  ← real SHA
```

`data/schemas/card_manifest_schema.json` 约束 `sha256_must_match_actual_file: true`，placeholder 也不例外。

**结论**: T01 必须为 3 个新增物种生成 deterministic placeholder PNG，并写入其 SHA256。Allowed Files 须包含 `assets/cards/placeholder/`。

### Check B: M14/M15 验收脚本使用 live pool 还是 fixture pool

| 文件 | 行号 | 使用方式 |
|------|------|---------|
| `tests/m15_t01_caremodel_verify.gd` | 222 | `_load_json_array("res://data/species_rescue_pool.json")` — **live pool** |
| `tests/run_m15_t01_acceptance.ps1` | 201 | 将 `species_rescue_pool.json` 列入 forbidden 修改检查 — 用于检测非法变更 |

**结论**: M15-T01 使用 **live pool**。pool 3→6 会改变 M15-T01 event sequence。必须纳入 Rebaseline Protocol v2。

---

## Allowed Files

| File | Operation | Reason |
|------|-----------|--------|
| `data/species_rescue_pool.json` | MODIFY | 3 → 6 条启用记录 |
| `data/card_manifest.json` | MODIFY | 6 个 placeholder 条目 + SHA256 |
| `assets/cards/placeholder/` | NEW (3 files) | 3 个新增物种的 deterministic placeholder PNG |
| `scripts/systems/RescueSystem.gd` | MODIFY | `_generate_candidate()` 改为 one-draw bag draw |
| `tests/m17_t01_*.gd` | NEW | M17-T01 headless verify |
| `tests/run_m17_t01_acceptance.ps1` | NEW | M17-T01 acceptance |
| `reports/m17/` | NEW | T01 report + receipt + rebaseline diff |

## Forbidden Files

| File | Reason |
|------|--------|
| `scripts/systems/SaveSystem.gd` | 零存档影响原则 |
| `data/schemas/save_schema.json` | 零存档影响原则 |
| `scenes/ui/LivestockPanel.gd` | UI 留给 T03 |
| `scenes/ui/RescueDockPanel.gd` | UI 留给 T03 |
| `scripts/systems/CardAssetLibrary.gd` | T01 不改 manifest schema |
| `assets/cards/rescue/*.png` | 真实资产留给 T02 |
| `data/rescue_config.json` | T01 不改 recovery/reward 配置 |
| `project.godot` / `*.tscn` | 不改场景 |
| M13/M14/M15/M16 tests | 不改既有测试 |

---

## Data — Species Pool (repo 启用 6)

### Phase 1: Enable 3 new species

| species_id | category | care_need 建议 | 理由 |
|---|---|---|---|
| `rescue_seahorse` | fish | weak | 海马 — 高频救助物种，辨识度极高 |
| `rescue_hermit_crab` | crustacean | weak | 寄居蟹 — 甲壳类扩展 |
| `rescue_brain_coral_frag` | coral | stressed | 脑珊瑚碎片 — 首个珊瑚救助物种 |

### JSON 规则

- `species_rescue_pool.json` 只包含 **6 条启用记录**（3 旧 + 3 新）。
- **不包含** 3 个预备物种。
- **不在 JSON 中写注释**。
- **不新增 `enabled` 字段**。
- **不修改 schema**。

### Category Arithmetic

| Category | M16 (当前) | Phase 1 新增 | M17 Phase 1 总计 |
|----------|-----------|-------------|-----------------|
| fish | 2 | +1 (seahorse) | **3** |
| crustacean | 1 | +1 (hermit_crab) | **2** |
| coral | 0 | +1 (brain_coral_frag) | **1** |
| **总计** | **3** | **+3** | **6** |

Schema support verified: `LivestockPanel.gd:246-250` — coral, fish, crustacean, algae, invertebrate 均已定义。

### Phase 2: Reserve 3 for later（仅写入 report，不写入 pool JSON）

| species_id | category |
|---|---|
| `rescue_mandarin_dragonet` | fish |
| `rescue_sea_star` | invertebrate |
| `rescue_anemone_tube` | invertebrate |

### 新增物种参数区间（必遵现有实测区间）

| Field | 现有实测区间 | 新增物种必须在此范围内 |
|-------|------------|---------------------|
| recovery_rate_base | 22–30 | **22–30** |
| reward_reputation | 5–7 | **5–7** |
| reward_rp | 6–8 | **6–8** |
| water_pressure | 0.05–0.08 | **0.05–0.08** |
| injury_type | `"reserved"` | `"reserved"` |

- **不引入新数值梯队。**
- **不夹带隐性难度调整。**
- 如某个物种确需出区间，必须单独列理由并等待用户/Fable 另行裁决；T01 默认不得出区间。

---

## Algorithm — One-Draw Bag Draw

### 禁止方案

- ❌ Fisher-Yates shuffle（消耗 N-1 次 RNG，破坏 arrival 序列）
- ❌ 预洗牌数组（同上）
- ❌ 周期边界额外 reroll（改变 RNG 消耗次数）
- ❌ 为避免周期边界重复而增加条件抽取

### 正确方案

```
var _bag: Array[int] = []
var _bag_rng_consumed: bool = false

func _generate_candidate(day: int) -> Dictionary:
    if _bag.is_empty():
        for i in range(species_pool.size()):
            _bag.append(i)
        # 重填袋不消耗 RNG

    var r: int = _rand_range(0, _bag.size() - 1)   # 1 次 RNG
    var idx: int = _bag[r]
    _bag.remove_at(r)

    return _build_rescue_entry(species_pool[idx], day)
```

属性：

- **每候选消耗 1 次 RNG**（与现行算法一致）
- 周期内不重复（从袋中移除已抽取索引）
- 袋空后重填（不消耗 RNG），进入下一周期
- 不改变 `_schedule_next_arrival` 的 RNG 消耗顺序

### Known Limitation 1: 读档重填袋

- T01 不新增存档字段，bag 状态不跨存档持久化。
- 读档后 `_bag` 为空，下次调用 `_generate_candidate()` 会重填。
- 这轻微削弱"周期不重复"保证，但可接受。
- **禁止**为了持久化 bag 状态而新增存档字段。

### Known Limitation 2: 周期边界重复

- 上一周期最后一个物种可能等于下一周期第一个物种。
- 6 物种阶段概率约 1/6。
- 这是可接受限制。
- **禁止**用"边界重抽一次"修复，条件抽取会破坏 RNG 消耗次数保留。

### 时间估计（仅规划参考，非验收硬指标）

| 场景 | 物种数 | 时间 |
|------|--------|------|
| 6 物种一轮（均值 arrival 7.2min） | 6 | **~43 分钟** |
| 9 物种一轮（均值 arrival 7.2min） | 9 | **~65 分钟** |
| 9 物种一轮（最小 arrival 4.8min，乐观下限） | 9 | ~43 分钟 |

以上仅用于规划，不作为验收硬指标。

---

## Acceptance Checks

### Asset & Manifest
1. species_rescue_pool.json: 6 条记录（无预留/注释/伪字段）
2. 9 物种完整清单仅存在于 `reports/m17/`，不在 pool JSON
3. card_manifest.json: 6 条条目，max_entries=6，source="placeholder"
4. 每条 placeholder SHA256 来自对应落盘 placeholder PNG
5. 新增物种 category ≥3 个（fish, crustacean, coral）
6. 所有 injury_type = "reserved"
7. 所有新增物种参数落在现有实测区间（22–30 / 5–7 / 6–8 / 0.05–0.08）

### Algorithm
8. One-draw bag draw: 每候选 1 次 RNG
9. 未使用 Fisher-Yates
10. 6 个连续候选全部唯一（周期内不重复）
11. 袋空后重填，下一周期可正常抽取

### Rebaseline Protocol v2
12. 重新生成 30 天 baseline export
13. diff old vs new baseline: 仅允许 species selection / species_id / species_name 差异
14. arrival day / next_arrival 逐项一致
15. event timestamp / event type / RP / reputation / comfort / first loop duration 逐项一致
16. save keys 逐项一致
17. 非物种字段漂移 → T01 FAIL
18. arrival 序列漂移 → T01 FAIL

### Zero Save Impact
19. SaveSystem.gd diff empty
20. save_schema.json diff empty
21. SAVE_VERSION 仍为 3
22. v3 save round-trip: save → quit → load → state identical

### Regression
23. M13 PASS
24. M14-T01/02/03/04 PASS
25. M15-T01 PASS（按 Rebaseline Protocol v2）
26. M15-T02/03 PASS
27. M16-T01/02/03 PASS
28. FIRST_LOOP_DURATION = 840 seconds
29. M15_T02_FIRST_LOOP_DURATION = 580 seconds

### Git
30. `git status --short` clean
31. FORBIDDEN_TOUCHED = 0

## PASS Criteria

All 31 checks above must PASS.

## Known Limitations (must appear in report)

1. **读档重填袋**：bag 不持久化，读档后重填，轻微削弱周期不重复保证。禁止为此新增存档字段。
2. **周期边界重复**：上周期末物种可能与下周期首物种相同（6 物种概率 ~1/6），可接受。禁止条件抽取修复。

## Report Path

`reports/m17/M17_T01_POOL_EXPANSION_REPORT.md`

报告必须包含：
- Rebaseline Protocol v2 diff（old vs new 30-day baseline）
- grep 结果：M15-T01 使用 live pool（`m15_t01_caremodel_verify.gd:222`）
- Known limitations section
- 9 物种完整规划清单

## Receipt Path

`reports/m17/M17_T01_POOL_EXPANSION_RECEIPT.json`

## Tag

`v3.5-m17-t01-pool-expansion-bag-draw`

## Codex Review (必须)

T01 完成后 Codex 复核必须核查：

1. one-draw bag draw 是否每候选只消耗 1 次 RNG
2. 是否未使用 Fisher-Yates
3. 是否未改变 `_schedule_next_arrival` RNG 消耗顺序
4. Rebaseline Protocol v2 diff 是否存在
5. diff 是否只允许 species selection 差异
6. arrival day / next_arrival 是否逐项一致
7. FIRST_LOOP_DURATION 840 / 580 是否保持
8. SaveSystem / save_schema 是否未改
9. species_rescue_pool.json 是否只有 6 条启用记录
10. 9 物种完整清单是否仅在 reports/m17/
11. 参数区间是否回收到现有实测区间
12. placeholder SHA 机制是否已先读确认
13. known limitations 是否写入 report

## Evidence Rule

`no_self_referential_annotated_tag_closure_v1`
