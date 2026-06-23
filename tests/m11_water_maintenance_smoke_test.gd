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
	var result: Dictionary = water.apply_maintenance_action("water_change_10")
	_assert(bool(result.get("success", false)), "water_change_10 succeeds")
	_assert(water.water_quality_score > before_quality, "water_change_10 improves quality")
	_assert(water.nitrate < before_nitrate, "water_change_10 lowers nitrate")
	_assert(water.phosphate < before_phosphate, "water_change_10 lowers phosphate")
	_assert(water.salinity < before_salinity, "water_change_10 lowers high salinity")
	_assert(String(water.last_maintenance_action_id) == "water_change_10", "last maintenance action recorded")
	_assert(int(water.get_debug_state().get("maintenance_action_count", 0)) == 1, "debug exposes maintenance count")

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
