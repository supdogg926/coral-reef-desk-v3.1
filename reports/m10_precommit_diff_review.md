# M10 Precommit Diff Review

Report date: 2026-06-23  
Scope: M10 precommit diff review only. No business code edits, no bug fixes, no commit, no push, no tag, no M11.

## Files Read Before Review

- `PROJECT_RULES.md`
- `reports/m10_runtime_regression_result.md`
- `reports/m10_correct_repo_preseal_audit.md`
- `reports/task_risk_report_template.md`

## Preflight

```text
pwd
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3

git rev-parse --show-toplevel
C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3

git branch --show-current
main

git status --short
 M data/livestock/starter_livestock_seed.json
 M data/schemas/species_schema.json
 M scenes/main/Main.gd
 M scripts/systems/LivestockSystem.gd
 M scripts/systems/SaveSystem.gd
?? PROJECT_RULES.md
?? data/schemas/rarity_enum.json
?? data/schemas/save_schema.json
?? reports/m10_1_repo_and_baseline_verification.md
?? reports/m10_autosave_observation_plan.md
?? reports/m10_correct_repo_preseal_audit.md
?? reports/m10_runtime_regression_result.md
?? reports/task_risk_report_template.md
?? tools/dev_guard_check.ps1

git log -1 --oneline
22d94a6 fix: M10.12 replace typed array assignment with manual String cast in SaveSystem
```

Actual pre-review changed file count: 14.

## Diff Stat

```text
 data/livestock/starter_livestock_seed.json | 12 +++++
 data/schemas/species_schema.json           | 10 ++++
 scenes/main/Main.gd                        | 52 +++++++++++---------
 scripts/systems/LivestockSystem.gd         | 12 +++--
 scripts/systems/SaveSystem.gd              | 78 +++++++++++++++++++++++++++---
 5 files changed, 130 insertions(+), 34 deletions(-)
```

Only tracked modified files appear in `git diff --stat`; untracked files are reviewed separately below.

## Runtime Context

`reports/m10_runtime_regression_result.md` currently records:

```text
PASS: 20
FAIL: 0
NOT_TESTED: 0
```

Items 15/16 were updated using the autosave evidence:

- `[SAVE] regular autosave firing`
- `[SAVE] file store_string done`
- `[SAVE] save_game returned=true`
- `[HEARTBEAT] tick=60`
- `[HEARTBEAT] tick=61`

This supports proceeding to diff review, not direct commit/tag.

## File-By-File Review

| File | Type | M10 necessary | Runtime impact | Save schema changed | UI main path changed | Debug/test/heartbeat exposure | JSON save risk | Include in M10 commit | Exclude/defer |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `data/livestock/starter_livestock_seed.json` | modified | YES | YES, fixes starter livestock income/rarity data | NO | NO | NO | LOW, JSON primitives only | YES after gate acceptance | NO |
| `data/schemas/species_schema.json` | modified | YES | NO direct runtime unless schema validation is used | NO | NO | NO | LOW, JSON schema enum only | YES | NO |
| `scenes/main/Main.gd` | modified | YES for M10 debug validation gating | YES, UI entry/debug behavior | NO | YES, script-level UI path only; no `.tscn` scene file changed | YES, but gated by `OS.is_debug_build()` | LOW, no save payload object added | YES, with warning | Defer later cleanup of heartbeat/manual debug noise |
| `scripts/systems/LivestockSystem.gd` | modified | YES | YES, M10 capacity/shop/starter/save import path | NO | NO | NO | LOW, export remains dictionary primitives | YES | NO |
| `scripts/systems/SaveSystem.gd` | modified | YES | YES, save robustness | YES, adds `save_schema` field id | NO | YES, detailed `[SAVE]` logs | LOW after `_to_json_safe()`; risk reduced | YES, with warning | Cleanup verbose logs after M10 seal if desired |
| `PROJECT_RULES.md` | untracked | YES, governance gate | NO gameplay runtime impact | NO | NO | Mentions debug rules only | NO | YES | NO |
| `data/schemas/rarity_enum.json` | untracked | YES | NO direct runtime unless schema validation is used | NO | NO | NO | LOW, schema enum only | YES | NO |
| `data/schemas/save_schema.json` | untracked | YES | NO direct runtime unless schema validation is used; referenced by SaveSystem | YES, documents save shape | NO | NO | LOW, schema only | YES | NO |
| `reports/m10_1_repo_and_baseline_verification.md` | untracked | YES, audit provenance | NO gameplay runtime impact | NO | NO | Mentions debug/save checks | NO | YES as audit evidence | NO |
| `reports/m10_autosave_observation_plan.md` | untracked | YES, explains autosave evidence path | NO gameplay runtime impact | NO | NO | Mentions autosave/debug logs | NO | YES as audit evidence | NO |
| `reports/m10_correct_repo_preseal_audit.md` | untracked | YES, final preseal audit evidence | NO gameplay runtime impact | NO | NO | Mentions debug buttons/logs | NO | YES as audit evidence | NO |
| `reports/m10_runtime_regression_result.md` | untracked | YES, runtime PASS evidence | NO gameplay runtime impact | NO | NO | Contains autosave/heartbeat evidence | NO | YES as acceptance evidence | NO |
| `reports/task_risk_report_template.md` | untracked | YES, future gate template | NO gameplay runtime impact | NO | NO | Mentions risk checklist only | NO | YES | NO |
| `tools/dev_guard_check.ps1` | untracked | YES, local gate script | NO gameplay runtime impact | NO | NO | Scans debug/test/heartbeat keywords | NO | YES | NO |

