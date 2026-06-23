# M11 Prototype Implementation Report

Report date: 2026-06-23
Current branch: `prototype/m11-biomanage-vertical-slice`
Mode: Fast prototype only.

## Modified Files

- `scenes/ui/LivestockPanel.gd`
- `scripts/systems/GameState.gd`
- `scripts/systems/LivestockSystem.gd`
- `reports/m11_prototype_acceptance_checklist.md`
- `reports/m11_prototype_implementation_report.md`

## Player-Visible Prototype Features

- `我的生物` rows now include a `选择` button.
- Selecting a livestock shows details:
  - name
  - rarity
  - capacity cost
  - income per hour
  - current status
- A `放归/移除` button appears after selection.
- Clicking release opens a second confirmation panel.
- Confirming release removes the livestock from active ownership.
- The owned list refreshes after release.
- Livestock count, used capacity, and income are recalculated by system logic.
- Success feedback shows text such as `已放归 XXX`.
- Confirmation and feedback use light fade / scale effects for prototype visibility.
- Release schedules a delayed autosave through the existing save path.

## Prototype-Only Parts

- The UI copy uses `放归/移除` to make the prototype behavior explicit.
- Release has no history archive and no recovery path.
- Release uses a compact inline confirmation panel, not final production UX.
- Debug output is prefixed with `[M11 PROTOTYPE]` for easy cleanup.
- The delayed save timer is separate from the purchase timer for clarity, but is still prototype-level plumbing.

## Not Recommended For Formal Version As-Is

- Do not keep the final product wording as `放归/移除` without a design decision.
- Do not keep release as permanent deletion unless the formal M11 spec approves that state model.
- Do not ship without a clearer empty-state and undo/recovery decision.
- Do not keep prototype debug prints forever.
- Do not expand this into ocean, expedition, achievements, rewards, breeding, death, or equipment systems in the same milestone.

## Worth Keeping

- Core mutation stays in `LivestockSystem`, not UI.
- `GameState.release_owned_livestock()` is a useful orchestration boundary.
- Save compatibility is simple because released livestock are absent from the existing `owned_livestock` array.
- Two-step confirmation is necessary and should stay.
- Lightweight feedback is enough for this scope.

## Save Compatibility

- No new save schema field was added.
- No `SaveSystem.gd` change was required.
- Existing save behavior persists release because the save payload already exports `owned_livestock`.
- Restart restore should load the reduced `owned_livestock` list after manual or autosave.

## Risk Points

- The prototype removes livestock permanently from active ownership.
- There is no released-history field, so formal M11 must decide whether history is required.
- Effective income depends on the regular livestock/economy recalculation path.
- Manual UI validation is still required because headless startup cannot click through panels.
- M10 purchase was not intentionally changed, but it should be spot-checked before any prototype commit.

## M10 Main Path Impact

- The existing shop purchase method was not edited.
- Existing save serialization path was not edited.
- Existing starter livestock and shop data were not edited.
- Expected M10 impact: low, but runtime spot-check is still required.

## Verification Performed

- Preflight confirmed repository root, branch, clean working tree, expected HEAD `767c39b`, and M10 tag presence before branch creation.
- Created branch `prototype/m11-biomanage-vertical-slice` from `main`.
- Ran Godot 4.7 headless project startup after granting filesystem permission for Godot logs.
- Ran Godot 4.7 headless short main-scene runtime with `--quit-after 3`.
- No red errors were printed by the successful headless runs.

## Next Recommendation

Recommendation: `adjust`

Reason:

- Keep the vertical slice for user testing because it proves the core loop quickly.
- Adjust the formal design before production: decide whether release means deletion, history archive, or another state.
- Do not merge to `main` until manual runtime acceptance is completed and the prototype decisions are either formalized or removed.
