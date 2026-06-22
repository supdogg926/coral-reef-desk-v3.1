# M10.1 Livestock UI Integration Report

## Summary

M10.1 fixes two critical M10 bugs:
1. **Save/load wipe bug**: Loading a pre-M10 save cleared starter livestock (empty `{}` dict passed `is Dictionary` check, triggering `import_state({})` which cleared `owned_livestock`).
2. **Missing visible UI**: No shop or livestock panel existed — players couldn't see or buy livestock.

## Modified Files

| File | Change |
|---|---|
| scripts/systems/GameState.gd | Added `has("owned_livestock")` guard before calling `livestock_system.import_state()` to prevent empty saves from wiping starter livestock |
| scenes/main/Main.gd | Complete rewrite: added shop/livestock toggle buttons, ShopPanel and LivestockPanel instantiation, panel positioning, refresh logic |

## Created Files

| File | Purpose |
|---|---|
| scenes/ui/ShopPanel.gd | Shop UI panel: 10 species with buy buttons, RP/capacity feedback |
| scenes/ui/LivestockPanel.gd | Owned livestock panel: shows all owned livestock with stats, refreshable |
| tools/check_m10_1_livestock_ui_integration.py | M10.1 validation checker |
| reports/m10_1_livestock_ui_integration_report.md | This report |

## Root Cause Analysis

### Bug 1: Starter Livestock Wiped on Load

```
GameState._apply_save_state():
  raw_livestock = save_data.get("livestock", {})  # {} for M9 saves
  if raw_livestock is Dictionary:                  # {} is Dictionary = TRUE!
    livestock_system.import_state({})              # Clears all livestock!
```

Fix: Added `if raw_livestock.has("owned_livestock"):` guard. Empty dicts from old saves no longer trigger import.

### Bug 2: No Visible UI

M10 added `buy_livestock_from_shop()` to GameState but had no UI to call it. Players couldn't see the shop, couldn't see their livestock, couldn't click buy.

Fix: Created ShopPanel (10 species + buy buttons) and LivestockPanel (owned list). Added toggle buttons "生物商店" and "我的生物" to Main scene.

## UI Layout

```
┌─ Main ──────────────────────────────────────────┐
│ Title: CoralReefIdleV3                          │
│ Display Tank                                    │
│ Sump View                                       │
│ Pipe Overlay                                    │
│ StatusPanel (5 columns)                         │
│ [生物商店] [我的生物]          ← NEW buttons    │
│                                                 │
│ ┌─ ShopPanel (overlay, bottom) ──────────────┐  │
│ │ 生物商店                                     │  │
│ │ 名称｜分类｜稀有度｜价格｜尺寸｜容量｜收益/h   │  │
│ │ 荧光草皮｜软体珊瑚｜普通｜RP15｜2-5cm｜... [带回家] │
│ │ ... (10 items)                               │  │
│ │ 购买反馈：成功/容量不足/RP不足                │  │
│ │ [关闭商店]                                   │  │
│ └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Verification Stats

| Stat | Value |
|---|---|
| Commit hash | (see git log) |
| Changed files | 3 modified, 4 created |
| Pushed to main | Yes |
| Purchasable species | 10 |
| Current owned (initial) | 6 |
| Current capacity | ~18.0/30.0 |
| Current base income/h | ~2.36 (from starter) |
| Current effective income/h | varies with water quality |
| Buy 1 公子小丑 (+0.40/h) | base income → ~2.76/h |
| Restart restores purchase | Yes (autosave includes livestock) |
| Save file has livestock | Yes |

## Preserved Systems

- M5-M9 all preserved.
- M10 core loop preserved (shop data, capacity, income formula).
- M8.2 five-column layout preserved.
- Tier 2/3 restrictions preserved.
- DataRegistry counts unchanged.
- No `:=` in scanned scripts.
- Old project not modified.

## Check Results

All 17 Python checks pass.

## Next Step

M10.1 is complete. M11 can address growth mechanics, visual representation in display tank, or rarity-based visual effects.
