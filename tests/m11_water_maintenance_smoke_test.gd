extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	_run()
	quit(1 if not _failures.is_empty() else 0)


func _run() -> void:
	var water_script = load("res://scripts/systems/WaterChemistrySystem.gd")
	_assert(water_script != null, "WaterChemistrySystem.gd loads")
	if water_script == null:
		_print_results()
		return

	var water: WaterChemistrySystem = WaterChemistrySystem.new()
	water.initialize()
	_assert(water.get_maintenance_actions().size() >= 4, "maintenance actions registered")

	water.nitrate = 14.0
	water.phosphate = 0.18
	water.salinity = 36.8
	water.ph = 7.78
	water.alkalinity = 6.7
	water.calcium = 360.0
	water.parameter_status = water.calculate_parameter_status()
	water.water_quality_score = water.calculate_water_quality_score()
	water.water_status = water.get_water_status()

	var before_quality: float = water.water_quality_score
	var before_nitrate: float = water.nitrate
	var before_phosphate: float = water.phosphate
	var before_salinity: float = water.salinity
	var before_ph: float = water.ph
	var result: Dictionary = water.apply_maintenance_action("water_change_10")
	_assert(bool(result.get("success", false)), "water_change_10 succeeds")
	_assert(water.water_quality_score > before_quality, "water_change_10 improves quality")
	_assert(water.nitrate < before_nitrate, "water_change_10 lowers nitrate")
	_assert(water.phosphate < before_phosphate, "water_change_10 lowers phosphate")
	_assert(water.salinity < before_salinity, "water_change_10 lowers high salinity")
	_assert(_is_closer_to_target(water.ph, before_ph, 8.20), "water_change_10 moves pH toward target")
	_assert(abs(float(result.get("ph_delta", 0.0))) > 0.001, "water_change_10 returns detectable pH delta")
	_assert(result.has("ph_before") and result.has("ph_after"), "water_change_10 returns pH before and after")
	_assert(String(water.last_maintenance_action_id) == "water_change_10", "last maintenance action recorded")
	_assert(int(water.get_debug_state().get("maintenance_action_count", 0)) == 1, "debug exposes maintenance count")
	_assert(String(water.last_maintenance_delta_summary).contains("pH"), "maintenance summary includes pH")

	water.ph = 7.94
	water.alkalinity = 7.1
	water.calcium = 390.0
	water.parameter_status = water.calculate_parameter_status()
	water.water_quality_score = water.calculate_water_quality_score()
	water.water_status = water.get_water_status()
	var before_kh_ph: float = water.ph
	var kh_result: Dictionary = water.apply_maintenance_action("dose_buffer")
	_assert(bool(kh_result.get("success", false)), "dose_buffer succeeds")
	_assert(_is_closer_to_target(water.ph, before_kh_ph, 8.20), "dose_buffer moves pH toward target")
	_assert(abs(float(kh_result.get("ph_delta", 0.0))) > 0.001, "dose_buffer returns detectable pH delta")

	var before_clean_ph: float = water.ph
	var clean_result: Dictionary = water.apply_maintenance_action("clean_filter")
	_assert(bool(clean_result.get("success", false)), "clean_filter succeeds")
	_assert(abs(water.ph - before_clean_ph) < 0.0001, "clean_filter does not directly change pH")

	var before_top_off_ph: float = water.ph
	var top_off_result: Dictionary = water.apply_maintenance_action("top_off")
	_assert(bool(top_off_result.get("success", false)), "top_off succeeds")
	_assert(abs(water.ph - before_top_off_ph) < 0.0001, "top_off does not directly change pH")

	var bad_result: Dictionary = water.apply_maintenance_action("bad_action")
	_assert(not bool(bad_result.get("success", true)), "unknown maintenance action fails")

	var game_state: GameState = _make_test_game_state(100.0)
	game_state.water_chemistry_system.ph = 7.86
	game_state.water_chemistry_system.nitrate = 14.0
	game_state.water_chemistry_system.phosphate = 0.18
	var before_rp: float = game_state.economy_system.get_reef_points()
	var water_change_result: Dictionary = game_state.apply_water_maintenance_action("water_change_10")
	_assert(bool(water_change_result.get("success", false)), "GameState water_change_10 succeeds with budget")
	_assert(is_equal_approx(game_state.economy_system.get_reef_points(), before_rp - 20.0), "GameState water_change_10 consumes cost")
	_assert(float(water_change_result.get("cost", 0.0)) == 20.0, "GameState water_change_10 returns cost")
	_assert(String(water_change_result.get("summary", "")).contains("消耗"), "GameState water_change_10 summary includes cost")

	var repeat_result: Dictionary = game_state.apply_water_maintenance_action("water_change_10")
	_assert(not bool(repeat_result.get("success", true)), "GameState water_change_10 immediate repeat is blocked")
	_assert(String(repeat_result.get("reason", "")) == "cooldown", "GameState repeat failure reason is cooldown")
	_assert(float(repeat_result.get("remaining_cooldown", 0.0)) > 0.0, "GameState cooldown returns remaining seconds")

	var before_buffer_ph: float = game_state.water_chemistry_system.ph
	var before_buffer_kh: float = game_state.water_chemistry_system.alkalinity
	var buffer_result: Dictionary = game_state.apply_water_maintenance_action("dose_buffer")
	_assert(bool(buffer_result.get("success", false)), "GameState dose_buffer succeeds with budget")
	_assert(game_state.water_chemistry_system.alkalinity > before_buffer_kh or _is_closer_to_target(game_state.water_chemistry_system.ph, before_buffer_ph, 8.20), "GameState dose_buffer changes KH or pH")

	var no_budget_state: GameState = _make_test_game_state(0.0)
	no_budget_state.water_chemistry_system.salinity = 37.2
	var before_no_budget_salinity: float = no_budget_state.water_chemistry_system.salinity
	var no_budget_result: Dictionary = no_budget_state.apply_water_maintenance_action("top_off")
	_assert(not bool(no_budget_result.get("success", true)), "GameState maintenance fails without budget")
	_assert(String(no_budget_result.get("reason", "")) == "insufficient_funds", "GameState no-budget failure reason is insufficient funds")
	_assert(is_equal_approx(no_budget_state.water_chemistry_system.salinity, before_no_budget_salinity), "GameState no-budget failure does not change water")
	_assert(no_budget_state.save_system == null, "GameState maintenance test does not touch SaveSystem")
	_print_results()


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		_failures.append(label)
		push_error("FAIL: " + label)


func _print_results() -> void:
	if _failures.is_empty():
		print("M11_WATER_MAINTENANCE_SMOKE_RESULT=PASS")
	else:
		print("M11_WATER_MAINTENANCE_SMOKE_RESULT=FAIL")
		for failure in _failures:
			print("FAILURE: " + failure)


func _is_closer_to_target(after_value: float, before_value: float, target: float) -> bool:
	return abs(after_value - target) < abs(before_value - target)


func _make_test_game_state(starting_reef_points: float) -> GameState:
	var game_state: GameState = GameState.new()
	game_state.economy_system = EconomySystem.new()
	game_state.economy_system.initialize()
	game_state.economy_system.add_reef_points(starting_reef_points)
	game_state.water_chemistry_system = WaterChemistrySystem.new()
	game_state.water_chemistry_system.initialize()
	return game_state
