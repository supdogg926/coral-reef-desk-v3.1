extends SceneTree

const RNG_MOD: int = 2147483647
const RNG_MULT: int = 1103515245
const RNG_INC: int = 12345

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []
var _baseline_result: String = "FAIL"
var _rng_result: String = "FAIL"
var _migration_result: String = "FAIL"


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append("FAIL: " + label)
		printerr("[M15-T01] FAIL: ", label)


func _run_tests() -> void:
	print("[M15-T01] Care model headless verification start")
	var RescueScript = load("res://scripts/systems/RescueSystem.gd")
	var SaveScript = load("res://scripts/systems/SaveSystem.gd")
	_assert(RescueScript != null, "LOAD.1 RescueSystem loads")
	_assert(SaveScript != null, "LOAD.2 SaveSystem loads")
	if RescueScript == null or SaveScript == null:
		return
	_test_config_shape()
	_test_no_care_baseline_bit_equivalence(RescueScript)
	_test_care_multipliers(RescueScript)
	_test_one_care_per_rescue(RescueScript)
	_test_save_v2_to_v3_migration(SaveScript)
	_test_rng_determinism(RescueScript)
	_test_screenshot_check_template_exists()


func _test_config_shape() -> void:
	var cfg: Dictionary = _load_json_dict("res://data/rescue_config.json")
	var recovery: Dictionary = cfg.get("recovery", {})
	var playable: Dictionary = cfg.get("first_playable", {})
	var care: Dictionary = cfg.get("care", {})
	_assert(care.has("needs") and care.has("actions"), "CFG.1 care needs/actions configured")
	_assert(care.has("effect_matrix"), "CFG.2 care effect_matrix configured")
	_assert(float(care.get("multiplier_gain", 0.0)) == 0.5, "CFG.3 multiplier_gain is 0.5")
	_assert(int(care.get("care_bonus_rp", 0)) == 1, "CFG.4 care_bonus_rp is 1")
	_assert(float(recovery.get("comfort_reference", 0.0)) == 80.0, "CFG.5 M14 recovery comfort_reference unchanged")
	_assert(float(recovery.get("water_quality_reference", 0.0)) == 85.0, "CFG.6 M14 recovery water_quality_reference unchanged")
	_assert(float(playable.get("target_recovery_seconds", 0.0)) == 215.0, "CFG.7 M14 target_recovery_seconds unchanged")


func _test_no_care_baseline_bit_equivalence(RescueScript) -> void:
	var m15 = RescueScript.new()
	m15.initialize(1401)
	var baseline: Dictionary = _simulate_m14_baseline(1401, 30, 96.0, 96.0)
	var m15_progress: Array = []
	for day in range(1, 31):
		m15.process_day(day, 96.0, 96.0, true)
		m15_progress.append(_progress_probe(m15.export_state()))
	var m15_state: Dictionary = _strip_care_from_state(m15.export_state())
	var baseline_state: Dictionary = baseline.get("state", {})
	var event_equal: bool = JSON.stringify(m15_state.get("event_log", [])) == JSON.stringify(baseline_state.get("event_log", []))
	var rng_equal: bool = int(m15_state.get("rng_state", 0)) == int(baseline_state.get("rng_state", -1))
	var progress_equal: bool = JSON.stringify(m15_progress) == JSON.stringify(baseline.get("progress_trace", []))
	var completed_equal: bool = JSON.stringify(m15_state.get("completed_rescues", [])) == JSON.stringify(baseline_state.get("completed_rescues", []))
	_assert(event_equal, "BASE.1 no-care event_log equals M14 baseline")
	_assert(rng_equal, "BASE.2 no-care rng_state equals M14 baseline")
	_assert(progress_equal, "BASE.3 no-care recovery_progress trace equals M14 baseline")
	_assert(completed_equal, "BASE.4 no-care completed_rescues equals M14 baseline after stripping care_*")
	_baseline_result = "PASS" if event_equal and rng_equal and progress_equal and completed_equal else "FAIL"


func _test_care_multipliers(RescueScript) -> void:
	_assert(_care_case(RescueScript, "nutrition", 1.5, 143.0), "MULT.1 correct care multiplier/time")
	_assert(_care_case(RescueScript, "soothe", 1.25, 172.0), "MULT.2 partial care multiplier/time")
	_assert(_care_case(RescueScript, "purify", 1.1, 195.0), "MULT.3 wrong care multiplier/time")


