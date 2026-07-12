class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://reef_idle_v3_save.json"
const SAVE_TEMP_PATH: String = "user://reef_idle_v3_save.json.tmp"
const SAVE_BACKUP_PATH: String = "user://reef_idle_v3_save.json.bak"
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
var _test_fault_points: Dictionary = {}
var wall_clock: WallClockService = null


func initialize(p_wall_clock: WallClockService = null) -> void:
	save_errors.clear()
	save_exists = FileAccess.file_exists(SAVE_PATH)
	wall_clock = p_wall_clock
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
	print("[SAVE] save_game start (atomic mode)")

	# --- Step 0: Serialize ---
	var timestamp: int = _get_current_unix_time()
	var raw_save_data: Dictionary = _build_save_dict(game_state_dict, timestamp)
	var safe_variant: Variant = _to_json_safe(raw_save_data, "save")
	if not (safe_variant is Dictionary) or not last_json_safety_ok:
		return _finish_save_failure("Save data contains non JSON-safe values")
	var save_data: Dictionary = safe_variant
	var json_text: String = JSON.stringify(save_data, "\t")
	if json_text.is_empty():
		print("[SAVE] json stringify FAILED")
		return _finish_save_failure("Failed to serialize save data")
	print("[SAVE] json serialized, length=", json_text.length())

	# --- Step 1: Clean orphaned tmp ---
	_remove_file_if_exists(SAVE_TEMP_PATH)

	# --- Step 2: Write to temp file ---
	if not _atomic_write_temp_file(json_text):
		return _finish_save_failure("Failed to write temporary save file")

	# --- Step 3: Validate temp file ---
	if not _atomic_validate_temp_file():
		_remove_file_if_exists(SAVE_TEMP_PATH)
		return _finish_save_failure("Temporary save file validation failed")

	# --- Step 4: Replace final with temp ---
	if not _atomic_replace_final():
		_remove_file_if_exists(SAVE_TEMP_PATH)
		return _finish_save_failure("Failed to replace final save file")

	# --- Step 5: Validate final file ---
	if not _atomic_validate_final_file():
		return _finish_save_failure("Final save file validation failed after replacement")

	# --- Step 6: Cleanup ---
	_remove_file_if_exists(SAVE_TEMP_PATH)
	_remove_file_if_exists(SAVE_BACKUP_PATH)

	# --- Success ---
	last_save_unix_time = timestamp
	save_exists = true
	_update_save_metadata(save_data)
	print("[SAVE] atomic save complete, return true")
	_is_saving = false
	return true


func _build_save_dict(game_state_dict: Dictionary, timestamp: int) -> Dictionary:
	return {
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
		"waves_balance": game_state_dict.get("waves_balance", game_state_dict.get("economy", {}).get("reef_points", 0.0)),
		"blue_guardian_state": game_state_dict.get("blue_guardian_state", {}),
		"collection_unlocked_species_ids": game_state_dict.get("collection_unlocked_species_ids", []),
		"release_count_by_species": game_state_dict.get("release_count_by_species", {}),
		"release_total_count": game_state_dict.get("release_total_count", 0),
		"discovered_postcard_ids": game_state_dict.get("discovered_postcard_ids", []),
		"recent_release_record_ids": game_state_dict.get("recent_release_record_ids", []),
	}


func _atomic_write_temp_file(json_text: String) -> bool:
	if _test_fault_points.get("TEMP_OPEN", false):
		print("[SAVE] FAULT INJECT: TEMP_OPEN")
		return false
	var file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		print("[SAVE] temp file open FAILED: ", SAVE_TEMP_PATH)
		return false
	if _test_fault_points.get("TEMP_WRITE", false):
		print("[SAVE] FAULT INJECT: TEMP_WRITE")
		file.close()
		return false
	file.store_string(json_text)
	file.flush()
	file.close()
	print("[SAVE] temp file written: ", SAVE_TEMP_PATH)
	return true


