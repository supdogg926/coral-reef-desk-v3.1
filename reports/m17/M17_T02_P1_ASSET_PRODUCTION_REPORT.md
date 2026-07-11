# M17-T02-P1 Asset Production Report

**Date**: 2026-07-11
**Generated**: 2026-07-11T16:06:10.901415+08:00
**Status**: REVIEW_PENDING

---

## 1. Task Identity

| Field | Value |
|-------|-------|
| Task | M17-T02-P1 |
| Milestone | M17-T02 Real Assets Production |
| Phase | P1 - Asset Production & Visual Review Preparation |
| Worktree | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02 |
| Branch | prototype/m17-t02-real-assets |
| Baseline Commit | fb8856e8336e5a6109138d609c7793d417a02416 |
| HEAD | fb8856e8336e5a6109138d609c7793d417a02416 |
| Predecessor Tag | v3.5-m17-t01-final |
| Manifest Schema | v2 |

---

## 2. Startup Gate

| Check | Result |
|-------|--------|
| Workspace = CoralReefIdleV3_M17_T02 | PASS |
| Branch = prototype/m17-t02-real-assets | PASS |
| HEAD = frozen baseline (fb8856e8) | PASS |
| Tag v3.5-m17-t01-final resolves to fb8856e8 | PASS |
| Initial workspace clean | PASS |
| M17_T02_P1_START_GATE | PASS |

---

## 3. Asset Production Set Definition

### 3.1 Summary

| Metric | Value |
|--------|-------|
| Asset Production Set Count | 9 |
| Active New Species | 6 |
| Reserved New Species | 3 |

### 3.2 Runtime Effective Pool

Current runtime pool (3 M16 existing + 6 M17 active): 9 total.
Reserved species are NOT in the runtime candidate pool.

### 3.3 Species Detail

| # | Species ID | Chinese | English | Role | Source Mode |
|---|-----------|---------|---------|------|-------------|
| 1 | rescue_clownfish_juvenile | 迷路小丑鱼 | Lost Clownfish Juvenile | active | image2_human_approved_reuse |
| 2 | rescue_cleaner_shrimp | 受困清洁虾 | Trapped Cleaner Shrimp | active | reuse_existing |
| 3 | rescue_goby | 虚弱虾虎 | Weak Goby | active | reuse_existing |
| 4 | rescue_seahorse | 受困海马 | Trapped Seahorse | active | seedream_generated |
| 5 | rescue_hermit_crab | 寄居蟹 | Hermit Crab | active | seedream_generated |
| 6 | rescue_brain_coral_frag | 脑珊瑚碎片 | Brain Coral Fragment | active | image2_human_approved_reuse |
| 7 | rescue_mandarin_dragonet | 花斑连鳍䲗 | Mandarin Dragonet | reserved | image2_human_approved_reuse |
| 8 | rescue_sea_star | 海星 | Sea Star | reserved | seedream_generated |
| 9 | rescue_anemone_tube | 管海葵 | Tube Anemone | reserved | image2_human_approved_reuse |

---

## 4. Asset Production Results

### 4.1 Per-Species Asset Detail

| # | Species ID | Role | Final Path | File SHA256 | Pixel SHA256 | Size |
|---|-----------|------|-----------|-------------|-------------|------|
| 1 | rescue_clownfish_juvenile | active | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02\assets\m17\t02\normalized\rescue_clownfish_juvenile_256.png | `96c0a0379a8b6f6b...` | `0477a5d74fa85991...` | 51114B |
| 2 | rescue_cleaner_shrimp | active | assets\m17\t02\normalized\rescue_cleaner_shrimp_256.png | `b106a67f63d3a0d6...` | `f863a9a9215cda2f...` | 28870B |
| 3 | rescue_goby | active | assets\m17\t02\normalized\rescue_goby_256.png | `eec2d417561e2c80...` | `114c000d01d465e5...` | 35269B |
| 4 | rescue_seahorse | active | assets\m17\t02\normalized\rescue_seahorse_256.png | `e8ff9fce35b16fba...` | `dba0be5c2ffaae84...` | 34140B |
| 5 | rescue_hermit_crab | active | assets\m17\t02\normalized\rescue_hermit_crab_256.png | `47b24230b6cb90da...` | `4854f2643f05604e...` | 68474B |
| 6 | rescue_brain_coral_frag | active | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02\assets\m17\t02\normalized\rescue_brain_coral_frag_256.png | `16ef829d4b1e8f5b...` | `66ba9113655df6b8...` | 77640B |
| 7 | rescue_mandarin_dragonet | reserved | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02\assets\m17\t02\normalized\rescue_mandarin_dragonet_256.png | `f5f82998abc8e160...` | `4936617e5281fccb...` | 60405B |
| 8 | rescue_sea_star | reserved | assets\m17\t02\normalized\rescue_sea_star_256.png | `bb743697300c3a30...` | `7bbcf73c2dbb14f1...` | 46235B |
| 9 | rescue_anemone_tube | reserved | C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02\assets\m17\t02\normalized\rescue_anemone_tube_256.png | `266f2e26b888b623...` | `8e2033dbeccb23f6...` | 117360B |

