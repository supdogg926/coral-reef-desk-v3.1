# M10 Autosave Observation Plan

Report date: 2026-06-23  
Scope: read-only autosave observation plan for M10 runtime checklist items 15 and 16.  
Restrictions: no business code changes, no Godot scene changes, no bug fixes, no commit, no push, no tag, no M11.

## Files Read

- `PROJECT_RULES.md`
- `reports/m10_runtime_regression_result.md`
- `scripts/systems/SaveSystem.gd`
- `scripts/systems/GameState.gd`
- `scenes/main/Main.gd`
- `project.godot`

## Autosave Facts

| Question | Answer | Evidence |
| --- | --- | --- |
| 自动保存触发间隔是多少秒 | 60.0 seconds | `scripts/systems/GameState.gd`: `const AUTOSAVE_INTERVAL: float = 60.0` |
| 自动保存从哪个脚本/函数触发 | `GameState.update(delta_seconds)` | `_autosave_timer += delta_seconds`; when timer reaches `AUTOSAVE_INTERVAL`, it calls `_perform_autosave()` |
| 自动保存最终调用哪个保存函数 | `SaveSystem.save_game(save_dict)` | `GameState._perform_autosave()` calls `save_system.save_game(save_dict)` |
| 保存文件路径或 `user://` 保存位置 | `user://reef_idle_v3_save.json` | `scripts/systems/SaveSystem.gd`: `const SAVE_PATH: String = "user://reef_idle_v3_save.json"` |
| 当前是否已有 autosave 输出日志 | YES | `GameState.update()` prints `[SAVE] regular autosave firing`; `_perform_autosave()` and `SaveSystem.save_game()` print detailed `[SAVE]` steps |
| 是否可以通过 Godot Output 观察自动保存 | YES | Wait for regular autosave and look for `[SAVE] regular autosave firing` followed by save completion logs |
| 是否可以通过保存文件修改时间观察自动保存 | YES | The save file is written with `FileAccess.open(SAVE_PATH, FileAccess.WRITE)` and `file.store_string(json_text)` |

## Autosave Call Chain

```text
Main._process(delta)
  -> game_state.update(delta)
    -> _autosave_timer += delta_seconds
    -> if _autosave_timer >= 60.0:
         print("[SAVE] regular autosave firing")
         _perform_autosave()
         _autosave_timer = 0.0
           -> export economy/water/time/unlocks/livestock/equipment
           -> print("[SAVE] calling save_game with keys=...")
           -> save_system.save_game(save_dict)
             -> print("[SAVE] save_game start")
             -> JSON.stringify(save_data, "\t")
             -> FileAccess.open("user://reef_idle_v3_save.json", FileAccess.WRITE)
             -> file.store_string(json_text)
             -> print("[SAVE] save_game return true")
           -> print("[SAVE] save_game returned=", ok)
```

## Save File Location

Godot path:

```text
user://reef_idle_v3_save.json
```

Project name:

```text
CoralReefIdleV3
```

Likely Windows filesystem location for Godot user data:

```text
%APPDATA%\Godot\app_userdata\CoralReefIdleV3\reef_idle_v3_save.json
```

If Godot uses a custom user-data directory on this machine, use Godot's editor/runtime path resolution for `user://`. This report did not run Godot and did not inspect the live user data folder.

## Manual Supplemental Verification For Items 15/16

Use this process to verify item 15 and item 16 without modifying code:

1. Start the project from Godot with the Output panel visible.
2. Keep the game running and responsive for at least 70 seconds after the last manual save or purchase save.
3. Watch Godot Output for this regular autosave marker:

```text
[SAVE] regular autosave firing
```

4. Confirm the autosave continues through the save chain without freeze. Useful completion markers include:

```text
[SAVE] perform_autosave start
[SAVE] calling save_game with keys=...
[SAVE] save_game start
[SAVE] file store_string done
[SAVE] save_game return true
[SAVE] save_game returned=true
```

5. While or after the autosave fires, confirm the UI still responds. For example:

- Open/close the shop.
- Open/close "我的生物".
- Confirm the window is not frozen.

6. Optional second evidence: check the modified time of the save file after the autosave fires.

Expected evidence for item 15:

- Godot Output contains `[SAVE] regular autosave firing`, or the save file modified time advances after waiting at least 60 seconds.

Expected evidence for item 16:

- After the autosave log/file timestamp change, the page remains responsive and Godot Output / Debugger shows no red error.

## How To Update `reports/m10_runtime_regression_result.md`

Only update items 15 and 16 after user-confirmed runtime evidence:

| # | Current | Can become PASS when |
| --- | --- | --- |
| 15 | `NOT_TESTED` | User confirms regular autosave was observed through Output log or save-file modified time. |
| 16 | `NOT_TESTED` | User confirms the game remained responsive after the observed autosave and no red Output / Debugger error appeared. |

Recommended evidence text:

```text
User verbal confirmation: after waiting 70 seconds, Godot Output showed "[SAVE] regular autosave firing" and "[SAVE] save_game returned=true".
```

If file timestamp is used:

```text
User verbal confirmation: save file modified time advanced after waiting 70 seconds; game remained responsive.
```

Do not mark item 15 or 16 as `PASS` from static code review alone.

## Need Code Changes?

Current answer: NO, code changes are not required to observe autosave.

Reason:

- Regular autosave already prints a clear start marker.
- The save chain already prints detailed `[SAVE]` logs.
- The save file path is fixed and can be checked by modified time.

Optional future improvement, not part of this task:

- Add a dev-only visible autosave timestamp in the debug panel.
- Add a dev-only explicit label for last autosave result.

These are suggestions only. No code was modified by this report.

## Current Gate

- 自动保存是否具备可观察验证路径: YES
- 建议用户等待多少秒: at least 70 seconds after the last manual save or purchase save
- 需要观察哪些证据: Godot Output `[SAVE] regular autosave firing` and completion logs, or save-file modified time plus UI responsiveness
- 当前是否允许把第15/16项改为 PASS: NO, not until the user performs and confirms the supplemental runtime observation
- Allow commit: NO
- Allow tag: NO
- Allow next milestone: NO
