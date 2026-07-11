extends RefCounted
class_name DynamicEventSystem

const EVENTS_PATH := "res://data/events/dynamic_events_seed.json"

enum Phase {INACTIVE, WARNING, ACTIVE, RECOVERY, RESOLVED, COOLDOWN}

var events: Array[Dictionary] = []
var events_by_id: Dictionary = {}
var current_event_id: String = ""
var current_phase: int = Phase.INACTIVE
var current_severity: int = 1
var remaining_days: int = 0
var cooldown_remaining_days: int = 0
var response_flags: Dictionary = {}
var cumulative_damage_ratio: float = 0.0
var initialized: bool = false
var load_errors: Array[String] = []
var _active_device_off_days: int = 0
var _rng_seed: int = 12345
var _rng_state: int = 12345


func initialize(p_seed: int = 12345) -> void:
	_rng_seed = p_seed
	_rng_state = p_seed
	load_events()


func load_events(path: String = EVENTS_PATH) -> void:
	events.clear()
	events_by_id.clear()
	if not FileAccess.file_exists(path):
		load_errors.append("Event data file not found: " + path)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not (parsed is Array):
		load_errors.append("Event data is not an array")
		return
	for item in parsed:
		if not (item is Dictionary):
			continue
		var eid: String = str(item.get("event_id", ""))
		if eid == "": continue
		if String(item.get("runtime_status", "")) != "active": continue
		if not bool(item.get("enabled", false)): continue
		events.append(item)
		events_by_id[eid] = item
	initialized = true


func get_current_event() -> Dictionary:
	if current_event_id == "" or not events_by_id.has(current_event_id):
		return {}
	return events_by_id[current_event_id].duplicate()


func get_event_phase() -> int:
	return current_phase


func get_event_remaining_days() -> int:
	return remaining_days


func get_event_warning() -> String:
	var event: Dictionary = get_current_event()
	if event.is_empty(): return ""
	var templates: Dictionary = event.get("timeline_templates", {})
	return str(templates.get("warning", ""))


func get_available_responses() -> Array:
	var event: Dictionary = get_current_event()
	if event.is_empty(): return []
	var responses: Array = event.get("player_responses", [])
	var result: Array = []
	for r in responses:
		if not (r is Dictionary): continue
		var rid: String = str(r.get("response_id", ""))
		var used: int = int(response_flags.get(rid, 0))
		var max_use: int = int(r.get("cooldown_per_event", 1))
		if used < max_use:
			var resp_copy: Dictionary = r.duplicate()
			resp_copy["available"] = true
			result.append(resp_copy)
	return result


func apply_event_response(response_id: String) -> Dictionary:
	if current_phase != Phase.WARNING and current_phase != Phase.ACTIVE:
		return {"success": false, "reason": "wrong_phase"}
	var event: Dictionary = get_current_event()
	if event.is_empty(): return {"success": false, "reason": "no_event"}
	var responses: Array = event.get("player_responses", [])
	var found: Dictionary = {}
	for r in responses:
		if str(r.get("response_id", "")) == response_id:
			found = r
			break
	if found.is_empty(): return {"success": false, "reason": "response_not_found"}
	var used: int = int(response_flags.get(response_id, 0))
	var max_use: int = int(found.get("cooldown_per_event", 1))
	if used >= max_use: return {"success": false, "reason": "already_used"}
	response_flags[response_id] = used + 1
	var multiplier: float = float(found.get("effect_multiplier", 1.0))
	cumulative_damage_ratio = clamp(cumulative_damage_ratio * multiplier, 0.05, 1.0)
	return {
		"success": true,
		"response_id": response_id,
		"display_name": str(found.get("display_name", response_id)),
		"effect_multiplier": multiplier,
		"rp_cost": int(found.get("rp_cost", 0)),
		"income_penalty_days": int(found.get("income_penalty_days", 0)),
		"cumulative_damage_ratio": cumulative_damage_ratio,
	}