### 4.2 Asset Source Summary

| Source Mode | Count | Species |
|-------------|-------|---------|
| reuse_existing | 2 | rescue_cleaner_shrimp, rescue_goby |
| reuse_ai_render | 0 |  |
| seedream_generated | 3 | rescue_seahorse, rescue_hermit_crab, rescue_sea_star |

### 4.3 Generation Attempts

| Species ID | Attempts | Final Status |
|-----------|----------|-------------|
| rescue_clownfish_juvenile | 0 | NORMALIZED |
| rescue_cleaner_shrimp | 0 | NORMALIZED |
| rescue_goby | 0 | NORMALIZED |
| rescue_seahorse | 1 | NORMALIZED |
| rescue_hermit_crab | 1 | NORMALIZED |
| rescue_brain_coral_frag | 0 | NORMALIZED |
| rescue_mandarin_dragonet | 0 | NORMALIZED |
| rescue_sea_star | 1 | NORMALIZED |
| rescue_anemone_tube | 0 | NORMALIZED |

### 4.4 Seedream Generation Details

Platform: 火山引擎 ARK
Model: Doubao Seedream 4.5
Endpoint: ep-20260625021114-w7ll4
API Key: Read from D:\NuwaSystem existing configuration (not hardcoded in repo)

3 species generated via Seedream 4.5, all succeeded on attempt 1:
- rescue_seahorse (受困海马) - 1 attempt, SUCCESS
- rescue_hermit_crab (寄居蟹) - 1 attempt, SUCCESS
- rescue_sea_star (海星) - 1 attempt, SUCCESS

3 species reused from existing AI renders (ComfyUI/Image2 outputs):
- rescue_brain_coral_frag (脑珊瑚碎片) - reused Trachyphyllia render
- rescue_mandarin_dragonet (花斑连鳍䲗) - reused Mandarinfish render
- rescue_anemone_tube (管海葵) - reused BTA render

3 M16 species reused with existing 256x256 assets:
- rescue_clownfish_juvenile (迷路小丑鱼)
- rescue_cleaner_shrimp (受困清洁虾)
- rescue_goby (虚弱虾虎)

---

## 5. Normalization Pipeline

All 9 species processed through rembg background removal pipeline:
1. Load source image
2. Remove background with rembg
3. Crop to subject bounding box with padding
4. Pad to square (preserving aspect ratio)
5. Adjust subject ratio to 50-85%
6. Resize to 256x256 with Lanczos filter
7. Save as RGBA PNG
8. Compute file SHA256 and RGBA8 pixel SHA256

Output directory: `assets/m17/t02/normalized/`

---

## 6. Artifacts Generated

