# ReefIdle V3 M6 Livestock Carrying Capacity And Reef Value Loop Report

## Scope

Task: ReefIdle_V3_M6_Livestock_CarryingCapacity_ReefValueLoop

V3 root:
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3

Old project modified: No

## Created Files

- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\livestock\starter_livestock_seed.json
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\tools\check_livestock_reef_value_loop.py
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m6_livestock_reef_value_check_summary.json
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m6_livestock_carrying_capacity_reef_value_loop_report.md

## Modified Files

- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scripts\systems\LivestockSystem.gd
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scripts\systems\EconomySystem.gd
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scripts\systems\GameState.gd
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scenes\main\Main.gd
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scenes\main\Main.tscn
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scenes\ui\StatusPanel.gd
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\tools\check_water_chemistry_ui_visibility.py
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\tools\check_ui_readability_dynamic_update.py

## Starter Livestock

Starter livestock count: 6

- clownfish_pair, Clownfish Pair
- blue_tang, Blue Tang
- anemone, Anemone
- green_star_polyps, Green Star Polyps
- zoanthids, Zoanthids
- soft_coral_frag, Soft Coral Frag

Chinese display names are stored in:
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\livestock\starter_livestock_seed.json

## Capacity Formula Summary

capacity_used is the sum of enabled starter livestock capacity_cost.

Current prototype:

- capacity_used: 18.0
- capacity_limit: carrying_capacity_score from GameState
- current Tier 1 carrying_capacity_score: 27.0
- capacity_status: normal when used is below 92 percent of limit, full near the limit, overloaded above the limit

No livestock death is implemented when capacity or water quality is bad.

## Reef Value Formula Summary

base_reef_value is the sum of enabled starter livestock base_reef_value.

Current prototype:

- base_reef_value: 59.0
- health_modifier comes from water quality score and livestock water sensitivity
- capacity_modifier reduces value only when capacity_used exceeds capacity_limit
- reef_value = base_reef_value * health_modifier * capacity_modifier

With current stable M5 water quality, reef_value is expected to stay near 59.0.

## Income Rate Formula Summary

income_rate_per_game_hour = reef_value * 0.04 * water_income_modifier

water_income_modifier is derived from water_quality_score and clamped from 0.20 to 1.00.

With current stable M5 water quality:

- water_income_modifier: about 1.00
- income_rate_per_game_hour: about 2.36
- Reef Points increase over accelerated game time through EconomySystem.update_income()

## Economy Fields

EconomySystem tracks:

- reef_points
- total_reef_points_earned
- reef_value
- income_rate_per_game_hour

Initial reef_points: 0.0

## UI Fields Added

StatusPanel now shows compact Chinese player-facing fields for:

- livestock count
- capacity used and limit
- capacity status
- reef tank value
- Reef Points
- income speed per game hour
- livestock health modifier
- water income modifier

StatusPanel rows were compacted into a two-column GridContainer to avoid overflow while preserving the existing aquarium and sump layout.

## Check Results

- python tools\validate_data.py: Passed
- python tools\check_godot_skeleton.py: Passed
- python tools\check_tier1_equipment_system.py: Passed
- python tools\check_equipment_slot_ui_binding.py: Passed
- python tools\check_water_chemistry_system.py: Passed
- python tools\check_water_chemistry_ui_visibility.py: Passed
- python tools\check_ui_readability_dynamic_update.py: Passed
- python tools\check_livestock_reef_value_loop.py: Passed

Validation summary:
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\validation_summary.json

M6 checker summary:
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m6_livestock_reef_value_check_summary.json

## Godot CLI Smoke Test

Godot CLI status: Not available in PATH.

Checked commands:

- godot --version: not found
- godot4 --version: not found
- Godot_v4* in PATH: not found

Headless smoke test status: Not run because Godot CLI was not available.

Manual follow-up: add the Godot 4 executable to PATH or run the project manually from the Godot editor.

## DataRegistry Counts

Counts remain unchanged:

- species: 161
- equipment: 28
- tasks: 10
- events: 7

## Explicit Non-Goals Preserved

- No livestock death.
- No breeding.
- No growth.
- No reproduction.
- No species shop.
- No Tier 2 or Tier 3 unlock.
- No plumbing gameplay.
- No free drag-and-drop.
- No full save/load.

## Variant Inference Scan

No := operator was found in scanned target GDScript files.

## Next Step Recommendation

Next recommended task: M6.1 StatusPanel Layout Cleanup.
