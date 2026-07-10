# M16-T02 Fixup1 Evidence Stability Report

Task: M16-T02-FIXUP1_EvidenceStability_ReportReceiptRerunClean

## Codex Review Failure

- M16-T02 functional checks passed, but Codex review failed the evidence closure.
- Rerunning `PowerShell -ExecutionPolicy Bypass -File tests/run_m16_t02_acceptance.ps1` rewrote:
  - `reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md`
  - `reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json`
- The pre-fix receipt recorded the base commit instead of the original T02 commit.
- The pre-fix report drifted in SHA casing, Tag/Suggested tag wording, and Final Closure content.

## Fixup Scope

- `tests/run_m16_t02_acceptance.ps1` now defaults to validation-only mode.
- The script no longer rewrites committed T02 report/receipt during normal reruns.
- Evidence writing is available only with explicit `M16_T02_WRITE_EVIDENCE=1`.
- T02 report/receipt were refreshed once with stable evidence content.
- SHA casing is lowercase in report, receipt, manifest, and script output.
- Tag wording is stable as `Tag`.
- Final Closure content is retained.

## Original T02 Evidence

- Original T02 tag: `v3.4-m16-t02-rescue-card-playable-ui`
- Original T02 tag object: `76cb2221e6fe26a11a364d8b841279e4d41cd15f`
- Original T02 target commit: `11dbf8a284acecfe16e2b9928a03aa4dfff7fc7f`
- Base tag: `v3.4-m16-t01-card-manifest`
- Base commit: `f7d2e7078e000ffd16e3160ea2dc4ace96d49825`

## Fixup Evidence Rule

- Evidence rule: `no_self_referential_annotated_tag_closure_v1`
- Old T02 tag is not moved.
- Fixup tag will be validated externally with:
  - `git rev-parse v3.4-m16-t02-rescue-card-playable-ui-fix1`
  - `git rev-parse v3.4-m16-t02-rescue-card-playable-ui-fix1^{}`

## Validation Result

- M16-T02 functional result: PASS
- M16-T01 regression: PASS
- M13/M14/M15 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds / 580 seconds unchanged
- FORBIDDEN_TOUCHED: 0
- SaveSystem/save_schema: unchanged
- SAVE_VERSION: v3
- Manifest SHA validation: PASS
- TextureRect.texture != null: PASS
- Five viewport screenshots remain present at 960x540
- M16-T03: not started

## Recommendation

- Re-run `tests/run_m16_t02_acceptance.ps1`.
- If `git status --short` remains empty after rerun, submit this fixup for Codex re-review.
- M16-T03 remains blocked until Codex PASS.
