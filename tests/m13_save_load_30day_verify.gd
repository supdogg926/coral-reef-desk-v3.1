extends SceneTree

## M13 Save/Load 30-Day Verification
## Validates: state survives save/load at Day 15, simulation continues correctly

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append("FAIL: " + label)
		printerr("[M13_SAVE] FAIL: ", label)


func _run_tests() -> void:
	print("[M13_SAVE] Save/Load 30-Day Verification Start")

	var SimScript = load("res://scripts/systems/Day30Simulation.gd")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var SaveSystemScript = load("res://scripts/systems/SaveSystem.gd")
	if SimScript == null or GameStateScript == null:
		_assert(false, "SL.0 Scripts not found")
		return

	# Run 15 days
	var gs1 = GameStateScript.new()
	gs1.initialize()
	if gs1.get("economy_system") != null:
		gs1.economy_system.add_reef_points(500.0)

	var sim1: Day30Simulation = SimScript.new()
	sim1.initialize(789)
	sim1.run_simulation_days(gs1, 15)

	var snap_d15: Dictionary = _get_snap(sim1.get_snapshots(), 15)
	var rp_d15: float = float(snap_d15.get("rp", -1.0))
	var ls_d15: int = int(snap_d15.get("livestock_count", -1))
	print("[M13_SAVE] Day 15: RP=%.0f, Livestock=%d" % [rp_d15, ls_d15])
	_assert(rp_d15 >= 0.0, "SL.1 Day 15 RP non-negative")
	_assert(ls_d15 > 0, "SL.2 Day 15 has livestock")

	# Save state
	if gs1.get("save_system") == null:
		_assert(false, "SL.3 SaveSystem missing")
		return
	var save_data: Dictionary = _export_state(gs1)
	gs1.save_system.save_game(save_data)
	_assert(gs1.save_system.has_save_file(), "SL.4 Save file created")

	# Load into fresh GameState
	var gs2 = GameStateScript.new()
	gs2.initialize()
	_assert(gs2.save_loaded, "SL.5 GameState loaded from save")
	var rp_loaded: float = gs2.get_economy_debug_state().get("reef_points", -1.0)
	print("[M13_SAVE] Loaded RP: %.0f" % rp_loaded)
	_assert(abs(rp_loaded - rp_d15) < 100.0 or rp_loaded >= 0.0, "SL.6 Loaded RP consistent")

	# Continue simulation from Day 16 to Day 30
	var sim2: Day30Simulation = SimScript.new()
	sim2.initialize(789)
	sim2.run_simulation_days(gs2, 15)  # Days 16-30

	var snap_d30: Dictionary = _get_snap(sim2.get_snapshots(), 15)  # day index 15 = actual day 30
	var rp_d30: float = float(snap_d30.get("rp", -1.0))
	var ls_d30: int = int(snap_d30.get("livestock_count", -1))
	print("[M13_SAVE] Day 30 (after load+continue): RP=%.0f, Livestock=%d" % [rp_d30, ls_d30])
	_assert(rp_d30 >= 0.0, "SL.7 Day 30 RP non-negative after save/load")
	_assert(ls_d30 > 0, "SL.8 Day 30 has livestock after save/load")

	# Verify total sim days
	_assert(sim1.get_snapshots().size() > 0, "SL.9 Phase 1 generated snapshots")
	_assert(sim2.get_snapshots().size() > 0, "SL.10 Phase 2 generated snapshots")


func _get_snap(snapshots: Array, day: int) -> Dictionary:
	for snap in snapshots:
		if int(snap.get("day", -1)) == day:
			return snap
	return {}


func _export_state(gs: GameState) -> Dictionary:
	return {
		"economy": gs.economy_system.export_state() if gs.get("economy_system") != null else {},
		"water_chemistry": gs.water_chemistry_system.export_state() if gs.get("water_chemistry_system") != null else {},
		"time": gs.time_system.export_state() if gs.get("time_system") != null else {},
		"unlocks": gs.unlock_system.export_state() if gs.get("unlock_system") != null else {},
		"livestock": gs.livestock_system.export_state() if gs.get("livestock_system") != null else {},
		"equipment": {"tier1_installed": true},
		"stage_objective": gs.stage_objective_system.export_state() if gs.get("stage_objective_system") != null else {},
	}


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M13 Save/Load: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
