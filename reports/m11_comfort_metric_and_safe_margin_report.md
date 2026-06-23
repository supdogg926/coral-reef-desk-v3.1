# M11 Comfort Metric And Safe Margin Report

Report date: 2026-06-24
Branch: `prototype/m11-biomanage-vertical-slice`
Base commit: `b8fb757 fix: clarify device feedback and RP placement`

## User Feedback

- RP balance near the water maintenance controls is now acceptable.
- Filter / NO3 / PO4 information is visible enough.
- The player still cannot identify which concrete value represents comfort.
- The player does not know where "health modifier" or "flow comfort" is shown.
- Screenshot feedback showed left-edge clipping on the top buttons, display tank border / overflow box, and status panel.

## Why Comfort Was Still Unclear

The previous wording used risk text such as `造浪不足，生物舒适度下降`. That described the problem but did not expose a measurable value. The StatusPanel also had health information in the livestock section, while device risk lived in the system section, so the connection between wave pump state, comfort, and health modifier was not obvious.

## Comfort Metrics Now Shown

`GameState.get_device_effect_summary()` now exposes prototype-only read fields:

- `flow_comfort_score` / `comfort_score`: default `100`, wave pump OFF subtracts `15`, return pump OFF subtracts `5`, clamped to `0-100`.
- `comfort_health_modifier`: default `1.00`, wave pump OFF subtracts `0.12`, return pump OFF subtracts `0.03`, clamped to `0.50-1.00`.
- `wave_comfort_effect`: `0.00` when wave pump is ON, `-0.12` when OFF.

The StatusPanel system area now includes a dedicated comfort line:

- `造浪ON：水流舒适度 100/100｜健康系数 1.00｜造浪影响 +0.00`
- `造浪OFF：水流舒适度 85/100｜健康系数 0.88｜造浪影响 -0.12`

## Health Modifier Mapping

For this prototype, the displayed health coefficient is a readable device-comfort indicator only. It is derived from the same device state that produces the flow comfort score. It is not saved, and it does not change the livestock or economy formulas.

## Other Device Feedback

Device impact text is split into concrete rows:

- Filter row: `过滤效率` plus NO3 / PO4 daily drift and water-quality score impact.
- Comfort row: wave pump state, flow comfort, health coefficient, and wave effect.
- Light row: light income percent, total income multiplier, and stability impact.

Device toggle feedback now uses the same explicit wording:

- Wave OFF reports flow comfort and health coefficient.
- Wave ON reports restored flow comfort.
- Return pump OFF reports filter efficiency and faster NO3 / PO4 rise.
- Main light OFF reports light income and income multiplier.

## Left-Side Clipping Diagnosis

The scene already had a root `MarginContainer`, but the screenshot showed practical left-edge clipping across multiple sections. That points to insufficient runtime safe margin at the viewport edge rather than a single child drawing issue. The display tank drawing itself starts inside its local rect, so the safer fix is to increase the root layout's left margin at runtime.

## Safe Margin Fix

`Main.gd` now applies runtime root safe margins:

- Left: `40px`
- Right: `18px`
- Top: `36px`
- Bottom: `24px`

The top prototype button rows were also made slightly more compact so the extra left margin does not push controls off the right edge.

## Modified Files

- `scenes/main/Main.gd`
- `scenes/ui/StatusPanel.gd`
- `scripts/systems/GameState.gd`
- `tests/m11_water_maintenance_smoke_test.gd`
- `reports/m11_comfort_metric_and_safe_margin_report.md`

## Test Results

- `git diff --check`: PASS. Only CRLF warnings were printed.
- `res://tests/m11_water_maintenance_smoke_test.gd`: PASS.
- `scenes/main/Main.tscn --quit-after 3`: PASS, no red errors printed.

## Manual Acceptance Checklist

- At 1280x720, confirm the left side of `生物商店` is fully visible.
- Confirm the display tank left border and left overflow box are fully visible.
- Confirm the status panel title and leftmost text are fully visible.
- Confirm `造浪ON` shows `水流舒适度 100/100` and `健康系数 1.00`.
- Toggle wave pump OFF and confirm the panel shows lower flow comfort and health coefficient.
- Toggle wave pump ON and confirm comfort recovers.
- Toggle return pump OFF and confirm filter efficiency plus NO3 / PO4 rise text is visible.
- Toggle main light OFF and confirm light income and income multiplier are visible.

## Explicit Non-Changes

- `SaveSystem.gd` was not modified.
- `WaterChemistrySystem.gd` was not modified.
- `LivestockSystem.gd` was not modified.
- `data/*` was not modified.
- `.tscn` scene files were not modified.
- `project.godot` was not modified.
- No main branch merge was performed.
- No tag operation was performed.
