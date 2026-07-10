# M17 规划冻结最终版 v2（Fable 裁决修订版）

**版本**: v2 — 基于 Fable 裁决修订
**日期**: 2026-07-10
**M16 状态**: CLOSED / CODEX FINAL PASS (v3.4-m16-final-rescue-visual-identity @ 4b66dbf7)
**M17 开发**: 尚未允许

---

## 一、M17 背景

- M14 建立救助闭环（840s first loop）
- M15 解决恢复等待无操作（580s care path）
- M16 解决救助生物没有视觉形象（3 真实物种卡片 + 图鉴）

M17 的自然承接：扩展救助物种池，从 3 → 6 → 9，增加内容厚度。

## 二、M17 冻结裁决

| # | 裁决项 | 决定 |
|---|--------|------|
| 1 | **方向** | `M17_RescueSpeciesPoolExpansion` |
| 2 | **规划目标** | 9 个救助物种 |
| 3 | **执行节奏** | **分两批：6 + 3**。第一阶段扩到 6，后续扩到 9 |
| 4 | **抽取算法** | 有放回随机 → **one-draw bag draw**（每候选 1 次 RNG） |
| 5 | **算法禁止** | 禁止 Fisher-Yates / 预洗牌 / 周期边界额外 reroll / 条件抽取 |
| 6 | **UI 策略** | 6 物种不改图鉴 UI；9 物种 HBoxContainer → FlowContainer |
| 7 | **card_manifest** | **保持 schema_version=2**，不升版 |
| 8 | **存档** | **零新增存档字段**。save_version 继续 v3。不改 SaveSystem/save_schema |
| 9 | **资产来源** | **Image2 为主**，沿用 M16 rembg→256→SHA→manifest 管线 |
| 10 | **图鉴边界** | 相册页，非收藏系统。不做未解锁剪影/稀有度/卡包/奖励 |
| 11 | **injury_branching** | 保持 false。所有物种 injury_type=reserved |
| 12 | **参数区间** | 新增物种必遵现有实测区间，不引入新数值梯队 |
| 13 | **JSON 规则** | species_rescue_pool.json 只含启用记录，无注释/伪字段/预备标记 |
| 14 | **回归策略** | M15-T01 按 Rebaseline Protocol v2 执行，非简单"全 PASS" |
| 15 | **RNG 约束** | 每候选 1 次 RNG；不改变 `_schedule_next_arrival` 的 RNG 消耗顺序 |

## 三、物种数量与分批

### 3.1 分批策略

| 阶段 | 启用数 | 清单数 | 说明 |
|------|--------|--------|------|
| M16 末态 | 3 | 3 | clownfish / shrimp / goby |
| M17 Phase 1 | **6** | 9 | 新增 3 个启用 + 3 个预备（仅 report） |
| M17 Phase 2 | **9** | 9 | 激活预备 3 个 |

### 3.2 Phase 1 新增物种清单（3 → 6，写入 pool JSON）

| species_id | category | care_need 建议 | 说明 |
|---|---|---|---|
| `rescue_seahorse` | fish | weak | 海马 — 高频救助物种 |
| `rescue_hermit_crab` | crustacean | weak | 寄居蟹 — 甲壳类扩展 |
| `rescue_brain_coral_frag` | coral | stressed | 脑珊瑚碎片 — 首个珊瑚救助物种 |

### 3.3 Category 配比

| Category | M16 | +Phase 1 | = Phase 1 总计 |
|----------|-----|----------|---------------|
| fish | 2 | +1 | **3** |
| crustacean | 1 | +1 | **2** |
| coral | 0 | +1 | **1** |
| **总计** | **3** | **+3** | **6** |

Schema support: `LivestockPanel.gd:246-250` — coral, fish, crustacean, algae, invertebrate 均已定义。

### 3.4 Phase 2 预备物种（仅写入 report，不写入 pool JSON）

| species_id | category |
|---|---|
| `rescue_mandarin_dragonet` | fish |
| `rescue_sea_star` | invertebrate |
| `rescue_anemone_tube` | invertebrate |

### 3.5 新增物种参数区间

| Field | 现有实测区间 | 新增物种必遵 |
|-------|------------|------------|
| recovery_rate_base | 22–30 | **22–30** |
| reward_reputation | 5–7 | **5–7** |
| reward_rp | 6–8 | **6–8** |
| water_pressure | 0.05–0.08 | **0.05–0.08** |
| injury_type | `"reserved"` | `"reserved"` |

