# Godot Crash Root Cause Analysis

Generated: 2026-06-23
Mode: read-only analysis, except this report file.

## 1. 摘要结论

当前最可能原因是 Godot 4.7 / Windows / GPU-driver / Vulkan-shader-cache / process-environment 层的进程级崩溃，而不是普通 GDScript Output 错误；但在没有 main/M10 对照运行前，不能排除 prototype UI 路径触发 Godot 引擎级崩溃。

## 2. 证据

### Preflight

```text
pwd:
C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3

git rev-parse --show-toplevel:
C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3

git branch --show-current:
prototype/m11-biomanage-vertical-slice

git status --short:
 M scenes/ui/LivestockPanel.gd
 M scripts/systems/GameState.gd
 M scripts/systems/LivestockSystem.gd
?? reports/godot_crash_triage_20260623_174619.md
?? reports/godot_crash_triage_complete_20260623_174731.md
?? reports/m11_prototype_acceptance_checklist.md
?? reports/m11_prototype_implementation_report.md

git log -5 --oneline:
767c39b docs: add M11 planning baseline
c71bb8f docs: archive M10 release documentation
1a4c334 chore: finalize M10 livestock core regression baseline
22d94a6 fix: M10.12 replace typed array assignment with manual String cast in SaveSystem
5826fd3 fix: M10.11 autosave interval 60s, re-entry guard, per-step logging, manual save button

git tag --list "v3.1-m10-livestock-core":
v3.1-m10-livestock-core
```

### Application / System Events

- `reports/godot_crash_triage_complete_20260623_174731.md` reports: `No matching Application events found in the last 6 hours`.
- The first triage report has empty Application/System event sections because its pipeline output was not captured into the Markdown file.
- A wider 24-hour Application log query found Windows Error Reporting kernel events, including `LiveKernelEvent`, `BlueScreen`, `WATCHDOG`, and `AppTermFailureEvent`, but did not find a clear `Godot_v4.7-stable_win64.exe` AppCrash record with faulting module / exception code.
- WER ReportArchive / ReportQueue search did not find a Godot-specific AppCrash entry. It found many unrelated `AppCrash_*` folders for other applications.
- System log keyword query found one relevant hardware warning:
  - Time: `2026/6/23 17:46:51`
  - Provider: `Microsoft-Windows-WHEA-Logger`
  - Event ID: `17`
  - Message: corrected hardware error
  - Component: `PCI Express Root Port`
  - Error source: `Advanced Error Reporting (PCI Express)`
- System log keyword query did not surface `Display`, `nvlddmkm`, Vulkan, OpenGL, disk, or memory errors directly tied to the Godot crash window.

### Missing Crash Fields

The available reports do not contain these fields:

- faulting application: not captured
- faulting module: not captured
- exception code: not captured
- fault offset: not captured

User-observed Windows popup:

```text
指令引用了 0x0000000000000058 内存，该内存不能为 read
```

This indicates a native process memory-access fault, not a normal GDScript exception.

### Godot User Data / Logs / Cache

Relevant paths found:

```text
C:\Users\admin\AppData\Roaming\Godot
C:\Users\admin\AppData\Roaming\Godot\app_userdata
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan
C:\Users\admin\AppData\Local\Godot
```

Recent Godot logs:

```text
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot.log
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.43.07.log
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.42.51.log
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.08.17.log
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T15.44.50.log
```

Recent save:

```text
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\reef_idle_v3_save.json
```

Log observations:

- `godot2026-06-23T17.42.51.log` contains `Vulkan 1.4.329 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 5060 Ti`.
- Recent `godot.log` tail shows heartbeat ticks and autosave success.
- Recent logs did not show `SCRIPT ERROR`, `ERROR`, `Invalid`, `Crash`, `Failed`, `nvlddmkm`, or M11 prototype failure lines in the searched segments.
- Earlier restricted headless run failed while opening `user://logs/godot...log` and produced a native crash backtrace, but elevated headless runs completed. That points toward environment / permission / log-path sensitivity, not necessarily project script behavior.

## 3. 当前 prototype diff 风险点

`git diff --stat`:

```text
 scenes/ui/LivestockPanel.gd        | 213 +++++++++++++++++++++++++++++++++++++
 scripts/systems/GameState.gd       |  33 ++++++
 scripts/systems/LivestockSystem.gd |  35 ++++++
 3 files changed, 281 insertions(+)
```

`git diff --name-status`:

```text
M	scenes/ui/LivestockPanel.gd
M	scripts/systems/GameState.gd
M	scripts/systems/LivestockSystem.gd
```

File-by-file risk:

