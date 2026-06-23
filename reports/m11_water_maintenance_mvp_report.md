# M11 Water Maintenance MVP Report

Report date: 2026-06-23
Branch: `prototype/m11-biomanage-vertical-slice`
Mode: Fast prototype only.

## Scope

Implemented a narrow water-quality maintenance MVP on top of the existing M11 prototype branch.

## Player-Visible Prototype Features

- Main prototype entry bar now includes `水质维护` controls.
- Four actions are available:
  - `换水`: pulls core parameters toward targets and lowers NO3/PO4.
  - `清滤`: lowers NO3/PO4 and gives a small immediate stability bump.
  - `补KH`: raises pH, KH, and Ca.
  - `补水`: pulls salinity and temperature toward targets.
- Clicking an action immediately updates the water chemistry state, water score, livestock/economy modifiers, and status panel.
- The status panel now displays the latest maintenance action and delta summary.
- Successful maintenance schedules a delayed autosave through the existing save path.

## Modified Files

- `scripts/systems/WaterChemistrySystem.gd`
- `scripts/systems/GameState.gd`
- `scenes/main/Main.gd`
- `scenes/ui/StatusPanel.gd`
- `tests/m11_water_maintenance_smoke_test.gd`
- `reports/m11_water_maintenance_mvp_report.md`

## Save Compatibility

- No new save schema field was added.
- Existing water parameters are still saved through `water_chemistry.export_state()`.
- Last maintenance UI/debug text is runtime-only and resets after load.
- Save payload remains JSON-safe.

## Verification Performed

- Confirmed authoritative repo path and branch.
- Confirmed working tree was clean before edits.
- Confirmed M10 tag `v3.1-m10-livestock-core` still exists.
- Checked no `:=` variant inference operators were introduced in changed GDScript files.
- Ran `res://tests/m11_water_maintenance_smoke_test.gd`: PASS.
- Ran Godot 4.7 headless main scene startup with `--quit-after 3`: no red errors printed.

## Known Verification Limits

- `python` and `py` are not available in this environment, so Python validation scripts were not run.
- Existing `res://tests/smoke_test.gd` prints `SMOKE_TEST_RESULT=PASS`, but also emits an existing `DataRegistry` autoload compile warning while loading `Main.tscn` in script mode; main-scene startup itself did not reproduce that warning.
- No manual click-through screenshot was captured in this task.

## Risk Report

- The prototype allows repeated maintenance clicks without cooldown, cost, inventory, or labor constraints.
- `清理滤材` has a small immediate stability bump, but the next equipment simulation tick may overwrite stability from equipment effects.
- Overuse of `补KH` can push KH/Ca/pH upward until debug clamps apply.
- The UI is a compact prototype entry-bar control, not final production UX.
- Manual runtime confirmation is still recommended for button spacing and feedback readability.