| Artifact | Path | SHA256 |
|----------|------|--------|
| Manifest Draft | data/card_manifest_m17_t02_draft.json | — |
| Provenance JSON | reports/m17/m17_t02_asset_provenance.json | — |
| Pixel Hash Fixture | reports/m17/t02_asset_pixel_hash_fixture.json | — |
| Asset Inventory CSV | reports/m17/t02_p1_asset_inventory.csv | — |
| Asset Inventory MD | reports/m17/t02_p1_asset_inventory.md | — |
| Contact Sheet | reports/m17/t02/evidence\t02_contact_sheet_20260711_160600.png | `7346757101508ebf...` |
| Contact Sheet Index | reports/m17/t02/evidence/t02_contact_sheet_index.md | — |
| Generation Records | reports/m17/t02/generation_records/generation_records.json | — |
| Acceptance Results | reports/m17/t02/evidence/acceptance_results.txt | — |
| Pipeline Results | assets/m17/t02/normalized/pipeline_results.json | — |

**Contact Sheet:** reports/m17/t02/evidence\t02_contact_sheet_20260711_160600.png
- Size: 1220x1490
- SHA256: `7346757101508ebf7e37ab5e0ed9bec4d2ac836413d32ecd48bc55a75669f9ea`

---

## 7. Programmatic Acceptance

### 7.1 Result: PASS

92 checks, 92 PASS, 0 FAIL.

### 7.2 Key Verification Results

| Category | Checks | Result |
|----------|--------|--------|
| Asset Production Set Count | 3 | PASS |
| Final Asset Files (9 x 5 checks) | 45 | PASS |
| No Duplicate SHA256 | 2 | PASS |
| Manifest Draft | 14 | PASS |
| Provenance JSON | 3 | PASS |
| Pixel Hash Fixture | 3 | PASS |
| Contact Sheet | 5 | PASS |
| Inventory & Records | 3 | PASS |
| T01 Regression | 6 | PASS |
| Forbidden Diff | 5 | PASS |
| Reserved Guards | 5 | PASS |

### 7.3 T01 Regression

- species_rescue_pool.json: 6 entries, IDs preserved ✓
- card_manifest.json: schema v2, 6 entries ✓
- M16 rescue assets: source = image2_user_generated ✓
- Reserved species NOT in pool JSON ✓
- No forbidden files modified ✓

---

## 8. Git Diff Scope

### Changed files:
```
(no committed changes - all files untracked/new)
```

### Untracked files:
```
assets/m17/t02/normalized/pipeline_results.json
assets/m17/t02/normalized/rescue_anemone_tube_256.png
assets/m17/t02/normalized/rescue_brain_coral_frag_256.png
assets/m17/t02/normalized/rescue_cleaner_shrimp_256.png
assets/m17/t02/normalized/rescue_clownfish_juvenile_256.png
assets/m17/t02/normalized/rescue_goby_256.png
assets/m17/t02/normalized/rescue_hermit_crab_256.png
assets/m17/t02/normalized/rescue_mandarin_dragonet_256.png
assets/m17/t02/normalized/rescue_sea_star_256.png
assets/m17/t02/normalized/rescue_seahorse_256.png
assets/m17/t02/source_candidates/rescue_anemone_tube_reuse_source.png
assets/m17/t02/source_candidates/rescue_anemone_tube_see_dream45_source.png
assets/m17/t02/source_candidates/rescue_brain_coral_frag_reuse_source.png
assets/m17/t02/source_candidates/rescue_brain_coral_frag_see_dream45_source.png
assets/m17/t02/source_candidates/rescue_clownfish_juvenile_see_dream45_source.png
assets/m17/t02/source_candidates/rescue_hermit_crab_attempt01.png
assets/m17/t02/source_candidates/rescue_mandarin_dragonet_reuse_source.png
assets/m17/t02/source_candidates/rescue_mandarin_dragonet_see_dream45_source.png
assets/m17/t02/source_candidates/rescue_sea_star_attempt01.png
assets/m17/t02/source_candidates/rescue_seahorse_attempt01.png
data/card_manifest_m17_t02_draft.json
reports/m17/M17_T01_CLOSE_OF_DAY_2026-07-11.md
reports/m17/M17_T02_P1_ASSET_PRODUCTION_RECEIPT.json
reports/m17/M17_T02_P1_ASSET_PRODUCTION_REPORT.md
reports/m17/m17_t02_asset_provenance.json
reports/m17/t02/evidence/acceptance_results.txt
reports/m17/t02/evidence/see_dream45_replacement_log.json
reports/m17/t02/evidence/t02_artifact_summary.json
reports/m17/t02/evidence/t02_contact_sheet_20260711_121000.png
reports/m17/t02/evidence/t02_contact_sheet_20260711_121030.png
reports/m17/t02/evidence/t02_contact_sheet_20260711_160600.png
reports/m17/t02/evidence/t02_contact_sheet_index.md
reports/m17/t02/generation_records/generation_records.json
reports/m17/t02/see_dream45_image_inventory.csv
reports/m17/t02/see_dream45_image_inventory.json
reports/m17/t02/see_dream45_species_matching.csv
reports/m17/t02/see_dream45_species_matching.json
reports/m17/t02_asset_pixel_hash_fixture.json
reports/m17/t02_p1_asset_inventory.csv
reports/m17/t02_p1_asset_inventory.md
reports/m17/t02_visual_signoff.json
reports/m17/t02_visual_signoff.md
scripts/m17_t02_apply_see_dream45.py
scripts/m17_t02_gen_seedream.py
scripts/m17_t02_generate_artifacts.py
scripts/m17_t02_generate_reports.py
scripts/m17_t02_normalize_assets.py
scripts/m17_t02_run_acceptance.py
scripts/m17_t02_see_dream45_scan.py
tests/run_m17_t02_p1_asset_acceptance.ps1
```