- `scenes/main/Main.gd`: no diff. Low likelihood as new cause.
- `scripts/systems/SaveSystem.gd`: no diff. Low likelihood as new cause.
- `data`: no diff. Low likelihood as new cause.
- `reports`: tracked diff is empty; untracked analysis/prototype reports exist. Not runtime-relevant.
- `scripts/systems/LivestockSystem.gd`: adds `get_livestock_snapshot()` and `release_livestock()`. Logic is dictionary/array removal and recalculation. It can cause gameplay state bugs if used incorrectly, but it is not a likely direct source of a native Godot process crash.
- `scripts/systems/GameState.gd`: adds release orchestration and a delayed autosave flag. It calls existing save code. It is not a likely direct source of a native process crash, unless repeated autosave or state mutation correlates with the user action in runtime.
- `scenes/ui/LivestockPanel.gd`: highest prototype-code risk because it adds dynamic buttons, signal connections, `queue_free()` list rebuilds, and `Tween` animations. Possible script-level risks include duplicate signal connections during rebuild, queued UI node cleanup timing, and tweening a node that may later be hidden or freed. These are still more likely to create GDScript errors than a Windows process memory fault.

Risk patterns explicitly checked:

- No scene file was modified.
- No data file was modified.
- No SaveSystem change was made.
- No obvious array index access was added.
- Null checks exist before most UI node access.
- There is dynamic UI and signal creation inside rebuilt rows, so manual UI reproduction is still required.

## 4. 可能性排序

### A. Godot / Windows / GPU / driver / shader cache layer

Probability: highest.

Evidence:

- User saw a Windows application memory-read fault, not a Godot Output script error.
- The observed address `0x0000000000000058` is a native null-near pointer style fault.
- Recent Godot logs do not show script errors around the captured runtime.
- A restricted headless run crashed while opening `user://logs/...`; elevated headless runs completed afterward.
- Godot user data includes Vulkan and shader cache directories.
- Runtime uses Vulkan Forward+ on `NVIDIA GeForce RTX 5060 Ti`.
- System log shows a WHEA corrected PCI Express Root Port hardware event near the triage window.

Counter-evidence:

- No direct `Display`, `nvlddmkm`, Vulkan, OpenGL, or Godot AppCrash event was captured.
- No faulting module / exception code / fault offset was captured.

### B. M11 prototype project code triggered a Godot crash

Probability: medium-low until reproduced.

Evidence:

- Current branch has uncommitted prototype UI/system changes.
- `LivestockPanel.gd` adds dynamic row buttons, signal connections, tweens, and list rebuilds.
- If the crash happens only after selecting/releasing in this branch, prototype code becomes a stronger suspect.

Counter-evidence:

- Headless startup and short runtime completed after permission escalation.
- Recent Godot logs show heartbeat and save success, not script errors.
- Modified logic is high-level GDScript and would normally report script errors before causing a native process crash.
- No Godot scene or resource import files were changed.

### C. Resource / cache / import issue

Probability: medium.

Evidence:

- Godot user data has shader cache and Vulkan pipeline cache.
- Crashes can occur in renderer/cache paths without clean GDScript Output errors.
- Log file write/cache behavior was involved in the restricted headless crash.

Counter-evidence:

- No `.godot`, `.import`, `.tscn`, shader, or asset diff exists in the repo.
- No import-cache or scene-import error was captured in logs.
- No cleanup has been performed, so this remains an untested hypothesis.

## 5. 建议的下一步

Only read-only or low-risk diagnostic steps are recommended:

1. In the current prototype branch, record the exact crash reproduction path: editor launch, project run, button clicked, elapsed time, and whether the popup appears before or after entering gameplay.
2. Do not commit prototype changes before root cause isolation.
3. Use a clean comparison run on `main` or the M10 tag `v3.1-m10-livestock-core` to verify whether Godot itself is stable without prototype changes.
4. If `main` / M10 does not crash, return to the prototype branch and isolate the trigger point by manual steps: open project, run scene, open `我的生物`, select, open confirmation, cancel, confirm release.
5. If `main` / M10 also crashes, prioritize Godot / GPU driver / Vulkan shader cache / environment triage before any code work.
6. Before deleting caches, first archive or list the current Godot user data paths and logs. Cache deletion should be a separate authorized action, not part of this read-only analysis.
7. Consider a controlled run using another renderer / Godot executable only after the main-vs-prototype comparison is recorded.
8. Check NVIDIA driver health/version and Windows reliability history if crashes continue.

Stop line:

- Current BLOCKED: YES
- Allow continued M11 prototype development: NO
- Allow prototype commit: NO
- Need clean main or M10 tag comparison test first: YES
- Recommend clearing Godot cache now: YES, but only after user authorizes a separate cache-cleaning step and after backing up/listing logs
- Recommend changing Godot version or re-downloading Godot: YES, if main/M10 also crashes or if cache/driver checks do not stabilize it
- Recommend checking graphics driver: YES

Do not:

- Do not modify business code.
- Do not modify Godot scene files.
- Do not delete caches in this task.
- Do not checkout, reset, commit, push, tag, or merge in this task.
- Do not continue M11 development until comparison testing identifies whether the crash follows the prototype branch.