func _care_case(RescueScript, action: String, expected_multiplier: float, expected_seconds: float) -> bool:
	var rescue = RescueScript.new()
	rescue.initialize(3101)
	rescue.force_start_rescue_for_test("rescue_clownfish_juvenile", 1)
	rescue.active_rescue["care_need"] = "weak"
	var result: Dictionary = rescue.apply_care(action)
	if not bool(result.get("success", false)):
		return false
	var multiplier_ok: bool = abs(float(result.get("care_multiplier", 0.0)) - expected_multiplier) <= 0.0001
	var seconds: int = _seconds_to_ready(rescue, 1)
	var seconds_ok: bool = abs(float(seconds) - expected_seconds) <= 1.0
	print("[M15-T01] care case action=%s multiplier=%.2f seconds=%d" % [action, float(result.get("care_multiplier", 0.0)), seconds])
	return multiplier_ok and seconds_ok


func _seconds_to_ready(rescue, day: int) -> int:
	var seconds: int = 0
	var base_rate: float = max(float(rescue.active_rescue.get("recovery_rate_base", 30.0)), 1.0)
	var scale: float = 1.0 / 215.0 * (100.0 / base_rate)
	while seconds <= 260:
		seconds += 1
		var event: Dictionary = rescue.advance_active_rescue_for_ui(day, 85.0, 80.0, scale)
		if String(event.get("type", "")) == "recovery_ready":
			return seconds
	return 999


func _test_one_care_per_rescue(RescueScript) -> void:
	var rescue = RescueScript.new()
	rescue.initialize(3201)
	rescue.force_start_rescue_for_test("rescue_clownfish_juvenile", 1)
	var first: Dictionary = rescue.apply_care("nutrition")
	var before: String = JSON.stringify(rescue.active_rescue)
	var second: Dictionary = rescue.apply_care("soothe")
	var after: String = JSON.stringify(rescue.active_rescue)
	_assert(bool(first.get("success", false)), "ONCE.1 first apply_care succeeds")
	_assert(not bool(second.get("success", true)) and String(second.get("error", "")) == "care_already_used", "ONCE.2 second apply_care returns care_already_used")
	_assert(before == after, "ONCE.3 second apply_care does not mutate state")


func _test_save_v2_to_v3_migration(SaveScript) -> void:
	var save_system = SaveScript.new()
	save_system.initialize()
	var old_active: Dictionary = {
		"rescue_id": "rescue_7_2",
		"species_id": "rescue_clownfish_juvenile",
		"rescue_status": "recovering",
		"recovery_progress": 42.0,
		"recovery_rate_base": 30.0,
	}
	var v2_save: Dictionary = {
		"save_version": 2,
		"last_save_unix_time": 100,
		"player": {"reputation": 0},
		"economy": {},
		"water_chemistry": {},
		"time": {},
		"unlocks": {},
		"livestock": {},
		"equipment": {},
		"rescue_data": {
			"dock_state": {"next_arrival": 9, "current_rescue_id": "", "rng_seed": 123},
			"active_rescue": old_active,
			"completed_rescues": [],
			"codex_rescue_marks": {},
			"rng_state": 123,
		},
	}
	var migrated_a: Dictionary = save_system.migrate_save_data(v2_save)
	var migrated_b: Dictionary = save_system.migrate_save_data(v2_save)
	var active_a: Dictionary = migrated_a.get("rescue_data", {}).get("active_rescue", {})
	var active_b: Dictionary = migrated_b.get("rescue_data", {}).get("active_rescue", {})
	var idempotent: Dictionary = save_system.migrate_save_data(migrated_a)
	var active_idem: Dictionary = idempotent.get("rescue_data", {}).get("active_rescue", {})
	var ok: bool = true
	ok = ok and int(migrated_a.get("save_version", 0)) == 3
	ok = ok and String(active_a.get("care_need", "")) != ""
	ok = ok and bool(active_a.get("care_used", true)) == false
	ok = ok and String(active_a.get("care_action_taken", "x")) == ""
	ok = ok and float(active_a.get("care_score", -1.0)) == 0.0
	ok = ok and String(active_a.get("care_need", "")) == String(active_b.get("care_need", ""))
	ok = ok and JSON.stringify(active_a) == JSON.stringify(active_idem)
	_assert(ok, "MIG.1 v2 active_rescue migrates to v3 care fields and is idempotent")
	_migration_result = "PASS" if ok else "FAIL"


