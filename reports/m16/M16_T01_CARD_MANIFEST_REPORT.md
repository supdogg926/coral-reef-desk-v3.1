# M16-T01 Card Manifest Report

Task: M16-T01_VisualCardManifest_And_PlaceholderPipeline

## Baseline

- Effective M15 final baseline tag: v3.3-m15-final-care-decision-depth-fix2
- Effective M15 final baseline commit: d87a2018e90549d200eece41c1bab72d7da911a8
- Evidence rule: no_self_referential_annotated_tag_closure_v1
- M15 care path first loop is 580 seconds. This is below first_loop_min_seconds=600 because that lower bound only constrains the M14 no-care baseline path; M16-T01 does not modify M15 config or scripts.
- M14 no-care baseline FIRST_LOOP_DURATION remains 840 seconds.

## Scope

- Adds card manifest contract, schema, placeholder card assets, CardAssetLibrary API, M16-T01 headless verification, and this report/receipt.
- Does not modify UI, save schema, SaveSystem, RescueSystem, GameState, LivestockSystem, species_rescue_pool, rescue_config, scenes, or existing M13/M14/M15 tests.
- Does not enter M16-T02 and does not connect real art samples.

## Manifest Contract

- data/card_manifest.json uses schema_version=1.
- max_entries=3, matching the current species_rescue_pool count.
- species_id is the card id.
- T01 source is placeholder only.
- Asset paths are res:// paths and placeholder filenames are ASCII.
- SHA256 values are checked against actual placeholder PNG files.

## CardAssetLibrary API

- Reads data/card_manifest.json on demand.
- Validates manifest schema and species pool constraints.
- get_card_texture(species_id) fallback order: manifest asset, generated placeholder texture, text_only fallback.
- Asset-missing and placeholder-disabled paths return structured fallback results and do not throw.
- No card fields are persisted.

## Automated Acceptance

- Godot static parse: PASS
- Manifest legal/illegal sample tests: PASS
- Placeholder determinism: PASS
- Fallback three cases: PASS
- Zero save impact: PASS
- Screenshot validator upgrade: PASS
- M13 regression: PASS
- M14-T01 regression: PASS
- M14-T02 regression: PASS
- M14-T03 regression: PASS
- M14-T04 regression: PASS
- M15-T01 regression: PASS
- M15-T02 regression: PASS
- M15-T03 regression: PASS
- FIRST_LOOP_DURATION: 840 seconds
- M15_T02_FIRST_LOOP_DURATION: 580 seconds
- FORBIDDEN_TOUCHED: 0

## Screenshot Validator Upgrade

- T01 does not consume screenshots.
- CardAssetLibrary.validate_visual_evidence supports viewport source checks, resolution >=960x540, variance checks, UI semantic assertions, TextureRect.texture != null, TextureRect rendered size >=64px, card-region variance, and manifest SHA checks.

## T02 Readiness Notes

- ReefSpeciesCards candidates recorded only for planning; T01 does not connect real art.
  - D:\NuwaSystem\ReefSpeciesCards\outputs\2026-06-26\raw\sp_0005_9c0853_粉蓝吊_attempt3.png
  - D:\NuwaSystem\ReefSpeciesCards\outputs\2026-06-26\raw\sp_0148_738128_黄金吊_attempt2.png
  - D:\NuwaSystem\ReefSpeciesCards\outputs\2026-06-26\raw\sp_0219_8c80c9_红奶嘴_attempt1.png
  - D:\NuwaSystem\ReefSpeciesCards\outputs\2026-06-26\raw\sp_0491_b52952_蓝吊_attempt2.png
  - D:\NuwaSystem\ReefSpeciesCards\outputs\2026-06-26\raw\sp_0148_738128_黄金吊_attempt1.png
- DESIGN_VISION.md files:
  - Not found in project tree.
- Overlay note: T01 does not enter UI. Project viewport is 1280x720; M15 evidence viewport is 960x540. T02 must measure actual overlay usable card region.

## Result

- M16-T01 result: PASS
- Recommendation: request Codex independent review before M16-T02.
- M16-T02 remains blocked until Codex PASS.
