# M19-H1 Deterministic Persistence Foundation — Closeout Report

**Date**: 2026-07-12
**Worktree**: CoralReefIdleV3_M19_H1
**Branch**: hotfix/m19-deterministic-persistence-foundation

## Commit History

| Role | Commit | Description |
|------|--------|-------------|
| Implementation | 579f1ea | Initial atomic save, WallClockService, blue guardian fields, SeedMixer |
| Verified | aef797a | Fault matrix + recovery tests verified, rename fix, FINAL_VALIDATE recovery |
| Closeout candidate | b1324f4 | Save result propagation fix (_perform_autosave → bool) |

## Premature Tag

```
PREMATURE_CANDIDATE_TAG=v4.0-m19-deterministic-persistence-foundation
PREMATURE_TAG_TARGET=579f1ea
PREMATURE_TAG_ACCEPTED_AS_FINAL=NO
```

This tag was created before full verification. It must not be deleted, moved, or force-pushed.

## Delivered Components

### SaveSystem (scripts/systems/SaveSystem.gd)
- Atomic write: temp file → flush → validate → replace final
- Backup recovery: final corrupt → restore from bak
- Fault injection API: 5 fault points (TEMP_OPEN, TEMP_WRITE, TEMP_VALIDATE, BACKUP_OR_REPLACE, FINAL_VALIDATE)
- Test path isolation: set_test_save_root() for isolated test directories
- Blue guardian state migration: _make_blue_guardian_defaults, _migrate_blue_guardian_state
- save_seed type fix: accepts int or float after JSON roundtrip

### WallClockService (scripts/systems/WallClockService.gd)
- now_unix() with test override
- set_test_override / advance_test_override / clear_test_override
- Business wall clock calls converged (cooldown get_ticks_msec exempt as performance timing)

### SeedMixer (scripts/systems/SeedMixer.gd)
- GOLDEN_GAMMA_I64 = -7046029254386353131
- stable_mix() using splitmix64-style construction
- voyage_seed(save_seed, voyage_sequence) = save_seed XOR stable_mix(sequence)
- 7 known vectors with fixed expected values

### GameState (scripts/systems/GameState.gd)
- wall_clock_service field + initialization
- blue_guardian_state field + persistence
- commit_current_state() → delegates to _perform_autosave()
- _perform_autosave() returns bool (was void)
- capture_mutable_state / restore_mutable_state for transaction rollback
- Save result propagated to callers

### H1 Test Suite (tests/m19_h1/)
- m19_h1_atomic_save_test.gd: 7 test functions
  - Atomic save success (save → reload → verify)
  - Fault matrix (5 fault points, each verifies old save preserved)
  - Recovery matrix (7 scenarios: A-G)
  - 10 consecutive save roundtrips
  - Save seed stability across reloads
  - WallClock override/advance/clear
  - SeedMixer known vectors

## Test Results

### H1 Core Tests: ALL PASS
```
ATOMIC_SAVE_SUCCESS=PASS
ATOMIC_SAVE_FAILURE_MATRIX=PASS (5/5 faults)
SAVE_RECOVERY_MATRIX=PASS (7/7 scenarios)
CONSECUTIVE_10_SAVES=PASS
SAVE_SEED_STABLE_AFTER_RELOAD=PASS
WALLCLOCK_OVERRIDE=PASS
KNOWN_VECTOR_TEST_RESULT=PASS (7/7)
```

### Legacy Regression: PENDING
Test files exist in tests/ directory (m11_*.gd through m19_t0_save_acceptance.gd).
Runner method confirmed: `godot --headless --path . -- <script>.gd`
Tests are long-running (30-day simulations, 2+ min each).
Not yet batched and executed.

### GUI Verification: PENDING
- F5 save-restart-restore: Not done (requires interactive Godot)
- Save feedback propagation: Code fixed, UI behavior not visually verified

## Codex Review Summary

| Item | Status |
|------|--------|
| temp write doesn't truncate final | PASS — writes to .tmp, validates, then renames |
| fault injection default off | PASS — _test_fault_points empty by default |
| fault not serialized | PASS — _test_fault_points is runtime-only, starts with {} |
| test path isolation | PASS — set_test_save_root uses user://m19_h1_test_save/ |
| backup recovery priority | PASS — final > bak > empty |
| rename failure preserves final | PASS — bak rename before final rename, restore on failure |
| FINAL_VALIDATE recovery | PASS — restores from bak on validation failure |
| save_seed stable | PASS — not regenerated if already non-zero |
| int/float type guard | PASS — accepts both after JSON roundtrip |
| commit_current_state propagates | PASS — returns bool from _perform_autosave |
| no blue guardian gameplay | PASS — fields are placeholder only |
| no M19-T2 UI | PASS — zero UI changes |
| known vectors lock behavior | PASS — 7 vectors with fixed expected values |
| cooldown exemption valid | PASS — get_ticks_msec for cooldown timing only |

## Status

```
M19_H1_STATUS=OPEN (regression + GUI pending)
M19_T2_STATUS=BLOCKED
M19_T3_STATUS=NOT_AUTHORIZED
```
