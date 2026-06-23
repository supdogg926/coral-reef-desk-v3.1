class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://reef_idle_v3_save.json"
const SAVE_VERSION: int = 1
const SAVE_SCHEMA_ID: String = "res://data/schemas/save_schema.json"
const OFFLINE_CAP_SECONDS: float = 86400.0

var initialized: bool = false
var _is_saving: bool = false
var last_save_unix_time: int = 0
var save_exists: bool = false
var save_errors: Array[String] = []
var last_saved_keys: Array[String] = []
var has_livestock_in_last_save: bool = false
var last_saved_livestock_count: int = 0
var last_json_safety_ok: bool = true
var last_json_safety_error_count: int = 0


func initialize() -> void:
	save_errors.clear()
	save_exists = FileAccess.file_exists(SAVE_PATH)
	initialized = true


func save_game(game_state_dict: Dictionary) -> bool:
	if _is_saving:
		save_errors.append("Save already in progress")
		print("[SAVE] skipped: save already in progress")
		return false
	_is_saving = true
	save_errors.clear()
	last_json_safety_ok = true
	last_json_safety_error_count = 0
	print("[SAVE] save_game start")
	var timestamp: int = _get_current_unix_time()
	var raw_save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"save_schema": SAVE_SCHEMA_ID,
		"last_save_unix_time": timestamp,
		"economy": game_state_dict.get("economy", {}),
		"water_chemistry": game_state_dict.get("water_chemistry", {}),
		"time": game_state_dict.get("time", {}),
		"unlocks": game_state_dict.get("unlocks", {}),
		"livestock": game_state_dict.get("livestock", {}),
		"equipment": game_state_dict.get("equipment", {}),
	}
	var safe_variant: Variant = _to_json_safe(raw_save_data, "save")
	if not (safe_variant is Dictionary) or not last_json_safety_ok:
		return _finish_save_failure("Save data contains non JSON-safe values")
	var save_data: Dictionary = safe_variant
	print("[SAVE] save_data keys=", save_data.keys())
	print("[SAVE] has livestock=", save_data.has("livestock"))
	var raw_ls2: Variant = save_data.get("livestock", {})
	if raw_ls2 is Dictionary:
		var raw_arr: Variant = raw_ls2.get("owned_livestock", [])
		print("[SAVE] livestock count=", raw_arr.size() if raw_arr is Array else -1)
	print("[SAVE] json stringify start")
	var json_text: String = JSON.stringify(save_data, "\t")
	if json_text.is_empty():
		print("[SAVE] json stringify FAILED")
		return _finish_save_failure("Failed to serialize save data")
	print("[SAVE] json stringify done length=", json_text.length())
	print("[SAVE] file open start path=", SAVE_PATH)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("[SAVE] file open FAILED")
		return _finish_save_failure("Cannot open save file for writing: " + SAVE_PATH)
	print("[SAVE] file open done")
	print("[SAVE] file store_string start")
	file.store_string(json_text)
	print("[SAVE] file store_string done")
	file.close()
	print("[SAVE] file close done")
	last_save_unix_time = timestamp
	save_exists = true
	print("[SAVE] last_saved_keys update start")
	last_saved_keys.clear()
	for key in save_data.keys():
		last_saved_keys.append(String(key))
	print("[SAVE] last_saved_keys update done keys=", last_saved_keys)
	var raw_livestock: Variant = save_data.get("livestock", {})
	print("[SAVE] livestock debug update start")
	if raw_livestock is Dictionary:
		has_livestock_in_last_save = "owned_livestock" in raw_livestock
		if has_livestock_in_last_save:
			var arr: Variant = raw_livestock.get("owned_livestock", [])
			last_saved_livestock_count = arr.size() if arr is Array else 0
		else:
			last_saved_livestock_count = 0
	else:
		has_livestock_in_last_save = false
		last_saved_livestock_count = 0
	print("[SAVE] livestock debug update done count=", last_saved_livestock_count)
	print("[SAVE] save_game return true")
	_is_saving = false
	return true


func load_game() -> Dictionary:
	save_errors.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		save_errors.append("No save file found")
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_errors.append("Cannot open save file for reading: " + SAVE_PATH)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		save_errors.append("Failed to parse save file")
		return {}
	var data: Dictionary = parsed
	last_save_unix_time = int(data.get("last_save_unix_time", 0))
	var version: int = int(data.get("save_version", 0))
	if version < 1:
		save_errors.append("Unknown save version: " + str(version))
	save_exists = true
	return data


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_save() -> bool:
	save_errors.clear()
	if FileAccess.file_exists(SAVE_PATH):
		var dir: DirAccess = DirAccess.open("user://")
		if dir == null:
			save_errors.append("Cannot access user:// directory")
			return false
		var result: Error = dir.remove("reef_idle_v3_save.json")
		if result != OK:
			save_errors.append("Failed to delete save file")
			return false
	last_save_unix_time = 0
	save_exists = false
	return true


func get_save_path() -> String:
	return SAVE_PATH


func get_last_save_timestamp() -> int:
	return last_save_unix_time


func calculate_offline_seconds(current_timestamp: int, last_timestamp: int) -> float:
	var raw: float = float(max(current_timestamp - last_timestamp, 0))
	return min(raw, OFFLINE_CAP_SECONDS)


func get_debug_state() -> Dictionary:
	return {
		"system": "SaveSystem",
		"initialized": initialized,
		"save_version": SAVE_VERSION,
		"save_schema": SAVE_SCHEMA_ID,
		"save_path": SAVE_PATH,
		"save_exists": save_exists,
		"last_save_unix_time": last_save_unix_time,
		"offline_cap_seconds": OFFLINE_CAP_SECONDS,
		"last_saved_keys": _to_plain_string_array(last_saved_keys),
		"has_livestock_in_last_save": has_livestock_in_last_save,
		"last_saved_livestock_count": last_saved_livestock_count,
		"save_errors": _to_plain_string_array(save_errors),
		"save_in_progress": _is_saving,
		"last_json_safety_ok": last_json_safety_ok,
		"last_json_safety_error_count": last_json_safety_error_count,
	}


func _get_current_unix_time() -> int:
	return int(Time.get_unix_time_from_system())


func _finish_save_failure(message: String) -> bool:
	save_errors.append(message)
	_is_saving = false
	return false


func _to_json_safe(value: Variant, path: String) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_ARRAY:
			var safe_array: Array = []
			var source_array: Array = value
			for i in range(source_array.size()):
				safe_array.append(_to_json_safe(source_array[i], "%s[%d]" % [path, i]))
			return safe_array
		TYPE_DICTIONARY:
			var safe_dict: Dictionary = {}
			var source_dict: Dictionary = value
			for key in source_dict.keys():
				var key_type: int = typeof(key)
				if key_type != TYPE_STRING and key_type != TYPE_INT and key_type != TYPE_FLOAT and key_type != TYPE_BOOL:
					_mark_non_json_safe("%s.<key>" % path, key)
					continue
				var safe_key: String = String(key)
				safe_dict[safe_key] = _to_json_safe(source_dict[key], "%s.%s" % [path, safe_key])
			return safe_dict
		_:
			_mark_non_json_safe(path, value)
			return null


func _mark_non_json_safe(path: String, value: Variant) -> void:
	last_json_safety_ok = false
	last_json_safety_error_count += 1
	save_errors.append("Non JSON-safe value at %s, type=%d" % [path, typeof(value)])


func _to_plain_string_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value))
	return result
