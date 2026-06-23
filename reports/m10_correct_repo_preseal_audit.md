# M10 Correct Repo Preseal Audit

Audit date: 2026-06-23  
Scope: correct Git repo only. M10 frozen. No M11 work, no gameplay additions, no commit, no push, no merge, no tag.

## Git State

Repository path:

```text
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3
```

Command evidence:

```text
pwd
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3

git rev-parse --show-toplevel
C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3

git branch --show-current
main

git remote -v
origin  https://github.com/supdogg926/coral-reef-desk-v3.1.git (fetch)
origin  https://github.com/supdogg926/coral-reef-desk-v3.1.git (push)

git log -1 --oneline
22d94a6 fix: M10.12 replace typed array assignment with manual String cast in SaveSystem
```

Latest commit:

- Hash: `22d94a6a7cb5177fc00331c9f5f8955b5574e44e`
- Message: `fix: M10.12 replace typed array assignment with manual String cast in SaveSystem`

Recent 5 commits:

```text
22d94a6 fix: M10.12 replace typed array assignment with manual String cast in SaveSystem
5826fd3 fix: M10.11 autosave interval 60s, re-entry guard, per-step logging, manual save button
d049fdb fix: M10.10 reset autosave timer after deferred save, add mouse_filter, heartbeat log
34de94e fix: M10.9f Timer-based defer + detailed per-step buy logging
e1ec810 test: add M10 reset save button to restore 6 starter livestock
```

Current working tree status before this report was generated:

```text
 M data/livestock/starter_livestock_seed.json
 M data/schemas/species_schema.json
 M scenes/main/Main.gd
 M scripts/systems/LivestockSystem.gd
 M scripts/systems/SaveSystem.gd
?? data/schemas/rarity_enum.json
?? data/schemas/save_schema.json
?? reports/m10_1_repo_and_baseline_verification.md
```

These are uncommitted local changes from earlier M10.1 work. This audit did not commit, push, merge, or tag.

## SaveSystem Typed Array Fix

The latest commit is SaveSystem typed-array related.

`git show --name-status HEAD`:

```text
22d94a6a7cb5177fc00331c9f5f8955b5574e44e
fix: M10.12 replace typed array assignment with manual String cast in SaveSystem

M scripts/systems/SaveSystem.gd
```

Patch evidence from HEAD:

- Replaced direct `last_saved_keys = save_data.keys().duplicate()`.
- Now clears `last_saved_keys` and appends `String(key)` for each key.
- Replaced `raw_livestock.has("owned_livestock")` with `"owned_livestock" in raw_livestock`.
- Added detailed save logging around last key and livestock debug updates.

Conclusion: yesterday's SaveSystem typed array fix exists in the correct Git repository.

## Save / Purchase Chains

Purchase "带回家" visible entry:

- `scenes/ui/ShopPanel.gd:45` loads player-visible shop items from `ls.get_shop_items()`.
- `scenes/ui/ShopPanel.gd:74-79` creates the button and sets `buy_btn.text = "带回家"`.
- `scenes/ui/ShopPanel.gd:147-158` defers button handling through `_buy_timer`.
- `scenes/ui/ShopPanel.gd:161-170` calls `game_state.buy_livestock_from_shop(shop_id)`.
- `scripts/systems/GameState.gd:242-286` creates a JSON-safe purchase dictionary, adds livestock, updates economy, then sets `_pending_save_after_purchase = true`.
- `scripts/systems/GameState.gd:87-95` performs delayed autosave after `PURCHASE_SAVE_DELAY = 2.0`.
- `scripts/systems/GameState.gd:353-391` calls `save_system.save_game(save_dict)`.

Manual save test chain:

- `scenes/main/Main.gd:88-103` adds `重置M10测试存档` and `手动保存测试` in dev/debug UI.
- `scenes/main/Main.gd:157-164` implements `_manual_save_test()`.
- `_manual_save_test()` calls `game_state._perform_autosave()`.
- `_perform_autosave()` calls `save_system.save_game(save_dict)`.

Automatic save chain:

- `scripts/systems/GameState.gd:28` sets `AUTOSAVE_INTERVAL = 60.0`.
- `scripts/systems/GameState.gd:82-86` increments `_autosave_timer` and calls `_perform_autosave()` at 60 seconds.
- `_perform_autosave()` calls `save_system.save_game(save_dict)`.

Re-entry/equivalent save protection:

- `scripts/systems/GameState.gd:34` has `_save_in_progress`.
- `scripts/systems/GameState.gd:353-359` skips `_perform_autosave()` when already saving.
- Current working tree also has `scripts/systems/SaveSystem.gd:10` `_is_saving` and `scripts/systems/SaveSystem.gd:27-32` re-entry skip. This is uncommitted local hardening from earlier M10.1 work.

## JSON Safety Static Check

Code-level evidence:

