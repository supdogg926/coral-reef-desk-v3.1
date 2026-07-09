extends SceneTree

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
		printerr("[M14-T01] FAIL: ", label)


func _run_tests() -> void:
	print("[M14-T01] RescueCore data/headless verification start")
	var RescueScript = load("res://scripts/systems/RescueSystem.gd")
	var SaveScript = load("res://scripts/systems/SaveSystem.gd")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	_assert(RescueScript != null, "T01.1 RescueSystem loads")
	_assert(SaveScript != null, "T01.2 SaveSystem loads")
	_assert(GameStateScript != null, "T01.3 GameState loads")
	if RescueScript == null or SaveScript == null or GameStateScript == null:
		return
	_test_migration(SaveScript)
	_test_dock_refresh(RescueScript)
	_test_rescue_loop_and_reputation(RescueScript)
	_test_recovery_speed_contrast(RescueScript)
	_test_save_restart_consistency(RescueScript)
	_test_gamestate_integration(GameStateScript)


func _test_migration(SaveScript) -> void:
	var save_system = SaveScript.new()
	save_system.initialize()
	var old_save: Dictionary = {
		"save_version": 1,
		"last_save_unix_time": 123,
		"economy": {"reef_points": 777.0, "total_reef_points_earned": 888.0},
		"water_chemistry": {"water_quality_score": 91.0},
		"time": {"elapsed_game_minutes": 4321},
		"unlocks": {"unlocked_states": {"tier2_equipment_preview": true}},
		"livestock": {
			"owned_livestock": [
				{"id": "fish_1", "species_name": "小丑鱼", "category": "fish", "purchase_price": 40.0},
				{"id": "coral_1", "species_name": "绿火柴", "category": "coral", "purchase_price": 80.0}
			],
			"tank_level": 1,
			"max_capacity": 30.0,
			"current_capacity_used": 4.0
		},
		"equipment": {"tier1_installed": true}
	}
	var migrated: Dictionary = save_system.migrate_save_data(old_save)
	_assert(int(migrated.get("save_version", 0)) == 2, "MIG.1 save schema migrates to v2")
	_assert(float(migrated.get("economy", {}).get("reef_points", -1.0)) == 777.0, "MIG.2 economy data preserved")
	_assert(int(migrated.get("time", {}).get("elapsed_game_minutes", -1)) == 4321, "MIG.3 time data preserved")
	_assert(migrated.has("player") and int(migrated.get("player", {}).get("reputation", -1)) == 0, "MIG.4 player reputation default added")
	_assert(migrated.has("rescue_data") and migrated.get("rescue_data", {}) is Dictionary, "MIG.5 rescue_data added")
	_assert(migrated.has("dock_state") and migrated.get("dock_state", {}) is Dictionary, "MIG.6 dock_state added")
	var owned: Array = migrated.get("livestock", {}).get("owned_livestock", [])
	_assert(owned.size() == 2, "MIG.7 livestock count preserved")
	var all_non_rescue: bool = true
	for entry in owned:
		all_non_rescue = all_non_rescue and entry is Dictionary and bool(entry.get("is_rescue", true)) == false and String(entry.get("rescue_status", "")) == "none"
	_assert(all_non_rescue, "MIG.8 old livestock defaults to non-rescue")


func _test_dock_refresh(RescueScript) -> void:
	var rescue = RescueScript.new()
	rescue.initialize(2201)
	var arrivals: int = 0
	for day in range(1, 31):
		var events: Array = rescue.process_day(day, 92.0, 92.0, false)
		for ev in events:
			if ev is Dictionary and String(ev.get("type", "")) == "dock_arrival":
				arrivals += 1
				rescue.accept_current_rescue(day)
				rescue.active_rescue = {}
	_assert(arrivals >= 7 and arrivals <= 15, "DOCK.1 seeded 30-day arrivals within config expectation (got %d)" % arrivals)


func _test_rescue_loop_and_reputation(RescueScript) -> void:
	var rescue = RescueScript.new()
	rescue.initialize(1401)
	var releases: Array[Dictionary] = []
	for day in range(1, 31):
		var events: Array = rescue.process_day(day, 96.0, 96.0, true)
		for ev in events:
			if ev is Dictionary and String(ev.get("type", "")) == "release":
				releases.append(ev)
	_assert(releases.size() >= 3, "LOOP.1 at least 3 rescue loops complete in 30 days (got %d)" % releases.size())
	var rep_sum: int = 0
	var rp_sum: int = 0
	for ev in releases:
		rep_sum += int(ev.get("reward_reputation", 0))
		rp_sum += int(ev.get("reward_rp", 0))
	var debug: Dictionary = rescue.get_debug_state()
	_assert(int(debug.get("ecological_reputation", -1)) == rep_sum, "REP.1 reputation equals release reward sum")
	_assert(int(debug.get("release_reward_sum_reputation", -1)) == rep_sum, "REP.2 internal reputation ledger matches")
	_assert(int(debug.get("total_release_rp_reward", -1)) == rp_sum, "REP.3 RP reward ledger matches")
	_assert(debug.get("codex_rescue_marks", {}) is Dictionary and not Dictionary(debug.get("codex_rescue_marks", {})).is_empty(), "CODEX.1 rescued codex marks recorded")


