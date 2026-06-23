class_name LivestockSystem
extends RefCounted

const STARTER_LIVESTOCK_PATH: String = "res://data/livestock/starter_livestock_seed.json"
const SHOP_DATA_PATH: String = "res://data/shop/initial_shop_seed.json"
const DEFAULT_MAX_CAPACITY: float = 30.0
const M10_SHOP_ITEM_COUNT: int = 10

var initialized: bool = false
var owned_livestock: Array[Dictionary] = []
var tank_level: int = 1
var max_capacity: float = DEFAULT_MAX_CAPACITY
var current_capacity_used: float = 0.0
var capacity_status: String = "normal"
var total_base_income_per_hour: float = 0.0
var total_effective_income_per_hour: float = 0.0
var water_quality_multiplier: float = 1.0
var health_modifier: float = 1.0
var load_errors: Array[String] = []

const RARITY_MAP: Dictionary = {
	"老练": "稀有",
}

const NAME_MAP: Dictionary = {
	"绿手指": "海葵",
	"糖果脑": "绿火柴",
	"火炬珊瑚": "宝石花",
}

const VALID_RARITIES: Array[String] = ["普通", "精品", "稀有", "大师", "传奇"]

const WATER_QUALITY_MULTIPLIER_TABLE: Array[Dictionary] = [
	{"min_score": 80.0, "multiplier": 1.0},
	{"min_score": 60.0, "multiplier": 0.85},
	{"min_score": 40.0, "multiplier": 0.60},
	{"min_score": 0.0, "multiplier": 0.30},
]


func initialize() -> void:
	load_errors.clear()
	owned_livestock.clear()
	tank_level = 1
	max_capacity = DEFAULT_MAX_CAPACITY
	current_capacity_used = 0.0
	total_base_income_per_hour = 0.0
	total_effective_income_per_hour = 0.0
	water_quality_multiplier = 1.0
	health_modifier = 1.0
	_load_starter_livestock()
	_recalculate_capacity_and_income()
	initialized = true


func _load_starter_livestock() -> void:
	var parsed: Variant = _load_json(STARTER_LIVESTOCK_PATH)
	if not parsed is Array:
		load_errors.append("Starter livestock data is not an array")
		return
	var records: Array = parsed
	for item in records:
		if not item is Dictionary:
			continue
		var record: Dictionary = item
		if not bool(record.get("enabled", false)):
			continue
		var livestock_entry: Dictionary = {
			"id": String(record.get("id", "")),
			"species_name": _map_name(String(record.get("display_name_cn", ""))),
			"category": String(record.get("category", "coral")),
			"rarity": _normalize_rarity(String(record.get("rarity", "普通"))),
			"size_cm": float(record.get("size_cm", 3.0)),
			"maturity_percent": 100.0,
			"health_percent": 100.0,
			"base_income_per_hour": float(record.get("base_income_per_hour", float(record.get("base_reef_value", 0.0)) * 0.04)),
			"tank_slot_cost": float(record.get("capacity_cost", 2.0)),
			"locked": false,
			"water_sensitivity": float(record.get("water_sensitivity", 0.4)),
		}
		owned_livestock.append(livestock_entry)


func add_livestock(entry: Dictionary) -> bool:
	var slot_cost: float = float(entry.get("tank_slot_cost", 1.0))
	if current_capacity_used + slot_cost > max_capacity:
		return false
	var rarity: String = _normalize_rarity(String(entry.get("rarity", "普通")))
	var new_entry: Dictionary = {
		"id": String(entry.get("id", "livestock_%d" % owned_livestock.size())),
		"species_name": _map_name(String(entry.get("species_name", ""))),
		"category": String(entry.get("category", "coral")),
		"rarity": rarity,
		"size_cm": float(entry.get("size_cm", 3.0)),
		"maturity_percent": 0.0,
		"health_percent": 100.0,
		"base_income_per_hour": float(entry.get("base_income_per_hour", 0.0)),
		"tank_slot_cost": slot_cost,
		"locked": false,
		"water_sensitivity": float(entry.get("water_sensitivity", 0.4)),
	}
	owned_livestock.append(new_entry)
	_recalculate_capacity_and_income()
	return true


