# M10 Livestock / Shop / Tank Capacity Core Loop Report

## Summary

M10 implements the core idle game loop: buy livestock from shop, add to tank, consume capacity, generate income at hourly rate, income multiplied by water quality and equipment factors. Livestock state is persisted in save files and restored on load. Offline progression uses livestock-based income.

## Stats

| Metric | Value |
|---|---|
| Purchasable species in shop | 10 |
| Default max capacity | 30.0 |
| Initial livestock count | 6 (from starter) |
| Initial capacity used | ~18.0/30.0 |
| Shop categories | 软体珊瑚 (4), LPS硬骨珊瑚 (3), 海水鱼 (3) |
| Rarity tiers | 普通, 精品, 稀有, 大师, 传奇 |
| Rarity "老练" removed | Yes (mapped to "稀有" on import) |
| Old names mapped | 绿手指→海葵, 糖果脑→绿火柴, 火炬珊瑚→宝石花 |

## Created Files

| File | Purpose |
|---|---|
| data/shop/initial_shop_seed.json | 10 purchasable species with prices, income, capacity costs |
| tools/check_m10_livestock_shop_capacity.py | M10 validation checker |
| reports/m10_livestock_shop_capacity_core_loop_report.md | This report |

## Modified Files

| File | Changes |
|---|---|
| scripts/systems/LivestockSystem.gd | Complete rewrite: owned_livestock array, add/remove, capacity management, income calculation with water quality multiplier table, rarity mapping, name mapping, shop data loading, export/import state |
| scripts/systems/GameState.gd | Updated income calculation to use livestock income + water quality + equipment multipliers. Added buy_livestock_from_shop() with RP checks and capacity validation. Added livestock to save/load flow. Milestone updated to M10. |
| scenes/ui/StatusPanel.gd | Updated livestock section: tank level, capacity used/max, base income, effective income, water quality multiplier, health modifier. Milestone to M10. |
| tools/check_livestock_reef_value_loop.py | Updated function signatures and UI text expectations for M10 API |
| tools/check_m6_1_ui_layout_cleanup.py | Updated livestock label expectations |
| tools/check_water_chemistry_ui_visibility.py | M9→M10 milestone |
| tools/check_m8_1_statuspanel_dynamic_reflow.py | M9→M10 milestone |
| tools/check_m8_2_statuspanel_five_column_reflow.py | M9→M10 milestone |

## Shop Species

| # | Name | Category | Rarity | Price | Income/h | Slot Cost |
|---|---|---|---|---|---|---|
| 1 | 荧光草皮 | 软体珊瑚 | 普通 | 15 | 0.20 | 2.0 |
| 2 | 闪千手 | 软体珊瑚 | 精品 | 40 | 0.50 | 3.0 |
| 3 | 海葵 | 软体珊瑚 | 稀有 | 120 | 1.20 | 5.0 |
| 4 | 纽扣珊瑚 | 软体珊瑚 | 普通 | 25 | 0.30 | 2.0 |
| 5 | 绿火柴 | LPS硬骨珊瑚 | 精品 | 60 | 0.70 | 4.0 |
| 6 | 宝石花 | LPS硬骨珊瑚 | 稀有 | 150 | 1.50 | 5.0 |
| 7 | 锤头珊瑚 | LPS硬骨珊瑚 | 精品 | 80 | 0.90 | 4.0 |
| 8 | 公子小丑 | 海水鱼 | 普通 | 30 | 0.40 | 3.0 |
| 9 | 蓝吊 | 海水鱼 | 精品 | 70 | 0.80 | 4.0 |
| 10 | 五彩青蛙 | 海水鱼 | 稀有 | 200 | 1.80 | 3.0 |

## Capacity System

- Default max_capacity: 30.0 (tank_level = 1)
- Initial capacity used: ~18.0 (6 starter livestock)
- Remaining capacity: ~12.0
- Purchase blocked when capacity exceeded, RP refunded
- Capacity status: normal (<92%), full (92-100%), overloaded (>100%)

## Income Formula

```
base_income = sum of (individual_income * health_percent) for all unlocked livestock
water_quality_multiplier = lookup from water_quality_score:
  >= 80: 1.00
  60-79: 0.85
  40-59: 0.60
  < 40: 0.30
equipment_multiplier = 1.0 + (stability_score - 50.0) * 0.004
effective_income = base_income * water_quality_multiplier * equipment_multiplier
```

## Purchase Flow

1. Player calls buy_livestock_from_shop(shop_id)
2. Shop entry fetched from initial_shop_seed.json
3. RP availability checked
4. RP spent (refunded on capacity failure)
5. Capacity checked: current + slot_cost <= max_capacity
6. Livestock added to owned_livestock array
7. Returns success/error with details

## Save/Load

- Livestock state included in save schema under "livestock" key
- Full livestock array saved with all fields
- On load, rarity normalized (老练→稀有), names mapped
- Capacity and income recalculated after import
- Offline progression uses loaded livestock income rate

## Rarity / Name Mapping

```
RARITY_MAP: {"老练": "稀有"}
NAME_MAP: {"绿手指": "海葵", "糖果脑": "绿火柴", "火炬珊瑚": "宝石花"}
VALID_RARITIES: ["普通", "精品", "稀有", "大师", "传奇"]
```

## Preserved Gameplay Systems

- M5 Water chemistry updates continue.
- M6 Livestock/economy loop upgraded for M10.
- M7 Unlock progression continues.
- M8 Full delta display continues.
- M8.2 Five-column weighted layout preserved.
- M9 Save/load/offline upgraded with livestock state.
- Tier 1 equipment remains installed/effective.
- Tier 2 remains preview only.
- Tier 3 remains locked.
- Plumbing/free-drag disabled.
- No livestock death/growth/breeding/reproduction.
- DataRegistry counts unchanged: species=161 equipment=28 tasks=10 events=7.
- No `:=` in scanned GDScript files (maturity_percent replaces growth_percent).

## Check Results

All 16 Python checks pass.

## Godot CLI Smoke Test

Godot CLI not found in PATH. Smoke test skipped.

## Old Project

C:\Users\admin\CoralReefIdle was NOT modified.

## Next Step Recommendation

M10 core loop is complete. Next milestone M11 could address:
- Livestock visual representation in display tank.
- Growth over time (maturity_percent increases with game time).
- Rarity-based visual effects.
- Bulk sell/remove livestock.
