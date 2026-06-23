# M10.1 Repo And Baseline Verification

Audit date: 2026-06-23  
Scope: M10 only. No M11 work, no tag, no commit, no push, no merge.

## Git Repository Candidates

Search roots used: `C:\Users\admin`, with focused scans under `Desktop` and `.codex`.

| Candidate | Branch | Remote | Latest commit | Latest message | `git status --short` | Assessment |
|---|---|---|---|---|---|---|
| `C:\Users\admin\cc-haha` | `main` | `https://github.com/NanmiCoder/cc-haha.git` | `61a857c2de00dc7d1f52773a00a145fa16a27d77` | `docs: move banner above badges in READMEs` | clean | Unrelated TypeScript/Codex tooling repo. Not the Godot project. |
| `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3` | `main` | `https://github.com/supdogg926/coral-reef-desk-v3.1.git` | `22d94a6a7cb5177fc00331c9f5f8955b5574e44e` | `fix: M10.12 replace typed array assignment with manual String cast in SaveSystem` | modified files listed below | Real candidate for `coral-reef-desk-v3.1`; contains Godot `project.godot`, `data/`, `scripts/systems/`, M10 reports, and current M10 SaveSystem work. |
| `C:\Users\admin\.codex\.tmp\plugins` | not inspected | internal `.codex` path | not inspected | not inspected | not inspected | Codex/plugin cache, not project candidate. |
| `C:\Users\admin\.codex\vendor_imports\skills` | not inspected | internal `.codex` path | not inspected | not inspected | not inspected | Codex vendor cache, not project candidate. |

## Current Godot Project Relationship

Declared current Godot path: `C:\Users\admin\CoralReefIdle`.

Result:

- `C:\Users\admin\CoralReefIdle` is not inside any Git repository. `git rev-parse --show-toplevel` returns `fatal: not a git repository`.
- It contains `project.godot`, `Scenes/`, `Scripts/`, and `UI/`, but no `.git`.
- It appears to be an older or copied Godot working directory, not the Git-managed `coral-reef-desk-v3.1` project. The Git project has different structure: `data/`, `scripts/systems/`, `scenes/ui/`, `reports/`.
- I did not run `git init`, move directories, or overwrite either project.

Practical implication: if Godot Editor is currently opening `C:\Users\admin\CoralReefIdle`, it is not opening the tracked repo version. M10 seal evidence should be collected from `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3` unless the user intentionally wants to migrate the non-Git copy later.

## Save Freeze / Card-Freezing Bug Check

Important interpretation: absence of a re-entry guard in an earlier static audit is not treated as evidence that yesterday's save/purchase freeze bug returned.

Git-managed repo evidence:

- Latest commit message is `fix: M10.12 replace typed array assignment with manual String cast in SaveSystem`, which directly indicates the typed-array save/debug issue was fixed yesterday in the tracked repo.
- Purchase button text is in `scenes/ui/ShopPanel.gd`: `buy_btn.text = "带回家"`.
- Purchase flow calls `game_state.buy_livestock_from_shop(shop_id)` in `scenes/ui/ShopPanel.gd`.
- Purchase save is delayed, not immediate: `scripts/systems/GameState.gd` sets `_pending_save_after_purchase = true`, then `update()` calls `_perform_autosave()` after `PURCHASE_SAVE_DELAY = 2.0`.
- Manual save test button calls `game_state._perform_autosave()` from `scenes/main/Main.gd`.
- Regular autosave is fixed at `AUTOSAVE_INTERVAL: float = 60.0` in `scripts/systems/GameState.gd`.
- Save call path ends at `scripts/systems/SaveSystem.gd::save_game()`.

This round added a low-risk hardening layer in the tracked repo:

- `scripts/systems/SaveSystem.gd` now has `_is_saving` re-entry protection.
- `scripts/systems/SaveSystem.gd` now recursively converts/checks save payloads with `_to_json_safe()`.
- Save debug output now returns plain arrays instead of typed array duplicates.

Static JSON safety result:

- Save payload is built from dictionaries exported by systems and passed through `_to_json_safe()`.
- Non JSON-safe values such as `Vector2`, `Node`, `Resource`, `Callable`, `Signal`, and packed arrays are rejected before `JSON.stringify`.
- Static search still finds `Vector2` and packed arrays in drawing/UI code, but not as part of the save payload path after the hardening above.

Conclusion: no static evidence of yesterday's save bug recurring was found in the Git-managed repo. Runtime confirmation still requires Godot Output/Debugger after the 20-item regression flow.

