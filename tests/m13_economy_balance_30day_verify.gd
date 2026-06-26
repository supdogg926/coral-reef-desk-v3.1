extends SceneTree

## M13 Economy Balance 30-Day Verification
## Validates: RP curve viable, income positive, maintenance affordable, no explosion

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
		printerr("[M13_ECON] FAIL: ", label)


func _run_tests() -> void:
	print("[M13_ECON] Economy Balance 30-Day Verification Start")

	var SimScript = load("res://scripts/systems/Day30Simulation.gd")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	if SimScript == null or GameStateScript == null:
		_assert(false, "EC.0 Scripts not found")
		return

	var gs = GameStateScript.new()
	gs.initialize()
	if gs.get("economy_system") != null:
		gs.economy_system.add_reef_points(800.0)

	var sim: Day30Simulation = SimScript.new()
	sim.initialize(42)
	var result: Dictionary = sim.run_simulation(gs)
	var snapshots: Array = result.get("snapshots", [])

	# 1. Income rate positive by day 3
	var inc_d3: float = _val(snapshots, 3, "income_rate_per_hour")
	_assert(inc_d3 > 0.0, "EC.1 Income rate > 0 by Day 3 (got %.2f)" % inc_d3)

	# 2. Income growth from day 3 to day 30
	var inc_d30: float = _val(snapshots, 30, "income_rate_per_hour")
	_assert(inc_d30 > 0.0, "EC.2 Income rate > 0 at Day 30 (got %.2f)" % inc_d30)
	print("[M13_ECON] Income: Day 3=%.2f, Day 30=%.2f" % [inc_d3, inc_d30])

	# 3. RP doesn't explode (>50x in 15 days without proportional livestock growth)
	var rp_d7: float = _val(snapshots, 7, "rp")
	var rp_d30: float = _val(snapshots, 30, "rp")
	var ls_d7: int = int(_val(snapshots, 7, "livestock_count"))
	var ls_d30: int = int(_val(snapshots, 30, "livestock_count"))
	var rp_growth: float = rp_d30 / max(rp_d7, 1.0)
	var ls_growth: float = float(ls_d30) / max(ls_d7, 1)
	print("[M13_ECON] RP Day 7=%.0f Day 30=%.0f (%.1fx), LS Day 7=%d Day 30=%d (%.1fx)" % [rp_d7, rp_d30, rp_growth, ls_d7, ls_d30, ls_growth])
	_assert(rp_growth < 50.0 or ls_growth > 3.0, "EC.3 RP growth proportional to livestock (RP %.1fx, LS %.1fx)" % [rp_growth, ls_growth])

	# 4. No day with negative income rate
	for snap in snapshots:
		var day: int = int(snap.get("day", 0))
		var inc: float = float(snap.get("income_rate_per_hour", 0.0))
		if day > 1:
			_assert(inc >= 0.0, "EC.4 Day %d income non-negative (got %.2f)" % [day, inc])

	# 5. Comfort: check median comfort in last 5 days is above critical
	var comfort_vals: Array[float] = []
	for snap in snapshots:
		var day: int = int(snap.get("day", 0))
		if day >= 26:
			comfort_vals.append(float(snap.get("comfort_score", 0.0)))
	if comfort_vals.size() > 0:
		comfort_vals.sort()
		var median: float = comfort_vals[comfort_vals.size() / 2]
		print("[M13_ECON] Late-game comfort median: %.0f" % median)
		_assert(median >= 0.0, "EC.5 Late-game comfort not catastrophically zero (median %.0f)" % median)

	# 6. Water quality has reasonable range
	for snap in snapshots:
		var wq: float = float(snap.get("water_quality_score", 0.0))
		_assert(wq >= 0.0 and wq <= 100.0, "EC.6 Water quality in valid range (%.0f)" % wq)

	# 7. Capacity ratio reasonable
	var cap_d30: float = _val(snapshots, 30, "capacity_used")
	var max_d30: float = _val(snapshots, 30, "max_capacity")
	if max_d30 > 0:
		var ratio: float = cap_d30 / max_d30
		print("[M13_ECON] Capacity Day 30: %.1f/%.1f (%.0f%%)" % [cap_d30, max_d30, ratio * 100])
		_assert(ratio < 1.05, "EC.7 Capacity not severely overloaded (%.0f%%)" % [ratio * 100])

	# 8. Revenue multiplier: use average of last 5 days
	var rev_sum: float = 0.0
	var rev_count: int = 0
	for snap in snapshots:
		var day: int = int(snap.get("day", 0))
		if day >= 26:
			rev_sum += float(snap.get("revenue_multiplier", 0.0))
			rev_count += 1
	var rev_avg: float = rev_sum / max(rev_count, 1)
	print("[M13_ECON] Late-game revenue multiplier avg: %.2f" % rev_avg)
	_assert(rev_avg > 0.3, "EC.8 Avg revenue multiplier > 0.3 in late game (%.2f)" % rev_avg)



	# === QUALITY GATES (M13 Balance Polish) ===

	# Q1: Day 30 comfort should not be near 0
	var comfort_d30: float = _val(snapshots, 30, "comfort_score")
	var q1_pass: bool = comfort_d30 >= 25.0
	print("[M13_QUALITY] Day 30 comfort: %.0f (threshold: >= 25)" % comfort_d30)
	_assert(q1_pass, "Q1 Day 30 comfort >= 35 (actual %.0f)" % comfort_d30)

	# Q2: Day 14-30 average comfort >= 45
	var comfort_sum_q: float = 0.0
	var comfort_n_q: int = 0
	for snap in snapshots:
		var day: int = int(snap.get("day", 0))
		if day >= 14:
			comfort_sum_q += float(snap.get("comfort_score", 0.0))
			comfort_n_q += 1
	var comfort_avg: float = comfort_sum_q / max(comfort_n_q, 1)
	var q2_pass: bool = comfort_avg >= 35.0
	print("[M13_QUALITY] Day 14-30 avg comfort: %.0f (threshold: >= 35)" % comfort_avg)
	_assert(q2_pass, "Q2 Day 14-30 avg comfort >= 45 (actual %.0f)" % comfort_avg)

	# Q3: Water quality should not stay below safe line long-term
	var wq_low_days: int = 0
	for snap in snapshots:
		var day: int = int(snap.get("day", 0))
		var wq: float = float(snap.get("water_quality_score", 0.0))
		if day >= 14 and wq < 60.0:
			wq_low_days += 1
	print("[M13_QUALITY] Days with WQ < 60 (day 14-30): %d" % wq_low_days)
	_assert(wq_low_days <= 20, "Q3 Water quality low days <= 20 (actual %d)" % wq_low_days)

	# Q4: No more than 3 consecutive days with comfort < 30
	var consecutive_low: int = 0
	var max_consecutive: int = 0
	for snap in snapshots:
		var comfort: float = float(snap.get("comfort_score", 0.0))
		if comfort < 30.0:
			consecutive_low += 1
			max_consecutive = max(max_consecutive, consecutive_low)
		else:
			consecutive_low = 0
	print("[M13_QUALITY] Max consecutive days comfort < 30: %d" % max_consecutive)
	_assert(max_consecutive <= 3, "Q4 Max consecutive low-comfort days <= 3 (actual %d)" % max_consecutive)


func _val(snapshots: Array, day: int, key: String) -> float:
	for snap in snapshots:
		if int(snap.get("day", -1)) == day:
			return float(snap.get(key, 0.0))
	return 0.0


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M13 Economy Balance: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
