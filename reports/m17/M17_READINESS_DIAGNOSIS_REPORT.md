# M17 Readiness Diagnosis Report

**Task**: M17_READINESS_DIAGNOSIS_FOR_FABLE_RULING
**Type**: Read-only diagnosis. Zero modifications to code/config/assets/tests.
**Date**: 2026-07-10

---

## 一、M16 末态代码确认

| Check | Value |
|-------|-------|
| 当前分支 | `m16-t01-card-manifest` |
| 当前 HEAD | `4b66dbf79a2baf673d20a9ca044ecfc795af3481` |
| 是否等于 M16 final commit | **YES** — exact match |
| git tag `v3.4-m16-t01-card-manifest` | **PRESENT** |
| git tag `v3.4-m16-t02-rescue-card-playable-ui-fix2` | **PRESENT** |
| git tag `v3.4-m16-t03-codex-visual-record-rc` | **PRESENT** |
| git tag `v3.4-m16-final-rescue-visual-identity` | **PRESENT** |
| git status --short | Only `?? reports/m17/` (untracked planning docs) |

**结论**：当前仓库处于 M16 Final 末态。所有 M16 阶段 tag 完整。工作区干净。

---

## 二、图鉴 UI 承载方式核查

源文件：`scenes/ui/LivestockPanel.gd`

### 2.1 当前承载方式

M16 末态图鉴**同时使用两种显示方式**：

**方式 A — 单行 Label（旧方式，保留中）**

- 文件/行号：`LivestockPanel.gd:254-271` (`_format_rescue_codex_marks()`)
- 使用 `"｜".join(parts)` 拼接已救助物种文本
- 显示为：`救助图鉴（已救助物种）：rescue_xxx 已救助｜rescue_yyy 已救助`
- 物种多时会在一行内超长溢出

**方式 B — HBoxContainer 卡片容器（M16-T03 新增）**

- 文件/行号：`LivestockPanel.gd:146-149` (`rescue_codex_cards: HBoxContainer`)
- 文件/行号：`LivestockPanel.gd:274-283` (`_update_rescue_codex_cards()`)
- 文件/行号：`LivestockPanel.gd:325-356` (`_make_rescue_codex_card()`)
- **每个已救助物种生成一张独立卡片**，包含：
  - 72×72 TextureRect（加载真实卡片图）
  - 物种名 label（9px）
  - 已救助次数 label（9px）
  - 上次放归日 label（9px）
- 卡片容器为 HBoxContainer，卡片最小宽度 86px，间距 6px

### 2.2 UI 溢出风险评估

| 物种数 | 最小总宽度（86px × N + 间距） | 1280px 视口可容纳？ | 风险 |
|--------|---------------------------|-------------------|------|
| 3 | ~280px | YES | 无 |
| 6 | ~560px | YES | 低 — 可行但接近一半视口 |
| 9 | ~840px | YES (65% 视口) | **中** — HBoxContainer 无自动折行，9 张卡片一字排开会挤压右侧面板 |
| 12 | ~1120px | 边界 (87%) | **高** — 几乎占满视口宽，无滚动 |

### 2.3 其他 UI 元素

| 元素 | 说明 |
|------|------|
| GridContainer | **不存在** |
| ScrollContainer for cards | **不存在** — cards 在 HBoxContainer，无滚动 |
| card grid | **不存在** |
| 是否仍是单行 | **方式 A 是单行 Label；方式 B 是 HBoxContainer 单行排列** |

### 2.4 图鉴 UI 建议

**9 个物种前不必强行网格化。** 840px 在 1280px 视口仍可容纳单行。但建议 M17 将 HBoxContainer 升级为 `FlowContainer`（或 HFlowContainer），实现**自动折行**——改动量极小（只改容器类型），不涉及存档、不涉及新交互。

| 建议 | 理由 |
|------|------|
| 3→6 物种 | HBoxContainer 足够，不改 |
| 6→9 物种 | 建议改用 FlowContainer 自动折行 |
| 9→12 物种 | 必须折行 + 考虑加 ScrollContainer |

---

## 三、候选抽取算法核查

