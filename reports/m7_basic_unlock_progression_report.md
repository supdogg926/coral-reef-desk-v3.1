# M7 Basic Unlock Progression Report

## Summary

M7 minimal unlock progression system is complete and all checks pass. Codex partially implemented before stream disconnect; this session completed the remaining gaps (StatusPanel unlock line IDs, check script milestone updates, report generation).

## Created Files

| File | Status |
|---|---|
| scripts/systems/UnlockSystem.gd | Already existed (by Codex) |
| data/unlocks/unlock_milestones_seed.json | Already existed (by Codex) |
| tools/check_basic_unlock_progression.py | Already existed (by Codex) |
| reports/m7_basic_unlock_progression_check_summary.json | Already existed (by Codex) |
| reports/m7_basic_unlock_progression_report.md | Created this session |

## Modified Files

| File | Change |
|---|---|
| scenes/ui/StatusPanel.gd | Added unlock line IDs to dynamic section (stage, target, progress, unlocked, preview, advanced). Added default unlock text. Updated milestone from M6 to M7. |
| tools/check_water_chemistry_ui_visibility.py | Added M7 milestone to allowed_milestones list. |
| tools/check_livestock_reef_value_loop.py | Updated REQUIRED_UI_TEXT milestone from M6 to M7. |
| tools/check_m6_1_ui_layout_cleanup.py | Updated REQUIRED_STATUS_TEXT milestone from M6 to M7. |

### Additional files touched this session

These existing files were verified complete, no changes needed:

- scripts/systems/GameState.gd — UnlockSystem integration confirmed.
- scripts/systems/EquipmentSystem.gd — Tier 2/3 guard confirmed.
- scenes/main/Main.gd — update_unlock_debug binding confirmed.

## Unlock Milestones

| unlock_id | display_name_cn | threshold_total_reef_points | preview_items |
|---|---|---|---|
| tier1_running | 初级玩家 | 0 | (none) |
| tier2_equipment_preview | 解锁中级设备预览 | 500 | 冷水机, 杀菌灯, 藻缸灯, 造流泵 |
| tier2_sump_space_preview | 解锁中级底缸空间预览 | 1500 | 中级底缸空间 |
| tier3_advanced_system_preview | 高级系统预告 | 5000 | KH 稳定器, 钙反, 卷纸机, 煮豆机 |

tier3_advanced_system_preview has force_locked_in_m7: true. It remains locked regardless of Reef Points.

## Player Stage Logic

- total_reef_points_earned < 500: stage = 初级玩家
- total_reef_points_earned >= 500 (tier2_equipment_preview unlocked) or >= 1500 (tier2_sump_space_preview unlocked): stage = 中级玩家预备
- tier3 is always locked in M7.

## Reef Points Threshold Logic

- 0 to < 500: progress toward tier2_equipment_preview (target: 500)
- 500 to < 1500: progress toward tier2_sump_space_preview (target: 1500, progress calculated from offset 500 over range 1000)
- >= 1500: target = 高级系统预告（未解锁）, progress toward 5000

## Tier 2 Preview Handling

- Tier 2 equipment is NOT installed, NOT effective.
- EquipmentSystem.unlock_equipment() blocks tier > 1.
- Tier 2 items appear only in preview lists (unlocked_preview_items / locked_preview_items).
- Tier 2 has zero nonzero effects in equipment data (tier2_effect_record_count = 0).

## Tier 3 Locked Handling

- tier3_advanced_system_preview force_locked_in_m7 = true.
- UnlockSystem never sets tier3_advanced_system_preview to true.
- EquipmentSystem never allows tier 3 installation or effects.

## UI Fields Added

StatusPanel now displays in the dynamic confirmation section:

| Field | Chinese Label | Source |
|---|---|---|
| Player stage | 玩家阶段 | unlock_debug.current_stage |
| Next target | 下个目标 | unlock_debug.next_unlock_target |
| Unlock progress | 解锁进度 | unlock_debug.unlock_progress (as %) |
| Unlocked items | 已解锁 | unlock_debug.unlocked_preview_items |
| Preview equipment | 预览设备 | unlock_debug.unlocked_preview_items or locked_preview_items |
| Advanced system | 高级系统：未解锁 | static text |

## Preserved Gameplay Systems

All pre-M7 systems remain intact:

- M5 Water chemistry dynamic updates continue (GameState.update calls water_chemistry_system.simulate_tick).
- M6 Livestock/economy loop continues (GameState._update_livestock_and_economy calculates reef_value and income_rate).
- Reef Points continue to increase over time.
- Tier 1 equipment remains installed/effective.
- Plumbing gameplay remains disabled.
- Free drag-and-drop remains disabled.
- No livestock death/growth/breeding/reproduction.
- DataRegistry counts unchanged: species=161 equipment=28 tasks=10 events=7.
- No `:=` variant inference operator in target GDScript files.

## Check Results

| Check Script | Result |
|---|---|
| tools/validate_data.py | PASS |
| tools/check_godot_skeleton.py | PASS |
| tools/check_tier1_equipment_system.py | PASS |
| tools/check_equipment_slot_ui_binding.py | PASS |
| tools/check_water_chemistry_system.py | PASS |
| tools/check_water_chemistry_ui_visibility.py | PASS |
| tools/check_ui_readability_dynamic_update.py | PASS |
| tools/check_livestock_reef_value_loop.py | PASS |
| tools/check_m6_1_ui_layout_cleanup.py | PASS |
| tools/check_m6_2_pipe_arrow_deemphasis.py | PASS |
| tools/check_basic_unlock_progression.py | PASS |

All 11 Python checks pass. Summary JSONs in reports/ directory.

## Godot CLI Smoke Test

Godot CLI not found in PATH. Smoke test skipped. This is expected per task requirements ("如果 Godot CLI 不在 PATH，不要失败，写入报告").

To run smoke test manually when Godot is available:
  godot --headless --path . --script tests/smoke_test.gd

## Old Project

C:\Users\admin\CoralReefIdle was NOT modified. Only CoralReefIdleV3 was touched.

## Acceptance Criteria Verification

| # | Criterion | Status |
|---|---|---|
| 1 | UnlockSystem exists | YES |
| 2 | StatusPanel shows 玩家阶段 | YES |
| 3 | StatusPanel shows 下个目标 | YES |
| 4 | StatusPanel shows 解锁进度 | YES |
| 5 | StatusPanel shows 已解锁 | YES |
| 6 | Reef Points still increase over time | YES (economy loop preserved) |
| 7 | Tier 2 is preview only and not effective | YES |
| 8 | Tier 3 remains locked | YES |
| 9 | Tier 1 remains installed/effective | YES |
| 10 | Water chemistry still updates | YES |
| 11 | Livestock/economy loop still works | YES |
| 12 | Plumbing gameplay remains disabled | YES |
| 13 | Free drag-and-drop remains disabled | YES |
| 14 | DataRegistry counts remain species=161 equipment=28 tasks=10 events=7 | YES |
| 15 | All Python checks pass | YES |
| 16 | No `:=` in scanned target scripts | YES |
| 17 | M7 report generated | YES |
| 18 | Old project not modified | YES |

## Next Step Recommendation

M7 Basic Unlock Progression is complete. Next milestone M8 could address:

- Save/load for unlock state (optional, per rules M7 does not require full save/load).
- Tier 2 equipment installation with real effects (currently blocked by design).
- Visual indicators on equipment slots showing unlock/preview/locked status.
- Sound/notification when a new milestone is reached.