func _test_recovery_speed_contrast(RescueScript) -> void:
	var high_days: Array[int] = []
	var low_days: Array[int] = []
	for i in range(4):
		high_days.append(_days_to_release(RescueScript, "rescue_clownfish_juvenile", 95.0, 95.0, 100 + i))
		low_days.append(_days_to_release(RescueScript, "rescue_clownfish_juvenile", 45.0, 70.0, 200 + i))
	var high_avg: float = _avg_int(high_days)
	var low_avg: float = _avg_int(low_days)
	print("[M14-T01] Recovery contrast high_avg=%.2f low_avg=%.2f" % [high_avg, low_avg])
	_assert(high_avg < low_avg, "SPEED.1 high comfort recovery strictly faster than low comfort")


func _days_to_release(RescueScript, species_id: String, comfort: float, water: float, seed: int) -> int:
	var rescue = RescueScript.new()
	rescue.initialize(seed)
	rescue.force_start_rescue_for_test(species_id, 1)
	for day in range(1, 31):
		var events: Array = rescue.process_day(day, water, comfort, true)
		for ev in events:
			if ev is Dictionary and String(ev.get("type", "")) == "release":
				return day
	return 999


func _test_save_restart_consistency(RescueScript) -> void:
	var continuous = RescueScript.new()
	continuous.initialize(4411)
	for day in range(1, 31):
		continuous.process_day(day, 94.0, 93.0, true)
	var split_a = RescueScript.new()
	split_a.initialize(4411)
	for day in range(1, 16):
		split_a.process_day(day, 94.0, 93.0, true)
	var saved: Dictionary = split_a.export_state()
	var split_b = RescueScript.new()
	split_b.initialize(9999)
	split_b.import_state(saved)
	for day in range(16, 31):
		split_b.process_day(day, 94.0, 93.0, true)
	_assert(_canonical_rescue_state(continuous.export_state()) == _canonical_rescue_state(split_b.export_state()), "SAVE.1 split save/restart final state equals continuous run")


func _test_gamestate_integration(GameStateScript) -> void:
	var gs = GameStateScript.new()
	gs.initialize()
	_assert(gs.get("rescue_system") != null, "GS.1 GameState initializes RescueSystem")
	var before_rp: float = float(gs.get_economy_debug_state().get("reef_points", 0.0))
	var releases: int = 0
	for day in range(1, 31):
		var events: Array = gs.advance_rescue_day_for_test(day, 96.0, 96.0, true)
		for ev in events:
			if ev is Dictionary and String(ev.get("type", "")) == "release":
				releases += 1
	var rescue_debug: Dictionary = gs.get_rescue_debug_state()
	var after_rp: float = float(gs.get_economy_debug_state().get("reef_points", 0.0))
	_assert(releases >= 3, "GS.2 GameState helper completes rescue loops")
	_assert(int(rescue_debug.get("ecological_reputation", 0)) > 0, "GS.3 ecological reputation accumulates")
	_assert(after_rp > before_rp, "GS.4 release grants small RP through GameState")


func _canonical_rescue_state(state: Dictionary) -> String:
	var compact: Dictionary = {
		"dock_state": state.get("dock_state", {}),
		"active_rescue": state.get("active_rescue", {}),
		"completed_rescues": state.get("completed_rescues", []),
		"codex_rescue_marks": state.get("codex_rescue_marks", {}),
		"ecological_reputation": state.get("ecological_reputation", 0),
		"total_release_rp_reward": state.get("total_release_rp_reward", 0),
		"release_reward_sum_reputation": state.get("release_reward_sum_reputation", 0),
		"rng_state": state.get("rng_state", 0),
	}
	return JSON.stringify(compact)


func _avg_int(values: Array[int]) -> float:
	var total: int = 0
	for v in values:
		total += v
	return float(total) / max(float(values.size()), 1.0)


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M14-T01 RescueCore: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  M14_T01_RESCUE_CORE_RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
