# M11 Maintenance Button State And Balance Report

Report date: 2026-06-23
Branch: `prototype/m11-biomanage-vertical-slice`
Scope: small UX/visibility fix for the maintenance cost/cooldown MVP.

## User Feedback

- Cost and cooldown logic basically worked in manual testing.
- Cooldown should be visible on the button itself.
- Cooldown buttons should turn grey and be unclickable.
- The current RP balance was not obvious.
- The flow felt like maintenance could be clicked indefinitely.

## Fix Summary

- `Main.gd` now stores runtime maintenance button references by `action_id`.
- Maintenance buttons refresh every 0.5 seconds.
- Cooldown buttons are disabled and show countdown text, for example `换水 20RP（8s）`.
- Buttons recover automatically when cooldown ends.
- If not cooling down but RP is insufficient, buttons are disabled and show `余额不足`.
- `GameState` now exposes read-only maintenance action state queries:
  - cost
  - cooldown
  - remaining cooldown
  - can_execute
  - reason
  - current balance
- Successful maintenance feedback includes cost and current balance.
- StatusPanel resource line now clearly shows RP balance.

## Button Cooldown State

- Cooldown priority is higher than insufficient funds.
- Cooldown display: disabled button with remaining seconds.
- Insufficient funds display: disabled button with `余额不足`.
- Normal display: action name plus RP cost.

## RP Balance Display

- RP is visible in StatusPanel under the livestock/economy section:
  - `资源：RP ...｜收益 .../h｜容量 .../...`
- Recent maintenance feedback also shows successful spend and resulting balance.

## Spend Verification

- Successful maintenance spends the configured RP cost exactly once.
- Immediate repeat while cooling down does not spend RP again.
- Immediate repeat while cooling down does not change water chemistry again.
- Insufficient RP does not change water chemistry.
- Insufficient RP does not make balance negative.
- Insufficient RP does not start cooldown.

## Modified Files

- `scripts/systems/GameState.gd`
- `scenes/main/Main.gd`
- `scenes/ui/StatusPanel.gd`
- `tests/m11_water_maintenance_smoke_test.gd`
- `reports/m11_maintenance_button_state_and_balance_report.md`

## Test Results

- `res://tests/m11_water_maintenance_smoke_test.gd`: PASS.
- Godot 4.7 headless main scene startup with `--quit-after 3`: no red errors printed.
- `git diff --check`: PASS, only line-ending warnings were printed.

## Manual Acceptance Checklist

- Confirm maintenance buttons show RP costs.
- Confirm successful click reduces visible RP.
- Confirm successful click changes the clicked button to a grey cooldown countdown.
- Confirm cooldown countdown reaches 0 and button becomes clickable again.
- Confirm insufficient RP shows `余额不足`.
- Confirm insufficient RP does not change water values.
- Confirm `生物商店` and `我的生物` still open normally.
- Confirm dev manual-save/reset controls are not pushed out of the bar at 1280x720.
- Confirm Output / Debugger has no red errors.

## Explicit Non-Changes

- `SaveSystem.gd` was not modified.
- `data/*` was not modified.
- `.tscn` scene files were not modified.
- `project.godot` was not modified.
- No main branch merge or tag operation was performed.

## Formal M11 Recommendation

Keep the button-state pattern for formal M11. Revisit final visual layout and economy balance before milestone lock.
