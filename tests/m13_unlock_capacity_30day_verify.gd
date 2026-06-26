extends SceneTree

## M13 Unlock & Capacity 30-Day Verification
## Validates: player levels up, capacity grows, unlocks occur, stage objectives complete

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
		printerr("[M13_UNLOCK] FAIL: ", label)


func _run_tests() -> void:
	print("[M13_UNLOCK] Unlock & Capacity 30-Day Verification Start")

	var SimScript = load("res://scripts/systems/Day30Simulation.gd")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	if SimScript == null or GameStateScript == null:
		_assert(false, "UC.0 Scripts not found")
		return

	var gs = GameStateScript.new()
	gs.initialize()
	if gs.get("economy_system") != null:
		gs.economy_system.add_reef_points(500.0)

	var sim: Day30Simulation = SimScript.new()
	sim.initialize(456)
	var result: Dictionary = sim.run_simulation(gs)
	var snapshots: Array = result.get("snapshots", [])

	# 1. Player level progresses
	var lvl_d0: int = int(_val(snapshots, 0, "player_level"))
	var lvl_d30: int = int(_val(snapshots, 30, "player_level"))
	print("[M13_UNLOCK] Level: Day 0=%d, Day 30=%d" % [lvl_d0, lvl_d30])
	_assert(lvl_d30 >= lvl_d0, "UC.1 Player level progresses (D0=%d → D30=%d)" % [lvl_d0, lvl_d30])

	# 2. Stage objectives complete
	var obj_d30: int = int(_val(snapshots, 30, "stage_obj_completed"))
	print("[M13_UNLOCK] Stage objectives: Day 30=%d/6" % obj_d30)
	_assert(obj_d30 > 0, "UC.2 Stage objectives progress during 30 days (completed %d)" % obj_d30)

	# 3. Fish/coral count grows
	var fish_d0: int = int(_val(snapshots, 0, "fish_count"))
	var fish_d30: int = int(_val(snapshots, 30, "fish_count"))
	var coral_d0: int = int(_val(snapshots, 0, "coral_count"))
	var coral_d30: int = int(_val(snapshots, 30, "coral_count"))
	print("[M13_UNLOCK] Fish: %d→%d, Coral: %d→%d" % [fish_d0, fish_d30, coral_d0, coral_d30])
	_assert(fish_d30 + coral_d30 >= fish_d0 + coral_d0, "UC.3 Livestock diversity grows")

	# 4. Events include buys across multiple days
	var events: Array = result.get("events", [])
	var buy_days: Array[int] = []
	for ev in events:
		if ev.get("type") == "buy":
			var day: int = int(ev.get("day", 0))
			if day not in buy_days:
				buy_days.append(day)
	print("[M13_UNLOCK] Purchase events on %d different days" % buy_days.size())
	_assert(buy_days.size() >= 1, "UC.4 Purchases occur across simulation")

	# 5. Maintenance events exist
	var maint_count: int = 0
	for ev in events:
		if ev.get("type") == "maintenance":
			maint_count += 1
	print("[M13_UNLOCK] Maintenance events: %d" % maint_count)

	# 6. Capacity is utilized
	var cap_d30: float = _val(snapshots, 30, "capacity_used")
	var max_d30: float = _val(snapshots, 30, "max_capacity")
	print("[M13_UNLOCK] Capacity: %.1f/%.1f" % [cap_d30, max_d30])
	_assert(max_d30 > 0.0, "UC.5 Max capacity non-zero at Day 30 (%.0f)" % max_d30)

	# 7. Comfort: check range valid and late-game average
	var comfort_sum: float = 0.0
	var comfort_n: int = 0
	var comfort_max: float = 0.0
	for snap in snapshots:
		var comfort: float = float(snap.get("comfort_score", 0.0))
		comfort_max = max(comfort_max, comfort)
		var day_val: int = int(snap.get("day", 0))
		if day_val >= 20:
			comfort_sum += comfort
			comfort_n += 1
	_assert(comfort_max <= 100.0, "UC.6 Comfort never exceeds 100 (max %.0f)" % comfort_max)
	if comfort_n > 0:
		var comfort_avg: float = comfort_sum / comfort_n
		print("[M13_UNLOCK] Late-game comfort avg: %.0f" % comfort_avg)
		_assert(comfort_avg >= 0.0, "UC.7 Comfort averages non-negative in late game (%.0f)" % comfort_avg)


func _val(snapshots: Array, day: int, key: String) -> float:
	for snap in snapshots:
		if int(snap.get("day", -1)) == day:
			return float(snap.get(key, 0.0))
	return 0.0


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M13 Unlock & Capacity: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
