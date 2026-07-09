# M14-T03 Evidence Fixup Report

Task: M14-T03-FIXUP_Evidence_Closure_And_Clean_Rerun

Overall Status: PASS for evidence fixup candidate; do not enter M14-T04 until Codex re-review.

## Codex Review FAIL Cause

Codex review failed M14-T03 evidence closure because the functional acceptance passed but the final evidence chain was not closed:
- Rerunning `tests/run_m14_t03_acceptance.ps1` changed tracked evidence files.
- The committed report and receipt recorded the base/T03 delivery commit instead of the fixup validation commit.
- `top_ux_issues` in the receipt was empty while the blind playtest report listed three issues.

## Files Fixed

- `tests/run_m14_t03_acceptance.ps1`
- `tests/m14_t03_capture_screenshots.gd`
- `reports/m14/M14_T03_RESCUE_UX_PACING_REPORT.md`
- `reports/m14/M14_T03_RESCUE_UX_PACING_RECEIPT.json`
- `reports/m14/M14_T03_CODEX_HANDOFF.md`
- `reports/m14/M14_T03_EVIDENCE_FIXUP_REPORT.md`
- `reports/m14/screenshots/t03_*.png`

## Commit Hash Correction

- Original Cloud Code commit: `bfa50f30c7e1f9b79ca5ea38463136482aaf69ed`
- Fixup validation commit: `a566b3ac15ba44381661a7918f6da4e6bf1eeb8b`
- `report`, `receipt`, and `handoff` were updated to identify `a566b3ac15ba44381661a7918f6da4e6bf1eeb8b` as the fixup validation commit.

Note: a Git commit cannot normally contain its own final SHA in tracked file content because the SHA is derived from that content. This report records the concrete fixup validation commit and the closure tag separately.

## top_ux_issues Completion

The receipt now matches blind playtest question 9:
- 恢复等待期间缺少主动操作 -> M15 护理决策
- 救助生物没有视觉形象 -> M16 卡牌美术接入
- 声望缺乏阶段感 -> M18 守护者等级 / 称号

## Screenshot Change

`t03_04_recovering.png` changed because the screenshot generator used runtime string hashing and unrounded float text in deterministic PNG seed/data generation. The fix replaces `String.hash()` with a stable FNV-style text seed and rounds recovery progress to two decimals. All T03 screenshots were regenerated once so future reruns compare against the deterministic generator output.

## Clean Rerun Fix

The acceptance script now preserves an already closed `final_validation_commit` from the receipt instead of rewriting evidence to the runtime HEAD on every rerun. This prevents report/receipt churn after evidence closure.

## Required Command Record

Initial commands before fixup:
- `git status --short`: dirty from Codex review rerun evidence files.
- `git log -5 --oneline`: current T03 delivery head was `bfa50f3`.
- `git tag --list "v3.2-m14-t03*"`: only `v3.2-m14-t03-rescue-ux-pacing` existed.

First rerun result:
- Command: `powershell -ExecutionPolicy Bypass -File tests/run_m14_t03_acceptance.ps1`
- Result: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 acceptance: PASS
- First loop duration: 840 seconds
- Forbidden touched: 0

After first fixup commit:
- Commit: `a566b3ac15ba44381661a7918f6da4e6bf1eeb8b`
- Purpose: deterministic screenshot generation, receipt field completion, regenerated evidence.

Second rerun result:
- Command: `powershell -ExecutionPolicy Bypass -File tests/run_m14_t03_acceptance.ps1`
- Result: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 acceptance: PASS
- First loop duration: 840 seconds
- Forbidden touched: 0

Second rerun `git status --short`:
- Empty output. Worktree clean after rerun.

## Tag Status

- `v3.2-m14-t03-rescue-ux-pacing`: superseded by evidence fix.
- `v3.2-m14-t03-rescue-ux-pacing-fix1`: Codex-reviewable closure candidate.

## Recommendation

- Recommend Codex re-review M14-T03 after this fixup.
- Do not enter M14-T04 until the re-review passes.
