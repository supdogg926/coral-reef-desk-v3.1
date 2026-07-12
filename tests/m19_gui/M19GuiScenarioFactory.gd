extends RefCounted
## M19 Deterministic Scenario Factory — builds product states via public API only

var _gs = null        # GameState
var _svc = null       # BlueGuardianService
var _wc = null        # WallClockService
var _ss = null        # SaveSystem
var _eco = null       # EconomySystem
var _livestock = null # LivestockSystem
var _rescue = null    # RescueSystem

const TEST_ROOT := "user://m19_scenario_test"


func setup(gs) -> void:
	_gs = gs
	_svc = gs.blue_guardian_service
	_wc = gs.wall_clock_service
	_ss = gs.save_system
	_eco = gs.economy_system
	_livestock = gs.livestock_system
	_rescue = gs.rescue_system
	_ss.set_test_save_root(TEST_ROOT)
	_ss.initialize(_wc)


func scenario_main() -> void:
	pass  # Main scene is already loaded


func scenario_ready() -> void:
	_wc.set_test_override(1000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 0, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)


func scenario_voyaging(seconds_remaining: int) -> void:
	var elapsed := 30 - seconds_remaining
	_wc.set_test_override(2000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 1, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(2000000 + elapsed)


func scenario_normal_result() -> void:
	_wc.set_test_override(3000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 2, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(3000031)
	_svc.ensure_voyage_settled_if_due()


func scenario_rare_result() -> void:
	_wc.set_test_override(4000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 7, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(4000031)
	_svc.ensure_voyage_settled_if_due()


func scenario_duplicate_result() -> void:
	# First voyage to get species
	_wc.set_test_override(5000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 0, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(5000031)
	_svc.ensure_voyage_settled_if_due()
	_svc.release_pending_result()
	# Second voyage with same seed — will get same species (duplicate)
	_wc.set_test_override(5000061)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 0, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(5000092)
	_svc.ensure_voyage_settled_if_due()


func scenario_catalog_overview() -> void:
	# Run multiple voyages to populate collection
	for i in range(5):
		_wc.set_test_override(6000000 + i * 100)
		_svc.import_state({"save_seed": 42, "voyage_sequence": 10 + i, "voyage_state": "READY"})
		_svc._set_test_commit_result(true)
		_svc.launch_voyage()
		_wc.set_test_override(6000000 + i * 100 + 31)
		_svc.ensure_voyage_settled_if_due()
		_svc.release_pending_result()


func scenario_keep_success() -> void:
	_livestock.used = 0.0
	_wc.set_test_override(7000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 20, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(7000031)
	_svc.ensure_voyage_settled_if_due()


func scenario_capacity_full() -> void:
	_livestock.used = 30.0  # at max capacity
	_wc.set_test_override(8000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 30, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(8000031)
	_svc.ensure_voyage_settled_if_due()


func scenario_wave_economy() -> void:
	_eco.balance = 5000.0
	_wc.set_test_override(9000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 40, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)


func scenario_save_restart() -> void:
	# Build rich state, save, then verify
	_eco.balance = 3456.0
	_wc.set_test_override(10000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 5, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	_wc.set_test_override(10000031)
	_svc.ensure_voyage_settled_if_due()
	# One keep
	_livestock.used = 0.0
	_svc.keep_pending_result()
	# Another voyage for pending
	_wc.set_test_override(10000000)
	_svc.import_state({"save_seed": 42, "voyage_sequence": 6, "voyage_state": "READY"})
	_svc._set_test_commit_result(true)
	_svc.launch_voyage()
	# Save state for restart test
	if _ss != null:
		_ss.save_game({"save_version": 4, "save_schema": "x", "waves_balance": _eco.balance,
			"blue_guardian_state": _svc.export_state(), "player": {}, "economy": {}, "water_chemistry": {},
			"time": {}, "unlocks": {}, "livestock": {}, "equipment": {}, "rescue_data": {},
			"collection_unlocked_species_ids": _svc.get_collection_ids(),
			"release_count_by_species": {}, "release_total_count": 1,
			"discovered_postcard_ids": [], "recent_release_record_ids": []})


func cleanup() -> void:
	if _wc != null: _wc.clear_test_override()
	if _ss != null:
		_ss.clear_save()
		_ss.clear_test_save_root()