Note: after this report is created, `reports/m10_precommit_diff_review.md` is also an untracked review artifact and should be included only if the release evidence bundle is intended to contain the precommit review itself.

## Focus Review: `SaveSystem.gd`

Result: WARNING, not BLOCKED.

Findings:

- Typed array fix remains compatible with latest HEAD: `last_saved_keys` is populated by clearing and appending `String(key)`.
- Autosave log chain matches the user-provided runtime output:
  - `file.store_string(json_text)`
  - `[SAVE] file store_string done`
  - `[SAVE] save_game return true`
  - `GameState._perform_autosave()` prints `[SAVE] save_game returned=...`
- JSON safety is strengthened:
  - `_to_json_safe()` accepts nil/bool/int/float/string/Array/Dictionary.
  - Non-JSON-safe values are rejected through `_mark_non_json_safe()`.
  - Debug arrays are converted through `_to_plain_string_array()`.
- Re-entry/equivalent protection exists:
  - `SaveSystem._is_saving`
  - `GameState._save_in_progress`
- Save schema is now explicitly referenced through `SAVE_SCHEMA_ID = "res://data/schemas/save_schema.json"`.

Warnings:

- Detailed `[SAVE]` logs are useful for M10 seal validation but noisy for later release builds.
- Recommendation: keep through M10 seal; schedule cleanup or dev-only logging after M10 tag, not in this task.

## Focus Review: `LivestockSystem.gd`

Result: PASS.

Findings:

- Changes serve M10 starter livestock, visible shop, carrying capacity, income, and save/import behavior.
- Adds `DEFAULT_MAX_CAPACITY = 30.0`.
- Adds `M10_SHOP_ITEM_COUNT = 10` and records a load error if visible shop count drifts.
- Starter rarity now reads normalized data rather than hardcoding all starter rarity in code.
- Import default capacity now uses the same default constant.
- No release-to-sea, ocean, expedition, breeding, complex death, encyclopedia, or new equipment system logic was found in `LivestockSystem.gd`.

Data check:

```text
starter_count=6
starter_capacity_sum=18
starter_income_sum=2.36
shop_count=10
rarity_enum=普通,精品,稀有,大师,传奇
```

## Focus Review: `Main.gd`

Result: WARNING, not BLOCKED.

Findings:

- No `.tscn` Godot scene file was modified.
- Script-level UI logic now gates heartbeat, reset-save button, manual-save button, and status label behind `_is_dev_debug_ui_enabled()`.
- `_is_dev_debug_ui_enabled()` returns `OS.is_debug_build()`.
- This is consistent with the project debug gating rule.