源文件：`scripts/systems/RescueSystem.gd`

### 3.1 核心函数

| 项目 | 值 |
|------|-----|
| 函数名 | `_generate_candidate(day: int)` |
| 文件 | `scripts/systems/RescueSystem.gd` |
| 行号 | `253-255` |
| 调用链 | `_tick_rescue_day()` → `_generate_candidate()` |

### 3.2 算法代码

```gdscript
func _generate_candidate(day: int) -> Dictionary:
    var idx: int = _rand_range(0, species_pool.size() - 1)
    return _build_rescue_entry(species_pool[idx], day)
```

### 3.3 算法类型

**有放回随机 (Random with replacement)**

每次候选生成独立随机抽取。使用 seeded RNG (`_rng_state`)，确定性可复现，但无记忆。

### 3.4 行为特征

| 问题 | 答案 |
|------|------|
| 是否可能连续重复同一物种 | **YES** — 每次独立抽取，可能 `clownfish → clownfish → clownfish` |
| 9 个物种是否能保证一轮不重复 | **NO** — 有放回随机不保证覆盖 |
| 加权随机 | NO — 等概率 |
| 固定顺序 | NO |
| 无放回轮转 | NO |
| 确定性 | YES — seeded RNG，同 seed 同序列 |

### 3.5 算法建议

**9 个物种下强烈建议改为无放回轮转 (shuffle bag / round-robin without replacement)。**

理由：
- 3 个物种时重复可接受（2-3 个救助后会自然轮换）
- 9 个物种时，如果连续抽到同一物种 3 次，玩家等 15-20 分钟才能见到新物种，体验很差
- 无放回轮转保证每轮 9 次救助至少覆盖全部物种一次
- 改动范围：RescueSystem 新增 `_shuffled_pool` + `_pool_index`，不涉及存档

---

## 四、TimeSystem / 游戏日真实时长核查

源文件：`scripts/systems/TimeSystem.gd`, `data/rescue_config.json`

### 4.1 关键参数

| 参数 | 值 | 来源 |
|------|-----|------|
| `debug_time_scale` | **600.0** | `TimeSystem.gd:9` |
| 1 游戏日 = 86400 秒 / 600 | **144 真实秒 = 2.4 分钟** | 计算值 |
| 1 real second = 600 game simulated seconds = 10 game minutes | | |
| Arrival interval (min) | 2 game days = **288 real seconds = 4.8 分钟** | `rescue_config.json:5` |
| Arrival interval (max) | 4 game days = **576 real seconds = 9.6 分钟** | `rescue_config.json:6` |
| M14 first loop baseline | 840 real seconds = 14 分钟 | 已知基线 |
| M15 care path first loop | 580 real seconds = 9.7 分钟 | 已知基线 |

### 4.2 9 物种理论与实际覆盖时间

| 场景 | 计算 | 时间 |
|------|------|------|
| 理想（每次不同物种） | 9 × 2 game days | 18 game days = **43.2 分钟** |
| 最坏（有放回，每物种需 3 次才抽到） | ~27 × 2 game days | **~130 分钟** |
| 平均（有放回 coupon collector） | 9 × H9 ≈ 9 × 2.83 ≈ 25.5 次 | ~52 game days ≈ **124 分钟** |
| **无放回轮转（建议）** | 9 × 2 game days | **43.2 分钟** |

### 4.3 结论

**当前有放回算法下，9 个物种见完一轮约需 2 小时。** 这意味着多数玩家在一次游玩中可能只见 3-4 个物种。如果改用无放回轮转，可降到 ~43 分钟见完一轮。

---

## 五、card_manifest schema_version 核查

源文件：`data/card_manifest.json`, `data/schemas/card_manifest_schema.json`

| Check | Value |
|-------|-------|
| `card_manifest.json` schema_version | **2** |
| `card_manifest_schema.json` schema_version | **2** |
| 是否确实为 v2 | **YES** — 两个文件一致 |
| M16 v1→v2 记录 | YES — M16-T02 从 v1 (placeholder only) 升级到 v2 (image2_user_generated) |
| source_allowed | `["placeholder", "image2_user_generated"]` |
| constraints | max_entries_equals_species_rescue_pool_count: true |

