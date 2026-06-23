# M11 Planning Report

Report date: 2026-06-23
Scope: M11 planning only.
Restrictions: no business code changes, no Godot scene changes, no bug fixes, no new gameplay, no commit, no push, no tag, no M11 development.

## 1. 当前状态确认

- Authoritative repository: `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3`
- Git root verified: YES
- Branch: `main`
- Current local HEAD during planning: `c71bb8f55c9affe987420ae5bcac500dd0b843a5`
- Current local HEAD summary: `c71bb8f (HEAD -> main, origin/main) docs: archive M10 release documentation`
- `CURRENT_STATE.md` read: YES
- `PROJECT_RULES.md` read: YES
- `reports/m10_completion_report.md` read: YES
- `reports/task_risk_report_template.md` read: YES
- `reports/agent_handoff_verification_template.md` read: YES
- Runtime started: NO
- Godot Output / Debugger checked: NO

State notes:

- `CURRENT_STATE.md` declares current milestone as `M10 livestock core` and status as `M10 已封版`.
- `CURRENT_STATE.md` records final tag `v3.1-m10-livestock-core` and final commit `1a4c334eb67090d2df66039bb519876376506e0e`.
- `reports/m10_completion_report.md` confirms M10 was sealed with runtime regression `PASS 20 / FAIL 0 / NOT_TESTED 0`.
- The working tree was clean before this planning document generation.
- The current local HEAD is a later documentation archive commit after the M10 sealed commit. This planning report does not alter the M10 runtime baseline or tag.

## 2. M10 留下的稳定基线

M10 stable baseline:

- Livestock shop opens and lists 10 products.
- Buying via "带回家" does not freeze the page.
- Store can still be closed after purchase.
- Livestock count changes from 6 to 7 after the validated purchase path.
- Capacity increases after livestock is added.
- Reef value / income increases after livestock is added.
- Manual save completes without freeze.
- Autosave completes without freeze.
- Restart restore keeps the purchased livestock.
- Godot Output / Debugger had no red errors in final M10 validation.

Git / release baseline from M10 report:

- M10 sealed tag: `v3.1-m10-livestock-core`
- M10 sealed commit: `1a4c334eb67090d2df66039bb519876376506e0e`
- Runtime regression: `PASS 20 / FAIL 0 / NOT_TESTED 0`

Governance baseline:

- `PROJECT_RULES.md` is now the shared rule source for Codex, Claude Code, and future agents.
- `tools/dev_guard_check.ps1` exists as the repository guard.
- Risk reporting and handoff templates exist under `reports/`.
- M11 is allowed only as planning until the user explicitly approves development.

## 3. M11 候选方向

### Candidate A: 放归系统 MVP

Purpose:

- Close the livestock lifecycle after M10 by allowing owned livestock to leave the tank through a controlled "release" path.

Likely scope:

- Define the release state model.
- Define whether released livestock are removed, archived, counted separately, or recoverable.
- Define reward policy, if any.
- Define minimal UI entry points and copy.
- Define save migration and rollback requirements before any implementation.

Main risks:

- Touches livestock ownership, capacity, save data, and UI flow.
- Can easily become an ocean / expedition / collection system if not frozen tightly.
- Requires strong acceptance tests before development starts.

Why it fits M11:

- It is the most direct continuation of M10 livestock core.
- It adds a meaningful player decision while staying smaller than ocean or expedition systems.

### Candidate B: 图鉴 / 生物记录 MVP

Purpose:

- Provide a non-invasive way to view known livestock, owned livestock, and possibly released history.

Likely scope:

- Define read-only collection categories.
- Define discovered / owned / released display states.
- Define whether this is data-only or UI-only for M11.
- Avoid achievements and reward logic in the first pass.

Main risks:

- Can expand into achievements, progression, and completion rewards.
- If it reads from save state, it still needs save contract review.

Why it fits M11:

- Lower gameplay risk than release, ocean, or expedition systems.
- Good companion feature if release history is selected as a future requirement.

### Candidate C: 大海 / 蓝色守护远征 Pre-MVP

Purpose:

- Prepare the larger outside-tank loop without building the full system.

Likely scope:

- Only produce a design contract and technical risk map.
- Identify required data schemas, UI routes, save impacts, and validation needs.
- No runtime feature work unless separately authorized later.

Main risks:

- Highest scope explosion risk.
- Can touch new systems, progression, rewards, timers, ocean state, and multi-page UI.
- Not suitable for immediate coding from the current M10 baseline.

Why it may fit later:

- It can become an M12+ feature after M11 proves the livestock lifecycle and state contracts.

### Candidate D: 设备 / 养殖支持系统扩展

Purpose:

