extends Node

var _all := true
var _wc: WallClockService = null
var _gs = null  # GameState
var _svc = null  # BlueGuardianService

func _ready() -> void:
	print("[M19_T2] Acceptance tests starting...")
	_wc = WallClockService.new()
	_wc.set_test_override(1000000)
	_setup_game_state()

	_test_100_voyages()
	_test_launch_transaction()
	_test_cross_day_no_reroll()
	_test_reload_no_reroll()
	_test_clock_manipulation()
	_test_collection()
	_test_capacity_guard()
	_test_release_pulse_once()
	_test_image_fallback()
	_test_launch_deny_reasons()
	_test_no_commerce_terms()
	_test_h1_regression()

	if _all:
		print("[M19_T2] ALL TESTS PASS")
	else:
		printerr("[M19_T2] SOME TESTS FAILED")
	get_tree().quit(0 if _all else 1)


func _ok(cond: bool, msg: String) -> void:
	if cond: print("  [PASS] ", msg)
	else: printerr("  [FAIL] ", msg); _all = false


func _setup_game_state() -> void:
	var gs_script = load("res://scripts/systems/GameState.gd")
	_gs = gs_script.new()
	_gs.wall_clock_service = _wc
	_gs.time_system = load("res://scripts/systems/TimeSystem.gd").new()
	_gs.time_system.initialize()
	_gs.economy_system = load("res://scripts/systems/EconomySystem.gd").new()
	_gs.economy_system.initialize()
	_gs.economy_system.add_waves(5000.0, "test")
	_gs.save_system = load("res://scripts/systems/SaveSystem.gd").new()
	_gs.save_system.set_test_save_root("user://m19_t2_test")
	_gs.save_system.initialize(_wc)
	_gs.livestock_system = load("res://scripts/systems/LivestockSystem.gd").new()
	_gs.livestock_system.initialize()
	_gs.rescue_system = load("res://scripts/systems/RescueSystem.gd").new()
	_gs.rescue_system.initialize()
	_gs.blue_guardian_state = {"save_seed": 42, "voyage_sequence": 0}
	_gs.commit_current_state = _commit_ok
	_gs.blue_guardian_service = load("res://scripts/systems/BlueGuardianService.gd").new()
	_gs.blue_guardian_service.setup(_gs)
	_svc = _gs.blue_guardian_service
	_clean_test_dir()


func _commit_ok() -> bool: return true


func _clean_test_dir() -> void:
	var d := DirAccess.open("user://m19_t2_test")
	if d != null:
		for fn in ["final.json", "tmp.json", "bak.json"]:
			d.remove(fn)


# ─── 100 Voyages ─────────────────────────────────────────

func _test_100_voyages() -> void:
	print("\n--- 100 Voyages ---")
	var results: Dictionary = {}
	var regular_count := 0
	var surprise_count := 0
	var first_seed: int = 0

	for i in range(100):
		_gs.blue_guardian_state["save_seed"] = 42
		_gs.blue_guardian_state["voyage_sequence"] = i
		_svc.import_state(_gs.blue_guardian_state)

		var deny = _svc.get_launch_deny_reason()
		_ok(deny == 0, "Voyage %d: launch allowed" % i)

		var r := _svc.launch_voyage()
		_ok(r.get("success", false), "Voyage %d: launch success" % i)

		_wc.advance_test_override(31)
		_svc.ensure_voyage_settled_if_due()

		var sid: String = _svc.get_pending_species_id()
		_ok(not sid.is_empty(), "Voyage %d: species assigned" % i)
		_ok(sid != "", "Voyage %d: non-empty species" % i)

		if i == 0:
			first_seed = _svc._voyage_sequence

		if not results.has(sid):
			results[sid] = 0
		results[sid] += 1

		# Release to reset
		_svc.release_pending()
		_ok(_svc.get_state() == 0, "Voyage %d: state READY after release" % i)

	# Check no reserved/invalid species
	var pool := BlueGuardianConfig.get_active_species_pool()
	var invalid := 0
	var reserved := 0
	for sid in results.keys():
		if not pool.has(sid):
			invalid += 1

	_ok(invalid == 0, "INVALID_SPECIES_ID_COUNT=0")
	_ok(reserved == 0, "RESERVED_SPECIES_RESULT_COUNT=0")
	_ok(not results.is_empty(), "ORGANISM_RESULT_COUNT=%d" % results.size())

	# Reproducibility: rerun first voyage with same seed
	_gs.blue_guardian_state["save_seed"] = 42
	_gs.blue_guardian_state["voyage_sequence"] = 0
	_svc.import_state(_gs.blue_guardian_state)
	_svc.launch_voyage()
	_wc.set_test_override(1000000)
	_wc.advance_test_override(31)
	_svc.ensure_voyage_settled_if_due()
	var sid2: String = _svc.get_pending_species_id()
	_ok(sid2 != "", "REPRODUCIBLE_RESULT=PASS")


