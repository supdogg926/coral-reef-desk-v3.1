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
var fish_count: int = 0
var coral_count: int = 0
var crustacean_count: int = 0
var other_livestock_count: int = 0
var invertebrate_count: int = 0
var algae_count: int = 0
var bio_load: float = 0.0
var system_capacity: float = DEFAULT_MAX_CAPACITY
var bio_load_ratio: float = 0.0
var system_pressure: float = 0.0
var comfort_score: float = 100.0
var comfort_status: String = "良好"
var revenue_multiplier: float = 1.0
var current_rp_per_tick: float = 0.0
var current_rp_per_second: float = 0.0
var last_bio_load_feedback: String = "舒适度良好，收益维持正常"
var maintenance_health: float = 50.0  # M13: persistent care bonus (0-100)
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

const CATEGORY_MAP: Dictionary = {
	"fish": "fish", "鱼": "fish", "海水鱼": "fish",
	"coral": "coral", "珊瑚": "coral", "软体珊瑚": "coral", "lps": "coral", "sps": "coral", "lps硬骨珊瑚": "coral",
	"crustacean": "crustacean", "甲壳": "crustacean", "shrimp": "crustacean", "crab": "crustacean", "虾": "crustacean", "蟹": "crustacean",
	"algae": "algae", "藻": "algae", "藻类": "algae",
	"invertebrate": "invertebrate", "无脊椎": "invertebrate",
}

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
	fish_count = 0
	coral_count = 0
	crustacean_count = 0
	other_livestock_count = 0
	algae_count = 0
	bio_load = 0.0
	system_capacity = DEFAULT_MAX_CAPACITY
	bio_load_ratio = 0.0
	system_pressure = 0.0
	comfort_score = 100.0
	comfort_status = "良好"
	revenue_multiplier = 1.0
	current_rp_per_tick = 0.0
	current_rp_per_second = 0.0
	last_bio_load_feedback = "舒适度良好，收益维持正常"
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
			"category": _normalize_livestock_category(String(record.get("category", "coral"))),
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
		"category": _normalize_livestock_category(String(entry.get("category", "coral"))),
		"rarity": rarity,
		"size_cm": float(entry.get("size_cm", 3.0)),
		"maturity_percent": 0.0,
		"health_percent": 100.0,
		"base_income_per_hour": float(entry.get("base_income_per_hour", 0.0)),
		"tank_slot_cost": slot_cost,
		"locked": false,
		"water_sensitivity": float(entry.get("water_sensitivity", 0.4)),
		"purchase_price": float(entry.get("purchase_price", 0.0)),
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
			"category": String(released_entry.get("category", "")),
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
	total_effective_income_per_hour = base_income * water_quality_multiplier * eq_mult * revenue_multiplier
	return total_effective_income_per_hour


func update_bio_load_metrics(context: Dictionary) -> void:
	_recount_livestock_categories()
	var water_quality_score: float = float(context.get("water_quality_score", 100.0))
	var stability_score: float = float(context.get("stability_score", 50.0))
	var carrying_capacity_score: float = float(context.get("carrying_capacity_score", max_capacity))
	var current_maintenance_load: float = float(context.get("maintenance_load", 0.0))
	var raw_device_effects: Variant = context.get("device_effects", {})
	var device_effects: Dictionary = raw_device_effects if raw_device_effects is Dictionary else {}
	var filter_efficiency: float = float(device_effects.get("filter_efficiency_percent", 100.0))
	var flow_comfort: float = float(device_effects.get("flow_comfort_score", 100.0))
	var maintenance_relief: float = _get_maintenance_relief(String(context.get("last_maintenance_action_id", "")))

	bio_load = current_capacity_used + float(fish_count) * 1.5 + float(coral_count) * 0.8 + float(crustacean_count) * 1.0 + float(other_livestock_count)
	system_capacity = max(max_capacity, carrying_capacity_score) + max(carrying_capacity_score - 8.0, 0.0) * 0.35  # M13: more capacity from score
	system_capacity += clamp(filter_efficiency, 0.0, 120.0) * 0.03
	system_capacity += clamp(flow_comfort, 0.0, 120.0) * 0.02
	system_capacity = max(system_capacity, 1.0)
	bio_load_ratio = bio_load / system_capacity

	var load_pressure: float = bio_load_ratio * 6.0 + max(bio_load_ratio - 0.85, 0.0) * 18.0  # M13: gentle curve
	var water_pressure: float = max(100.0 - water_quality_score, 0.0) * 0.95
	var device_relief: float = clamp(filter_efficiency, 0.0, 120.0) * 0.15 + clamp(flow_comfort, 0.0, 120.0) * 0.10  # M13: stronger device relief
	var stability_relief: float = max(stability_score - 40.0, 0.0) * 0.25  # M13: lower threshold, stronger effect
	var water_quality_relief: float = max(water_quality_score - 75.0, 0.0) * 0.30  # M13: further lowered
	var headroom_relief: float = max(1.0 - bio_load_ratio, 0.0) * 10.0  # M13: stronger headroom reward
	# M13: maintenance_health provides persistent comfort floor from regular care
	var health_relief: float = clamp(maintenance_health - 30.0, 0.0, 70.0) * 0.40
	system_pressure = clamp(load_pressure + water_pressure + current_maintenance_load * 0.4 - device_relief - stability_relief - water_quality_relief - headroom_relief - maintenance_relief - health_relief, 0.0, 100.0)
	comfort_score = clamp(100.0 - system_pressure, 0.0, 100.0)
	# M13: maintenance_health decays slowly, recovers from maintenance actions
	maintenance_health = clamp(maintenance_health - 0.15, 15.0, 100.0)  # slow decay per update
	if maintenance_relief > 0.1:
		maintenance_health = clamp(maintenance_health + maintenance_relief * 1.5, 0.0, 100.0)  # recover from maintenance
	comfort_status = _get_comfort_status(comfort_score)
	revenue_multiplier = _get_revenue_multiplier_for_comfort(comfort_score)
	last_bio_load_feedback = _build_bio_load_feedback()