func get_livestock_snapshot(livestock_id: String) -> Dictionary:
	for entry in owned_livestock:
		if String(entry.get("id", "")) == livestock_id:
			return entry.duplicate(true)
	return {}


func release_livestock(livestock_id: String) -> Dictionary:
	var before_count: int = get_livestock_count()
	var before_capacity: float = current_capacity_used
	var before_base_income: float = total_base_income_per_hour
	var released_entry: Dictionary = get_livestock_snapshot(livestock_id)
	if released_entry.is_empty():
		return {"success": false, "error": "not_found", "livestock_id": livestock_id}
	if bool(released_entry.get("locked", false)):
		return {"success": false, "error": "locked", "livestock_id": livestock_id}
	if not remove_livestock(livestock_id):
		return {"success": false, "error": "remove_failed", "livestock_id": livestock_id}
	return {
		"success": true,
		"livestock_id": livestock_id,
		"species_name": String(released_entry.get("species_name", "")),
		"rarity": String(released_entry.get("rarity", "普通")),
		"released_capacity": float(released_entry.get("tank_slot_cost", 0.0)),
		"released_base_income_per_hour": float(released_entry.get("base_income_per_hour", 0.0)),
		"old_count": before_count,
		"new_count": get_livestock_count(),
		"old_capacity_used": before_capacity,
		"capacity_used": current_capacity_used,
		"max_capacity": max_capacity,
		"old_base_income_per_hour": before_base_income,
		"base_income_per_hour": total_base_income_per_hour,
	}


func remove_livestock(livestock_id: String) -> bool:
	for i in range(owned_livestock.size()):
		var entry: Dictionary = owned_livestock[i]
		if String(entry.get("id", "")) == livestock_id:
			owned_livestock.remove_at(i)
			_recalculate_capacity_and_income()
			return true
	return false


func get_total_income_per_hour() -> float:
	return total_effective_income_per_hour


func get_capacity_used() -> float:
	return current_capacity_used


func get_max_capacity() -> float:
	return max_capacity


func get_capacity_status() -> String:
	if current_capacity_used > max_capacity:
		return "overloaded"
	if current_capacity_used >= max_capacity * 0.92:
		return "full"
	return "normal"


func get_livestock_count() -> int:
	return owned_livestock.size()


func get_available_rarities() -> Array[String]:
	return VALID_RARITIES.duplicate()


func get_shop_items() -> Array[Dictionary]:
	var parsed: Variant = _load_json(SHOP_DATA_PATH)
	if not parsed is Array:
		return []
	var items: Array[Dictionary] = []
	for item in parsed:
		if item is Dictionary:
			var entry: Dictionary = item
			entry["rarity"] = _normalize_rarity(String(entry.get("rarity", "普通")))
			entry["species_name"] = _map_name(String(entry.get("species_name", "")))
			items.append(entry)
	if items.size() != M10_SHOP_ITEM_COUNT:
		load_errors.append("M10 shop item count mismatch: expected %d got %d" % [M10_SHOP_ITEM_COUNT, items.size()])
	return items


func get_shop_entry(shop_id: String) -> Dictionary:
	var items: Array[Dictionary] = get_shop_items()
	for item in items:
		if String(item.get("id", "")) == shop_id:
			return item
	return {}


func update_water_quality_multiplier(water_quality_score: float) -> void:
	for row in WATER_QUALITY_MULTIPLIER_TABLE:
		if water_quality_score >= float(row.get("min_score", 0.0)):
			water_quality_multiplier = float(row.get("multiplier", 1.0))
			break


func calculate_income_rate(water_chemistry_state: Dictionary, equipment_multiplier: float) -> float:
	var water_quality_score: float = float(water_chemistry_state.get("water_quality_score", 100.0))
	update_water_quality_multiplier(water_quality_score)
	health_modifier = calculate_health_from_water(water_chemistry_state)
	var base_income: float = 0.0
	for entry in owned_livestock:
		if bool(entry.get("locked", false)):
			continue
		var individual_income: float = float(entry.get("base_income_per_hour", 0.0))
		var health_pct: float = float(entry.get("health_percent", 100.0)) / 100.0
		base_income += individual_income * health_pct
	total_base_income_per_hour = base_income
	var eq_mult: float = max(equipment_multiplier, 0.5)
	total_effective_income_per_hour = base_income * water_quality_multiplier * eq_mult
	return total_effective_income_per_hour


