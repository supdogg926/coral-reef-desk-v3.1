class_name EquipmentSystem
extends RefCounted

const EQUIPMENT_TIERS_PATH: String = "res://data/equipment/equipment_tiers_seed.json"

var initialized: bool = false
var equipment_records: Dictionary = {}
var unlocked_equipment: Dictionary = {}
var owned_equipment: Dictionary = {}
var enabled_equipment: Dictionary = {}
var storage_states: Dictionary = {}
var load_errors: Array[String] = []


func initialize() -> void:
	load_tier_equipment()
	initialized = load_errors.is_empty()


func load_tier_equipment(path: String = EQUIPMENT_TIERS_PATH) -> void:
	equipment_records.clear()
	unlocked_equipment.clear()
	owned_equipment.clear()
	enabled_equipment.clear()
	storage_states.clear()
	load_errors.clear()

	var parsed: Variant = _load_json(path)
	if not parsed is Array:
		load_errors.append("Equipment tier data is not an array: " + path)
		return

	var records: Array = parsed
	for item in records:
		if not item is Dictionary:
			continue
		var record: Dictionary = item
		var equipment_id: String = String(record.get("id", ""))
		if equipment_id.is_empty():
			load_errors.append("Equipment tier record missing id")
			continue

		equipment_records[equipment_id] = record
		unlocked_equipment[equipment_id] = bool(record.get("default_unlocked", false))
		owned_equipment[equipment_id] = bool(record.get("default_owned", false))
		storage_states[equipment_id] = String(record.get("storage_state", "locked"))
		enabled_equipment[equipment_id] = _is_record_installed_effective(record)


func get_tier1_equipment() -> Array:
	var result: Array = []
	for record in equipment_records.values():
		if record is Dictionary and int(record.get("tier", 0)) == 1:
			result.append(record)
	return result


func get_owned_equipment() -> Array:
	return _records_for_state(owned_equipment)


func get_unlocked_equipment() -> Array:
	return _records_for_state(unlocked_equipment)


func get_enabled_equipment() -> Array:
	return _records_for_state(enabled_equipment)


func get_installed_equipment() -> Array:
	var result: Array = []
	for record in equipment_records.values():
		if record is Dictionary and String(record.get("storage_state", "")) == "installed":
			result.append(record)
	return result


func get_warehouse_equipment() -> Array:
	var result: Array = []
	for record in equipment_records.values():
		if record is Dictionary and String(record.get("storage_state", "")) == "warehouse":
			result.append(record)
	return result


func unlock_equipment(equipment_id: String) -> bool:
	if not equipment_records.has(equipment_id):
		return false
	var record: Dictionary = _get_equipment_record(equipment_id)
	if int(record.get("tier", 0)) > 1:
		return false
	unlocked_equipment[equipment_id] = true
	return true


func enable_equipment(equipment_id: String) -> bool:
	if not equipment_records.has(equipment_id):
		return false
	var record: Dictionary = _get_equipment_record(equipment_id)
	if bool(record.get("first_version_enabled", false)) != true:
		return false
	if bool(unlocked_equipment.get(equipment_id, false)) != true:
		return false
	if bool(owned_equipment.get(equipment_id, false)) != true:
		return false
	if String(record.get("storage_state", "")) != "installed":
		return false
	record["installed_effective"] = true
	equipment_records[equipment_id] = record
	enabled_equipment[equipment_id] = _is_record_installed_effective(record)
	return true


func disable_equipment(equipment_id: String) -> bool:
	if not equipment_records.has(equipment_id):
		return false
	var record: Dictionary = _get_equipment_record(equipment_id)
	record["installed_effective"] = false
	equipment_records[equipment_id] = record
	enabled_equipment[equipment_id] = false
	return true


func install_equipment(equipment_id: String, slot_id: String) -> bool:
	if not equipment_records.has(equipment_id):
		return false
	var record: Dictionary = _get_equipment_record(equipment_id)
	if bool(record.get("installable", false)) != true:
		return false
	if String(record.get("storage_state", "")) == "locked":
		return false
	record["storage_state"] = "installed"
	record["slot_id"] = slot_id
	record["installed_effective"] = true
	equipment_records[equipment_id] = record
	storage_states[equipment_id] = "installed"
	enabled_equipment[equipment_id] = _is_record_installed_effective(record)
	return true


func remove_equipment(equipment_id: String) -> bool:
	if not equipment_records.has(equipment_id):
		return false
	var record: Dictionary = _get_equipment_record(equipment_id)
	if bool(record.get("removable", false)) != true:
		return false
	if String(record.get("storage_state", "")) != "installed":
		return false
	record["storage_state"] = "warehouse"
	record["slot_id"] = ""
	record["installed_effective"] = false
	equipment_records[equipment_id] = record
	storage_states[equipment_id] = "warehouse"
	enabled_equipment[equipment_id] = false
	return true


