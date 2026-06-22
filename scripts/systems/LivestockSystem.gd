class_name LivestockSystem
extends RefCounted

const STARTER_LIVESTOCK_PATH: String = "res://data/livestock/starter_livestock_seed.json"

var initialized: bool = false
var starter_livestock: Array[Dictionary] = []
var capacity_used: float = 0.0
var capacity_limit: float = 0.0
var capacity_status: String = "normal"
var reef_value: float = 0.0
var income_rate_per_game_hour: float = 0.0
var health_modifier: float = 1.0
var water_income_modifier: float = 1.0
var load_errors: Array[String] = []


func initialize() -> void:
	load_starter_livestock()
	initialized = load_errors.is_empty()


func load_starter_livestock(path: String = STARTER_LIVESTOCK_PATH) -> void:
	starter_livestock.clear()
	load_errors.clear()
	var parsed: Variant = _load_json(path)
	if not parsed is Array:
		load_errors.append("Starter livestock data is not an array: " + path)
		return
	var records: Array = parsed
	for item in records:
		if not item is Dictionary:
			continue
		var record: Dictionary = item
		if String(record.get("id", "")).is_empty():
			load_errors.append("Starter livestock record missing id")
			continue
		starter_livestock.append(record)
	_recalculate_capacity_used()


func get_livestock_count() -> int:
	var count: int = 0
	for record in starter_livestock:
		if bool(record.get("enabled", false)) == true:
			count += 1
	return count


func get_capacity_used() -> float:
	_recalculate_capacity_used()
	return capacity_used


func get_capacity_limit() -> float:
	return capacity_limit


func get_capacity_status() -> String:
	var used: float = get_capacity_used()
	if used > capacity_limit:
		return "overloaded"
	if used >= capacity_limit * 0.92:
		return "full"
	return "normal"


func calculate_livestock_health_modifier(water_chemistry_state: Dictionary) -> float:
	var water_quality_score: float = float(water_chemistry_state.get("water_quality_score", 100.0))
	var average_sensitivity: float = _get_average_water_sensitivity()
	var quality_factor: float = clamp(water_quality_score / 100.0, 0.20, 1.0)
	health_modifier = clamp(quality_factor * (1.05 - average_sensitivity * 0.10), 0.20, 1.0)
	return health_modifier


func calculate_reef_value(water_chemistry_state: Dictionary, carrying_capacity_score: float) -> float:
	capacity_limit = max(carrying_capacity_score, 1.0)
	var used: float = get_capacity_used()
	var capacity_modifier: float = 1.0
	if used > capacity_limit:
		capacity_modifier = clamp(capacity_limit / max(used, 0.001), 0.25, 1.0)
	var base_value: float = _get_base_reef_value()
	var current_health_modifier: float = calculate_livestock_health_modifier(water_chemistry_state)
	reef_value = base_value * current_health_modifier * capacity_modifier
	capacity_status = get_capacity_status()
	return reef_value


func calculate_income_rate(water_chemistry_state: Dictionary, carrying_capacity_score: float) -> float:
	var current_reef_value: float = calculate_reef_value(water_chemistry_state, carrying_capacity_score)
	var water_quality_score: float = float(water_chemistry_state.get("water_quality_score", 100.0))
	water_income_modifier = clamp(0.35 + water_quality_score / 100.0 * 0.65, 0.20, 1.0)
	income_rate_per_game_hour = current_reef_value * 0.04 * water_income_modifier
	return income_rate_per_game_hour


func get_debug_state() -> Dictionary:
	return {
		"system": "LivestockSystem",
		"initialized": initialized,
		"livestock_count": get_livestock_count(),
		"capacity_used": get_capacity_used(),
		"capacity_limit": capacity_limit,
		"capacity_status": capacity_status,
		"reef_value": reef_value,
		"income_rate_per_game_hour": income_rate_per_game_hour,
		"health_modifier": health_modifier,
		"water_income_modifier": water_income_modifier,
		"starter_livestock": starter_livestock.duplicate(true),
		"load_errors": load_errors.duplicate(),
	}


func _recalculate_capacity_used() -> void:
	capacity_used = 0.0
	for record in starter_livestock:
		if bool(record.get("enabled", false)) == true:
			capacity_used += float(record.get("capacity_cost", 0.0))


func _get_base_reef_value() -> float:
	var total: float = 0.0
	for record in starter_livestock:
		if bool(record.get("enabled", false)) == true:
			total += float(record.get("base_reef_value", 0.0))
	return total


func _get_average_water_sensitivity() -> float:
	var total: float = 0.0
	var count: int = 0
	for record in starter_livestock:
		if bool(record.get("enabled", false)) == true:
			total += float(record.get("water_sensitivity", 0.0))
			count += 1
	if count <= 0:
		return 0.0
	return total / float(count)


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing starter livestock data file: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open starter livestock data file: " + path)
		return []
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse starter livestock data file: " + path)
		return []
	return parsed
