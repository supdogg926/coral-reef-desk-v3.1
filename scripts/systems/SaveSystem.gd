class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://reef_idle_v3_save.json"
const SAVE_VERSION: int = 1
const OFFLINE_CAP_SECONDS: float = 86400.0

var initialized: bool = false
var last_save_unix_time: int = 0
var save_exists: bool = false
var save_errors: Array[String] = []
var last_saved_keys: Array[String] = []
var has_livestock_in_last_save: bool = false
var last_saved_livestock_count: int = 0


func initialize() -> void:
	save_errors.clear()
	save_exists = FileAccess.file_exists(SAVE_PATH)
	initialized = true


func save_game(game_state_dict: Dictionary) -> bool:
	save_errors.clear()
	print("[SAVE] save_game start")
	var timestamp: int = _get_current_unix_time()
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"last_save_unix_time": timestamp,
		"economy": game_state_dict.get("economy", {}),
		"water_chemistry": game_state_dict.get("water_chemistry", {}),
		"time": game_state_dict.get("time", {}),
		"unlocks": game_state_dict.get("unlocks", {}),
		"livestock": game_state_dict.get("livestock", {}),
		"equipment": game_state_dict.get("equipment", {}),
	}
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
		save_errors.append("Failed to serialize save data")
		return false
	print("[SAVE] json stringify done length=", json_text.length())
	print("[SAVE] file open start path=", SAVE_PATH)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("[SAVE] file open FAILED")
		save_errors.append("Cannot open save file for writing: " + SAVE_PATH)
		return false
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
		"last_saved_keys": last_saved_keys.duplicate(),
		"has_livestock_in_last_save": has_livestock_in_last_save,
		"last_saved_livestock_count": last_saved_livestock_count,
		"save_errors": save_errors.duplicate(),
	}


func _get_current_unix_time() -> int:
	return int(Time.get_unix_time_from_system())
