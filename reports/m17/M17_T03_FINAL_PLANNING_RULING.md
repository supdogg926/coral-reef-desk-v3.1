# M17-T03 Final Planning Ruling

**Generated**: 2026-07-11T18:32:51.478778+08:00
**Baseline**: v3.5-m17-t02-final (607f5aa)
**Worktree**: CoralReefIdleV3_M17_T03
**Branch**: prototype/m17-t03

---

## 1. Facts

- Old T03 scope: 16 items defined in M17 planning freeze
- Completed in T01: 1 item (bag draw algorithm)
- Completed in T02: 14 items (pool, assets, manifest, dock, codex, regression, Codex, tag)
- Not started: 1 item (FlowContainer UI upgrade)

## 2. The One Remaining Gap

**FlowContainer upgrade for LivestockPanel codex cards**

- Current state: HBoxContainer with 72px cards, 86px min width, 6px gap
- At 9 species: ~828px total width fits comfortably in 1280px viewport (65% usage)
- Not a functional blocker: cards display correctly, no overflow, no clipping
- Old plan said: "6 species no change; 9 species upgrade to FlowContainer"
- Reality: HBoxContainer works fine at 9 species

**Verdict**: This is a NICE-TO-HAVE, not a blocking gap. The codex is functional.
FlowContainer upgrade should be deferred to maintenance (when pool exceeds HBoxContainer capacity).

## 3. Options

### Option A: Cancel T03, Direct M17 Closeout (RECOMMENDED)

- 15/16 legacy scope items complete (1 T01 + 14 T02)
- The 1 remaining item is non-blocking (HBoxContainer works)
- T02 final tag v3.5-m17-t02-final already serves as M17 milestone marker
- No M17-scope functional gaps exist

**Action**: Keep T03 worktree for future maintenance. M17 is effectively closed.
No new T03 milestone needed. Future FlowContainer work is a maintenance task.

### Option B: Minimal T03 (FlowContainer Only)

- Single target: upgrade LivestockPanel codex from HBoxContainer to FlowContainer
- ~5 lines changed in LivestockPanel.gd
- Risk: changes Godot node type, requires regression
- Benefit: automatic wrapping if pool ever exceeds 9
- Not justified by current pool size

### Option C: Evidence-only T03

- Add runtime screenshots to evidence directory
- No code changes
- Pure documentation
- Already partially done (contact sheets exist; game launched for UI review)

## 4. Fable5 Review

FABLE5_REVIEW_RESULT=PASS
FABLE5_RECOMMENDED_OPTION=A
FABLE5_BLOCKING_CONCERNS=None
FABLE5_NON_BLOCKING_NOTES=FlowContainer is a maintenance task, not a milestone. M17 is effectively complete. T03 worktree can be preserved for future use but no new milestone is needed.

## 5. Selected Option: A

**M17-T03 is cancelled. M17 proceeds directly to closeout.**

Reasoning:
1. 15 of 16 old T03 scope items were absorbed into T02
2. The 1 remaining item (FlowContainer) is non-blocking and better handled as maintenance
3. v3.5-m17-t02-final is the de facto M17 final tag
4. Creating a T03 for FlowContainer alone would be ceremony without substance
5. The T03 worktree and branch are preserved for future maintenance

## 6. M17 Closeout Actions

1. Keep T03 worktree and branch (prototype/m17-t03) for future maintenance
2. No M17-T03 milestone tag needed
3. v3.5-m17-t02-final serves as the M17 completion marker
4. Future FlowContainer work: maintenance task, not M17-T03

## 7. Gates

| Gate | Status |
|------|--------|
| M17_T03_DEVELOPMENT_ALLOWED | NO |
| M17_T03_COMMIT_ALLOWED | NO |
| M17_T03_PUSH_ALLOWED | NO |
| M17_CLOSEOUT_ALLOWED | YES |
| NEXT_TASK | M17 Closeout Report |

---

**M17 development is complete. Proceed to M17 Closeout.**
