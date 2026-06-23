# Godot Crash Contrast Test

Generated: 2026-06-23 18:17:07

## Purpose

Compare current M11 prototype crash behavior against a clean M10 tag baseline without touching the current prototype working tree.

## Safety Rules

- Do not modify prototype code
- Do not commit main
- Do not push main
- Do not tag
- Do not reset
- Do not checkout the current working tree
- Use a separate git worktree for M10 baseline

## Current Prototype Git State

```text
repo: C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3
branch: prototype/m11-biomanage-vertical-slice
head: 767c39b docs: add M11 planning baseline
tag present: v3.1-m10-livestock-core
```

## M10 Tag Verification

```text
tag object: f27be3f4721a5490233bf3977e5c0d5443a31756
peeled commit: 1a4c334eb67090d2df66039bb519876376506e0e
```

## Baseline Worktree

```text
path: C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M10_CrashCheck_20260623_181707
head: 1a4c334 chore: finalize M10 livestock core regression baseline
commit: 1a4c334eb67090d2df66039bb519876376506e0e
```

## Manual Result

Manual crash result was not recorded in this file before the task changed direction.
The baseline worktree was created for contrast testing and the current prototype working tree was not checked out or reset.
