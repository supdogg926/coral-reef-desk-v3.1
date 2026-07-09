class_name RescueSystem
extends RefCounted

const CONFIG_PATH: String = "res://data/rescue_config.json"
const POOL_PATH: String = "res://data/species_rescue_pool.json"
const RNG_MOD: int = 2147483647
const RNG_MULT: int = 1103515245
const RNG_INC: int = 12345

var initialized: bool = false
var config: Dictionary = {}
var species_pool: Array[Dictionary] = []
var dock_state: Dictionary = {}
var active_rescue: Dictionary = {}
var completed_rescues: Array[Dictionary] = []
var codex_rescue_marks: Dictionary = {}
var ecological_reputation: int = 0
var total_release_rp_reward: int = 0
var release_reward_sum_reputation: int = 0
var event_log: Array[Dictionary] = []
var load_errors: Array[String] = []
var _rng_state: int = 1


func initialize(seed: int = 1401) -> void:
	load_errors.clear()
	config = _load_json_dict(CONFIG_PATH)
	species_pool = _load_json_array(POOL_PATH)
	_rng_state = max(seed, 1)
	dock_state = {
		"next_arrival": int(config.get("dock", {}).get("first_arrival_day", 1)),
		"current_rescue_id": "",
		"rng_seed": _rng_state,
	}
	active_rescue = {}
	completed_rescues.clear()
	codex_rescue_marks.clear()
	ecological_reputation = 0
	total_release_rp_reward = 0
	release_reward_sum_reputation = 0
	event_log.clear()
	initialized = true


func process_day(day: int, water_quality_score: float, comfort_score: float, auto_accept: bool = true) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if species_pool.is_empty():
		return events
	if String(dock_state.get("current_rescue_id", "")).is_empty() and day >= int(dock_state.get("next_arrival", 1)):
		var candidate: Dictionary = _generate_candidate(day)
		dock_state["current_rescue_id"] = String(candidate.get("rescue_id", ""))
		dock_state["candidate"] = candidate
		events.append({"day": day, "type": "dock_arrival", "rescue_id": candidate.get("rescue_id", ""), "species_id": candidate.get("species_id", "")})
	if auto_accept and active_rescue.is_empty() and not String(dock_state.get("current_rescue_id", "")).is_empty():
		var accepted: Dictionary = accept_current_rescue(day)
		if bool(accepted.get("success", false)):
			events.append({"day": day, "type": "rescue_accept", "rescue_id": accepted.get("rescue_id", ""), "species_id": accepted.get("species_id", "")})
	if not active_rescue.is_empty():
		var recovery_event: Dictionary = _advance_recovery(day, water_quality_score, comfort_score)
		if not recovery_event.is_empty():
			events.append(recovery_event)
	for ev in events:
		event_log.append(ev.duplicate(true))
	return events


func accept_current_rescue(day: int) -> Dictionary:
	if not active_rescue.is_empty():
		return {"success": false, "error": "rescue_slot_occupied"}
	var raw_candidate: Variant = dock_state.get("candidate", {})
	if not raw_candidate is Dictionary:
		return {"success": false, "error": "no_candidate"}
	var candidate: Dictionary = raw_candidate.duplicate(true)
	if candidate.is_empty():
		return {"success": false, "error": "no_candidate"}
	candidate["rescue_status"] = "recovering"
	candidate["recovery_progress"] = 0.0
	candidate["rescued_at_day"] = day
	candidate["is_rescue"] = true
	active_rescue = candidate
	dock_state["current_rescue_id"] = ""
	dock_state.erase("candidate")
	_schedule_next_arrival(day)
	return {"success": true, "rescue_id": active_rescue.get("rescue_id", ""), "species_id": active_rescue.get("species_id", "")}