## M10 Baseline Difference Explanation

Why earlier audit saw missing baselines:

- Earlier audit was performed against `C:\Users\admin\CoralReefIdle`, which is not the Git-managed M10 project.
- That non-Git copy has no `data/livestock/starter_livestock_seed.json`.
- It generates initial state from `Scripts/GameManager.gd`, where `owned_bios` defaults to `[]`.
- Its default tank table uses `capacity=6` for `tank_30`.
- Its shop UI builds from full data pools in `UI/Main.gd`, including `SpeciesData.FISH + SpeciesData.LEGACY_FISH`, so visible shop rows exceed 10.

Tracked repo baseline after this round:

| Baseline | Result | Evidence |
|---|---|---|
| Starter seed file exists | PASS | `data/livestock/starter_livestock_seed.json` |
| Initial livestock count | PASS | Parsed count: `6` |
| Initial capacity | PASS | Starter `capacity_cost` sum: `18.0`; `LivestockSystem.DEFAULT_MAX_CAPACITY = 30.0` |
| Player-visible shop item count | PASS | `data/shop/initial_shop_seed.json` parsed count: `10`; `ShopPanel` renders `ls.get_shop_items()` only |
| Rarity enum fixed | PASS | `data/schemas/rarity_enum.json`; `LivestockSystem.VALID_RARITIES` |
| Save schema fixed | PASS | `data/schemas/save_schema.json`; `SaveSystem.SAVE_SCHEMA_ID` |
| Autosave strategy | PASS | `GameState.AUTOSAVE_INTERVAL = 60.0` |
| Save re-entry hardening | PASS | `SaveSystem._is_saving`; `GameState._save_in_progress` |
| Debug/save JSON-safe fields | PASS static | `SaveSystem._to_json_safe()` rejects unsupported Variant types |

Starter livestock summary:

| id | name | capacity | rarity | base income/h |
|---|---|---:|---|---:|
| `clownfish_pair` | 小丑鱼一对 | 4.0 | 普通 | 0.48 |
| `blue_tang` | 蓝吊 | 5.0 | 普通 | 0.64 |
| `anemone` | 海葵 | 3.0 | 普通 | 0.40 |
| `green_star_polyps` | 草皮珊瑚 | 2.0 | 普通 | 0.32 |
| `zoanthids` | 纽扣珊瑚 | 2.0 | 普通 | 0.28 |
| `soft_coral_frag` | 软体珊瑚断枝 | 2.0 | 普通 | 0.24 |

Shop item summary:

`fluorescent_turf`, `pulsing_xenia`, `sea_anemone_shop`, `button_polyps`, `green_torch`, `jewel_flower`, `hammer_coral`, `ocellaris_clown`, `blue_tang_shop`, `mandarin_dragonet`.

## Files Modified This Round

No commit was made. No tag was created.

Tracked repo status currently includes:

- `data/livestock/starter_livestock_seed.json`
- `data/schemas/species_schema.json`
- `data/schemas/rarity_enum.json`
- `data/schemas/save_schema.json`
- `scripts/systems/LivestockSystem.gd`
- `scripts/systems/SaveSystem.gd`
- `scenes/main/Main.gd`
- `reports/m10_1_repo_and_baseline_verification.md`

No files were modified in `C:\Users\admin\CoralReefIdle` during this verification pass.

## Gate Decision

M10 tag remains blocked because the task explicitly says no tag and because runtime evidence is still required.

M10封版 blocker status:

- For `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3`: static M10.1 baseline is ready for another 20-item regression run.
- For `C:\Users\admin\CoralReefIdle`: still blocked as a seal source because it is not Git-managed and does not match the tracked M10.1 baseline.

Next step: re-run the 20-item M10 regression against the Git-managed project path, not the non-Git copy.

Suggested next Codex/Godot verification command:

```bash
codex "仍冻结 M10，不进入 M11，不打 tag。请在 C:\\Users\\admin\\Desktop\\桌面海缸v3.0\\CoralReefIdleV3 运行/指导执行 20 项 M10 回归验收：重置M10测试存档、重启、确认 6 个生物、容量 18.0/30.0、商店 10 项、购买带回家后 7 个生物且容量/收益增加、手动保存不卡死、等待 60 秒自动保存不卡死、重启恢复、Godot Output/Debugger 无红色错误。若 Godot CLI 不可用，请明确列出需要用户手动截图的步骤。"
```