func _atomic_validate_temp_file() -> bool:
	if _test_fault_points.get("TEMP_VALIDATE", false):
		print("[SAVE] FAULT INJECT: TEMP_VALIDATE")
		return false
	if not FileAccess.file_exists(SAVE_TEMP_PATH):
		print("[SAVE] temp file missing after write")
		return false
	var file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
	if file == null:
		print("[SAVE] cannot re-open temp file for validation")
		return false
	var text: String = file.get_as_text()
	file.close()
	if text.is_empty():
		print("[SAVE] temp file is empty")
		return false
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		print("[SAVE] temp file JSON parse failed")
		return false
	if not (parsed as Dictionary).has("save_version"):
		print("[SAVE] temp file missing save_version")
		return false
	print("[SAVE] temp file validated, size=", text.length())
	return true


func _atomic_replace_final() -> bool:
	if _test_fault_points.get("BACKUP_OR_REPLACE", false):
		print("[SAVE] FAULT INJECT: BACKUP_OR_REPLACE")
		return false
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		print("[SAVE] cannot access user:// for rename")
		return false
	# Remove old backup if exists
	_remove_file_if_exists(SAVE_BACKUP_PATH)
	# If final exists, rename to backup first
	if FileAccess.file_exists(SAVE_PATH):
		var bak_err: Error = dir.rename("reef_idle_v3_save.json", "reef_idle_v3_save.json.bak")
		if bak_err != OK:
			print("[SAVE] failed to backup final, error=", bak_err)
			# If we can't backup, the final is still intact; we fail
			return false
	# Rename tmp to final
	var final_err: Error = dir.rename("reef_idle_v3_save.json.tmp", "reef_idle_v3_save.json")
	if final_err != OK:
		print("[SAVE] failed to rename tmp to final, error=", final_err)
		# Attempt restore from backup
		if FileAccess.file_exists(SAVE_BACKUP_PATH):
			dir.rename("reef_idle_v3_save.json.bak", "reef_idle_v3_save.json")
		return false
	print("[SAVE] tmp renamed to final")
	return true


func _atomic_validate_final_file() -> bool:
	if _test_fault_points.get("FINAL_VALIDATE", false):
		print("[SAVE] FAULT INJECT: FINAL_VALIDATE")
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SAVE] final file missing after rename")
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("[SAVE] cannot open final file for validation")
		return false
	var text: String = file.get_as_text()
	file.close()
	if text.is_empty():
		print("[SAVE] final file is empty after replacement")
		return false
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		print("[SAVE] final file JSON parse failed after replacement")
		return false
	print("[SAVE] final file validated")
	return true


func _remove_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	var filename: String = path.trim_prefix("user://")
	dir.remove(filename)


func _update_save_metadata(save_data: Dictionary) -> void:
	last_saved_keys.clear()
	for key in save_data.keys():
		last_saved_keys.append(String(key))
	var raw_livestock: Variant = save_data.get("livestock", {})
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


func load_game() -> Dictionary:
	save_errors.clear()
	var data: Variant = _try_load_file(SAVE_PATH)
	if data != null and data is Dictionary:
		save_exists = true
		_cleanup_orphaned_temp_files()
		return _post_load(data)
	# Final missing or corrupt — try backup
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		print("[SAVE] final missing/corrupt, attempting backup recovery")
		data = _try_load_file(SAVE_BACKUP_PATH)
		if data != null and data is Dictionary:
			save_exists = true
			_cleanup_orphaned_temp_files()
			# Restore backup as final
			_restore_backup_to_final()
			return _post_load(data)
	# Neither final nor backup valid
	save_exists = false
	save_errors.append("No valid save file found (final and backup both invalid or missing)")
	return {}


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
		data["blue_guardian_state"] = _make_blue_guardian_defaults(_get_current_unix_time())
	else:
		data["blue_guardian_state"] = _migrate_blue_guardian_state(data["blue_guardian_state"], _get_current_unix_time())
	if not data.has("discovered_postcard_ids") or not data["discovered_postcard_ids"] is Array:
		data["discovered_postcard_ids"] = []
	if not data.has("recent_release_record_ids") or not data["recent_release_record_ids"] is Array:
		data["recent_release_record_ids"] = []
	return data


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_save() -> bool:
	save_errors.clear()
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		save_errors.append("Cannot access user:// directory")
		return false
	_remove_file_if_exists(SAVE_PATH)
	_remove_file_if_exists(SAVE_TEMP_PATH)
	_remove_file_if_exists(SAVE_BACKUP_PATH)
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
	if wall_clock != null:
		return wall_clock.now_unix()
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


