# M17 Final Closeout Report

**Generated**: 2026-07-11T18:38:06.825963+08:00
**Completion Tag**: v3.5-m17-t02-final
**Completion Commit**: 607f5aa55951a05bc0f6985f05b01547ae6d122c

---

## 1. M17 Objective

Rescue species pool expansion from 3 to 9 species, with real Image2 assets,
producer-reviewed visual identity, schema-v2 manifest, one-draw bag draw,
dock and codex integration, full regression, and independent Codex review.

## 2. Original Scope (M17 Planning Freeze)

- T01: Pool expansion 3->6, bag draw algorithm, placeholder assets
- T02: Real assets, manifest, dock/codex, playable UI, regression
- T03: FlowContainer upgrade, final playable verification

## 3. T01 Completion

- Pool expanded 3->6 species (3 M16 legacy + 3 new T01)
- One-draw bag draw algorithm (1 RNG per candidate, no Fisher-Yates)
- Deterministic placeholders with SHA256
- Manifest schema v2 frozen
- Rebaseline Protocol v2 for regression
- Tag: various T01 tags, final closure at fb8856e

## 4. T02 Completion

- Selection policy: AVAILABLE_APPROVED_IMAGES_FIRST
- 6 new active species from producer-reviewed Image2 pool
- 3 reserved species with full assets (not in candidate pool)
- Pool total: 9 (3 M16 + 6 M17 new active)
- All 12 assets: 256x256 RGBA PNG, rembg processed
- File SHA256: 9/9 verified
- RGBA8 pixel SHA256: 12/12 verified
- Runtime texture mapping: 12 loaded, 6/6 PASS
- Placeholder fallback: 0
- Dock: 9 active species in candidate rotation
- Codex: HBoxContainer with real cards
- Build ID: CoralReefIdleV3 M17-T02 v3.5-m17-t02-final
- Full regression: M11/M12/M13/M16/M17-T01/M17-T02 all PASS
- 2 rounds Codex independent review: PASS
- Final tag: v3.5-m17-t02-final

## 5. T03 Cancellation

- Old T03 scope: 16 items
- Completed in T01/T02: 15 items
- Remaining: FlowContainer upgrade (non-blocking)
- Ruling: Option A -- cancel T03, direct M17 closeout
- FlowContainer deferred to maintenance (MNT-001)
- T03 worktree preserved for archive (prototype/m17-t03)

## 6. Final Species Pool

### Active (9 in candidate pool)

M16 legacy (3):
1. rescue_clownfish_juvenile (迷路小丑鱼)
2. rescue_cleaner_shrimp (受困清洁虾)
3. rescue_goby (虚弱虾虎)

M17 new active (6):
4. rescue_blue_eye_bristletooth_tang (蓝眼食苔吊)
5. rescue_eight_line_flasher_wrasse (八线龙)
6. rescue_bicolor_angelfish (双色神仙)
7. rescue_green_star_polyp (荧光绿草皮)
8. rescue_pulsing_xenia (闪千手)
9. rescue_golden_brain_coral (金菊脑)

### Reserved (3, assets present, not in pool)

10. rescue_yellow_coris_wrasse (黄龙)
11. rescue_mountain_gold_green_euphyllia (山脉金绿猪腰)
12. rescue_holy_grail_matchstick_coral (圣杯火柴珊瑚)

## 7. Gates Summary

| Gate | Status |
|------|--------|
| M17 planning freeze | COMPLETE |
| M17-T01 pool + bag draw | PASS |
| M17-T02-P1 asset production | PASS (87/87) |
| M17-T02-P2 runtime integration | PASS |
| Build ID hotfixes | PASS |
| Codex Review round 1 | PASS (conditional) |
| Full regression evidence | PASS |
| Codex Review round 2 | PASS |
| Final tag creation | PASS |
| T03 scope reconciliation | PASS (cancelled) |
| M17 closeout | PASS |

## 8. Final Verdict

**M17_FINAL_RESULT=PASS**

M17 is complete. The rescue species pool has been expanded from 3 to 9 active species
with 3 additional reserved backup species. All assets are 256x256 RGBA PNGs with
verified SHA256 hashes. The dock, codex, and UI all function correctly. Full regression
across M11 through M17-T02 passes. Two rounds of independent Codex review confirm
all gates.

M17 completion marker: **v3.5-m17-t02-final** at commit **607f5aa55951a05bc0f6985f05b01547ae6d122c**.

No T03 milestone was needed. FlowContainer upgrade is deferred to maintenance.