func get_equipment_effects_summary() -> Dictionary:
	var stability_bonus: float = 0.0
	var carrying_capacity_bonus: float = 0.0
	var maintenance_load: float = 0.0
	var nutrient_export: float = 0.0
	var bio_filtration: float = 0.0
	var temperature_control: float = 0.0
	var flow: float = 0.0
	var oxygenation: float = 0.0
	var enabled_count: int = 0
	var tier1_enabled_count: int = 0

	for equipment_id in enabled_equipment.keys():
		if not equipment_records.has(equipment_id):
			continue
		var record: Dictionary = _get_equipment_record(equipment_id)
		if not _is_record_installed_effective(record):
			continue
		var effects: Dictionary = _get_record_effects(record)
		enabled_count += 1
		if int(record.get("tier", 0)) == 1:
			tier1_enabled_count += 1
		stability_bonus += float(effects.get("stability_score", 0.0))
		carrying_capacity_bonus += float(effects.get("carrying_capacity_score", 0.0))
		maintenance_load += float(effects.get("maintenance_load", 0.0))
		nutrient_export += float(effects.get("nutrient_export", 0.0))
		bio_filtration += float(effects.get("bio_filtration", 0.0))
		temperature_control += float(effects.get("temperature_control", 0.0))
		flow += float(effects.get("flow", 0.0))
		oxygenation += float(effects.get("oxygenation", 0.0))

	return {
		"enabled_count": enabled_count,
		"tier1_enabled_count": tier1_enabled_count,
		"tier1_total_count": get_tier1_equipment().size(),
		"stability_bonus": stability_bonus,
		"carrying_capacity_bonus": carrying_capacity_bonus,
		"maintenance_load": maintenance_load,
		"nutrient_export": nutrient_export,
		"bio_filtration": bio_filtration,
		"temperature_control": temperature_control,
		"flow": flow,
		"oxygenation": oxygenation,
	}


func get_debug_state() -> Dictionary:
	var tier2_reserved_count: int = 0
	var tier3_reserved_count: int = 0
	for record in equipment_records.values():
		if not record is Dictionary:
			continue
		if int(record.get("tier", 0)) == 2:
			tier2_reserved_count += 1
		elif int(record.get("tier", 0)) == 3:
			tier3_reserved_count += 1

	return {
		"system": "EquipmentSystem",
		"initialized": initialized,
		"tier1_total_count": get_tier1_equipment().size(),
		"tier1_enabled_count": int(get_equipment_effects_summary().get("tier1_enabled_count", 0)),
		"tier2_reserved_count": tier2_reserved_count,
		"tier3_reserved_count": tier3_reserved_count,
		"owned_count": get_owned_equipment().size(),
		"unlocked_count": get_unlocked_equipment().size(),
		"enabled_count": get_enabled_equipment().size(),
		"installed_count": get_installed_equipment().size(),
		"warehouse_count": get_warehouse_equipment().size(),
		"locked_count": _get_locked_equipment_count(),
		"effects_summary": get_equipment_effects_summary(),
		"load_errors": load_errors.duplicate(),
	}


func _records_for_state(state: Dictionary) -> Array:
	var result: Array = []
	for equipment_id in state.keys():
		if bool(state.get(equipment_id, false)) == true and equipment_records.has(equipment_id):
			result.append(equipment_records[equipment_id])
	return result


func _get_equipment_record(equipment_id: String) -> Dictionary:
	var raw_record: Variant = equipment_records.get(equipment_id, {})
	if raw_record is Dictionary:
		return raw_record
	return {}


func _get_record_effects(record: Dictionary) -> Dictionary:
	var raw_effects: Variant = record.get("effects", {})
	if raw_effects is Dictionary:
		return raw_effects
	return {}


func _get_locked_equipment_count() -> int:
	var locked_count: int = 0
	for record in equipment_records.values():
		if record is Dictionary and String(record.get("storage_state", "")) == "locked":
			locked_count += 1
	return locked_count


func _is_record_installed_effective(record: Dictionary) -> bool:
	if String(record.get("storage_state", "")) != "installed":
		return false
	if bool(record.get("installed_effective", false)) != true:
		return false
	if bool(record.get("implicit_plumbing", false)) != true:
		return false
	if bool(record.get("pipe_connection_required", true)) != false:
		return false
	return true


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing equipment data file: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open equipment data file: " + path)
		return []
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse equipment data file: " + path)
		return []
	return parsed
