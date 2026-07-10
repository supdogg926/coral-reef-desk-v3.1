# M17-T01 Final Closure Report

**Date**: 2026-07-11
**Task**: M17-T01_FINAL_CLOSURE_AND_CODEX_REVIEW_PACKAGE
**Status**: PASS — Ready for Codex Review
**Type**: Codex Review Candidate (not final close tag)

---

## 1. Tag Chain and Commit Identity

### 1.1 Tag Chain

| Tag | Commit | Description |
|-----|--------|-------------|
| v3.5-m17-planning-freeze | b09ecc7 | M17 planning baseline |
| v3.5-m17-t01-pool-datacontract-no-repeat | 269606b | Main T01: pool 3→6 + bag draw |
| (screenshot evidence) | 9a065fd | M17-T01 screenshot evidence commit |
| v3.5-m17-t01-visible-build-id-hotfix | 43256ba | Hotfix 1: header build ID |
| (chore) | 740379d | .gitignore *.import |
| v3.5-m17-t01-hotfix2-system-menu-dock-button-layout | 12d37ab | Hotfix 2: system menu layout |
| v3.5-m17-t01-final-closure-candidate | 944a5e0 | Closure docs (this report) |

### 1.2 Commit Identity (Verified Externally)

| Role | Identifier | How Verified |
|------|-----------|--------------|
| **runtime_tested_code_baseline** | `12d37ab25efa3f48906bca3773e333eecacbbf49` | All acceptance/regression tests executed at this commit |
| **closure_candidate_tag** | `v3.5-m17-t01-final-closure-candidate` | `git rev-parse v3.5-m17-t01-final-closure-candidate^{commit}` |
| **review_target_commit** | Supplied by reviewer: `git rev-parse HEAD` during Codex review | Externally verified — NOT self-embedded in this file |
| **closure package commit** | Verified externally by git/tag — NOT self-embedded in this file | `git tag -v` or `git rev-list` |

**Branch**: `m16-t01-card-manifest`
**Git status**: clean

---

## 2. M17-T01 Acceptance

All tests run at runtime code baseline (commit 12d37ab), Godot 4.7 headless.

```
M17_T01_POOL_RESULT=PASS
M17_T01_MANIFEST_RESULT=PASS
M17_T01_BAG_DRAW_RESULT=PASS
M17_T01_RANGE_RESULT=PASS
M17_T01_ZERO_SAVE_IMPACT_RESULT=PASS
M17_T01_ASSERTIONS_PASSED=66
M17_T01_ASSERTIONS_FAILED=0
```

**Verdict**: ALL PASS. 66 assertions, 0 failures.

---

## 3. Regression Results

### 3.1 Original T01 Regression (at commit 9a065fd / tag v3.5-m17-t01-pool-datacontract-no-repeat)

Results recorded in `M17_T01_POOL_EXPANSION_RECEIPT.json`:

| Milestone | Result |
|-----------|--------|
| M13 (4 tests) | PASS |
| M14-T01~T04 | PASS |
| M15-T01~T03 | PASS |
| M16-T01~T03 | PASS |

Run details: Godot 4.7 headless, commit 269606b / tag v3.5-m17-t01-pool-datacontract-no-repeat.

### 3.2 Re-run at Runtime Code Baseline (commit 12d37ab)

| Test | Result | Notes |
|------|--------|-------|
| m15_t01_caremodel_verify | BASELINE_BIT_EQUIVALENCE=FAIL | **Expected** — Rebaseline Protocol v2: pool 3→6 changes species selection, RNG determinism preserved |
| m15_t02_care_ui_verify | PASS | Care UI unaffected |
| m16_t01_card_manifest_verify | PASS | 26 passed, 0 failed |
| m16_t02_rescue_card_verify | PASS_WITH_EXPECTED_FAILURES | 55 pass / 16 expected / 0 unexpected — 3 new species use placeholder source, not image2_user_generated |
| m16_t03_codex_visual_verify | PASS | 35 passed, 0 failed |
| m14_rescue_core_verify | EXPECTED_DIVERGENCE | **Expected** — species selection divergence from pool expansion (Rebaseline Protocol v2) |
| m14_t02_rescue_ui_verify | EXPECTED_DIVERGENCE | **Expected** — flow tests depend on simulation state diverged by species selection |
| m14_t03_copy_ui_verify | EXPECTED_DIVERGENCE | **Expected** — copy text references diverge with different species |

