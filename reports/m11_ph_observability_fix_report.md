# M11 pH Observability Fix Report

Report date: 2026-06-23
Branch: `prototype/m11-biomanage-vertical-slice`
Scope: small MVP fix only.

## User-Found Issue

- Manual testing found that water maintenance buttons were visible and other maintenance effects worked.
- The player could not tell which maintenance action affected pH.
- pH appeared static in the HUD during maintenance testing.

## Root Cause Judgment

- The pH operation chain was present but unclear.
- `换水` changed pH, but the feedback only showed a compact signed delta, which was easy to miss.
- `补KH` used a fixed pH increase, which did not teach “KH stabilizes pH toward target” and could move pH away from 8.20 if already high.
- The recent-maintenance feedback did not show pH before and after values.

## Fix Summary

- `换水10%` now pulls pH more visibly toward target pH 8.20.
- `补充KH缓冲` now lightly pulls pH toward target pH 8.20.
- `清理滤材` does not directly change pH.
- `补淡水` does not directly change pH.
- Maintenance result dictionaries now include:
  - `ph_before`
  - `ph_after`
  - `ph_delta`
- Recent maintenance feedback now includes pH before/after and `ΔpH`.
- No save schema changes were made.

## Tools That Affect pH

- `换水`: pH moves toward 8.20.
- `补KH`: pH lightly moves toward 8.20 as teaching feedback for alkalinity stabilization.

## Tools That Do Not Directly Affect pH

- `清滤`: affects nutrients and stability only.
- `补水`: affects salinity and temperature only.

## Test Results

- Updated `res://tests/m11_water_maintenance_smoke_test.gd` to assert:
  - `换水` moves pH closer to 8.20.
  - `换水` returns detectable `ph_delta`.
  - `补KH` moves pH closer to 8.20.
  - `补KH` returns detectable `ph_delta`.
  - `清滤` does not directly change pH.
  - `补水` does not directly change pH.

## Manual Acceptance Checklist

- Click `换水`; recent maintenance line shows `pH old→new` and `ΔpH`.
- Click `补KH`; recent maintenance line shows `KH +...`, `pH old→new`, and `ΔpH`.
- Click `清滤`; nutrients change and pH remains stable.
- Click `补水`; salinity changes and pH remains stable.
- Confirm pH current reading remains visible with two decimals.
- Confirm no red Output / Debugger errors.
- Confirm no abnormal popup or click freeze.
