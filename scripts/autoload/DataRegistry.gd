extends Node

const DATA_FILES := {
	"corals": "res://data/species/corals_seed.json",
	"fish": "res://data/species/fish_seed.json",
	"legacy_species": "res://data/species/legacy_species_extracted.json",
	"tool_creatures": "res://data/species/tool_creatures_seed.json",
	"equipment": "res://data/equipment/equipment_seed.json",
	"tanks": "res://data/equipment/tanks_seed.json",
	"tasks": "res://data/tasks/maintenance_tasks_seed.json",
	"events": "res://data/events/random_events_seed.json",
	"formulas": "res://data/formulas/formulas_seed.json",
}

var _tables: Dictionary = {}
var _species_by_id: Dictionary = {}
var _equipment_by_id: Dictionary = {}
var _tasks_by_id: Dictionary = {}
var _load_errors: Array[String] = []
var _loaded = false


func _ready() -> void:
	load_all()


func load_all() -> void:
	_tables.clear()
	_species_by_id.clear()
	_equipment_by_id.clear()
	_tasks_by_id.clear()
	_load_errors.clear()

	for table_name in DATA_FILES.keys():
		_tables[table_name] = _load_json(DATA_FILES[table_name])

	_index_records(["corals", "fish", "legacy_species", "tool_creatures"], _species_by_id)
	_index_records(["equipment", "tanks"], _equipment_by_id)
	_index_records(["tasks"], _tasks_by_id)

	_loaded = _load_errors.is_empty()


func get_species_count() -> int:
	var total = 0
	for table_name in ["corals", "fish", "legacy_species", "tool_creatures"]:
		total += _record_count(_tables.get(table_name, []))
	return total


func get_equipment_count() -> int:
	return _record_count(_tables.get("equipment", [])) + _record_count(_tables.get("tanks", []))


func get_task_count() -> int:
	return _record_count(_tables.get("tasks", []))


func get_event_count() -> int:
	return _record_count(_tables.get("events", []))


func get_species_by_id(id: String) -> Dictionary:
	return _species_by_id.get(id, {})


func get_equipment_by_id(id: String) -> Dictionary:
	return _equipment_by_id.get(id, {})


func get_task_by_id(id: String) -> Dictionary:
	return _tasks_by_id.get(id, {})


func get_load_errors() -> Array[String]:
	return _load_errors.duplicate()


func is_loaded_ok() -> bool:
	return _loaded and _load_errors.is_empty()


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_load_errors.append("Missing data file: " + path)
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("Cannot open data file: " + path)
		return []

	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		_load_errors.append("Cannot parse JSON data file: " + path)
		return []

	return parsed


func _index_records(table_names: Array, target: Dictionary) -> void:
	for table_name in table_names:
		var records = _records_from(_tables.get(table_name, []))
		for record in records:
			if not record.has("id"):
				_load_errors.append("Missing id in table: " + table_name)
				continue
			target[String(record["id"])] = record


func _records_from(data: Variant) -> Array:
	if data is Array:
		return data
	if data is Dictionary:
		var records: Array = []
		for value in data.values():
			if value is Array:
				records.append_array(value)
		return records
	return []


func _record_count(data: Variant) -> int:
	return _records_from(data).size()