func get_device_mitigation(device_id: String) -> Dictionary:
	var event: Dictionary = get_current_event()
	if event.is_empty(): return {"mitigation_multiplier": 1.0, "mitigation_pct": 0}
	var mitigations: Dictionary = event.get("device_mitigations", {})
	if not mitigations.has(device_id): return {"mitigation_multiplier": 1.0, "mitigation_pct": 0}
	var mit: Dictionary = mitigations[device_id]
	return {
		"mitigation_multiplier": float(mit.get("tier1_multiplier", 1.0)),
		"tier2_multiplier": float(mit.get("tier2_multiplier", 1.0)),
		"severity_reduction": float(mit.get("severity_reduction", 0.0)),
		"mitigation_pct": int((1.0 - float(mit.get("tier1_multiplier", 1.0))) * 100),
	}


func advance_event_day() -> Dictionary:
	if current_phase == Phase.INACTIVE or current_event_id == "":
		return {"action": "none"}

	var event: Dictionary = get_current_event()
	if event.is_empty(): return {"action": "none"}

	if _active_device_off_days > 0:
		_active_device_off_days -= 1

	remaining_days -= 1

	var result: Dictionary = {"action": "tick", "event_id": current_event_id, "phase": current_phase, "remaining_days": remaining_days}

	if current_phase == Phase.WARNING and remaining_days <= 0:
		current_phase = Phase.ACTIVE
		remaining_days = int(event.get("active_days", 2))
		result["phase_transition"] = "WARNING->ACTIVE"
	elif current_phase == Phase.ACTIVE:
		cumulative_damage_ratio = clamp(cumulative_damage_ratio + 0.15, 0.0, 1.0)
		if remaining_days <= 0:
			current_phase = Phase.RECOVERY
			remaining_days = int(event.get("recovery_days", 1))
			result["phase_transition"] = "ACTIVE->RECOVERY"
	elif current_phase == Phase.RECOVERY and remaining_days <= 0:
		resolve_event()
		result["phase_transition"] = "RECOVERY->RESOLVED"
		result["resolution"] = get_event_resolution()
	elif current_phase == Phase.COOLDOWN:
		cooldown_remaining_days -= 1
		if cooldown_remaining_days <= 0:
			current_phase = Phase.INACTIVE
			current_event_id = ""
			response_flags.clear()
			cumulative_damage_ratio = 0.0
			result["phase_transition"] = "COOLDOWN->INACTIVE"

	return result


func resolve_event() -> void:
	var event: Dictionary = get_current_event()
	if event.is_empty(): return
	current_phase = Phase.COOLDOWN
	cooldown_remaining_days = int(event.get("cooldown_days", 5))


func get_event_resolution() -> Dictionary:
	var event: Dictionary = get_current_event()
	if event.is_empty(): return {"result": "unknown"}
	var rules: Dictionary = event.get("recovery_rules", {})
	var good: float = float(rules.get("good_threshold", 0.30))
	var neutral: float = float(rules.get("neutral_threshold", 0.60))

	if cumulative_damage_ratio <= good:
		return {
			"result": "GOOD",
			"reward_rp": int(rules.get("good_reward_rp", 10)),
			"stability_recovery": float(rules.get("good_stability_recovery", 3.0)),
		}
	elif cumulative_damage_ratio <= neutral:
		return {"result": "NEUTRAL", "reward_rp": 0, "stability_recovery": 0}
	else:
		return {
			"result": "POOR",
			"extra_recovery_days": int(rules.get("poor_extra_recovery_days", 1)),
			"income_penalty": int(rules.get("poor_income_penalty", 10)),
		}