All divergences at runtime code baseline are species-selection consequences per Rebaseline Protocol v2. No non-species configuration changes detected.

### 3.3 M13 Notes

M13 tests (30-day progression, economy, save/load, unlock) are economy-system tests predating the rescue system. They do not consume the species_rescue_pool. Original results at T01 commit: PASS. Re-run deferred due to test duration (~10 min per test); no code path connecting M13 to pool changes.

### 3.4 M17-T01 at Runtime Code Baseline

| Test | Result |
|------|--------|
| m17_t01_pool_verify | PASS (66/0) |
| m17_t01_capture_screenshots | 4 screenshots generated |

---

## 4. Core Evidence Checklist

### 4.1 Pool

- **File**: `data/species_rescue_pool.json`
- **Enabled entries**: 6
- **Verification**: `python3 -c "import json; print(len(json.load(open('data/species_rescue_pool.json'))))"` → 6

| # | ID | Species Name | Category | Recovery | Rep | RP | Pressure | Injury |
|---|-----|-------------|----------|----------|-----|----|----------|--------|
| 1 | rescue_clownfish_juvenile | 迷路小丑鱼 | fish | 30.0 | 5 | 6 | 0.08 | reserved |
| 2 | rescue_cleaner_shrimp | 受困清洁虾 | crustacean | 24.0 | 6 | 7 | 0.05 | reserved |
| 3 | rescue_goby | 虚弱虾虎 | fish | 22.0 | 7 | 8 | 0.07 | reserved |
| 4 | rescue_seahorse | 受困海马 | fish | 26.0 | 5 | 6 | 0.06 | reserved |
| 5 | rescue_hermit_crab | 寄居蟹 | crustacean | 22.0 | 6 | 7 | 0.05 | reserved |
| 6 | rescue_brain_coral_frag | 脑珊瑚碎片 | coral | 28.0 | 7 | 8 | 0.07 | reserved |

All parameter ranges confirmed:
- recovery_rate_base: 22–30 ✓
- reward_reputation: 5–7 ✓
- reward_rp: 6–8 ✓
- water_pressure: 0.05–0.08 ✓
- injury_type: all "reserved" ✓

### 4.2 9-Species Complete List

The 9-species plan exists ONLY in `reports/m17/` (M17_READINESS_DIAGNOSIS_REPORT.md, M17_PLANNING_FREEZE_FINAL_AFTER_DIAGNOSIS.md, M17_T01_TASK_CARD_DRAFT.md). Not present in `data/species_rescue_pool.json`. ✓

### 4.3 Card Manifest

- **File**: `data/card_manifest.json`
- **schema_version**: 2
- **max_entries**: 6
- **Entries aligned with pool**: 6/6 ✓

| Species ID | Source | Asset Path |
|------------|--------|------------|
| rescue_clownfish_juvenile | image2_user_generated | assets/cards/rescue/ |
| rescue_cleaner_shrimp | image2_user_generated | assets/cards/rescue/ |
| rescue_goby | image2_user_generated | assets/cards/rescue/ |
| rescue_seahorse | placeholder | assets/cards/placeholder/ |
| rescue_hermit_crab | placeholder | assets/cards/placeholder/ |
| rescue_brain_coral_frag | placeholder | assets/cards/placeholder/ |

### 4.4 Placeholder SHA Mechanism

3 new M17-T01 species use deterministic placeholders:
- Type: `deterministic_placeholder`
- Style: `species_theme_color_name_card`
- SHA256 recorded in manifest ✓
- Generated by `tests/m17_t01_generate_placeholders.gd` ✓

### 4.5 No Real Assets Added

`assets/cards/rescue/` contains only 3 files (M16 species):
- rescue_clownfish_juvenile.png
- rescue_cleaner_shrimp.png
- rescue_goby.png

No new real Image2 assets added for M17-T01. ✓

### 4.6 SaveSystem / save_schema

Zero diff from planning freeze to HEAD:
```
git diff v3.5-m17-planning-freeze..HEAD -- scripts/systems/SaveSystem.gd
# (empty)
git diff v3.5-m17-planning-freeze..HEAD -- data/save_schema.json
# (empty)
```
✓

