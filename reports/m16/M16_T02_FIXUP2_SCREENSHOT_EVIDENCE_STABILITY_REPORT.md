# M16-T02 Fixup2 Screenshot Evidence Stability Report

Task: M16-T02-FIXUP2_ScreenshotEvidence_RerunClean

## Codex Second Review Failure

- M16-T02-FIXUP1 fixed report/receipt drift, but Codex second review still failed evidence closure.
- A normal rerun of `PowerShell -ExecutionPolicy Bypass -File tests/run_m16_t02_acceptance.ps1` passed functionally but rewrote committed screenshot files:
  - `reports/m16/screenshots/m16_t02_02_active_rescue_card_visible.png`
  - `reports/m16/screenshots/m16_t02_03_care_need_text_still_visible.png`
  - `reports/m16/screenshots/m16_t02_04_fallback_placeholder_visible.png`
  - `reports/m16/screenshots/m16_t02_05_release_ready_card_visible.png`
- M16-T03 remains blocked.

## Fixup2 Scope

- Default `tests/run_m16_t02_acceptance.ps1` now verifies committed screenshots without overwriting repo screenshot evidence.
- Official screenshot refresh is gated behind explicit `-RefreshEvidence`.
- `tests/m16_t02_capture_screenshots.gd` now supports `M16_T02_SCREENSHOT_OUTPUT_DIR` so screenshot output can be directed by the PowerShell wrapper.
- `tests/m16_t02_rescue_card_verify.gd` now includes headless UI semantic checks for `RescueCardTexture`, including 96x96 size and non-null texture in candidate and active rescue states.
- No gameplay code changed.
- No UI behavior changed.
- No asset content changed.
- No save schema or SaveSystem changes.

## Default Rerun Behavior

- Normal command:
  - `PowerShell -ExecutionPolicy Bypass -File tests/run_m16_t02_acceptance.ps1`
- Default behavior:
  - runs asset, manifest, fallback, TextureRect, zero-save, and regression checks
  - verifies committed screenshots exist
  - verifies committed screenshots are 960x540
  - rejects 32x32 screenshots
  - verifies full-image variance
  - verifies card-region variance
  - does not rewrite `reports/m16/screenshots/*.png`
  - does not rewrite final report/receipt

## Refresh Evidence Behavior

- Explicit command:
  - `PowerShell -ExecutionPolicy Bypass -File tests/run_m16_t02_acceptance.ps1 -RefreshEvidence`
- Only this mode may refresh official repo screenshot evidence.
- The Godot screenshot script accepts `M16_T02_SCREENSHOT_OUTPUT_DIR`.
- Default temp screenshot directory for rerun diagnostics:
  - `$env:TEMP\CoralReefDesk\M16_T02_RERUN_SCREENSHOTS`

## Tag Chain

- Original T02 tag: `v3.4-m16-t02-rescue-card-playable-ui`
- Original T02 commit: `11dbf8a284acecfe16e2b9928a03aa4dfff7fc7f`
- Fixup1 tag: `v3.4-m16-t02-rescue-card-playable-ui-fix1`
- Fixup1 commit: `e2558f10aae402286e370cf06d315b292765d770`
- Fixup2 tag: `v3.4-m16-t02-rescue-card-playable-ui-fix2`
- Old T02 tag is not moved.
- Fixup1 tag is not moved.
- Evidence rule: `no_self_referential_annotated_tag_closure_v1`

## Validation Result

- M16-T02 default rerun: PASS
- M16-T01 regression: PASS
- M13/M14/M15 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds / 580 seconds unchanged
- FORBIDDEN_TOUCHED: 0
- SaveSystem/save_schema: unchanged
- SAVE_VERSION: v3
- Manifest SHA validation: PASS
- TextureRect.texture != null: PASS
- Committed screenshots: 5 present, 960x540, non-flat variance, card-region variance PASS
- Final report/receipt: not rewritten during default rerun
- Screenshot evidence: not rewritten during default rerun
- M16-T03: not started

## Recommendation

- Submit Fixup2 for Codex re-review.
- M16-T02 may close only after Codex PASS.
- M16-T03 remains blocked until Codex PASS.