func try_trigger_event(current_state: Dictionary) -> Dictionary:
	if current_phase != Phase.INACTIVE: return {"triggered": false, "reason": "event_in_progress"}
	if cooldown_remaining_days > 0: return {"triggered": false, "reason": "in_cooldown"}

	var day: int = int(current_state.get("day", 1))
	var rng: int = int(current_state.get("rng_seed", _rng_seed))
	var no3: float = float(current_state.get("no3", 3.0))
	var po4: float = float(current_state.get("po4", 0.04))
	var comfort: float = float(current_state.get("comfort", 75.0))
	var stability: float = float(current_state.get("stability", 50.0))
	var maint_pressure: int = int(current_state.get("maintenance_pressure", 0))
	var bio_load: float = float(current_state.get("bio_load_ratio", 0.3))
	var recent_event_type: String = str(current_state.get("last_event_category", ""))

	var candidates: Array = []
	var total_weight: float = 0.0

	for event in events:
		var eligible_day: int = int(event.get("eligible_from_day", 1))
		if day < eligible_day: continue
		var weight: float = float(event.get("base_weight", 1.0))

		var modifiers: Dictionary = event.get("state_pressure_modifiers", {})
		if modifiers.has("high_no3") and no3 > 10.0: weight *= float(modifiers["high_no3"])
		if modifiers.has("high_po4") and po4 > 0.08: weight *= float(modifiers["high_po4"])
		if modifiers.has("low_comfort") and comfort < 55.0: weight *= float(modifiers["low_comfort"])
		if modifiers.has("low_stability") and stability < 40.0: weight *= float(modifiers["low_stability"])
		if modifiers.has("high_bio_load") and bio_load > 0.6: weight *= float(modifiers["high_bio_load"])
		if modifiers.has("high_maintenance_pressure") and maint_pressure >= 3: weight *= float(modifiers["high_maintenance_pressure"])

		var cat: String = str(event.get("category", ""))
		if recent_event_type == cat and modifiers.has("recent_event"):
			weight *= float(modifiers["recent_event"])

		if weight > 0:
			candidates.append({"event": event, "weight": weight})
			total_weight += weight

	if candidates.is_empty() or total_weight <= 0: return {"triggered": false, "reason": "no_eligible_events"}

	# Weighted random selection using simple RNG
	_rng_state = (_rng_state * 1103515245 + 12345) & 0x7fffffff
	var roll: float = float(_rng_state % 10000) / 10000.0 * total_weight
	var cumulative: float = 0.0
	var selected: Dictionary = {}
	for c in candidates:
		cumulative += float(c["weight"])
		if roll <= cumulative:
			selected = c["event"]
			break
	if selected.is_empty(): selected = candidates[0]["event"]

	current_event_id = str(selected.get("event_id", ""))
	current_phase = Phase.WARNING
	remaining_days = int(selected.get("warning_days", 1))
	response_flags.clear()
	cumulative_damage_ratio = 0.0

	var sev_min: int = int(selected.get("severity_min", 1))
	var sev_max: int = int(selected.get("severity_max", 1))
	current_severity = sev_min if sev_min == sev_max else (sev_min + (_rng_state % (sev_max - sev_min + 1)))

	return {"triggered": true, "event_id": current_event_id, "phase": "WARNING", "remaining_days": remaining_days, "severity": current_severity}


func get_event_effects_for_tick() -> Dictionary:
	var event: Dictionary = get_current_event()
	if event.is_empty() or current_phase != Phase.ACTIVE: return {}
	var effects: Dictionary = event.get("base_effects", {}).duplicate()
	# Apply cumulative damage ratio
	for key in effects.keys():
		if typeof(effects[key]) == TYPE_FLOAT or typeof(effects[key]) == TYPE_INT:
			effects[key] = float(effects[key]) * cumulative_damage_ratio
	return effects


func get_debug_state() -> Dictionary:
	return {
		"initialized": initialized,
		"current_event_id": current_event_id,
		"phase": current_phase,
		"remaining_days": remaining_days,
		"cooldown_remaining_days": cooldown_remaining_days,
		"severity": current_severity,
		"cumulative_damage_ratio": cumulative_damage_ratio,
		"event_count": events.size(),
		"load_errors": load_errors.duplicate(),
	}


func export_state() -> Dictionary:
	return {
		"current_event_id": current_event_id,
		"phase": current_phase,
		"remaining_days": remaining_days,
		"cooldown_remaining_days": cooldown_remaining_days,
		"severity": current_severity,
		"response_flags": response_flags.duplicate(),
		"cumulative_damage_ratio": cumulative_damage_ratio,
	}


func import_state(state: Dictionary) -> void:
	current_event_id = str(state.get("current_event_id", ""))
	current_phase = int(state.get("phase", Phase.INACTIVE))
	remaining_days = int(state.get("remaining_days", 0))
	cooldown_remaining_days = int(state.get("cooldown_remaining_days", 0))
	current_severity = int(state.get("severity", 1))
	var raw_flags: Variant = state.get("response_flags", {})
	response_flags = raw_flags if raw_flags is Dictionary else {}
	cumulative_damage_ratio = float(state.get("cumulative_damage_ratio", 0.0))
