# M11 Candidate Scope

Date: 2026-06-23
Status: Planning only. Not approved for development.

## 推荐方向

Recommended M11 direction:

```text
放归系统 MVP
```

Definition:

- A narrow owned-livestock lifecycle extension.
- Player can release one owned livestock through a controlled confirmation flow.
- Active livestock, capacity, and save/restore behavior must remain consistent.
- This is not the full ocean system.

Recommended default decisions for confirmation:

- Released livestock are removed from active tank ownership.
- Released livestock may be recorded in one minimal JSON-safe history field only if approved.
- No release rewards in the first M11 MVP unless the user explicitly approves a reward rule.
- No achievement, expedition, breeding, death, or ocean-map logic.

## 可选方向

Optional directions for later selection:

1. 图鉴 / 生物记录 MVP
   - Read-only display of known, owned, and possibly released livestock.
   - Must not include achievement rewards in the first pass.

2. 大海 / 蓝色守护远征 Pre-MVP
   - Design contract and risk mapping only.
   - Should not enter implementation directly from M10.

3. 设备 / 养殖支持系统扩展
   - One narrow support upgrade path only.
   - Must define whether it affects capacity, chemistry, income, or display.

## 冻结方向

Frozen recommended scope for M11:

- One release action.
- One confirmation step.
- One defined post-release state.
- Capacity recalculation after release.
- Explicit income / reef value rule before implementation.
- JSON-safe save data only.
- Restart restore validation.
- Minimal UI using existing patterns.

Frozen out of M11:

- Full ocean system.
- Blue Guardian expedition.
- Encyclopedia achievements.
- Breeding.
- Complex livestock death or illness.
- New equipment families.
- Multi-page final UI art pass.
- Broad refactors.

## 禁止事项

Until the user separately authorizes M11 development:

- Do not modify business code.
- Do not modify Godot scene files.
- Do not fix bugs.
- Do not add gameplay code.
- Do not commit.
- Do not push.
- Do not create tags.
- Do not start M11 implementation.

During future M11 implementation, if authorized:

- Do not store non-JSON-safe engine runtime values in save data.
- Do not let UI own economy, save, or lifecycle rules.
- Do not add hidden changes to M10 purchase, capacity, manual save, autosave, or restart restore behavior.
- Do not expand release into ocean, expedition, achievement, breeding, death, or equipment systems.

## 验收原则

M11 acceptance should require:

- Correct source-of-truth repository verified.
- `CURRENT_STATE.md` and `PROJECT_RULES.md` read before work.
- Scope remains within the approved M11 direction.
- Changed files are minimal and match the approved file list.
- Save payload remains JSON-safe.
- Manual save, autosave, and restart restore pass after the new flow.
- Godot Output / Debugger has no red errors.
- Risk report is completed before any commit request.
- Commit, push, and tag require separate user authorization.