func _try_load_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[SAVE] cannot open for reading: ", path)
		return null
	var text: String = file.get_as_text()
	file.close()
	if text.is_empty():
		print("[SAVE] file is empty: ", path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		print("[SAVE] failed to parse: ", path)
		return null
	return parsed


func _post_load(raw_data: Variant) -> Dictionary:
	var data: Dictionary = migrate_save_data(raw_data)
	last_save_unix_time = int(data.get("last_save_unix_time", 0))
	var version: int = int(data.get("save_version", 0))
	if version < 1:
		save_errors.append("Unknown save version: " + str(version))
	return data


func _cleanup_orphaned_temp_files() -> void:
	_remove_file_if_exists(SAVE_TEMP_PATH)


func _restore_backup_to_final() -> void:
	if not FileAccess.file_exists(SAVE_BACKUP_PATH):
		return
	_remove_file_if_exists(SAVE_PATH)
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null:
		dir.rename("reef_idle_v3_save.json.bak", "reef_idle_v3_save.json")
		print("[SAVE] restored backup to final")


# --- Fault Injection API (test-only) ---


func set_test_fault_point(fault_name: String, enabled: bool) -> void:
	_test_fault_points[fault_name] = enabled


func clear_test_fault_points() -> void:
	_test_fault_points.clear()


func get_save_temp_path() -> String:
	return SAVE_TEMP_PATH


func get_save_backup_path() -> String:
	return SAVE_BACKUP_PATH



func _make_blue_guardian_defaults(seed_time: int) -> Dictionary:
	var seed_val: int = seed_time
	if seed_val <= 0:
		seed_val = 1
	seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
	if seed_val <= 0:
		seed_val = 1
	return {
		"schema_version": 1,
		"save_seed": seed_val,
		"voyage_sequence": 0,
		"voyage_state": "READY",
		"voyage_end_ts": 0,
		"pending_result": {},
		"active": false,
		"active_dock_id": "",
		"last_rotation_at": 0,
		"last_action_at": 0,
		"next_available_at": 0,
		"pending_reward_or_rescue_id": "",
	}


func _migrate_blue_guardian_state(raw: Dictionary, seed_time: int) -> Dictionary:
	var bg: Dictionary = raw.duplicate(true)
	if not bg.has("schema_version") or not (bg["schema_version"] is int):
		bg["schema_version"] = 1
	if not bg.has("save_seed") or not (bg["save_seed"] is int) or int(bg["save_seed"]) <= 0:
		bg["save_seed"] = _make_blue_guardian_defaults(seed_time)["save_seed"]
	if not bg.has("voyage_sequence") or not (bg["voyage_sequence"] is int):
		bg["voyage_sequence"] = 0
	if not bg.has("voyage_state") or not (bg["voyage_state"] is String):
		bg["voyage_state"] = "READY"
	if not bg.has("voyage_end_ts") or not (bg["voyage_end_ts"] is int):
		bg["voyage_end_ts"] = 0
	if not bg.has("pending_result") or not bg["pending_result"] is Dictionary:
		bg["pending_result"] = {}
	if not bg.has("active"):
		bg["active"] = false
	if not bg.has("active_dock_id"):
		bg["active_dock_id"] = ""
	if not bg.has("last_rotation_at"):
		bg["last_rotation_at"] = 0
	if not bg.has("last_action_at"):
		bg["last_action_at"] = 0
	if not bg.has("next_available_at"):
		bg["next_available_at"] = 0
	if not bg.has("pending_reward_or_rescue_id"):
		bg["pending_reward_or_rescue_id"] = ""
	return bg


func _to_plain_string_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value))
	return result
