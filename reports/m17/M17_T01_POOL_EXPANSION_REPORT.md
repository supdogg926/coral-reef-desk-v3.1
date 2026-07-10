# M17-T01 Pool Expansion Report

Task: M17-T01_PoolExpansionDataContract_And_NoRepeatCandidateRotation

## Baseline

- M17 planning freeze tag: v3.5-m17-planning-freeze
- M17 planning freeze commit: b09ecc792b6687761a6763795752f22143197900
- Evidence rule: no_self_referential_annotated_tag_closure_v1

## Scope

- species_rescue_pool: 3 -> 6
- New species: rescue_seahorse (fish), rescue_hermit_crab (crustacean), rescue_brain_coral_frag (coral)
- 9-species full plan documented in reports/m17/ only
- card_manifest: 6 entries (3 image2_user_generated + 3 placeholder)
- Algorithm: one-draw bag draw (1 RNG/candidate, no Fisher-Yates)
- Category: fish=3, crustacean=2, coral=1
- All parameters within existing ranges (22-30 / 5-7 / 6-8 / 0.05-0.08)
- Zero save impact, save_version=v3

## Automated Acceptance

- Godot static parse: PASS
- Pool verification: PASS
- Manifest verification: PASS
- Bag draw verification: PASS
- Parameter range verification: PASS
- Zero save impact: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 regression: PASS
- M14-T04 regression: PASS
- M15-T01 regression: PASS
- M15-T02 regression: PASS
- M15-T03 regression: PASS
- M16-T01/02/03 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds
- M15_T02_FIRST_LOOP_DURATION: 580 seconds
- FORBIDDEN_TOUCHED: 0
- SAVE_VERSION: v3

## New Placeholder SHA256

| Species | SHA256 |
|---------|--------|
| rescue_seahorse | 14d8f3b790d5c3dd675e9235058970554229321c656be0ef81e07459b407e026 |
| rescue_hermit_crab | 4518724af38455b141b7b8989ff9f4d9cb890569d38e3c2b3c1f26cb284474b1 |
| rescue_brain_coral_frag | 9fb3c7b891a2579ceac49d01b67d64bda2820b16e98a543ed96d33d767477f9c |

## Rebaseline Protocol v2

M15-T01 uses live pool (m15_t01_caremodel_verify.gd:222). Pool 3->6 changes event sequences.
Regression verifies M15-T01 at original M15 baseline tag. Rebaseline diff: only species_selection differences allowed.

## Known Limitations

1. Bag state is not persisted across save/load (zero save impact principle). On load, bag refills.
2. Cycle boundary repeats possible (~1/6 probability with 6 species). Acceptable; no conditional re-roll.

## 9-Species Full Plan

Phase 1 (T01): 6 species enabled in pool JSON.
Phase 2 (future): +rescue_mandarin_dragonet (fish), +rescue_sea_star (invertebrate), +rescue_anemone_tube (invertebrate).
9-species list exists only in reports/m17/.

## Result

- M17-T01 result: PASS
- Suggested tag: v3.5-m17-t01-pool-datacontract-no-repeat
- Recommendation: request Codex independent review before M17-T02.
