# M17-T02 Final Regression Report

**Generated**: 2026-07-11T18:17:18.942299+08:00
**Commit**: 289af7d556fd4213ab92fecef4eb0bb6d994b354
**Branch**: prototype/m17-t02-real-assets

## Regression Results

| Milestone | Result | Assertions | Notes |
|-----------|--------|-----------|-------|
| M11 | PASS | 42/42 (via M12 re-run) | M14 worktree, reset_flow 17/17 + ui_layout 25/25 |
| M12 | PASS | 36/36 + smoke | M14 worktree, feedback_timeline 19/19 + reset_visual 17/17 |
| M13 | PASS | 30-day sim | M14 worktree, progression 19/19 + save_load 9/9 |
| M16 | PASS | 26/0 | T02 worktree, manifest verify |
| M17-T01 | PASS | Structural 5/5 | Rebaseline Protocol v2, 11 content divergences expected |
| M17-T02-P1 | PASS | 87/87 | Asset production + signoff |
| M17-T02 Runtime Mapping | PASS | 6/6 | 12 textures loaded (9 manifest + 3 reserved) |
| M17-T02 Pool Semantics | PASS | All checks | 9 active, 3 reserved, 0 in pool |
| Build ID | PASS | Correct | CoralReefIdleV3 · M17-T02 · review-candidate |
| Godot Errors | PASS | 0/0/0/0/0 | Parse/Script/MissingResource/TextureLoad/AssertionFailure |

## Full Regression Verdict

FULL_REGRESSION_REVIEW_RESULT=PASS

All applicable frozen regression milestones verified PASS.
M11/M12/M13 run from CoralReefIdleV3_M14_T01 worktree (HEAD fb8856e, clean).
M16/M17-T01/M17-T02 run from CoralReefIdleV3_M17_T02 worktree (HEAD 289af7d556fd4213ab92fecef4eb0bb6d994b354).

## Screenshot Evidence

Runtime screenshots captured via live game launch.
Directory: reports/m17/t02/runtime_evidence/
See screenshot receipt for validation details.

## Godot Error Counts

GODOT_PARSE_ERROR_COUNT=0
GODOT_SCRIPT_ERROR_COUNT=0
GODOT_MISSING_RESOURCE_COUNT=0
GODOT_TEXTURE_LOAD_ERROR_COUNT=0
GODOT_ASSERTION_FAILURE_COUNT=0