- Expand existing equipment or support systems to create more tuning levers for livestock capacity and reef value.

Likely scope:

- Define one narrow equipment or support upgrade path.
- Decide whether it modifies capacity, chemistry, income, or UI display only.

Main risks:

- Touches economy balancing, equipment slots, UI, and possibly save data.
- May distract from closing the livestock lifecycle.

Why it may fit:

- Existing equipment foundation exists, but it is less directly connected to the M10 validation path than release.

## 4. 推荐 M11 方向

Recommended direction:

```text
M11 = 放归系统 MVP planning, with implementation deferred until user approval.
```

Recommended M11 objective:

- Define and later implement the smallest safe release-to-sea lifecycle for owned livestock.
- Treat it as a livestock lifecycle extension, not as the full ocean system.
- Keep ocean, expedition, achievement, breeding, and advanced death systems out of M11.

Reasoning:

- M10 proved the owned-livestock purchase, capacity, income, save, autosave, and restore loop.
- A tightly scoped release MVP is the natural next lifecycle step.
- The feature has enough player meaning to justify M11, but can remain small if the frozen scope is enforced.

## 5. M11 冻结范围

Recommended frozen M11 scope:

- One player-facing release action for owned livestock.
- One clear confirmation step before release.
- One defined post-release state: removed from active tank and recorded in a minimal released-history field, if approved during final design.
- Capacity must update consistently after release.
- Income / reef value impact must be explicitly defined before coding.
- Save data must remain JSON-safe.
- Restart restore must preserve the post-release state.
- UI must remain minimal and reuse existing patterns.

Out of scope for M11:

- Full ocean map.
- Blue Guardian expedition gameplay.
- Achievements or encyclopedia rewards.
- Breeding.
- Complex livestock death, illness, decay, or random loss.
- New equipment families.
- Multi-page final UI art pass.
- Broad refactors of livestock, save, UI, or economy systems.

## 6. M11 验收清单草案

Draft acceptance checklist for future M11 development:

| # | Acceptance Item | Expected Result |
| --- | --- | --- |
| 1 | Start from sealed M10-compatible save state | Initial livestock, capacity, and income display correctly |
| 2 | Open owned livestock view | Owned livestock list renders without errors |
| 3 | Select one releasable livestock | Release action is available only for valid owned livestock |
| 4 | Cancel release confirmation | No livestock, capacity, income, or save state changes |
| 5 | Confirm release | Selected livestock leaves active owned list |
| 6 | Capacity recalculates | Used capacity decreases consistently |
| 7 | Income / reef value recalculates | Change follows the approved design rule |
| 8 | Manual save after release | Save completes without freeze |
| 9 | Autosave after release | Autosave completes without freeze |
| 10 | Restart after release | Released state remains consistent after restore |
| 11 | Invalid release attempt | No crash, no duplicate state mutation, no negative capacity |
| 12 | Godot Output / Debugger | No red errors during the full flow |

Required evidence after future implementation:

- Changed files list.
- Diff summary.
- Risk report using `reports/task_risk_report_template.md`.
- Runtime started: YES.
- Godot Output / Debugger checked: YES.
- Manual screenshot or runtime confirmation if UI changed.

## 7. M11 防屎山预警

High-risk expansion points:

- Do not let "release" silently become a full ocean system.
- Do not add expedition, timers, rewards, achievements, or collection completion in the same change.
- Do not mix release logic with broad save refactors.
- Do not store non-JSON-safe engine runtime values in save data.
- Do not allow UI buttons to own economy or save rules.
- Do not add development-only controls to the normal player path.
- Do not change M10 baseline behavior while adding M11 behavior.
- Do not treat reports from non-authoritative project copies as evidence.
- Do not enter M11 development from this planning report alone.

Risk controls before any development:

- Write the final M11 functional spec first.
- Identify exact files expected to change.
- Define save schema change, if any.
- Define rollback behavior and migration behavior.
- Define the exact runtime regression script/manual checklist.
- Run `tools/dev_guard_check.ps1` before and after implementation.

## 8. 下一步只读方案确认建议

Recommended next step:

```text
Perform a read-only M11 scope confirmation pass before development.
```

That pass should confirm:

- Whether M11 is exactly "放归系统 MVP".
- Whether released livestock are only removed from the active tank or also recorded in history.
- Whether release changes income / reef value immediately.
- Whether release gives any reward. Recommended default: no reward in M11 MVP.
- Whether any save schema field is allowed. Recommended default: allow only one minimal JSON-safe field if required.
- Which manual runtime checklist is mandatory for future implementation.

Planning gate result:

- Allow game runtime impact: NO
- Allow commit of planning documents: NO, requires separate user authorization
- Allow M11 development: NO, requires user confirmation after planning