### 建议

**M17 不需要升级 schema_version。** v2 已支持新增物种条目。只要 species_rescue_pool 和 card_manifest 条目数一致、SHA256 验证通过、source 在 allowed 列表中即可。唯有在需要新增必填字段或新增 source 类型时才考虑 v2→v3。

---

## 六、species_rescue_pool 结构核查

源文件：`data/species_rescue_pool.json`

### 6.1 当前状态

| Check | Value |
|-------|-------|
| 物种数量 | **3** |
| 物种 ID | `rescue_clownfish_juvenile`, `rescue_cleaner_shrimp`, `rescue_goby` |
| Category 分布 | fish × 2, crustacean × 1 |
| recovery_rate_base 区间 | 22.0 ~ 30.0 |
| reward_reputation 区间 | 5 ~ 7 |
| reward_rp 区间 | 6 ~ 8 |
| water_pressure 区间 | 0.05 ~ 0.08 |
| injury_type | **全部为 "reserved"** |
| `injury_branching_enabled` | **false** (`rescue_config.json:25`) |

### 6.2 M17 新增物种字段建议

新增物种必须保持以下区间一致性（不引入新数值体系）：

| 字段 | 建议区间 | 理由 |
|------|---------|------|
| recovery_rate_base | 20 ~ 32 | 保持与现有区间一致 |
| reward_reputation | 4 ~ 8 | 不引入过高声望物种 |
| reward_rp | 5 ~ 10 | 不引入经济锚定突变 |
| water_pressure | 0.04 ~ 0.10 | 略扩但不破坏水质阈值 |
| injury_type | 保持 "reserved" | 仍禁用 injury branching |
| category | 可新增 coral / invertebrate | 增加类别多样性 |

---

## 七、M17 数量放行建议

基于以上全部诊断：

| # | 问题 | 建议 | 理由 |
|---|------|------|------|
| 1 | 是否支持规划目标 9 | **YES** | 基础设施（manifest/fallback/cards/codex）已支撑 |
| 2 | 是否建议一次性启用 9 | **NO** | 建议先 6 后 3 分批灰度，降低资产风险和 UI 风险 |
| 3 | 是否必须先做图鉴网格化 | **NO（6 物种）; 建议（9 物种）** | 6 物种 HBoxContainer 够用；9 物种建议改用 FlowContainer |
| 4 | 是否建议抽取算法改为无放回轮转 | **YES — M17-T01** | 9 物种下有放回体验很差；必须在扩池同时改算法 |
| 5 | "到达不报种名、带回后揭晓" | 可选增强，**非 M17 必须** | 属于情感设计优化，可留在 T03 或 M18 |
| 6 | M17-T01 范围 | 物种清单 + pool 更新 + manifest placeholder + 算法改无放回 | 数据层冻结 |
| 7 | M17-T03 范围 | 真实资产接入 + RescueDockPanel 验证 + 图鉴折行 + 全回归 | 可玩层验证 |
| 8 | M18+ 保留 | 海域、声望等级、收藏奖励、多救助位、稀有度 | M17 不做 |

---

## 八、诊断数据汇总

| 维度 | 当前值 | M17 影响 |
|------|--------|---------|
| species_pool count | 3 | 目标 6~9 |
| card_manifest schema | v2 | 保持 v2，不升 |
| 候选抽取算法 | 有放回随机 | 必须改无放回轮转 |
| 图鉴 Visual Cards | HBoxContainer, 72×72 cards | 6 个够用，9 个建议 FlowContainer |
| 图鉴 Text Label | join 拼接 | 保留（兜底），不删 |
| 游戏日时长 | 2.4 分钟/天 | 不变 |
| 救助到达间隔 | 2-4 游戏日 / 4.8-9.6 分钟 | 不变 |
| 9 物种首轮覆盖（当前算法） | ~124 分钟 | 改无放回后 ~43 分钟 |
| injury_branching | false | 保持 false |
| save_version | v3 | 保持 v3 |
| save_schema | 未修改 | 保持未修改 |