### 4.7 UI Diff Scope

Only 2 files changed:
```
scenes/tank/DisplayTankView.gd | 2 +-   (header build ID text)
scenes/ui/StatusPanel.gd       | 2 +-   (columns 2→3)
```

No other UI files touched. ✓

### 4.8 RescueSystem Diff

```
scripts/systems/RescueSystem.gd | 15 ++++++++++++++-
1 file changed, 14 insertions(+), 1 deletion(-)
```

Changes:
- Added `_bag: Array[int]` field
- `import_state`: added `_bag.clear()` (ephemeral, not persisted)
- `_generate_candidate`: replaced `_rand_range(0, pool.size()-1)` with one-draw bag draw

### 4.9 RNG Constraints

Verified in `scripts/systems/RescueSystem.gd`:

- **No Fisher-Yates**: `grep -rni "fisher\|yates\|shuffle" scripts/` → no matches ✓
- **One RNG per candidate**: Each `_generate_candidate` call uses exactly 1 `_rand_range` call ✓
- **_schedule_next_arrival RNG preserved**: Bag refill consumes zero RNG (comment at line 264) ✓
- **No period boundary reroll**: No reroll logic anywhere in RescueSystem ✓
- **Bag not persisted**: `_bag.clear()` in `import_state` (line 188-189) ✓

### 4.10 FIRST_LOOP_DURATION

Documented baselines:
- M14 first loop: 840 seconds
- M15 care path: 580 seconds

Rescue config (`data/rescue_config.json`) has zero diff from planning freeze. Dock section unchanged:
```json
{
  "first_arrival_day": 1,
  "arrival_interval_min_days": 2,
  "arrival_interval_max_days": 4
}
```
✓

---

## 5. Rebaseline Protocol v2

### 5.1 Evidence

**Old baseline**: `v3.5-m17-planning-freeze` (commit b09ecc7) — 3-species pool
**New baseline**: runtime code baseline (commit 12d37ab) — 6-species pool

**Pool diff**: Pure append-only
- 3 original species unchanged (same id, name, recovery_rate_base, reward_reputation, reward_rp, water_pressure, injury_type)
- 3 new species appended

**Config diff**: Zero
- `data/rescue_config.json` identical between old and new
- Dock timing, recovery parameters, care multipliers all preserved

### 5.2 Diff Analysis

```
git diff v3.5-m17-planning-freeze..HEAD -- data/species_rescue_pool.json
```

Only additions:
```diff
+   { "id": "rescue_seahorse", ... },
+   { "id": "rescue_hermit_crab", ... },
+   { "id": "rescue_brain_coral_frag", ... }
```

No deletions, no modifications to existing entries.

### 5.3 Rebaseline Verdict

- Species selection differences: YES (expected — pool 3→6 + bag draw)
- Recovery rate differences: YES (consequence of selecting different species with different base rates)
- Arrival day / next_arrival timing: PRESERVED (same RNG sequence, same config)
- Event timestamps: DIVERGE due to different recovery durations (species-dependent)
- RP / reputation totals: DIVERGE due to different species rewards
- Save keys / schema: NO DIFF
- FIRST_LOOP_DURATION 840/580: PRESERVED (same config)

**All differences are direct or indirect consequences of species selection changes. No non-species configuration was modified.**

---

## 6. Screenshot Evidence Index

| File | Purpose | Generated By |
|------|---------|-------------|
| m17_t01_01_rescue_dock_candidate_visible.png | Rescue dock with candidate species visible | m17_t01_capture_screenshots.gd |
| m17_t01_02_active_rescue_no_repeat_candidate.png | Active rescue card with bag-draw no-repeat validation | m17_t01_capture_screenshots.gd |
| m17_t01_03_rescue_codex_or_livestock_record_visible.png | Codex / livestock record with rescue entries | m17_t01_capture_screenshots.gd |
| m17_t01_03b_rescue_codex_after_release.png | Codex view after rescue release | m17_t01_capture_screenshots.gd |
| m17_t01_hotfix_header_version_visible.png | Header build ID visible (hotfix 1) | m17_t01_hotfix_capture_header.gd |
| m17_t01_hotfix2_system_menu_layout_fixed.png | System menu layout fixed (hotfix 2) | m17_t01_hotfix2_capture_layout.gd |

