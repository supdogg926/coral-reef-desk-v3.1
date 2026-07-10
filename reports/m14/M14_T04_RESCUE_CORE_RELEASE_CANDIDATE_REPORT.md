# M14-T04 RescueCore Playable Release Candidate Report

Overall Status: **PASS**

- Task: M14-T04_RescueCore_PlayableReleaseCandidate
- Branch: m14-t04-rescue-core-release-candidate
- Base tag: v3.2-m14-t03-closeout
- HEAD commit: verified externally by: git rev-parse HEAD
- Evidence rule: no_self_referential_annotated_tag_closure_v1
- Final candidate tag: v3.2-m14-t04-rescue-core-rc
- Final candidate tag target verification command: git rev-parse v3.2-m14-t04-rescue-core-rc^{}

## M14 Stage Summary

M14 is scoped to validating the RescueCore bring-back, recovery, release, reputation, and rescued-codex loop as a stable playable candidate. T04 does not add new systems; it consolidates T01, T02, and T03 into a release-candidate evidence package.

## T01 / T02 / T03 Output Summary

- T01: rescue data model, headless simulation, save migration, save/restart consistency.
- T02: first playable rescue UI, single rescue slot, release settlement, reputation display, rescued codex mark, first loop timing.
- T03: blind playtest, copy/pacing hardening, dock/rescue-slot/release/reputation/codex expression hardening, Codex handoff, evidence rule patch, formal closeout.

## Current RescueCore Loop

The current playable loop is: dock entry -> candidate appears -> player brings rescue into the single rescue slot -> recovery progresses over the first 10-15 minute window -> ready-to-release state appears -> player releases the rescue -> ecological reputation and rescued-codex marks persist.

## Verified Player Flows

- New game RescueCore loop: PASS via M14-T02 first playable verification.
- Old save migration: PASS via M14-T01 save schema migration verification.
- Save/restart consistency: PASS via M13 save/load and M14-T02 UI reload verification.
- 30-day simulation stability: PASS via M13 regressions and M14-T01 headless rescue simulation.
- First 10-15 minute rescue loop: PASS (840 seconds).

## Known Limitations

- Only one rescue slot exists.
- Injury type remains reserved data only; there is no injury branching.
- Recovery waiting has no active care decisions yet.
- Rescue creatures use text/UI state only; no card art integration is included.
- Reputation accumulates but has no shop or level system.
- Screenshot evidence remains deterministic headless state captures.

## Out Of Scope For T04

- Ocean/sea-zone system, ocean map, large ocean codex, multi-rescue slots, injury branches, care actions, breeding, card art, complex animation, reputation shop, reputation levels, new resources, species_master.json edits, M11 water/comfort core refactors, unrelated UI optimization.

## Follow-Up Recommendations

- M15: care decisions / active operation during recovery waiting.
- M16: rescue creature card art and visual identity.
- M18: reputation stage feel, guardian title/rank, and long-term recognition.

## Automatic Acceptance Results

| Test | Passed | Exit | Log |
|---|---:|---:|---|
| godot_static_editor_check | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_godot_static_editor_check.log |
| m13_smoke_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m13_smoke_regression.log |
| m13_progression_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m13_progression_regression.log |
| m13_economy_balance_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m13_economy_balance_regression.log |
| m13_unlock_capacity_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m13_unlock_capacity_regression.log |
| m13_save_load_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m13_save_load_regression.log |
| m14_t01_core_regression | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m14_t01_core_regression.log |
| m14_t02_rescue_ui_verify | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m14_t02_rescue_ui_verify.log |
| m14_t03_copy_ui_verify | True | 0 | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\logs\t04_m14_t03_copy_ui_verify.log |

## Manual Experience Acceptance

- Blind playtest evidence: `reports/m14/M14_T03_BLIND_PLAYTEST_REPORT.md`
- T03 Codex handoff: `reports/m14/M14_T03_CODEX_HANDOFF.md`
- Manual experience result: PASS

## Screenshot Evidence

Required T02/T03 screenshot evidence exists and is referenced; no screenshot generation logic was changed.
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\01_dock_entry.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\02_dock_panel_candidate.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\03_rescue_slot_recovering.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\04_ready_to_release.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\05_release_settlement.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\06_reputation_display.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\07_codex_rescued_badge.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_01_dock_entry.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_02_dock_candidate.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_03_rescue_slot_after_bring.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_04_recovering.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_05_ready_to_release.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_06_release_settlement.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_07_reputation_change.png
- C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m14\screenshots\t03_08_codex_rescued_mark.png

## Evidence Rule

- evidence_rule_version: no_self_referential_annotated_tag_closure_v1
- `git rev-parse <tag>` verifies the annotated tag object.
- `git rev-parse <tag>^{}` verifies the tag target commit.
- The current annotated tag object is not required inside its own target commit.
- Base closeout tag type: tag
- Base closeout tag target: 32d852b86647afa4ce5d84f73f22dbd5944c6d6c
- Final candidate tag: v3.2-m14-t04-rescue-core-rc
- Final candidate tag target verification command: git rev-parse v3.2-m14-t04-rescue-core-rc^{}
- HEAD commit verification: verified externally by: git rev-parse HEAD

## Forbidden Scope Check

- FORBIDDEN_TOUCHED=0
- None.

## Modified Files

- reports/m14/M14_T04_RESCUE_CORE_RELEASE_CANDIDATE_RECEIPT.json
- reports/m14/M14_T04_RESCUE_CORE_RELEASE_CANDIDATE_REPORT.md
- tests/run_m14_t04_release_candidate.ps1

## Release Candidate Decision

- Current M14 RescueCore playable candidate: PASS
- Stable base for M15/M16/M18: YES_AFTER_CODEX_REVIEW
- Recommendation for M14 final closeout: YES_AFTER_CODEX_REVIEW
