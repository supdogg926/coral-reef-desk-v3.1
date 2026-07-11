class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://reef_idle_v3_save.json"
const SAVE_VERSION: int = 4
const SAVE_SCHEMA_ID: String = "res://data/schemas/save_schema.json"
const OFFLINE_CAP_SECONDS: float = 86400.0
const CARE_NEEDS: Array[String] = ["weak", "stressed", "minor_injury"]

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
		"player": game_state_dict.get("player", {"reputation": 0}),
		"economy": game_state_dict.get("economy", {}),
		"water_chemistry": game_state_dict.get("water_chemistry", {}),
		"time": game_state_dict.get("time", {}),
		"unlocks": game_state_dict.get("unlocks", {}),
		"livestock": game_state_dict.get("livestock", {}),
		"equipment": game_state_dict.get("equipment", {}),
		"dock_state": game_state_dict.get("dock_state", game_state_dict.get("rescue_data", {}).get("dock_state", {})),
		"rescue_data": game_state_dict.get("rescue_data", {}),
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
	var data: Dictionary = migrate_save_data(parsed)
	last_save_unix_time = int(data.get("last_save_unix_time", 0))
	var version: int = int(data.get("save_version", 0))
	if version < 1:
		save_errors.append("Unknown save version: " + str(version))
	save_exists = true
	return data


func migrate_save_data(raw_data: Dictionary) -> Dictionary:
	var data: Dictionary = raw_data.duplicate(true)
	var version: int = int(data.get("save_version", 0))
	if version < 1:
		save_errors.append("Unknown save version: " + str(version))
	if version >= 2 and version < SAVE_VERSION:
		data["save_version"] = SAVE_VERSION
	elif version < 2:
		data["save_version"] = 2
	if not data.has("player") or not data["player"] is Dictionary:
		data["player"] = {"reputation": 0}
	else:
		var player: Dictionary = data["player"]
		player["reputation"] = int(player.get("reputation", 0))
		data["player"] = player
	var raw_livestock: Variant = data.get("livestock", {})
	if raw_livestock is Dictionary:
		var livestock: Dictionary = raw_livestock
		var raw_owned: Variant = livestock.get("owned_livestock", [])
		if raw_owned is Array:
			var migrated_owned: Array = []
			for item in raw_owned:
				if item is Dictionary:
					var entry: Dictionary = item.duplicate(true)
					entry["is_rescue"] = bool(entry.get("is_rescue", false))
					entry["rescue_status"] = String(entry.get("rescue_status", "none"))
					migrated_owned.append(entry)
			livestock["owned_livestock"] = migrated_owned
		data["livestock"] = livestock
	var rescue_data: Dictionary = {}
	var raw_rescue: Variant = data.get("rescue_data", data.get("rescue", {}))
	if raw_rescue is Dictionary:
		rescue_data = raw_rescue.duplicate(true)
	if not rescue_data.has("dock_state") or not rescue_data["dock_state"] is Dictionary:
		rescue_data["dock_state"] = {
			"next_arrival": 1,
			"current_rescue_id": "",
			"rng_seed": 1401,
		}
	if not rescue_data.has("active_rescue") or not rescue_data["active_rescue"] is Dictionary:
		rescue_data["active_rescue"] = {}
	elif version >= 2:
		var active: Dictionary = rescue_data["active_rescue"]
		if not active.is_empty():
			rescue_data["active_rescue"] = _ensure_care_fields(active)
	if not rescue_data.has("completed_rescues") or not rescue_data["completed_rescues"] is Array:
		rescue_data["completed_rescues"] = []
	elif version >= 2:
		var migrated_completed: Array = []
		for item in rescue_data["completed_rescues"]:
			if item is Dictionary:
				migrated_completed.append(_ensure_care_fields(item))
		rescue_data["completed_rescues"] = migrated_completed
	if not rescue_data.has("codex_rescue_marks") or not rescue_data["codex_rescue_marks"] is Dictionary:
		rescue_data["codex_rescue_marks"] = {}
	rescue_data["ecological_reputation"] = int(rescue_data.get("ecological_reputation", data.get("player", {}).get("reputation", 0)))
	rescue_data["total_release_rp_reward"] = int(rescue_data.get("total_release_rp_reward", 0))
	rescue_data["release_reward_sum_reputation"] = int(rescue_data.get("release_reward_sum_reputation", rescue_data.get("ecological_reputation", 0)))
	rescue_data["rng_state"] = int(rescue_data.get("rng_state", rescue_data.get("dock_state", {}).get("rng_seed", 1401)))
	if not rescue_data.has("event_log") or not rescue_data["event_log"] is Array:
		rescue_data["event_log"] = []
	data["rescue_data"] = rescue_data
	data["dock_state"] = rescue_data["dock_state"]
	# --- v4 migration (M19) ---
	data["save_version"] = SAVE_VERSION
	if not data.has("waves_balance") or not (data["waves_balance"] is float or data["waves_balance"] is int):
		var rp: float = float(data.get("economy", {}).get("reef_points", 0.0))
		data["waves_balance"] = rp
	if not data.has("collection_unlocked_species_ids") or not data["collection_unlocked_species_ids"] is Array:
		var codex: Dictionary = rescue_data.get("codex_rescue_marks", {})
		var unlocked: Array[String] = []
		for species_id in codex.keys():
			unlocked.append(String(species_id))
		data["collection_unlocked_species_ids"] = unlocked
	if not data.has("release_count_by_species") or not data["release_count_by_species"] is Dictionary:
		var counts: Dictionary = {}
		for item in rescue_data.get("completed_rescues", []):
			if item is Dictionary:
				var sid: String = String(item.get("species_id", ""))
				if sid != "":
					counts[sid] = int(counts.get(sid, 0)) + 1
		data["release_count_by_species"] = counts
	if not data.has("release_total_count") or not (data["release_total_count"] is int):
		data["release_total_count"] = int(rescue_data.get("completed_rescues", []).size())
	if not data.has("blue_guardian_state") or not data["blue_guardian_state"] is Dictionary:
		data["blue_guardian_state"] = {
			"active": false,
			"active_dock_id": "",
			"last_rotation_at": 0,
			"last_action_at": 0,
			"next_available_at": 0,
			"pending_reward_or_rescue_id": "",
		}
	if not data.has("discovered_postcard_ids") or not data["discovered_postcard_ids"] is Array:
		data["discovered_postcard_ids"] = []
	if not data.has("recent_release_record_ids") or not data["recent_release_record_ids"] is Array:
		data["recent_release_record_ids"] = []
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


func _ensure_care_fields(entry: Dictionary) -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	var need: String = String(result.get("care_need", ""))
	if not CARE_NEEDS.has(need):
		need = _derive_care_need(String(result.get("rescue_id", "")))
	result["care_need"] = need
	result["care_used"] = bool(result.get("care_used", false))
	result["care_action_taken"] = String(result.get("care_action_taken", ""))
	result["care_score"] = clamp(float(result.get("care_score", 0.0)), 0.0, 1.0)
	return result


func _derive_care_need(rescue_id: String) -> String:
	var raw_hash: int = int(hash(rescue_id))
	if raw_hash < 0:
		raw_hash = -raw_hash
	return CARE_NEEDS[raw_hash % CARE_NEEDS.size()]


func _to_plain_string_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value))
	return result
