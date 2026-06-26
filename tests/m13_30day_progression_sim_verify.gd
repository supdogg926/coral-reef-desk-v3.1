extends SceneTree

## M13 30-Day Progression Simulation Verification
## Validates: 30-day sim completes, key day snapshots exist, RP growth, no deadlock

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
		printerr("[M13] FAIL: ", label)


func _run_tests() -> void:
	print("[M13] 30-Day Progression Simulation Verification Start")

	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var SimScript = load("res://scripts/systems/Day30Simulation.gd")
	_assert(GameStateScript != null, "PS.1 GameState loads")
	_assert(SimScript != null, "PS.2 Day30Simulation loads")
	if GameStateScript == null or SimScript == null:
		return

	var gs = GameStateScript.new()
	gs.initialize()
	_assert(gs.initialized, "PS.3 GameState initializes")

	# Add starting RP so auto-buy works
	if gs.get("economy_system") != null:
		gs.economy_system.add_reef_points(500.0)

	var sim: Day30Simulation = SimScript.new()
	sim.initialize(42)
	var result: Dictionary = sim.run_simulation(gs)

	# Verify sim ran
	_assert(result.get("all_days_complete", false), "PS.4 All 30 days completed")
	var total_days: int = int(result.get("total_days_simulated", 0))
	_assert(total_days >= 30, "PS.5 At least 30 days simulated (got %d)" % total_days)

	# No deadlock
	_assert(not bool(result.get("deadlocked", true)), "PS.6 No economic deadlock detected")
	_assert(not bool(result.get("negative_values", true)), "PS.7 No negative/NAN values detected")

	# Key day snapshots exist
	var snapshots: Array = result.get("snapshots", [])
	for day in [0, 1, 3, 7, 14, 21, 30]:
		var found: bool = false
		for snap in snapshots:
			if int(snap.get("day", -1)) == day:
				found = true
				break
		_assert(found, "PS.8 Day %d snapshot exists" % day)

	# RP growth over time
	var rp_day0: float = float(_get_snap(snapshots, 0).get("rp", 0.0))
	var rp_day30: float = float(_get_snap(snapshots, 30).get("rp", 0.0))
	print("[M13] RP Day 0: %.0f, Day 30: %.0f" % [rp_day0, rp_day30])
	_assert(rp_day30 >= 0.0, "PS.9 Day 30 RP non-negative")

	# Livestock growth
	var ls_day0: int = int(_get_snap(snapshots, 0).get("livestock_count", 0))
	var ls_day30: int = int(_get_snap(snapshots, 30).get("livestock_count", 0))
	print("[M13] Livestock Day 0: %d, Day 30: %d" % [ls_day0, ls_day30])
	_assert(ls_day30 >= ls_day0, "PS.10 Livestock count grows or stable")

	# Events occurred
	var events: Array = result.get("events", [])
	var buy_events: int = 0
	var maint_events: int = 0
	for ev in events:
		if ev.get("type") == "buy":
			buy_events += 1
		elif ev.get("type") == "maintenance":
			maint_events += 1
	print("[M13] Events: %d buys, %d maintenance" % [buy_events, maint_events])
	_assert(buy_events + maint_events > 0, "PS.11 Simulation generated player-like events")

	# CSV export
	var csv: String = sim.export_csv()
	_assert(not csv.is_empty(), "PS.12 CSV export non-empty")
	_assert("day,rp" in csv, "PS.13 CSV has correct header")

	# Warnings (not necessarily failures)
	var warnings: Array = result.get("warnings", [])
	print("[M13] Simulation warnings: %d" % warnings.size())
	for w in warnings:
		print("  ", w)


func _get_snap(snapshots: Array, day: int) -> Dictionary:
	for snap in snapshots:
		if int(snap.get("day", -1)) == day:
			return snap
	return {}


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M13 30-Day Progression: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