- `scripts/systems/GameState.gd:253-265` creates purchase entries using strings, floats, and bools.
- `scripts/systems/GameState.gd:380-387` save payload contains dictionaries exported by systems.
- `scripts/systems/LivestockSystem.gd:245-254` exports livestock as dictionaries with numeric/string/bool fields.
- Current working tree `scripts/systems/SaveSystem.gd:188-211` includes `_to_json_safe()` that accepts nil/bool/int/float/string/Array/Dictionary and rejects other Variant types.
- Current working tree `scripts/systems/SaveSystem.gd:158-175` returns debug fields as JSON-safe primitive/dictionary/array values.

Static search notes:

- `Vector2`, `PackedVector2Array`, `Node`, and scene `PackedScene` references exist in drawing/UI `.gd` and `.tscn` files, as expected for Godot UI/rendering.
- The static save chain above does not show those UI/rendering objects being written into save payload fields.

Result:

- Code static check: PASS for the current working tree.
- Runtime validation: NOT RUN. Godot Output/Debugger still must be checked manually before sealing.
- Bug recurrence evidence: no static evidence was found that yesterday's save/purchase freeze bug has recurred in the correct repo.

## M10 Data Baseline

Data files:

- Starter seed: `data/livestock/starter_livestock_seed.json`
- Player-visible M10 shop: `data/shop/initial_shop_seed.json`
- Rarity enum: `data/schemas/rarity_enum.json` and `scripts/systems/LivestockSystem.gd:31`
- Save schema: `data/schemas/save_schema.json` and `scripts/systems/SaveSystem.gd:6`

Parsed data evidence:

```text
starter_exists=True
starter_count=6
starter_capacity_sum=18
starter_income_sum=2.36
shop_exists=True
shop_count=10
rarities_starter=普通
rarities_shop=普通,精品,稀有
rarity_schema=True
save_schema=True
```

Baseline result table:

| Item | Result | Evidence |
|---|---|---|
| `starter_livestock_seed.json` exists | PASS | `data/livestock/starter_livestock_seed.json` |
| Initial livestock count is 6 | PASS static | Parsed starter count is `6`; loaded in `LivestockSystem._load_starter_livestock()` |
| Initial capacity is about 18.0/30.0 | PASS static | Starter capacity sum is `18`; max capacity is `DEFAULT_MAX_CAPACITY = 30.0` |
| Player-visible shop count is 10 | PASS static | `initial_shop_seed.json` parsed count is `10`; `ShopPanel` renders `ls.get_shop_items()` |
| Rarity enum stable | PASS static | `VALID_RARITIES = ["普通", "精品", "稀有", "大师", "传奇"]`; schema exists |
| Save schema stable | PASS static | `data/schemas/save_schema.json`; `SAVE_SCHEMA_ID` in SaveSystem |
| Capacity default | PASS static | `scripts/systems/LivestockSystem.gd:6`, `:12`, `:45` set/use `30.0` |
| Autosave strategy | PASS static | `scripts/systems/GameState.gd:28` sets `60.0` seconds |
| Save re-entry/equivalent protection | PASS static | `GameState._save_in_progress`; current working tree also has `SaveSystem._is_saving` |

Full data pool vs visible shop:

- Full project data includes other species/equipment/task files under `data/`.
- Player M10 shop does not render the full species pool directly.
- Player-visible M10 shop is `LivestockSystem.get_shop_items()` from `data/shop/initial_shop_seed.json`, then rendered by `scenes/ui/ShopPanel.gd`.
- The parsed player-visible list contains 10 items.

## Debug Buttons

| Entry | Location | Current behavior | Recommendation |
|---|---|---|---|
| `重置M10测试存档` | `scenes/main/Main.gd:88-95`, handler `:142-154` | Clears save and reinitializes `GameState`; current working tree gates it behind `_is_dev_debug_ui_enabled()` | Keep only in dev/debug builds; do not expose in release UI. |
| `手动保存测试` | `scenes/main/Main.gd:97-103`, handler `:157-164` | Calls `game_state._perform_autosave()` | Keep only in dev/debug builds; useful for M10 regression. |
| `heartbeat tick` | `scenes/main/Main.gd:30-37` | Prints `[HEARTBEAT] tick=...`; current working tree gates it behind `_is_dev_debug_ui_enabled()` | Keep as dev/debug diagnostic only; remove or silence for release if noisy. |

No debug entry was deleted by this audit.

## Gate Decisions

20-item regression:

- Can begin: YES, static prerequisites in the correct Git repo are present.
- Caveat: Godot runtime was not executed in this audit. The 20-item checklist still needs manual or automated Godot validation, including restart recovery and Output/Debugger red-error check.

Tag `v3.1-m10-livestock-core`:

- Allowed now: NO.
- Reasons: user explicitly forbids tag in this task; working tree is dirty; runtime 20-item regression has not been completed in this audit.

Enter M11:

- Allowed now: NO.
- Reasons: task is frozen at M10 and M10 runtime acceptance remains pending.

Final conclusion:

- Correct repo was audited.
- Latest commit is the SaveSystem typed-array fix.
- Static code/data baseline looks ready for M10 20-item regression on the current working tree.
- No static evidence was found that yesterday's save/purchase freeze bug has recurred.
- Do not use this audit as runtime pass evidence; it is static-only until Godot is run and screenshots/output are captured.

