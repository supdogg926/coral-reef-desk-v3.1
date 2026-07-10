# M15 Final Closeout Report

Overall Status: **PASS**

- Task: M15-Final-Closeout_CareDecisionDepth
- Branch: m15-final-closeout-care-decision-depth
- Base tag: v3.3-m15-t03-care-blindplay-rc
- Final tag: v3.3-m15-final-care-decision-depth
- Evidence rule: no_self_referential_annotated_tag_closure_v1
- Validation command: PowerShell -ExecutionPolicy Bypass -File tests/run_m15_t03_acceptance.ps1

## M15 Summary

M15 closes as a narrow care decision depth milestone. It adds one lightweight care decision per rescue, keeps care free, avoids daily scheduling, avoids hidden needs, avoids visible ratings, and preserves the M14 positive release loop. The system stores care_score and applies a recovery multiplier after the existing M14 recovery formula.

## Stage Outputs

- M15-T01_CareModel_And_HeadlessSim: PASS. Added care data model, deterministic care_need derivation, apply_care API, v2 to v3 save migration, no-care baseline equivalence, RNG determinism checks, and screenshot validation helper.
- M15-T02_CarePlayable_UI_FirstLoop: PASS. Added care need text, nutrition/soothe/purify buttons, single-use UI state, care feedback text, appended care RP bonus line, and real 960px viewport screenshot evidence.
- M15-T03_CareDecision_BlindPlaytest_And_RC: PASS. Consolidated blind-play answers, RC judgment, T02 UI regression, screenshot resolution/variance/viewport-source checks, M13/M14/M15-T01 regression, and forbidden scope checks.

## Final Tag Chain

- v3.2-m14-final-rescue-core-playable
- v3.3-m15-t01-care-datamodel
- v3.3-m15-t02-care-playable-ui
- v3.3-m15-t03-care-blindplay-rc
- v3.3-m15-final-care-decision-depth

## Final M15 Result

- Care model and headless simulation: PASS
- Playable care UI first loop: PASS
- Blind-play and RC judgment: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 regression: PASS
- M14-T04 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds
- M15-T02_FIRST_LOOP_DURATION: 580 seconds
- FORBIDDEN_TOUCHED: 0
- Screenshot evidence: PASS, real viewport capture, width >= 800px, height >= 450px, and non-flat pixel variance

## First Loop Evidence Closure

- M14 / no-care baseline FIRST_LOOP_DURATION remains 840 seconds from M14 final regression.
- M15 care path FIRST_LOOP_DURATION is 580 seconds under fixed T02/T03 evidence conditions: clean new-game test state, fixed rescue_id sequence, care_need=weak, action=nutrition, water quality 40, and comfort 40.
- 580 seconds is below the <= 900 seconds M15 playable requirement.
- This does not break the M14 baseline because no-care bit-equivalence and M14 final regression remain covered by M15-T01/T03 validation.

## Player-Visible Loop

- Rescue dock shows a pending rescue.
- Player brings the rescue back to the single rescue slot.
- Active rescue shows a single care need.
- Player chooses one of three care actions: nutrition, soothe, or purify.
- Buttons disable after the first care action.
- Care feedback is shown.
- Rescue recovers and becomes releasable.
- Release keeps the M14 ordinary positive copy and appends only the small care bonus line when applicable.
- Ecological reputation and rescued collection marking remain part of the M14 loop.

## Known Limits

- Care still has no new animal card art or codex visual identity. This belongs to M16 card art and presentation work.
- Care decision is intentionally simple and table-readable. If future playtests show it becomes mechanical too quickly, M16 or later can add presentation cues without adding hidden needs.
- Reputation still lacks staged identity. This belongs to M18 guardian rank/title work.
- M15 does not add more recovery-period operations; it only adds one clear, low-pressure decision per rescue.

## Explicitly Not Included

- Daily care
- Primary plus secondary needs
- Observation action
- Hidden needs
- Visible release rating
- M14 ordinary release copy rewrite
- Ocean system
- Big ocean codex
- Multiple rescue slots
- Breeding
- Card art
- Reputation shop
- Reputation levels
- Complex disease
- Death
- Complex animation
- New economy resources
- M11 water or comfort core rewrite
- M16 development

## Evidence Rule

- evidence_rule_version: no_self_referential_annotated_tag_closure_v1
- git rev-parse <tag> verifies the annotated tag object.
- git rev-parse <tag>^{} verifies the tag target commit.
- The annotated tag object is not required inside its own target commit.

## Screenshot Evidence Rule

M15 corrects the M14 weak screenshot evidence pattern. Later screenshot validation must check more than file existence and size:

- Width must be at least 800px.
- Height must be at least 450px.
- Files must be real rendered PNGs.
- Pixel variance must be non-flat.
- Screenshot scripts must use viewport capture, not generated placeholder images.
- UI node semantic assertions must pass before saving screenshot evidence.

## Final Recommendation

M15 is recommended for formal closeout after the final tag is created and the T03 RC validation reruns clean. M16 may start only after final Codex total review PASS.
