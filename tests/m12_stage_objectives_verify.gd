extends SceneTree

## M12 Stage Objectives Verification
## Validates: objective initialization, progression tracking, completion conditions

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []


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
		printerr("[M12] FAIL: ", label)


const STAGE_OBJ_SCRIPT = preload("res://scripts/systems/StageObjectiveSystem.gd")

func _run_tests() -> void:
	print("[M12] Stage Objectives Verification Start")
	var sys = STAGE_OBJ_SCRIPT.new()
	sys.initialize()

	# Test 1: Initialization
	_assert(sys.get_completed_count() == 0, "1.1 Initial completed count is 0")
	_assert(sys.get_total_count() == 6, "1.2 Total count is 6")
	var active: Dictionary = sys.get_active_objective()
	_assert(not active.is_empty(), "1.3 Active objective exists")
	_assert(String(active.get("id", "")) == "buy_first_creature", "1.4 First objective is buy_first_creature")

	# Test 2: First objective completion - buy creature
	sys.check_progress({"livestock_count": 1, "comfort_score": 100.0, "devices_running": true, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys.get_completed_count() == 1, "2.1 buy_first_creature completed (livestock_count >= 1)")

	# Test 3: Observe comfort (triggered after purchase)
	sys.set_initial_comfort(100.0)
	sys.check_progress({"livestock_count": 1, "comfort_score": 95.0, "devices_running": true, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys.get_objective_state("observe_comfort") == 2, "3.1 observe_comfort completed when comfort differs from initial")
	# (observe_comfort completed in previous step — single trigger)

	# Test 4: Enable device
	_assert(sys.get_objective_state("enable_device") == 2, "4.1 enable_device auto-completed (devices already running)")
	sys.check_progress({"livestock_count": 1, "comfort_score": 94.3, "devices_running": true, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys.get_objective_state("enable_device") == 2, "4.2 enable_device completed (devices_running=true)")

	# Test 5: Perform maintenance
	sys.check_progress({"livestock_count": 1, "comfort_score": 94.3, "devices_running": true, "maintenance_count": 1, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys.get_objective_state("perform_maintenance") == 2, "5.1 perform_maintenance completed")

	# Test 6: Restore water quality
	sys.check_progress({"livestock_count": 1, "comfort_score": 94.3, "devices_running": true, "maintenance_count": 1, "water_quality_score": 85.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys.get_objective_state("restore_water_quality") == 2, "6.1 restore_water_quality completed (score >= 80)")

	# Test 7: Accumulate RP
	sys.set_initial_rp(0.0)
	sys.check_progress({"livestock_count": 1, "comfort_score": 94.3, "devices_running": true, "maintenance_count": 1, "water_quality_score": 85.0, "total_rp_earned": 250.0, "current_rp": 250.0})
	_assert(sys.get_objective_state("accumulate_rp") == 2, "7.1 accumulate_rp completed (RP >= 200)")

	# Test 8: All completed
	_assert(sys.get_completed_count() == 6, "8.1 All 6 objectives completed")
	var debug: Dictionary = sys.get_debug_state()
	_assert(bool(debug.get("all_completed", false)), "8.2 all_completed flag is true")

	# Test 9: Export/Import
	var exported: Dictionary = sys.export_state()
	var sys2 = STAGE_OBJ_SCRIPT.new()
	sys2.initialize()
	sys2.import_state(exported)
	_assert(sys2.get_completed_count() == 6, "9.1 Import preserves completed count")
	_assert(sys2.get_objective_state("buy_first_creature") == 2, "9.2 Import preserves objective states")

	# Test 10: Device not running - objective not completed
	var sys3 = STAGE_OBJ_SCRIPT.new()
	sys3.initialize()
	sys3.check_progress({"livestock_count": 0, "comfort_score": 100.0, "devices_running": false, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
	_assert(sys3.get_objective_state("buy_first_creature") == 1, "10.1 buy_first_creature stays active without creatures")


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M12 Stage Objectives: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		print("  FAILED:")
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