Warnings:

- `Main.gd` is still UI main path code, so it should be reviewed carefully before commit.
- Heartbeat and manual save are test/debug helpers. They are currently gated and useful for M10 validation, but should be cleaned up or moved to a dev panel before a polished release pass.

## Focus Review: Data Files

Result: PASS.

Findings:

- `starter_livestock_seed.json` has 6 starter records.
- Starter capacity sum is `18`, matching about `18.0/30.0`.
- Starter data now includes `rarity` and `base_income_per_hour`.
- `rarity_enum.json` fixes allowed rarity labels:
  - `普通`
  - `精品`
  - `稀有`
  - `大师`
  - `传奇`
- `save_schema.json` defines the M10 save envelope and required major sections.
- `species_schema.json` now includes the same rarity enum and remains compatible with current livestock data.

## Forbidden M11 / New-System Check

Result: PASS.

Checked modified gameplay files:

- `scenes/main/Main.gd`
- `scripts/systems/LivestockSystem.gd`
- `scripts/systems/SaveSystem.gd`

Search for forbidden system terms found no gameplay implementation of:

- 放归 / release-to-sea
- 大海 / ocean
- 远征 / expedition
- 繁殖 / breeding
- 复杂死亡 / complex death

Mentions of forbidden systems exist in governance/report files only as restrictions or audit text.

## Dev Guard Script

Command:

```text
PowerShell -ExecutionPolicy Bypass -File .\tools\dev_guard_check.ps1
```

Exit code: `1`

Summary:

```text
Gate Result: WARNING
Allow continue: YES
Allow commit: NO
Allow tag: NO
Allow next milestone: NO
```

Warnings:

- Changed file count is above warning limit: `14 > 12`.
- Changed files include save-related paths.
- Changed files include UI-related paths.
- `debug/test/heartbeat` keyword found in changed content.
- Save-risk keyword found in changed content.
- Wrong project path `C:\Users\admin\CoralReefIdle` found in changed content; review confirms it appears as a forbidden/non-authoritative path in rules and reports, not as an active project path.
- PowerShell/Git emitted LF-to-CRLF working-copy warnings for the 5 tracked modified files.

BLOCKED findings: none found.

## Recommendation

Current recommendation: DO NOT COMMIT YET.

Reason:

- The current task forbids committing.
- The guard script returned WARNING and `Allow commit: NO`.
- Human approval is needed for the warning set because the changed set intentionally includes save/UI/debug-gated work and audit governance files.

Recommended candidate files for the eventual M10 commit after warning acceptance:

- `data/livestock/starter_livestock_seed.json`
- `data/schemas/species_schema.json`
- `data/schemas/rarity_enum.json`
- `data/schemas/save_schema.json`
- `scenes/main/Main.gd`
- `scripts/systems/LivestockSystem.gd`
- `scripts/systems/SaveSystem.gd`
- `PROJECT_RULES.md`
- `tools/dev_guard_check.ps1`
- `reports/m10_1_repo_and_baseline_verification.md`
- `reports/m10_autosave_observation_plan.md`
- `reports/m10_correct_repo_preseal_audit.md`
- `reports/m10_runtime_regression_result.md`
- `reports/task_risk_report_template.md`
- `reports/m10_precommit_diff_review.md` if this review report should be part of the release evidence bundle.

Recommended files to exclude/defer:

- None are clearly unrelated to M10.
- The verbose save/heartbeat debug logs should be cleaned up later, after M10 seal, not removed before the current M10 evidence is committed.

Suggested commit message:

```text
chore: seal M10 livestock save baseline and audit evidence
```

## Final Gate

- BLOCKED found: NO
- WARNING found: YES
- Recommend commit now: NO
- Allow commit: NO
- Allow tag: NO
- Allow next milestone: NO
- M10 status: runtime regression PASS 20 / FAIL 0 / NOT_TESTED 0, pending human acceptance of precommit warnings and explicit commit permission.
