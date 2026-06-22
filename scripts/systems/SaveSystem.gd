class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://reef_idle_v3_save.json"
const SAVE_VERSION: int = 1
const OFFLINE_CAP_SECONDS: float = 86400.0

var initialized: bool = false
var last_save_unix_time: int = 0
var save_exists: bool = false
var save_errors: Array[String] = []


func initialize() -> void:
	save_errors.clear()
	save_exists = FileAccess.file_exists(SAVE_PATH)
	initialized = true


func save_game(game_state_dict: Dictionary) -> bool:
	save_errors.clear()
	var timestamp: int = _get_current_unix_time()
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"last_save_unix_time": timestamp,
		"economy": game_state_dict.get("economy", {}),
		"water_chemistry": game_state_dict.get("water_chemistry", {}),
		"time": game_state_dict.get("time", {}),
		"unlocks": game_state_dict.get("unlocks", {}),
		"equipment": game_state_dict.get("equipment", {}),
	}
	var json_text: String = JSON.stringify(save_data, "\t")
	if json_text.is_empty():
		save_errors.append("Failed to serialize save data")
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_errors.append("Cannot open save file for writing: " + SAVE_PATH)
		return false
	file.store_string(json_text)
	file.close()
	last_save_unix_time = timestamp
	save_exists = true
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
		"save_path": SAVE_PATH,
		"save_exists": save_exists,
		"last_save_unix_time": last_save_unix_time,
		"offline_cap_seconds": OFFLINE_CAP_SECONDS,
		"save_errors": save_errors.duplicate(),
	}


func _get_current_unix_time() -> int:
	return int(Time.get_unix_time_from_system())