All changes are within the allowed P1 scope:
- assets/m17/t02/ (source candidates, normalized)
- reports/m17/ (reports, evidence, generation records)
- data/card_manifest_m17_t02_draft.json (manifest draft)
- scripts/m17_t02_*.py (processing scripts)
- tests/run_m17_t02_p1_asset_acceptance.ps1 (acceptance script)

### Forbidden areas confirmed untouched:
- SaveSystem.gd ✓
- RescueSystem.gd ✓
- scenes/ui/ ✓
- scenes/tank/ ✓
- project.godot ✓
- save_schema.json ✓
- rescue_config.json ✓
- species_rescue_pool.json ✓
- card_manifest.json ✓
- M16 rescue assets ✓

---

## 9. BLOCKED Species

None. All 9 species have finalized 256x256 assets.

---

## 10. Species Requiring Extra Producer Review

The following species were generated via Seedream and should receive
extra visual scrutiny from the producer:

- rescue_seahorse (受困海马) - generated, white background fish
- rescue_hermit_crab (寄居蟹) - generated, white background crustacean
- rescue_sea_star (海星) - generated, black background invertebrate

Species with lower subject ratios (may need tighter framing review):
- rescue_seahorse: 46.5% subject ratio before adjustment
- rescue_hermit_crab: 48.8% subject ratio before adjustment

---

## 11. Visual Review Declaration

**M17_T02_ASSET_VISUAL_STATUS = REVIEW_PENDING**

The execution layer has performed programmatic checks only (dimensions,
file integrity, SHA256, no duplicates, no placeholders, manifest consistency).

The execution layer has NOT certified:
- Species 100% taxonomic accuracy
- Zero AI artifacts/deformities
- Thumbnail-level species recognizability
- Cross-species visual consistency
- Overall aesthetic quality

These judgments require the producer's human visual review.

---

## 12. Next Steps (Producer Action Required)

1. Review the contact sheet: `reports/m17/t02/evidence\t02_contact_sheet_20260711_160600.png`
2. For each of the 9 species, make one of these decisions:
   - APPROVED: asset accepted as-is
   - REDO: asset needs regeneration
   - RESERVE_PROMOTION_APPROVED: reserved species promoted to active
3. Complete the signoff form: `reports/m17/t02_visual_signoff.md`
4. After signoff, P2 can begin with approved assets

---

## 13. P1 Final Status

```
M17_T02_P1_OVERALL_STATUS=REVIEW_PENDING
M17_T02_P1_START_GATE=PASS
M17_T02_P1_FACT_DISCOVERY_RESULT=PASS
M17_T02_P1_ASSET_PROGRAMMATIC_RESULT=PASS
M17_T02_ASSET_VISUAL_STATUS=REVIEW_PENDING
M17_T02_P2_STATUS=NOT_STARTED
COMMIT_RESULT=NOT_ALLOWED
PUSH_RESULT=NOT_ALLOWED
```