func calculate_health_from_water(water_chemistry_state: Dictionary) -> float:
	var water_quality_score: float = float(water_chemistry_state.get("water_quality_score", 100.0))
	var avg_sensitivity: float = _get_avg_water_sensitivity()
	var quality_factor: float = clamp(water_quality_score / 100.0, 0.20, 1.0)
	return clamp(quality_factor * (1.05 - avg_sensitivity * 0.10), 0.20, 1.0)


func calculate_reef_value(water_chemistry_state: Dictionary) -> float:
	var total_value: float = 0.0
	for entry in owned_livestock:
		if bool(entry.get("locked", false)):
			continue
		var base_income: float = float(entry.get("base_income_per_hour", 0.0))
		var health_pct: float = float(entry.get("health_percent", 100.0)) / 100.0
		var rarity_mult: float = _rarity_value_multiplier(String(entry.get("rarity", "普通")))
		total_value += base_income * 25.0 * health_pct * rarity_mult
	return total_value


func _rarity_value_multiplier(rarity: String) -> float:
	match rarity:
		"传奇": return 5.0
		"大师": return 3.0
		"稀有": return 2.0
		"精品": return 1.5
		_: return 1.0


func _get_avg_water_sensitivity() -> float:
	var total: float = 0.0
	var count: int = 0
	for entry in owned_livestock:
		if bool(entry.get("locked", false)):
			continue
		total += float(entry.get("water_sensitivity", 0.4))
		count += 1
	if count <= 0:
		return 0.0
	return total / float(count)


func _recalculate_capacity_and_income() -> void:
	current_capacity_used = 0.0
	total_base_income_per_hour = 0.0
	for entry in owned_livestock:
		if bool(entry.get("locked", false)):
			continue
		current_capacity_used += float(entry.get("tank_slot_cost", 0.0))
		total_base_income_per_hour += float(entry.get("base_income_per_hour", 0.0))
	capacity_status = get_capacity_status()


func export_state() -> Dictionary:
	var livestock_data: Array[Dictionary] = []
	for entry in owned_livestock:
		livestock_data.append(entry.duplicate(true))
	return {
		"owned_livestock": livestock_data,
		"tank_level": tank_level,
		"max_capacity": max_capacity,
		"current_capacity_used": current_capacity_used,
	}


func import_state(state: Dictionary) -> void:
	owned_livestock.clear()
	var raw_livestock: Variant = state.get("owned_livestock", [])
	if raw_livestock is Array:
		for item in raw_livestock:
			if item is Dictionary:
				var entry: Dictionary = item
				entry["rarity"] = _normalize_rarity(String(entry.get("rarity", "普通")))
				entry["species_name"] = _map_name(String(entry.get("species_name", "")))
				owned_livestock.append(entry)
	tank_level = int(state.get("tank_level", 1))
	max_capacity = float(state.get("max_capacity", DEFAULT_MAX_CAPACITY))
	current_capacity_used = float(state.get("current_capacity_used", 0.0))
	_recalculate_capacity_and_income()


func get_debug_state() -> Dictionary:
	return {
		"system": "LivestockSystem",
		"initialized": initialized,
		"livestock_count": get_livestock_count(),
		"capacity_used": current_capacity_used,
		"max_capacity": max_capacity,
		"capacity_status": capacity_status,
		"tank_level": tank_level,
		"total_base_income_per_hour": total_base_income_per_hour,
		"total_effective_income_per_hour": total_effective_income_per_hour,
		"water_quality_multiplier": water_quality_multiplier,
		"health_modifier": health_modifier,
		"owned_livestock": owned_livestock.duplicate(true),
		"load_errors": load_errors.duplicate(),
	}


func _normalize_rarity(rarity: String) -> String:
	if RARITY_MAP.has(rarity):
		return String(RARITY_MAP[rarity])
	if rarity in VALID_RARITIES:
		return rarity
	return "普通"


func _map_name(name: String) -> String:
	if NAME_MAP.has(name):
		return String(NAME_MAP[name])
	return name


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing livestock data file: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open livestock data file: " + path)
		return []
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse livestock data file: " + path)
		return []
	return parsed
