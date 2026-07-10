# M16-T02 Rescue Card Playable UI Report

Task: M16-T02_RescueCardPlayable_UI

## Baseline

- M16-T01 final baseline tag: v3.4-m16-t01-card-manifest
- M16-T01 final baseline commit: f7d2e7078e000ffd16e3160ea2dc4ace96d49825
- Evidence rule: no_self_referential_annotated_tag_closure_v1
- M14 no-care baseline FIRST_LOOP_DURATION: 840 seconds
- M15 care path FIRST_LOOP_DURATION: 580 seconds

## Scope

- Adds 3 processed real card assets (256x256, rembg, transparent bg)
- Updates card_manifest.json to schema_version 2, all entries image2_user_generated
- Updates card_manifest_schema.json to allow image2_user_generated source
- Updates CardAssetLibrary.gd to support schema v2 and multi-source validation
- Adds 96x96 TextureRect to RescueDockPanel between dock_status and candidate_label
- Does not modify save_schema, SaveSystem, RescueSystem, GameState, LivestockSystem
- Does not modify any UI panels other than RescueDockPanel
- Does not enter M16-T03

## Asset Processing

| Species | Original | Processed | SHA256 |
|---------|----------|-----------|--------|
| rescue_clownfish_juvenile | 1254x1254 RGB | 256x256 RGBA | bac63dfbb2f16bd63f8ec0e9bf749d72fe32ce7ab8107d11ea4ccf2b79a3fe6f |
| rescue_cleaner_shrimp | 1254x1254 RGB | 256x256 RGBA | b106a67f63d3a0d6a9e86016360cf5913a25b558ff1935f6ab17df1e1bc9da8e |
| rescue_goby | 1254x1254 RGB | 256x256 RGBA | eec2d417561e2c80bfbee4901a86689998f897f79738c4cb7d000c173edbef27 |

Processing: rembg (white bg removal) -> resize 256x256 (Lanczos) -> SHA256

## Automated Acceptance

- Godot static parse: PASS
- Asset verification: PASS
- Manifest v2 validation: PASS
- Fallback three cases: PASS
- Zero save impact: PASS
- Screenshot count: 5
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 regression: PASS
- M14-T04 regression: PASS
- M15-T01 regression: PASS
- M15-T02 regression: PASS
- M15-T03 regression: PASS
- M16-T01 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds
- M15_T02_FIRST_LOOP_DURATION: 580 seconds
- FORBIDDEN_TOUCHED: 0
- SAVE_VERSION: v3

## Screenshots

- m16_t02_01_dock_candidate_card_visible.png
- m16_t02_02_active_rescue_card_visible.png
- m16_t02_03_care_need_text_still_visible.png
- m16_t02_04_fallback_placeholder_visible.png
- m16_t02_05_release_ready_card_visible.png

## UI Semantics

- RescueDockPanel TextureRect (RescueCardTexture) exists
- TextureRect custom_minimum_size: 96x96
- TextureRect stretch_mode: KEEP_ASPECT_CENTERED
- TextureRect inserted between dock_status_label and candidate_label
- Candidate phase: card shows candidate species texture
- Active rescue phase: card shows active rescue species texture
- Fallback: real asset missing -> placeholder -> text_only
- No new buttons, no new interactions

## Result

- M16-T02 result: PASS
- Tag: v3.4-m16-t02-rescue-card-playable-ui
- Recommendation: request Codex independent review before M16-T03.
- M16-T03 remains blocked until Codex PASS.

## Final Closure

- **Base tag**: v3.4-m16-t01-card-manifest
- **Base commit**: f7d2e7078e000ffd16e3160ea2dc4ace96d49825
- **Tag**: v3.4-m16-t02-rescue-card-playable-ui
- **Manifest schema_version**: 2 (card manifest only; save_version remains v3)
- **Manifest source**: image2_user_generated (all 3 entries)
- **SaveSystem/save_schema**: untouched
- **SAVE_VERSION**: v3
- **FIRST_LOOP_DURATION**: 840 seconds (M14 baseline) / 580 seconds (M15 care path) — unchanged
- **Evidence rule**: no_self_referential_annotated_tag_closure_v1
- **M16-T03**: not started, blocked until Codex PASS

### Processed Asset SHA256

| Species | SHA256 |
|---------|--------|
| rescue_clownfish_juvenile | bac63dfbb2f16bd63f8ec0e9bf749d72fe32ce7ab8107d11ea4ccf2b79a3fe6f |
| rescue_cleaner_shrimp | b106a67f63d3a0d6a9e86016360cf5913a25b558ff1935f6ab17df1e1bc9da8e |
| rescue_goby | eec2d417561e2c80bfbee4901a86689998f897f79738c4cb7d000c173edbef27 |

### Screenshots (5)

- m16_t02_01_dock_candidate_card_visible.png (960×540)
- m16_t02_02_active_rescue_card_visible.png (960×540)
- m16_t02_03_care_need_text_still_visible.png (960×540)
- m16_t02_04_fallback_placeholder_visible.png (960×540)
- m16_t02_05_release_ready_card_visible.png (960×540)

### Changed Files

| File | Operation |
|------|-----------|
| data/card_manifest.json | MODIFY (schema v2, 3 real assets) |
| data/schemas/card_manifest_schema.json | MODIFY (schema v2, new source) |
| scripts/systems/CardAssetLibrary.gd | MODIFY (multi-source, schema v1/v2) |
| scenes/ui/RescueDockPanel.gd | MODIFY (96×96 TextureRect) |
| assets/cards/rescue/*.png (3) | NEW |
| tests/m16_t02_*.gd (2) | NEW |
| tests/run_m16_t02_acceptance.ps1 | NEW |
| reports/m16/screenshots/*.png (5) | NEW |
| reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md | NEW |
| reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json | NEW |

### Forbidden Files

0 touched. SaveSystem.gd, save_schema.json, RescueSystem.gd, GameState.gd, LivestockSystem.gd, LivestockPanel.gd, StatusPanel.gd, Main.gd, species_rescue_pool.json, rescue_config.json, project.godot, .tscn files — all untouched.