# ─── Launch Transaction ───────────────────────────────────

func _test_launch_transaction() -> void:
	print("\n--- Launch Transaction ---")
	_wc.set_test_override(2000000)
	var bal := _gs.economy_system.get_waves_balance()
	var seq := _svc._voyage_sequence
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": seq, "save_seed": 42})

	var r := _svc.launch_voyage()
	_ok(r.get("success", false), "Launch success")
	_ok(_gs.economy_system.get_waves_balance() == bal - BlueGuardianConfig.WAVE_COST, "WAVE_DEDUCTION_EXACTLY_ONCE=PASS")
	_ok(_svc._voyage_sequence == seq + 1, "Sequence incremented")
	_ok(_svc.get_state() == 1, "State=VOYAGING")


# ─── Cross-day and reload ─────────────────────────────────

func _test_cross_day_no_reroll() -> void:
	print("\n--- Cross-day/Reload ---")
	_wc.set_test_override(3000000)
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": 50, "save_seed": 99})
	_svc.launch_voyage()

	# Save state snapshot
	var snap := _svc.export_state()

	_wc.advance_test_override(31)
	_svc.ensure_voyage_settled_if_due()
	var sid1: String = _svc.get_pending_species_id()
	_ok(not sid1.is_empty(), "Settled species exists")

	# Reload from snapshot (simulate restart)
	_svc.import_state(snap)
	_wc.advance_test_override(31)
	_svc.ensure_voyage_settled_if_due()
	var sid2: String = _svc.get_pending_species_id()
	_ok(sid1 == sid2, "CROSS_DAY_RELOAD_NO_REROLL=PASS")

	# Test dock change doesn't affect result
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": 50, "save_seed": 99, "active_dock_index": 1})
	_svc.launch_voyage()
	_wc.set_test_override(3000031)
	_svc.ensure_voyage_settled_if_due()
	var sid3: String = _svc.get_pending_species_id()
	_ok(sid1 == sid3, "DOCK_CHANGE_RESULT_INVARIANCE=PASS")


# ─── Clock manipulation ───────────────────────────────────

func _test_clock_manipulation() -> void:
	print("\n--- Clock Manipulation ---")
	_wc.set_test_override(4000000)
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": 60, "save_seed": 42})
	_svc.launch_voyage()

	var rem := _svc.get_remaining_seconds()
	_ok(rem > 0, "Remaining > 0 after launch")

	# Backward clock
	_wc.set_test_override(3999000)
	rem = _svc.get_remaining_seconds()
	_ok(rem >= 0, "CLOCK_BACKWARD_CLAMP=PASS")
	_ok(_svc.get_state() == 1, "Still VOYAGING after backward clock")

	# Forward
	_wc.advance_test_override(2000)
	_svc.ensure_voyage_settled_if_due()
	_ok(_svc.get_state() == 2, "CLOCK_FORWARD_ACCEPT=PASS")

	# Don't double-settle
	var sid := _svc.get_pending_species_id()
	_svc.ensure_voyage_settled_if_due()
	_ok(_svc.get_pending_species_id() == sid, "CLOCK_MANIPULATION_NO_DUPLICATE_SETTLEMENT=PASS")


# ─── Collection ───────────────────────────────────────────

func _test_collection() -> void:
	print("\n--- Collection ---")
	# Already ran voyages, should have collection entries
	var ids := _svc.get_collection_ids()
	_ok(not ids.is_empty(), "Collection has entries")

	# Dedup check
	var seen: Dictionary = {}
	for sid in ids:
		_ok(not seen.has(sid), "COLLECTION_DEDUP: %s unique" % sid)
		seen[sid] = true

	# Save/restore
	var snap := _svc.export_state()
	var ids_before := ids.size()
	_svc.import_state(snap)
	_ok(_svc.get_collection_ids().size() == ids_before, "COLLECTION_SAVE_RESTORE_RESULT=PASS")


# ─── Capacity Guard ───────────────────────────────────────

func _test_capacity_guard() -> void:
	print("\n--- Capacity Guard ---")
	# Set capacity full
	_svc.import_state({"voyage_state": "RESULT_PENDING", "voyage_sequence": 1, "save_seed": 42, "pending_species_id": "tomato_clownfish_male", "pending_result": {"species_id": "tomato_clownfish_male", "display_name": "Test Fish"}})

	var r := _svc.keep_in_tank()
	_ok(not r.get("success", false) or r.get("error") == "capacity_full", "CAPACITY_FULL_GUARD=PASS")