不出区间。如需出区间，单独列理由等用户/Fable 另行裁决。

## 四、任务拆分

### M17-T01_PoolExpansionDataContract_And_OneDrawBagDraw

- 3 → 6 species_rescue_pool（9 完整清单仅 report）
- 新增 3 张 deterministic placeholder PNG + SHA → manifest
- 候选算法：有放回 → **one-draw bag draw**（每候选 1 次 RNG）
- M15-T01 回归按 Rebaseline Protocol v2
- 不接真实美术，不改 UI

### M17-T02_RescueSpeciesArtPipeline_And_ManifestAssets

- 为新增物种生成 Image2 资产
- rembg → resize 256 → SHA256 → manifest
- 资产验证截图（不验证 UI）

### M17-T03_ExpandedPoolPlayable_And_Regression

- 新增物种接入码头候选池
- RescueDockPanel 卡片验证
- LivestockPanel 图鉴：6 物种不改；9 物种 FlowContainer
- 全链路回归

### M17-Final_Closeout

- 关闭 M17，总结扩池数量、资产、回归、已知限制

## 五、M17 禁止范围

1. 不新增存档字段
2. 不修改 SaveSystem / save_schema / save_version
3. 不做 save migration
4. 不做海域地图 / 声望等级 / 声望商店
5. 不做收藏奖励 / 稀有度 / 卡包 / 卡背
6. 不做未解锁剪影墙
7. 不做多救助位
8. 不新增 care_need / 护理动作
9. 不做疾病 / 死亡 / 捕食
10. 不做新经济资源
11. 不进入 M18
12. JSON 中不写注释 / 不新增伪字段 / 不通过 enabled 字段表达预备

## 六、Rebaseline Protocol v2

M15-T01 使用 live pool（`m15_t01_caremodel_verify.gd:222`），pool 3→6 必然导致 event sequence 漂移。T01 回归必须执行：

1. 重新生成 30 天 baseline export
2. diff old vs new baseline
3. 仅允许 species selection / species_id / species_name 差异
4. arrival day / next_arrival / event timestamp / event type / RP / reputation / comfort / first loop duration / save keys 必须逐项一致
5. 非物种字段漂移 → T01 FAIL
6. Codex 须核查此 diff

## 七、Known Limitations

1. **读档重填袋**：bag 不持久化，读档后重填，轻微削弱周期不重复保证。禁止为此新增存档字段。
2. **周期边界重复**：上周期末物种可能与下周期首物种相同（6 物种概率 ~1/6），可接受。禁止条件抽取修复。

## 八、Readiness Diagnosis 关键证据

| 维度 | 实测值 | M17 影响 |
|------|--------|---------|
| species_pool | 3 | → 6 → 9 |
| 抽取算法 | 有放回随机 (RescueSystem.gd:253) | → one-draw bag draw |
| 图鉴 UI | HBoxContainer 72px cards | 6 够用; 9 → FlowContainer |
| card_manifest schema | v2 | 保持 v2 |
| placeholder SHA | 落盘 PNG SHA 必须 | T01 须生成 3 张 placeholder PNG |
| 游戏日 | 144s/day | 不变 |
| arrival interval | 2-4 days / 4.8-9.6min | 不变 |
| save_version | v3 | 保持 v3 |
| M15-T01 pool 使用方式 | live pool (verify.gd:222) | 必须 Rebaseline Protocol v2 |

## 九、时间估计（仅规划参考）

| 场景 | 时间 |
|------|------|
| 6 物种一轮（均值 arrival 7.2min） | ~43 分钟 |
| 9 物种一轮（均值 arrival 7.2min） | ~65 分钟 |
| 9 物种一轮（最小 arrival，乐观下限） | ~43 分钟 |

非验收硬指标。

## 十、仍需确认

1. 物种清单（seahorse / hermit_crab / brain_coral_frag）是否最终确认？
2. brain_coral_frag 配 stressed 是否接受？
3. Phase 2 预备清单是否接受？
4. one-draw bag draw 方案是否接受？
5. Rebaseline Protocol v2 是否接受？
6. M17-T01 任务卡是否可以下发执行？
