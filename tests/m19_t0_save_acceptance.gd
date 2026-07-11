extends SceneTree
# M19-T0 Save Schema v4 Acceptance

var _pass := 0
var _fail := 0

func _init() -> void:
	print("M19-T0 Save Schema v4 Acceptance")
	run_checks()
	print("M19_T0_SAVE_ASSERTIONS_TOTAL=%d" % (_pass + _fail))
	print("M19_T0_SAVE_ASSERTIONS_PASSED=%d" % _pass)
	print("M19_T0_SAVE_ASSERTIONS_FAILED=%d" % _fail)
	print("M19_T0_SAVE_ACCEPTANCE_RESULT=%s" % ("PASS" if _fail == 0 else "FAIL"))
	quit(0 if _fail == 0 else 1)

func _new_ss() -> Variant:
	var ss_class = load("res://scripts/systems/SaveSystem.gd")
	return ss_class.new()

func run_checks() -> void:
	_check("T0-02 v3 migration preserves RP to waves_balance 1:1", _test_v3_rp())
	_check("T0-02 v3 migration backfills collection from codex", _test_v3_collection())
	_check("T0-02 v3 migration sets save_version=4", _test_v3_version())
	_check("T0-04 empty save gets safe defaults", _test_empty_defaults())
	_check("T0-05 missing fields get defaults", _test_missing_fields())
	_check("T0-06 extra fields preserved", _test_extra_fields())
	_check("T0-07 bad wave type fixed", _test_bad_wave_type())
	_check("T0-07 bad collection type fixed", _test_bad_collection_type())
	_check("T0-12 migration idempotent on waves_balance", _test_idempotent_waves())
	_check("T0-12 migration idempotent on collection", _test_idempotent_collection())
	_check("T0-15 blue_guardian defaults inactive", _test_bg_default())
	_check("T0-14 release_total_count from completed_rescues", _test_release_count())

func _test_v3_rp() -> bool:
	var ss = _new_ss(); ss.initialize()
	var d: Dictionary = {"save_version": 3, "economy": {"reef_points": 250.0, "total_reef_points_earned": 500.0}}
	var m: Dictionary = ss.migrate_save_data(d)
	return abs(float(m.get("waves_balance", -1.0)) - 250.0) < 0.01

func _test_v3_collection() -> bool:
	var ss = _new_ss(); ss.initialize()
	var d: Dictionary = {"save_version": 3, "rescue_data": {"codex_rescue_marks": {"rescue_clownfish_juvenile": {"rescued": true}, "rescue_goby": {"rescued": true}}, "completed_rescues": [], "dock_state": {}, "active_rescue": {}, "ecological_reputation": 0, "total_release_rp_reward": 0, "release_reward_sum_reputation": 0, "rng_state": 1401, "event_log": []}}
	var m: Dictionary = ss.migrate_save_data(d)
	var col: Array = m.get("collection_unlocked_species_ids", [])
	return col.size() == 2

func _test_v3_version() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3})
	return int(m.get("save_version", 0)) == 4

func _test_empty_defaults() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({})
	return m.has("waves_balance") and m.has("blue_guardian_state") and m.has("collection_unlocked_species_ids")

func _test_missing_fields() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3})
	return m.has("waves_balance") and m.has("discovered_postcard_ids") and m.has("recent_release_record_ids")

func _test_extra_fields() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3, "custom_future_field": "hello"})
	return str(m.get("custom_future_field", "")) == "hello"

func _test_bad_wave_type() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3, "waves_balance": "bad_string"})
	return m.get("waves_balance") is float

func _test_bad_collection_type() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3, "collection_unlocked_species_ids": "not_array"})
	return m.get("collection_unlocked_species_ids") is Array

func _test_idempotent_waves() -> bool:
	var ss = _new_ss(); ss.initialize()
	var d: Dictionary = {"save_version": 3, "economy": {"reef_points": 100.0}}
	var m1: Dictionary = ss.migrate_save_data(d)
	var m2: Dictionary = ss.migrate_save_data(m1)
	return abs(float(m1.get("waves_balance", 0)) - float(m2.get("waves_balance", 0))) < 0.01

func _test_idempotent_collection() -> bool:
	var ss = _new_ss(); ss.initialize()
	var d: Dictionary = {"save_version": 3, "rescue_data": {"codex_rescue_marks": {"a": {}}, "completed_rescues": [], "dock_state": {}, "active_rescue": {}, "ecological_reputation": 0, "total_release_rp_reward": 0, "release_reward_sum_reputation": 0, "rng_state": 1401, "event_log": []}}
	var m1: Dictionary = ss.migrate_save_data(d)
	var m2: Dictionary = ss.migrate_save_data(m1)
	return m1.get("collection_unlocked_species_ids", []).size() == m2.get("collection_unlocked_species_ids", []).size()

func _test_bg_default() -> bool:
	var ss = _new_ss(); ss.initialize()
	var m: Dictionary = ss.migrate_save_data({"save_version": 3})
	var bg: Dictionary = m.get("blue_guardian_state", {})
	return not bool(bg.get("active", true))

func _test_release_count() -> bool:
	var ss = _new_ss(); ss.initialize()
	var d: Dictionary = {"save_version": 3, "rescue_data": {"completed_rescues": [{"species_id": "a"}, {"species_id": "b"}, {"species_id": "a"}], "codex_rescue_marks": {}, "dock_state": {}, "active_rescue": {}, "ecological_reputation": 0, "total_release_rp_reward": 0, "release_reward_sum_reputation": 0, "rng_state": 1401, "event_log": []}}
	var m: Dictionary = ss.migrate_save_data(d)
	return int(m.get("release_total_count", 0)) == 3

func _check(name: String, ok: bool) -> void:
	if ok: _pass += 1; print("  PASS: %s" % name)
	else: _fail += 1; print("  FAIL: %s" % name)