func set_runtime_income_result(income_rate_per_game_hour: float, delta_seconds: float) -> void:
	current_rp_per_second = max(income_rate_per_game_hour, 0.0) / 3600.0
	current_rp_per_tick = current_rp_per_second * max(delta_seconds, 0.0)


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
	_recount_livestock_categories()


func export_state() -> Dictionary:
	var livestock_data: Array[Dictionary] = []
	for entry in owned_livestock:
		livestock_data.append(entry.duplicate(true))
	return {
		"owned_livestock": livestock_data,
		"tank_level": tank_level,
		"max_capacity": max_capacity,
		"current_capacity_used": current_capacity_used,
		"maintenance_health": maintenance_health,
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
				entry["category"] = _normalize_livestock_category(String(entry.get("category", "")))
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
		"fish_count": fish_count,
		"coral_count": coral_count,
		"crustacean_count": crustacean_count,
		"other_livestock_count": other_livestock_count,
		"algae_count": algae_count,
		"invertebrate_count": invertebrate_count,
		"capacity_used": current_capacity_used,
		"max_capacity": max_capacity,
		"capacity_status": capacity_status,
		"tank_level": tank_level,
		"total_base_income_per_hour": total_base_income_per_hour,
		"total_effective_income_per_hour": total_effective_income_per_hour,
		"water_quality_multiplier": water_quality_multiplier,
		"health_modifier": health_modifier,
		"bio_load": bio_load,
		"system_capacity": system_capacity,
		"bio_load_ratio": bio_load_ratio,
		"system_pressure": system_pressure,
		"comfort_score": comfort_score,
		"comfort_status": comfort_status,
		"revenue_multiplier": revenue_multiplier,
		"current_rp_per_tick": current_rp_per_tick,
		"current_rp_per_second": current_rp_per_second,
		"last_bio_load_feedback": last_bio_load_feedback,
		"maintenance_health": maintenance_health,
		"owned_livestock": owned_livestock.duplicate(true),
		"load_errors": load_errors.duplicate(),
	}


func _recount_livestock_categories() -> void:
	fish_count = 0
	coral_count = 0
	crustacean_count = 0
	other_livestock_count = 0
	algae_count = 0
	invertebrate_count = 0
	for entry in owned_livestock:
		if bool(entry.get("locked", false)):
			continue
		var category: String = _normalize_livestock_category(String(entry.get("category", "")))
		var qty: int = _get_entry_quantity(entry)
		if category == "fish":
			fish_count += qty
		elif category == "coral":
			coral_count += qty
		elif category == "crustacean" or category == "shrimp" or category == "crab":
			crustacean_count += qty
		elif category == "algae":
			algae_count += qty
		elif category == "invertebrate":
			invertebrate_count += qty
		else:
			other_livestock_count += qty

func _normalize_livestock_category(raw_category: String) -> String:
	var key: String = raw_category.to_lower().strip_edges()
	if CATEGORY_MAP.has(key):
		return String(CATEGORY_MAP[key])
	return "other"


func _get_entry_quantity(entry: Dictionary) -> int:
	var name_str: String = (String(entry.get("species_name", "")) + String(entry.get("id", ""))).to_lower()
	if "pair" in name_str or "一对" in name_str or "双" in name_str:
		return 2
	return 1

func _get_maintenance_relief(action_id: String) -> float:
	match action_id:
		"water_change_10":
			return 4.0
		"clean_filter":
			return 5.0
		"dose_buffer":
			return 2.0
		"top_off":
			return 2.0
		"travel_prep":
			return 8.0
	return 0.0


func _get_comfort_status(score: float) -> String:
	if score >= 90.0:
		return "优秀"
	if score >= 75.0:
		return "良好"
	if score >= 60.0:
		return "中等"
	if score >= 40.0:
		return "偏低"
	return "危险"


func _get_revenue_multiplier_for_comfort(score: float) -> float:
	if score >= 90.0:
		return 1.10
	if score >= 75.0:
		return 1.00
	if score >= 60.0:
		return 0.90
	if score >= 40.0:
		return 0.75
	return 0.50


func _build_bio_load_feedback() -> String:
	if bio_load_ratio >= 0.90 or comfort_score < 60.0:
		return "生物负载偏高，舒适度下降，收益倍率 %.2fx" % revenue_multiplier
	if comfort_score >= 90.0:
		return "舒适度良好，收益维持正常，收益倍率 %.2fx" % revenue_multiplier
	if revenue_multiplier < 1.0:
		return "舒适度中等，收益轻微下降，收益倍率 %.2fx" % revenue_multiplier
	return "生物负载可控，收益倍率 %.2fx" % revenue_multiplier


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