func force_start_rescue_for_test(species_id: String, day: int) -> Dictionary:
	for raw in species_pool:
		if String(raw.get("id", "")) == species_id:
			active_rescue = _build_rescue_entry(raw, day)
			active_rescue["rescue_status"] = "recovering"
			active_rescue["recovery_progress"] = 0.0
			return active_rescue.duplicate(true)
	return {}


func export_state() -> Dictionary:
	return {
		"schema_version": 1,
		"dock_state": dock_state.duplicate(true),
		"active_rescue": active_rescue.duplicate(true),
		"completed_rescues": completed_rescues.duplicate(true),
		"codex_rescue_marks": codex_rescue_marks.duplicate(true),
		"ecological_reputation": ecological_reputation,
		"total_release_rp_reward": total_release_rp_reward,
		"release_reward_sum_reputation": release_reward_sum_reputation,
		"event_log": event_log.duplicate(true),
		"rng_state": _rng_state,
	}


func import_state(state: Dictionary) -> void:
	dock_state = _default_dock_state()
	var raw_dock: Variant = state.get("dock_state", {})
	if raw_dock is Dictionary:
		for key in raw_dock.keys():
			dock_state[key] = raw_dock[key]
	active_rescue = {}
	var raw_active: Variant = state.get("active_rescue", {})
	if raw_active is Dictionary:
		active_rescue = raw_active.duplicate(true)
	completed_rescues = []
	var raw_completed: Variant = state.get("completed_rescues", [])
	if raw_completed is Array:
		for item in raw_completed:
			if item is Dictionary:
				completed_rescues.append(item.duplicate(true))
	codex_rescue_marks = {}
	var raw_codex: Variant = state.get("codex_rescue_marks", {})
	if raw_codex is Dictionary:
		codex_rescue_marks = raw_codex.duplicate(true)
	ecological_reputation = int(state.get("ecological_reputation", 0))
	total_release_rp_reward = int(state.get("total_release_rp_reward", 0))
	release_reward_sum_reputation = int(state.get("release_reward_sum_reputation", ecological_reputation))
	event_log = []
	var raw_events: Variant = state.get("event_log", [])
	if raw_events is Array:
		for ev in raw_events:
			if ev is Dictionary:
				event_log.append(ev.duplicate(true))
	_rng_state = int(state.get("rng_state", dock_state.get("rng_seed", 1)))
	dock_state["rng_seed"] = _rng_state


func get_debug_state() -> Dictionary:
	return {
		"initialized": initialized,
		"dock_state": dock_state.duplicate(true),
		"active_rescue": active_rescue.duplicate(true),
		"completed_rescue_count": completed_rescues.size(),
		"completed_rescues": completed_rescues.duplicate(true),
		"codex_rescue_marks": codex_rescue_marks.duplicate(true),
		"ecological_reputation": ecological_reputation,
		"total_release_rp_reward": total_release_rp_reward,
		"release_reward_sum_reputation": release_reward_sum_reputation,
		"event_log": event_log.duplicate(true),
		"load_errors": load_errors.duplicate(),
	}


func _advance_recovery(day: int, water_quality_score: float, comfort_score: float) -> Dictionary:
	var base_rate: float = float(active_rescue.get("recovery_rate_base", 0.0))
	var recovery_cfg: Dictionary = config.get("recovery", {})
	var comfort_ref: float = float(recovery_cfg.get("comfort_reference", 80.0))
	var water_ref: float = float(recovery_cfg.get("water_quality_reference", 85.0))
	var comfort_mod: float = clamp(comfort_score / max(comfort_ref, 1.0), float(recovery_cfg.get("comfort_modifier_min", 0.45)), float(recovery_cfg.get("comfort_modifier_max", 1.35)))
	var water_mod: float = clamp(water_quality_score / max(water_ref, 1.0), float(recovery_cfg.get("water_modifier_min", 0.50)), float(recovery_cfg.get("water_modifier_max", 1.20)))
	var delta: float = base_rate * comfort_mod * water_mod
	active_rescue["recovery_progress"] = min(float(active_rescue.get("recovery_progress", 0.0)) + delta, 100.0)
	active_rescue["last_recovery_delta"] = delta
	active_rescue["last_comfort_score"] = comfort_score
	active_rescue["last_water_quality_score"] = water_quality_score
	if float(active_rescue.get("recovery_progress", 0.0)) >= 100.0:
		return _release_active_rescue(day)
	return {"day": day, "type": "recovery_tick", "rescue_id": active_rescue.get("rescue_id", ""), "recovery_progress": active_rescue.get("recovery_progress", 0.0), "delta": delta}


