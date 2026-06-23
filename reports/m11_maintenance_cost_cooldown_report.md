# M11 Maintenance Cost And Cooldown Report

Report date: 2026-06-23
Branch: `prototype/m11-biomanage-vertical-slice`
Scope: prototype water maintenance cost/cooldown MVP.

## Implementation Summary

- Water maintenance actions now route through a unified `GameState` runtime wrapper.
- The wrapper checks cost, checks cooldown, performs the water chemistry action, and returns a unified result dictionary.
- Existing Reef Points are used as the prototype maintenance currency.
- Cooldowns are runtime-only and are not saved.
- Maintenance feedback now includes cost and cooldown details.
- Buttons show action cost in the compact M11 prototype entry bar.
- StatusPanel recent-maintenance line shows success, cooldown, or insufficient-funds feedback.

## Modified Files

- `scripts/systems/WaterChemistrySystem.gd`
- `scripts/systems/GameState.gd`
- `scenes/main/Main.gd`
- `scenes/ui/StatusPanel.gd`
- `tests/m11_water_maintenance_smoke_test.gd`
- `reports/m11_maintenance_cost_cooldown_report.md`

## Cost Table

- `换水`: 20 RP
- `清滤`: 15 RP
- `补KH`: 12 RP
- `补水`: 8 RP
- `出门维护`: 60 RP

## Cooldown Table

- `换水`: 10 seconds
- `清滤`: 8 seconds
- `补KH`: 12 seconds
- `补水`: 6 seconds
- `出门维护`: 30 seconds

## Currency Decision

- Used existing `EconomySystem.reef_points` and `spend_reef_points()`.
- No prototype-only maintenance budget was added.
- Formal M11 should decide whether maintenance consumes Reef Points or a dedicated currency/resource.

## Explicit Non-Changes

- `SaveSystem.gd` was not modified.
- No save schema field was added.
- `data/*` was not modified.
- `.tscn` scene files were not modified.
- `project.godot` was not modified.
- No livestock death, disease, or health penalty system was added.

## Test Results

- Updated `res://tests/m11_water_maintenance_smoke_test.gd`.
- Covered:
  - successful paid water change
  - cost deduction
  - immediate cooldown block
  - KH/pH observable change from `补KH`
  - insufficient funds failure without water mutation
  - no SaveSystem instance used in the cost/cooldown smoke path

## Manual Acceptance Checklist

- Confirm maintenance buttons show costs.
- Confirm successful maintenance shows cost and cooldown in recent feedback.
- Confirm clicking the same maintenance action again immediately shows cooldown remaining.
- Confirm insufficient RP shows an insufficient-funds message and does not change water readings.
- Confirm `生物商店` and `我的生物` still open normally.
- Confirm dev manual-save/reset buttons still work in debug builds.
- Confirm 1280x720 layout remains usable with StatusPanel scrolling.
- Confirm Godot Output / Debugger has no red errors.

## Risk Points

- Costs are prototype numbers and may not match final economy balance.
- Cooldowns are runtime-only and reset after restart.
- The compact entry-bar UI may need a formal layout pass later.
- `出门维护` is a prototype convenience action, not a full travel-prep system.

## Formal M11 Recommendation

Keep the cost/cooldown wrapper concept for formal M11, but rebalance costs and decide the final maintenance currency before lock.