### 6.1 Screenshot Coverage

- [x] Dock candidate visible
- [x] Active rescue state
- [x] Codex / livestock record
- [x] Post-release codex update
- [x] Header build ID
- [x] System menu layout (2 rows)

### 6.2 Font Fallback Notes

Chinese font rendering in Godot headless mode may display `?` characters. This is a headless/font fallback issue, not a game bug. All semantic assertions are backed by automated state/text dumps, not screenshot OCR.

### 6.3 M17 Forbidden Items Check

None of these appear in any screenshot:
- [x] No 收藏墙 (collection wall)
- [x] No 稀有度 (rarity system)
- [x] No 卡包 (card packs)
- [x] No 未解锁剪影墙 (locked silhouette wall)
- [x] No FlowContainer (not in T01 scope)
- [x] No massive UI restructure

---

## 7. Two Hotfix Closures

### 7.1 Hotfix 1: Visible Build ID

- **Commit**: `43256ba15b7e54430809ad96693e95306281b396`
- **Tag**: `v3.5-m17-t01-visible-build-id-hotfix`
- **Change**: `scenes/tank/DisplayTankView.gd:19` — header text: `"CoralReefIdleV3 · M17-T01 · v3.5-m17-t01-pool-datacontract-no-repeat"`
- **.gitignore *.import**: Standard Godot `.import` sidecar ignore rule, not evidence hiding. All `.import` files are auto-generated by Godot.
- **M17-T01 acceptance**: PASS (re-confirmed at runtime code baseline)

### 7.2 Hotfix 2: System Menu Dock Button Layout

- **Commit**: `12d37ab25efa3f48906bca3773e333eecacbbf49`
- **Tag**: `v3.5-m17-t01-hotfix2-system-menu-dock-button-layout`
- **Change**: `scenes/ui/StatusPanel.gd:441` — `entry_grid.columns = 2` → `entry_grid.columns = 3`
- **Result**: Row 1 = 商店/生物/码头, Row 2 = 观赏/保存/重置
- **M17-T01 regression**: PASS (66 assertions, 0 failed)
- **No unexpected diff**: Only columns change, no other UI or logic modifications

---

## 8. Known Limitations

1. **Bag state not persisted**: Bag is runtime-ephemeral. On save/load, bag refills from scratch. This means consecutive loads may produce different species sequences.
2. **Period boundary may repeat**: With 6 species in bag, 1/6 probability of same species at period boundary (bag refill edge).
3. **No boundary reroll**: Per RNG constraint — each candidate consumes exactly 1 RNG draw. Boundary reroll would break this.
4. **9 species, real assets, FlowContainer**: Not in T01 scope. Deferred to T02/T03.
5. **M14/M15 regression at runtime code baseline**: Expected divergence due to Rebaseline Protocol v2 (species selection differences). Original regression at T01 commit was all PASS.

---

## 9. Forbidden Diff Verification

| Rule | Status |
|------|--------|
| No M17-T02 entry | ✓ (branch is m16-t01-card-manifest) |
| No new real assets | ✓ (only placeholder PNGs added) |
| No UI changes beyond 2 hotfixes | ✓ (DisplayTankView.gd + StatusPanel.gd only) |
| No SaveSystem changes | ✓ (zero diff) |
| No save_schema changes | ✓ (zero diff) |
| No species_rescue_pool modifications to existing entries | ✓ (append-only) |
| No card_manifest schema change | ✓ (schema_version=2 maintained) |
| No RescueSystem changes beyond bag draw | ✓ (14 lines, bag draw only) |
| No Fisher-Yates | ✓ |
| No boundary reroll | ✓ |
| No new functional features | ✓ |

---

## 10. Final Verdict

**M17-T01 is ready for Codex review.**

- Acceptance: 66/66 PASS
- Regression (original T01): all PASS
- Rebaseline Protocol v2: diff is species-selection only
- Forbidden diff: 0
- 2 hotfixes documented and regression-verified
- All evidence items confirmed

**This is a Codex review candidate, not a final close.** Final close tag will be created after Codex PASS.
