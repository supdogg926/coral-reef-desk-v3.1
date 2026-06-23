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
