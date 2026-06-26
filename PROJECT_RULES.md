# CoralReefDesk Project Rules

These rules apply to Codex, Claude Code, and any other coding assistant working on this repository.

## Single Source Of Truth

- The only authoritative Git repository path is:
  `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3`
- Work performed in any copied directory is not valid for release decisions.
- `C:\Users\admin\CoralReefIdle` is not the authoritative repository and must not be used as a release audit source.

## Non-Git Directory Rule

- Do not modify project files in a directory that is not inside the authoritative Git repository.
- Do not run `git init` to turn a copied project into a new repository.
- Do not move, overwrite, or sync files between project copies unless the user explicitly requests it.

## Milestone Freeze Rule

- A milestone freeze means the current milestone scope is locked.
- During M11 freeze, do not enter M12 functional development without user approval.
- M11 is frozen as a Stable Acceptance Baseline with `v3.1-m11-acceptance-harness` tag.
- Do not create tags, merge branches, push commits, or commit changes unless the user explicitly requests that action.
- Audit conclusions must be based on Git evidence, changed files, diff summaries, and runtime validation.

## M12 Autonomous Execution Rules

### Autonomy Levels

- **Level 1 (active)**: Standard autonomy — continuous execution within guardrails, no per-operation confirmation needed for file I/O, Godot headless, git read-only, tool scripts.
- **Level 0 (emergency only)**: Full confirmation — only when save system corruption, detached HEAD, or .godot/ corruption detected.

### Stop Conditions (must wait for user)

- `git commit`, `git push`, `git tag` operations
- Deleting `.gd` / `.tscn` source files
- Modifying `SaveSystem` or `project.godot`
- Cross-branch operations

### No-Ask List (do NOT stop to ask)

- "Can I continue?" — just continue
- "Can I run tests?" — just run them
- "Can I read this file?" — just read it
- "Looks good, proceed?" — just proceed
- Single tool script execution — aggregate results

### Batch Rules

- Max 15 write operations per autonomous window
- Max 10 Godot runs per autonomous window
- Visual QA: minimum 10 issues aggregated per round
- Report progress when window limit reached

### Failure Rules

- Single test FAIL → stop, report assertion details
- Acceptance FAIL → stop immediately, no auto-fix
- Godot launch FAIL → retry once, then stop

## Systems Forbidden Before M12 Is Planned

Before M12 is approved, do not add these systems:

- Release-to-sea system
- Ocean system
- Blue Guardian expedition
- New device/equipment system
- Encyclopedia achievement system
- Complex livestock death system
- Breeding system
- Multi-page final UI art pass

## Minimal Change Principle

- Prefer the smallest change that fixes the verified problem.
- Do not refactor unrelated code while completing an audit, fix, or validation task.
- Do not change behavior merely to make code look cleaner.
- If a risk can be reported safely instead of fixed immediately, report it first.

## Code Budget

- Each task should state whether it is audit-only, data-only, script-only, or business-logic-changing.
- Keep changed files to the minimum needed for the stated task.
- New tools and reports must not alter gameplay behavior.
- Any change touching save, shop, livestock, capacity, or UI flow requires a risk report.

## UI / System / Data Boundaries

- UI files should display and route player actions, not own economy or save rules.
- System scripts should own game-state transitions and validation.
- Data files should define stable content and schema values, not runtime behavior.
- Save data must use JSON-safe values only: null, bool, number, string, Array, and Dictionary composed of JSON-safe values.
- Do not write Node, Resource, Callable, Signal, Vector2, Packed arrays, typed arrays, or engine objects into save or debug payloads.

## Debug Button Gating

- Debug buttons must be gated behind a dev/debug mode check.
- Debug buttons must not be part of the normal player path.
- Heartbeat, reset-save, manual-save, and similar diagnostics should be hidden in release builds or moved to a development panel.
- Do not delete debug controls during audit-only tasks; report and recommend handling instead.

## End-Of-Task Evidence

Every task must end with:

- Changed files
- Diff summary
- Risk report
- Whether the game runtime was started
- Whether Godot Output / Debugger was checked
- Whether manual screenshots or runtime confirmation are still required
- Use `docs/tech/FINAL_REPORT_TEMPLATE.md` for autonomous execution reports

## Visual QA Rules

- Minimum 10 visible issues per review round
- Batch submit all issues at once, never one at a time
- Each issue requires screenshot + location + description
- Use severity: BLOCKER / HIGH / MEDIUM / LOW
- See `docs/tech/VISUAL_QA_PROTOCOL.md` for full protocol

## Shared Assistant Rule

- Codex and Claude Code must follow the same rules.
- One assistant's audit is invalid if it used the wrong project directory.
- Do not use static audit findings from a non-authoritative project copy to contradict a runtime fix confirmed in the authoritative repository.