func _test_rng_determinism(RescueScript) -> void:
	var rescue = RescueScript.new()
	rescue.initialize(1401)
	var before_rng: int = int(rescue.export_state().get("rng_state", 0))
	rescue.process_day(1, 96.0, 96.0, false)
	var after_candidate_rng: int = int(rescue.export_state().get("rng_state", 0))
	var expected_after_candidate: int = _lcg(before_rng)
	var dock: Dictionary = rescue.export_state().get("dock_state", {})
	var candidate: Dictionary = dock.get("candidate", {})
	var has_care_need: bool = String(candidate.get("care_need", "")) != ""
	var next_arrivals_m15: Array = _collect_m15_next_arrivals(RescueScript, 1401)
	var next_arrivals_base: Array = _simulate_m14_baseline(1401, 30, 96.0, 96.0).get("next_arrivals", [])
	var rng_ok: bool = after_candidate_rng == expected_after_candidate
	var arrival_ok: bool = JSON.stringify(next_arrivals_m15) == JSON.stringify(next_arrivals_base)
	_assert(has_care_need, "RNG.1 candidate care_need derived")
	_assert(rng_ok, "RNG.2 care_need derivation does not consume _rng_state")
	_assert(arrival_ok, "RNG.3 next_arrival sequence equals M14 baseline")
	_rng_result = "PASS" if has_care_need and rng_ok and arrival_ok else "FAIL"


func _test_screenshot_check_template_exists() -> void:
	var path: String = "res://tests/run_m15_t01_acceptance.ps1"
	if not FileAccess.file_exists(path):
		_assert(false, "SHOT.1 M15-T01 runner exists for screenshot check template")
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var has_width_check: bool = text.find("MinWidth") >= 0 and text.find("800") >= 0
	var has_variance_check: bool = text.find("pixel variance") >= 0 or text.find("PixelVariance") >= 0
	_assert(has_width_check and has_variance_check, "SHOT.1 screenshot resolution/variance check function present")


func _collect_m15_next_arrivals(RescueScript, seed: int) -> Array:
	var rescue = RescueScript.new()
	rescue.initialize(seed)
	var arrivals: Array = []
	for day in range(1, 31):
		var before: int = int(rescue.export_state().get("dock_state", {}).get("next_arrival", 0))
		rescue.process_day(day, 96.0, 96.0, true)
		var after: int = int(rescue.export_state().get("dock_state", {}).get("next_arrival", 0))
		if after != before:
			arrivals.append(after)
	return arrivals


