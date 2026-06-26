extends SceneTree

## M12 Reset Visual Regression Verification
## Validates: GameState reset hygiene, StatusPanel button dedup, label integrity.

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
		printerr("[M12_RESET_VISUAL] FAIL: ", label)


func _run_tests() -> void:
	print("[M12_RESET_VISUAL] Reset Visual Regression Start")

	# === PART 1: GameState clean reset (no save interference) ===
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	_assert(GameStateScript != null, "RV.1 GameState.gd loads")
	if GameStateScript == null:
		return

	var gs = GameStateScript.new()
	gs.initialize()
	_assert(gs.initialized, "RV.2 GameState initializes")

	var so_debug = gs.get_stage_objective_debug_state()
	_assert(not so_debug.is_empty(), "RV.3 StageObjectiveSystem present")
	_assert(so_debug.get("total_count", 0) == 6, "RV.4 6 objectives total")

	# Simulate reset: create fresh GameState
	var gs2 = GameStateScript.new()
	gs2.initialize()
	_assert(gs2.initialized, "RV.5 Reset GameState initializes")
	var so2 = gs2.get_stage_objective_debug_state()
	_assert(so2.get("completed_count", 0) == 0, "RV.6 Reset: 0 objectives completed")

	# Third reset
	var gs3 = GameStateScript.new()
	gs3.initialize()
	_assert(gs3.initialized, "RV.7 Third reset initializes")
	var so3 = gs3.get_stage_objective_debug_state()
	_assert(so3.get("completed_count", 0) == 0, "RV.8 Third reset: 0 completed")

	# === PART 2: StatusPanel button dedup on re-configure ===
	var StatusPanelScript = load("res://scenes/ui/StatusPanel.gd")
	_assert(StatusPanelScript != null, "RV.9 StatusPanel.gd loads")

	if StatusPanelScript != null:
		var panel = StatusPanelScript.new()
		get_root().add_child(panel)
		# Force ready notification if not triggered by scene tree
		if panel.get_child_count() == 0:
			panel._ready()
		OS.delay_msec(50)

		# First configure
		var actions: Array = [
			{"id": "water_change_10", "label": "换水10%", "short_label": "换水", "cost": 20.0, "description": "换水降低NO3/PO4"},
			{"id": "clean_filter", "label": "清洁过滤", "short_label": "清滤", "cost": 15.0, "description": "恢复过滤效率"},
		]
		var feeds: Array = [
			{"id": "coral_food", "label": "喂珊瑚粮", "short_label": "喂珊瑚粮"},
		]
		var dev_state: Dictionary = {
			"devices": {
				"return_pump": {"device_id": "return_pump", "display_name": "水泵", "enabled": true},
				"wave_pump": {"device_id": "wave_pump", "display_name": "造浪", "enabled": true},
				"main_light": {"device_id": "main_light", "display_name": "主灯", "enabled": true},
			}
		}
		var cb: Dictionary = {
			"shop": Callable(),
			"livestock": Callable(),
			"maintenance": Callable(),
			"device": Callable(),
			"feed": Callable(),
			"save": Callable(),
			"reset": Callable(),
		}

		var result1: Dictionary = panel.configure_dock_controls(actions, feeds, dev_state, cb, true)
		var btns1: int = _count_buttons(panel)
		print("[M12_RESET_VISUAL] After first configure: %d buttons" % btns1)
		_assert(btns1 > 0, "RV.10 StatusPanel has buttons after first configure")

		# Second configure (simulates reset) — should NOT duplicate
		var result2: Dictionary = panel.configure_dock_controls(actions, feeds, dev_state, cb, true)
		var btns2: int = _count_buttons(panel)
		print("[M12_RESET_VISUAL] After second configure: %d buttons" % btns2)
		_assert(btns2 == btns1, "RV.11 Reset reconfigure: button count stable (%d vs %d)" % [btns1, btns2])

		# Check no duplicate button texts
		var dupes: Array = _find_dupes(panel)
		_assert(dupes.is_empty(), "RV.12 No duplicate button texts (found: %s)" % str(dupes))

		# Third configure
		var result3: Dictionary = panel.configure_dock_controls(actions, feeds, dev_state, cb, true)
		var btns3: int = _count_buttons(panel)
		_assert(btns3 == btns1, "RV.13 Third configure: button count stable (%d vs %d)" % [btns1, btns3])

		panel.queue_free()
		OS.delay_msec(50)

	# === PART 3: Stage objective label integrity ===
	var StageObjScript = load("res://scripts/systems/StageObjectiveSystem.gd")
	_assert(StageObjScript != null, "RV.14 StageObjectiveSystem.gd loads")
	if StageObjScript != null:
		var so = StageObjScript.new()
		so.initialize()
		var active: Dictionary = so.get_active_objective()
		var title: String = String(active.get("title", ""))
		_assert(not title.is_empty(), "RV.15 Active objective has title")
		_assert(title.length() < 30, "RV.16 Objective title fits in label (len=%d: %s)" % [title.length(), title])

		# Complete all and check final state
		# Sequential progress: objectives complete in order
		# Step 1: buy first creature
		so.check_progress({"livestock_count": 1, "comfort_score": 100.0, "devices_running": true, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
		# Step 2: comfort changes → observe_comfort triggers
		so.check_progress({"livestock_count": 1, "comfort_score": 93.0, "devices_running": true, "maintenance_count": 0, "water_quality_score": 100.0, "total_rp_earned": 0.0, "current_rp": 0.0})
		# Step 3: all conditions met → remaining objectives complete
		so.check_progress({"livestock_count": 1, "comfort_score": 93.0, "devices_running": true, "maintenance_count": 1, "water_quality_score": 85.0, "total_rp_earned": 250.0, "current_rp": 250.0})
		var all_debug: Dictionary = so.get_debug_state()
		_assert(bool(all_debug.get("all_completed", false)), "RV.17 All objectives can complete in sequence")


func _count_buttons(root: Node) -> int:
	var count: int = 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button:
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _find_dupes(root: Node) -> Array:
	var seen: Dictionary = {}
	var dupes: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button:
			var t: String = node.text
			if not t.is_empty():
				if t in seen:
					dupes.append(t)
				seen[t] = true
		for child in node.get_children():
			stack.append(child)
	return dupes


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M12 Reset Visual Regression: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		print("  FAILED:")
		for err in _errors:
			print("    ", err)
	print("  M12_RESET_VISUAL_RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
