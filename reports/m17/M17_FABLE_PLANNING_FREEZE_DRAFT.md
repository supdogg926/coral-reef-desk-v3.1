# M17 规划冻结草案：RescueSpeciesPoolExpansion

## 一、M17 背景

ReefIdle / CoralReefDesk 的救助系统经历了三个阶段：

- **M14_RescueCore_Playable**：建立救助闭环（码头来客 → 带回 → 恢复 → 放归 → 图鉴记录），基线 first loop 840s。
- **M15_RescueCare_DecisionDepth**：解决"恢复等待无操作"，加入轻量护理决策，first loop 优化至 580s。
- **M16_RescueVisualIdentity_CardsAndCodex**：解决"救助生物没有视觉形象"，接入真实卡片图和图鉴视觉档案。

当前 M16 已正式封版（tag: `v3.4-m16-final-rescue-visual-identity`），三张真实救助生物图（小丑鱼、清洁虾、虾虎）已接入 RescueDockPanel 和 LivestockPanel 图鉴。

M17 的自然承接方向是扩展救助物种池。目前只有 3 个救助物种，内容厚度不足以支撑长期救助体验。玩家很快会重复遇到相同的三个物种，救助的新鲜感和情感价值会迅速衰减。

## 二、M17 初步方向

**代号**：`M17_RescueSpeciesPoolExpansion`

**一句话目标**：在不新增存档字段、不引入新经济系统、不做收藏玩法的前提下，把当前 3 个救助物种扩展为一组更有代表性的海水救助物种池。

**核心理由**：
1. 3 个物种的救助循环在 2-3 小时后即产生重复疲劳。
2. M14/M15/M16 的救助基础设施已足够支撑更多物种，不需要先重构。
3. 扩池是最高性价比的内容厚度提升，远低于新玩法系统的开发成本。
4. 扩池不破坏现有救助语义，只增加多样性。

## 三、Fable 必答 P0 问题

### P0-1：M17 优先级裁决

M17 是否确实应该优先扩展救助物种池，而不是做以下任一方向？

- 海域地图 / 目的地系统
- 声望等级 / 声望商店
- 收藏奖励 / 收集进度奖励
- 新经济资源（如珊瑚币）
- 多救助位

### P0-2：M17 扩展几个物种最合适？

| 选项 | 数量 | 说明 |
|------|------|------|
| A | 3 → 6 | 最小扩展，1 批次 |
| B | 3 → 9 | 中等扩展，2 批次 |
| C | 3 → 12 | 较大扩展，3 批次 |
| D | 先只加 3 个做小扩展 | 最小可行验证 |
| E | 其他数量 | 请指定 |

### P0-3：物种选择原则

候选原则（请确认或修改）：

- 高频海水观赏生物（玩家可能认识或见过的）
- 视觉辨识度强（不同物种外观差距明显）
- 与救助场景匹配（虚弱、受困、搁浅等场景合理）
- 适合 Image2 / ReefSpeciesCards 生成
- 不需要复杂动画
- 不引发疾病 / 死亡 / 捕食等复杂系统
- 至少覆盖 2-3 个生物类别（鱼、甲壳、软体等）

### P0-4：M17 是否继续保持零存档字段？

**建议：是。** 继续从以下现有数据派生显示：
- `species_rescue_pool` → 物种定义
- `card_manifest` → 卡片资产
- `codex_rescue_marks` → 已救助标记
- `completed_rescues` → 救助历史计数

### P0-5：M17 是否允许修改 species_rescue_pool.json？

**建议：允许。** 但必须是 M17 唯一核心数据变更之一，且需要：
- Schema 验证
- Manifest 同步更新
- Fallback 回归
- M13/M14/M15/M16 全回归 PASS

### P0-6：M17 资产来源如何冻结？

| 选项 | 方案 |
|------|------|
| A | 全部 Image2 生成（延续 M16-T02 管线） |
| B | 全部 ReefSpeciesCards（需要匹配物种） |
| C | Image2 为主，ReefSpeciesCards 为参考 |
| D | 先用 deterministic placeholder，真实图后续再接 |

**建议：A 或 C。** M16-T02 已验证 Image2 + rembg + resize 256 管线可行。

### P0-7：card_manifest schema_version 是否升级？

当前 schema_version = 2。M17 新增物种条目是否需要升级到 v3？

**建议：不升级，除非有硬需求。** 2 → 3 需要明确的 schema 变更理由（如新增必填字段）。

### P0-8：M17 是否允许显示未救助物种？

**建议：仍不做未解锁剪影墙。** 最多只显示已救助记录。避免把图鉴从"相册页"变成"收集进度表"。

### P0-9：M17 是否允许增加图鉴排序 / 分类？

**建议：可以规划，但谨慎。** 若做，只能是视觉排序（按类别/救助时间），不新增存档字段。

### P0-10：M17 是否允许引入新奖励？

**建议：不允许。** 扩池任务不应变成经济系统任务。新物种的声望/RP 奖励沿用现有 rescue_config 参数体系即可。

## 四、建议的 M17 任务拆分

### 方案 A：标准 4 阶段

1. **M17-T01_RescueSpeciesPoolExpansionPlan_And_DataContract**
   - 冻结新增物种清单
   - 更新 species_rescue_pool
   - 更新 card_manifest（先 placeholder，后真实图）
   - 不接真实美术
   - 不做 UI