func _simulate_m14_baseline(seed: int, days: int, water: float, comfort: float) -> Dictionary:
	var cfg: Dictionary = _load_json_dict("res://data/rescue_config.json")
	var pool: Array = _load_json_array("res://data/species_rescue_pool.json")
	var rng_state: int = max(seed, 1)
	var dock_state: Dictionary = {"next_arrival": int(cfg.get("dock", {}).get("first_arrival_day", 1)), "current_rescue_id": "", "rng_seed": rng_state}
	var active: Dictionary = {}
	var completed: Array = []
	var event_log: Array = []
	var codex: Dictionary = {}
	var ecological_reputation: int = 0
	var total_release_rp_reward: int = 0
	var release_reward_sum_reputation: int = 0
	var progress_trace: Array = []
	var next_arrivals: Array = []
	for day in range(1, days + 1):
		if String(dock_state.get("current_rescue_id", "")).is_empty() and day >= int(dock_state.get("next_arrival", 1)):
			rng_state = _lcg(rng_state)
			var idx: int = int(rng_state % pool.size())
			var candidate: Dictionary = _build_m14_entry(pool[idx], day, event_log.size() + completed.size() + 1)
			dock_state["current_rescue_id"] = String(candidate.get("rescue_id", ""))
			dock_state["candidate"] = candidate
			event_log.append({"day": day, "type": "dock_arrival", "rescue_id": candidate.get("rescue_id", ""), "species_id": candidate.get("species_id", "")})
		if active.is_empty() and not String(dock_state.get("current_rescue_id", "")).is_empty():
			active = Dictionary(dock_state.get("candidate", {})).duplicate(true)
			active["rescue_status"] = "recovering"
			active["recovery_progress"] = 0.0
			active["rescued_at_day"] = day
			active["is_rescue"] = true
			dock_state["current_rescue_id"] = ""
			dock_state.erase("candidate")
			rng_state = _lcg(rng_state)
			var dock_cfg: Dictionary = cfg.get("dock", {})
			var min_days: int = int(dock_cfg.get("arrival_interval_min_days", 2))
			var max_days: int = int(dock_cfg.get("arrival_interval_max_days", 4))
			dock_state["next_arrival"] = day + min_days + int(rng_state % int(max_days - min_days + 1))
			dock_state["rng_seed"] = rng_state
			next_arrivals.append(int(dock_state.get("next_arrival", 0)))
			event_log.append({"day": day, "type": "rescue_accept", "rescue_id": active.get("rescue_id", ""), "species_id": active.get("species_id", "")})
		if not active.is_empty():
			var recovery_cfg: Dictionary = cfg.get("recovery", {})
			var comfort_ref: float = float(recovery_cfg.get("comfort_reference", 80.0))
			var water_ref: float = float(recovery_cfg.get("water_quality_reference", 85.0))
			var comfort_mod: float = clamp(comfort / max(comfort_ref, 1.0), float(recovery_cfg.get("comfort_modifier_min", 0.45)), float(recovery_cfg.get("comfort_modifier_max", 1.35)))
			var water_mod: float = clamp(water / max(water_ref, 1.0), float(recovery_cfg.get("water_modifier_min", 0.50)), float(recovery_cfg.get("water_modifier_max", 1.20)))
			var delta: float = float(active.get("recovery_rate_base", 0.0)) * comfort_mod * water_mod
			active["recovery_progress"] = min(float(active.get("recovery_progress", 0.0)) + delta, 100.0)
			active["last_recovery_delta"] = delta
			active["last_comfort_score"] = comfort
			active["last_water_quality_score"] = water
			if float(active.get("recovery_progress", 0.0)) >= 100.0:
				var released: Dictionary = active.duplicate(true)
				released["rescue_status"] = "released"
				released["released_at_day"] = day
				released["recovery_progress"] = 100.0
				var rep: int = int(released.get("reward_reputation", 0))
				var rp: int = int(released.get("reward_rp", 0))
				ecological_reputation += rep
				release_reward_sum_reputation += rep
				total_release_rp_reward += rp
				codex[String(released.get("species_id", ""))] = {"rescued": true, "last_released_day": day}
				completed.append(released)
				active = {}
				event_log.append({"day": day, "type": "release", "rescue_id": released.get("rescue_id", ""), "species_id": released.get("species_id", ""), "reward_reputation": rep, "reward_rp": rp})
			else:
				event_log.append({"day": day, "type": "recovery_tick", "rescue_id": active.get("rescue_id", ""), "recovery_progress": active.get("recovery_progress", 0.0), "delta": delta})
		progress_trace.append(_progress_probe({"active_rescue": active}))
	return {
		"state": {
			"schema_version": 1,
			"dock_state": dock_state,
			"active_rescue": active,
			"completed_rescues": completed,
			"codex_rescue_marks": codex,
			"ecological_reputation": ecological_reputation,
			"total_release_rp_reward": total_release_rp_reward,
			"release_reward_sum_reputation": release_reward_sum_reputation,
			"event_log": event_log,
			"rng_state": rng_state,
		},
		"progress_trace": progress_trace,
		"next_arrivals": next_arrivals,
	}


func _build_m14_entry(species: Dictionary, day: int, sequence: int) -> Dictionary:
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


func _strip_care_from_state(state: Dictionary) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	result["active_rescue"] = _strip_care_from_entry(result.get("active_rescue", {}))
	var completed: Array = []
	for item in result.get("completed_rescues", []):
		if item is Dictionary:
			completed.append(_strip_care_from_entry(item))
	result["completed_rescues"] = completed
	return result


func _strip_care_from_entry(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var result: Dictionary = Dictionary(entry).duplicate(true)
	result.erase("care_need")
	result.erase("care_used")
	result.erase("care_action_taken")
	result.erase("care_score")
	result.erase("care_bonus_rp")
	return result


func _progress_probe(state: Dictionary) -> Variant:
	var active: Dictionary = state.get("active_rescue", {}) if state.get("active_rescue", {}) is Dictionary else {}
	if active.is_empty():
		return null
	return float(active.get("recovery_progress", 0.0))


func _lcg(state: int) -> int:
	return int((int(state) * RNG_MULT + RNG_INC) % RNG_MOD)


func _load_json_dict(path: String) -> Dictionary:
	var parsed: Variant = _load_json(path)
	return parsed if parsed is Dictionary else {}


func _load_json_array(path: String) -> Array:
	var parsed: Variant = _load_json(path)
	return parsed if parsed is Array else []


func _load_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(text)


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M15-T01 CareModel: %d/%d" % [_passed, _passed + _failed])
	print("  BASELINE_BIT_EQUIVALENCE=%s" % _baseline_result)
	print("  RNG_DETERMINISM=%s" % _rng_result)
	print("  V2_TO_V3_MIGRATION=%s" % _migration_result)
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  M15_T01_CAREMODEL_RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