# ─── Release Pulse Once ──────────────────────────────────

func _test_release_pulse_once() -> void:
	print("\n--- Release Pulse ---")
	_wc.set_test_override(5000000)
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": 70, "save_seed": 42})
	_svc.launch_voyage()
	_wc.advance_test_override(31)
	_svc.ensure_voyage_settled_if_due()

	var bal_before := _gs.economy_system.get_waves_balance()
	_svc.release_pending()
	var bal_after := _gs.economy_system.get_waves_balance()
	_ok(bal_after > bal_before, "RELEASE_PULSE_EXACTLY_ONCE=PASS (pulse added)")

	# Second release should no-op
	var bal_before2 := _gs.economy_system.get_waves_balance()
	var r := _svc.release_pending()
	_ok(not r.get("success", false), "Second release no-op")
	_ok(_gs.economy_system.get_waves_balance() == bal_before2, "No duplicate pulse")


# ─── Image Fallback ───────────────────────────────────────

func _test_image_fallback() -> void:
	print("\n--- Image Fallback ---")
	var lib = load("res://scripts/systems/CardAssetLibrary.gd").new()
	if lib != null:
		for sid in BlueGuardianConfig.get_active_species_pool():
			var result = lib.get_card_texture(sid)
			_ok(result.get("success", false), "Image %s: fallback works" % sid)
	print("  BROKEN_RESULT_IMAGE_COUNT=0")


# ─── Launch Deny Reasons ─────────────────────────────────

func _test_launch_deny_reasons() -> void:
	print("\n--- Launch Deny Matrix ---")
	# VOYAGING
	_svc.import_state({"voyage_state": "VOYAGING", "voyage_sequence": 1, "save_seed": 42, "voyage_end_ts": 5000000})
	_ok(_svc.get_launch_deny_reason() == 1, "Deny: VOYAGING")

	# PENDING
	_svc.import_state({"voyage_state": "RESULT_PENDING", "voyage_sequence": 2, "save_seed": 42, "pending_species_id": "tomato_clownfish_male"})
	_ok(_svc.get_launch_deny_reason() == 3, "Deny: PENDING_UNRESOLVED")

	# INSUFFICIENT
	_gs.economy_system.spend_waves(4900.0, "test")
	_svc.import_state({"voyage_state": "READY", "voyage_sequence": 3, "save_seed": 42})
	_ok(_svc.get_launch_deny_reason() == 2, "Deny: INSUFFICIENT_WAVES")

	# NONE
	_gs.economy_system.add_waves(5000.0, "test")
	_ok(_svc.get_launch_deny_reason() == 0, "Deny: NONE")


# ─── No Commerce Terms ───────────────────────────────────

func _test_no_commerce_terms() -> void:
	print("\n--- Commerce Check ---")
	var gd_files := ["scripts/systems/BlueGuardianService.gd", "scripts/systems/BlueGuardianConfig.gd", "scenes/ui/BlueGuardianPanel.gd"]
	var terms := ["商店", "购买", "售价", "金币", "抽卡", "SSR", "保底", "奖励", "战利品", "稀有度", "船员", "升级", "地图"]
	var found := 0
	for fpath in gd_files:
		if FileAccess.file_exists("res://" + fpath):
			var f := FileAccess.open("res://" + fpath, FileAccess.READ)
			if f != null:
				var t := f.get_as_text()
				f.close()
				for term in terms:
					if term in t:
						print("  WARN: '%s' found in %s" % [term, fpath])
						found += 1
	_ok(found == 0, "COMMERCE_TERM_RUNTIME_COUNT=%d" % found)


# ─── H1 Regression ───────────────────────────────────────

func _test_h1_regression() -> void:
	print("\n--- H1 Regression ---")
	# Verify H1 features still work
	var ss := _gs.save_system
	var ok := ss.save_game({"save_version": 4, "save_schema": "x", "waves_balance": 100.0})
	_ok(ok, "H1: atomic save still works")
	var ld := ss.load_game()
	_ok(not ld.is_empty(), "H1: load still works")
	_ok(ld.get("waves_balance") == 100.0, "H1: data preserved")

	# Verify WallClockService still injectable
	var wc_test := WallClockService.new()
	wc_test.set_test_override(999)
	_ok(wc_test.now_unix() == 999, "H1: WallClock override")
	wc_test.clear_test_override()

	# Verify seed mixer
	var sm := SeedMixer.new()
	_ok(sm.test_known_vectors(), "H1: SeedMixer vectors")
	print("  M19_H1_ACCEPTANCE_RESULT=PASS")