2. **M17-T02_RescueSpeciesArtPipeline_And_ManifestAssets**
   - 为新增物种生成 / 处理真实卡片图
   - rembg → resize 256 → SHA256 → manifest
   - 截图证据：只做资产验证，不做 UI 验证

3. **M17-T03_ExpandedRescuePoolPlayableRegression**
   - 让新增物种进入码头候选池
   - RescueDockPanel 卡片显示验证
   - LivestockPanel 图鉴记录验证
   - 全链路回归（M13/M14/M15/M16）

4. **M17-Final_Closeout**
   - 关闭 M17
   - 总结扩池数量、资产清单、回归结果、已知限制
   - 不进入 M18

### 方案 B：紧凑 3 阶段（T02+T03 合并）

1. **M17-T01_DataContract_And_PlaceholderAssets**
2. **M17-T02_RealAssets_PlayableUI_And_Regression**
3. **M17-Final_Closeout**

**请 Fable 裁决选择 A 还是 B，或给出自己的拆分。**

## 五、M17 禁止范围

1. 不新增存档字段
2. 不修改 SaveSystem
3. 不修改 save_schema
4. 不修改 save_version（保持 v3）
5. 不做 save migration
6. 不做海域地图
7. 不做声望等级
8. 不做声望商店
9. 不做收藏奖励
10. 不做稀有度
11. 不做卡包
12. 不做卡背
13. 不做未解锁剪影墙
14. 不做多救助位
15. 不新增 care_need 类型
16. 不新增护理动作
17. 不做疾病 / 死亡 / 捕食系统
18. 不做新经济资源
19. 不进入 M18
20. 不做大规模 UI 重构

## 六、M17 风险清单

| # | 风险 | 等级 | 缓解措施 |
|---|------|------|---------|
| 1 | 物种数量过多导致资产生产化失控 | HIGH | 先冻结数量再开发；Image2 批量生成 |
| 2 | Image2 风格不统一（不同物种视觉差距大） | MEDIUM | 制定风格 prompt 模板；人工筛选 |
| 3 | ReefSpeciesCards 物种名不匹配 rescue pool | MEDIUM | 以 rescue species_id 为准；不匹配则用 Image2 |
| 4 | manifest SHA 漂移（处理后资产与记录不一致） | HIGH | T02 验收强制 SHA 校验；资产处理脚本化 |
| 5 | 截图 rerun 再次污染 repo | MEDIUM | 沿用 M16 证据规则；截图只进 report 不污染 worktree |
| 6 | 扩池破坏 M14/M15 first loop | HIGH | 回归必须验证 FIRST_LOOP_DURATION 840/580 不变 |
| 7 | 图鉴从相册页变成收藏系统 | MEDIUM | 仍不做未解锁剪影；不做收集进度；不做奖励 |
| 8 | 玩家期待稀有度 / 卡包 / 收集奖励 | LOW | 可以在 M18 或之后考虑，M17 明确不做 |
| 9 | species_rescue_pool 与 card_manifest 条目数不一致 | HIGH | 验收脚本强制校验 count 相等 |
| 10 | UI 空间被新增卡片挤爆（图鉴列表过长） | LOW | 当前只有 3 个物种卡片，即使扩到 9-12 仍然可控 |

## 七、需要 Fable 反驳的问题

请 Fable 明确反驳以下任何一点（同意则无需反驳）：

1. **M17 做扩池是不是错误方向？** 是否应该先做声望阶段、海域或其他系统？
2. **是否应该先做声望阶段而不是扩池？** 声望阶段感是 M14 暴露的第三个问题。
3. **是否应该先做海域而不是扩池？** 海域可以给救助增加空间叙事。
4. **物种数量应该是 6、9、12 还是更少？** 6 太保守？12 太多？
5. **是否应该继续零存档字段？** 还是应该在 M17 引入第一个存档扩展？
6. **是否应该继续不显示未救助剪影？** 未救助预览会变成变相收集系统吗？
7. **是否应该继续不做收藏奖励？** 无奖励的图鉴是否足够驱动玩家？
8. **是否应该把 Image2 资产纳入正式资产管线？** 还是应该等真实摄影/绘画资产？
9. **是否需要单独做 M17-T00 Art Pipeline Spike？** 在正式 T01 之前先验证资产生成管线？
10. **是否存在更小但价值更高的 M17？** 例如只加 1-2 个物种做极小验证？

## 八、Fable 最终输出要求

请在阅读本草案后，给出以下裁决：

1. **M17 方向裁决**：继续扩池 / 改为其他方向 / 缩小范围 / 延期
2. **M17 最小可行范围**：如果用一句话描述 M17 最小版本
3. **新增物种数量**：建议数字 + 理由
4. **新增物种选择原则**：确认、修改或补充
5. **资产来源裁决**：Image2 / ReefSpeciesCards / placeholder / 混合
6. **是否继续零存档字段**：YES / NO（如 NO，说明允许新增什么字段）
7. **是否允许改 species_rescue_pool**：YES / NO
8. **是否允许改 card_manifest schema**：YES → v3 / NO → 保持 v2
9. **最终任务拆分**：确认方案 A / B / 自定
10. **M17-T01 可执行任务卡**：如果方向确认，请输出冻结的 T01 任务卡
