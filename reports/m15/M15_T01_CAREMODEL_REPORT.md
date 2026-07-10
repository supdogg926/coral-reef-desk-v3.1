# M15-T01 CareModel And HeadlessSim Report

Overall Status: **PASS**

- Task: M15-T01_CareModel_And_HeadlessSim
- Branch: m15-t01-caremodel-headless
- Base tag: v3.2-m14-final-rescue-core-playable
- HEAD commit: verified externally by: git rev-parse HEAD
- Evidence rule: no_self_referential_annotated_tag_closure_v1
- Final tag: v3.3-m15-t01-care-datamodel
- Validation command: PowerShell -ExecutionPolicy Bypass -File tests/run_m15_t01_acceptance.ps1

## Scope

M15-T01 implements only the care data model, deterministic care_need derivation, apply_care API, recovery tail multiplier, v2-to-v3 save migration, headless simulation tests, and acceptance evidence. It does not add UI, observation, daily care, hidden needs, cooldowns, death, negative effects, release ratings, ocean systems, breeding, card art, reputation shop, reputation levels, or M15-T02 work.

## Care Model

- care_need: weak / stressed / minor_injury, deterministically derived from rescue_id with no _rng_state consumption.
- actions: nutrition / soothe / purify.
- care_score: 1.0 correct, 0.5 partial, 0.2 wrong.
- care_multiplier: 1.0 + care_score * 0.5.
- one care action per rescue; a second action returns care_already_used without state mutation.
- no-care path uses care_multiplier=1.0 and preserves M14 recovery behavior after stripping new care_* keys.

## Automatic Acceptance Results

| Check | Result | Log |
|---|---|---|
| Godot static parse | PASS | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m15\logs\m15_t01_godot_static_editor_check.log |
| gdlint | PASS_GDLINT_UNAVAILABLE_GODOT_STATIC_PARSE_0_ERROR | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m15\logs\m15_t01_godot_static_editor_check.log |
| M15-T01 care model | PASS | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m15\logs\m15_t01_caremodel_verify.log |
| M14 final regression / T04 RC | PASS | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M14_T01\reports\m15\logs\m15_t01_m14_final_regression.log |

## Required Results

- Baseline bit equivalence: PASS
- RNG determinism: PASS
- v2-to-v3 migration: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 regression: PASS
- M14-T04 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds
- T04 FORBIDDEN_TOUCHED: 0
- M15 FORBIDDEN_TOUCHED: 0

## Screenshot Resolution Check Template

The acceptance runner includes Test-ScreenshotEvidence for T02/T03. It requires width >= 800px and includes a pixel variance check to reject pure-color captures. T01 does not consume screenshots.

## Forbidden Scope Check

- FORBIDDEN_TOUCHED=0

## Modified Files

- data/rescue_config.json
- data/schemas/save_schema.json
- reports/m15/M15_T01_CAREMODEL_RECEIPT.json
- reports/m15/M15_T01_CAREMODEL_REPORT.md
- scripts/systems/RescueSystem.gd
- scripts/systems/SaveSystem.gd
- tests/m15_t01_caremodel_verify.gd
- tests/run_m15_t01_acceptance.ps1

## Evidence Rule

- evidence_rule_version: no_self_referential_annotated_tag_closure_v1
- git rev-parse <tag> verifies the annotated tag object.
- git rev-parse <tag>^{} verifies the tag target commit.
- The annotated tag object is not required inside its own target commit.

## Recommendation

- Codex review: RECOMMENDED
- M15-T02 entry: ONLY_AFTER_CODEX_REVIEW_PASS