func _release_active_rescue(day: int) -> Dictionary:
	var released: Dictionary = active_rescue.duplicate(true)
	released["rescue_status"] = "released"
	released["released_at_day"] = day
	released["recovery_progress"] = 100.0
	var rep: int = int(released.get("reward_reputation", 0))
	var rp: int = int(released.get("reward_rp", 0))
	ecological_reputation += rep
	release_reward_sum_reputation += rep
	total_release_rp_reward += rp
	codex_rescue_marks[String(released.get("species_id", ""))] = {"rescued": true, "last_released_day": day}
	completed_rescues.append(released)
	active_rescue = {}
	return {"day": day, "type": "release", "rescue_id": released.get("rescue_id", ""), "species_id": released.get("species_id", ""), "reward_reputation": rep, "reward_rp": rp}


func _generate_candidate(day: int) -> Dictionary:
	var idx: int = _rand_range(0, species_pool.size() - 1)
	return _build_rescue_entry(species_pool[idx], day)


func _build_rescue_entry(species: Dictionary, day: int) -> Dictionary:
	var sequence: int = event_log.size() + completed_rescues.size() + 1
	return {
		"rescue_id": "rescue_%d_%d" % [day, sequence],
		"species_id": String(species.get("id", "")),
		"species_name": String(species.get("species_name", "")),
		"category": String(species.get("category", "fish")),
		"is_rescue": true,
		"rescue_status": "waiting",
		"recovery_progress": 0.0,
		"recovery_rate_base": float(species.get("recovery_rate_base", 20.0)),
		"rescued_at_day": 0,
		"injury_type": String(species.get("injury_type", "reserved")),
		"reward_reputation": int(species.get("reward_reputation", 0)),
		"reward_rp": int(species.get("reward_rp", 0)),
		"water_pressure": float(species.get("water_pressure", 0.0)),
	}


func _schedule_next_arrival(day: int) -> void:
	var dock_cfg: Dictionary = config.get("dock", {})
	var min_days: int = int(dock_cfg.get("arrival_interval_min_days", 2))
	var max_days: int = int(dock_cfg.get("arrival_interval_max_days", 4))
	dock_state["next_arrival"] = day + _rand_range(min_days, max_days)
	dock_state["rng_seed"] = _rng_state


func _rand_range(min_value: int, max_value: int) -> int:
	_rng_state = int((int(_rng_state) * RNG_MULT + RNG_INC) % RNG_MOD)
	if max_value <= min_value:
		return min_value
	return min_value + int(_rng_state % int(max_value - min_value + 1))


func _default_dock_state() -> Dictionary:
	return {
		"next_arrival": int(config.get("dock", {}).get("first_arrival_day", 1)),
		"current_rescue_id": "",
		"rng_seed": _rng_state,
	}


func _load_json_dict(path: String) -> Dictionary:
	var parsed: Variant = _load_json(path)
	if parsed is Dictionary:
		return parsed
	load_errors.append("JSON dictionary expected: " + path)
	return {}


func _load_json_array(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var parsed: Variant = _load_json(path)
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				result.append(item)
		return result
	load_errors.append("JSON array expected: " + path)
	return result


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing rescue data file: " + path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open rescue data file: " + path)
		return null
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse rescue data file: " + path)
	return parsed
