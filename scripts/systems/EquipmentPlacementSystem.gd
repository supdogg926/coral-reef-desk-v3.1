class_name EquipmentPlacementSystem
extends RefCounted

const PLACEMENT_ZONES_PATH: String = "res://data/equipment/placement_zones_seed.json"

var initialized: bool = false
var placement_zones: Dictionary = {}
var equipment_slots: Dictionary = {}
var zone_equipment: Dictionary = {}
var slot_zones: Dictionary = {}
var load_errors: Array[String] = []


func initialize() -> void:
	load_placement_zones()
	assign_default_tier1_layout()
	initialized = load_errors.is_empty()


func load_placement_zones(path: String = PLACEMENT_ZONES_PATH) -> void:
	placement_zones.clear()
	zone_equipment.clear()
	slot_zones.clear()
	load_errors.clear()

	var parsed: Variant = _load_json(path)
	if not parsed is Array:
		load_errors.append("Placement zone data is not an array: " + path)
		return

	var records: Array = parsed
	for item in records:
		if not item is Dictionary:
			continue
		var record: Dictionary = item
		var zone_id: String = String(record.get("id", ""))
		if zone_id.is_empty():
			load_errors.append("Placement zone record missing id")
			continue
		placement_zones[zone_id] = record
		zone_equipment[zone_id] = []
		var slot_ids: Array = _get_zone_slot_ids(record)
		for slot_id in slot_ids:
			slot_zones[String(slot_id)] = zone_id


func assign_default_tier1_layout() -> void:
	equipment_slots.clear()
	for zone_id in zone_equipment.keys():
		zone_equipment[zone_id] = []

	_assign_slot_if_valid("filter_sock", "slot_mech_01")
	_assign_slot_if_valid("protein_skimmer", "slot_skimmer_01")
	_assign_slot_if_valid("refugium", "slot_refugium_01")
	_assign_slot_if_valid("return_pump", "slot_return_01")
	_assign_slot_if_valid("live_rock", "slot_display_rock_01")
	_assign_slot_if_valid("filter_media", "slot_mech_media_01")
	_assign_slot_if_valid("heater", "slot_return_heater_01")


func get_equipment_slot(equipment_id: String) -> String:
	return String(equipment_slots.get(equipment_id, ""))


func get_zone_equipment(zone_id: String) -> Array:
	if not zone_equipment.has(zone_id):
		return []
	var equipment: Array = _get_zone_equipment_array(zone_id)
	return equipment.duplicate()


func is_valid_placement(equipment_id: String, zone_id: String) -> bool:
	if not placement_zones.has(zone_id):
		return false
	var zone: Dictionary = _get_zone_record(zone_id)
	var allowed_equipment: Array = _get_zone_allowed_equipment(zone)
	return allowed_equipment.has(equipment_id)


func is_valid_slot(equipment_id: String, slot_id: String) -> bool:
	if not slot_zones.has(slot_id):
		return false
	var zone_id: String = String(slot_zones.get(slot_id, ""))
	return is_valid_placement(equipment_id, zone_id)


func install_to_slot(equipment_id: String, slot_id: String) -> bool:
	if not is_valid_slot(equipment_id, slot_id):
		return false
	_clear_equipment_assignment(equipment_id)
	var zone_id: String = String(slot_zones.get(slot_id, ""))
	equipment_slots[equipment_id] = slot_id
	var equipment: Array = _get_zone_equipment_array(zone_id)
	if not equipment.has(equipment_id):
		equipment.append(equipment_id)
	zone_equipment[zone_id] = equipment
	return true


func remove_from_slot(equipment_id: String) -> bool:
	if not equipment_slots.has(equipment_id):
		return false
	_clear_equipment_assignment(equipment_id)
	return true


func get_reserved_zones() -> Array:
	var result: Array = []
	for zone in placement_zones.values():
		if zone is Dictionary and bool(zone.get("reserved", false)) == true:
			result.append(zone)
	return result


func get_debug_state() -> Dictionary:
	return {
		"system": "EquipmentPlacementSystem",
		"initialized": initialized,
		"placement_zone_count": placement_zones.size(),
		"assigned_equipment_count": equipment_slots.size(),
		"reserved_zone_count": get_reserved_zones().size(),
		"slot_count": slot_zones.size(),
		"equipment_slots": equipment_slots.duplicate(),
		"load_errors": load_errors.duplicate(),
	}


func _assign_slot_if_valid(equipment_id: String, slot_id: String) -> void:
	if not install_to_slot(equipment_id, slot_id):
		load_errors.append("Invalid default slot placement: " + equipment_id + " -> " + slot_id)
		return


func _clear_equipment_assignment(equipment_id: String) -> void:
	if not equipment_slots.has(equipment_id):
		return
	var slot_id: String = String(equipment_slots.get(equipment_id, ""))
	var zone_id: String = String(slot_zones.get(slot_id, ""))
	if zone_equipment.has(zone_id):
		var equipment: Array = _get_zone_equipment_array(zone_id)
		equipment.erase(equipment_id)
		zone_equipment[zone_id] = equipment
	equipment_slots.erase(equipment_id)


func _get_zone_record(zone_id: String) -> Dictionary:
	var raw_zone: Variant = placement_zones.get(zone_id, {})
	if raw_zone is Dictionary:
		return raw_zone
	return {}


func _get_zone_allowed_equipment(zone: Dictionary) -> Array:
	var raw_allowed: Variant = zone.get("allowed_equipment", [])
	if raw_allowed is Array:
		return raw_allowed
	return []


func _get_zone_slot_ids(zone: Dictionary) -> Array:
	var raw_slots: Variant = zone.get("slot_ids", [])
	if raw_slots is Array:
		return raw_slots
	return []


func _get_zone_equipment_array(zone_id: String) -> Array:
	var raw_equipment: Variant = zone_equipment.get(zone_id, [])
	if raw_equipment is Array:
		return raw_equipment
	return []


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing placement data file: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open placement data file: " + path)
		return []
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse placement data file: " + path)
		return []
	return parsed
