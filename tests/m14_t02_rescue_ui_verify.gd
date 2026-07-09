extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []
var _first_loop_seconds: float = 0.0


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
		printerr("[M14-T02] FAIL: ", label)


func _run_tests() -> void:
	print("[M14-T02] Rescue first playable UI verification start")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var PanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	var StatusPanelScript = load("res://scenes/ui/StatusPanel.gd")
	var LivestockPanelScript = load("res://scenes/ui/LivestockPanel.gd")
	_assert(GameStateScript != null, "LOAD.1 GameState loads")
	_assert(PanelScript != null, "LOAD.2 RescueDockPanel loads")
	_assert(StatusPanelScript != null, "LOAD.3 StatusPanel loads")
	_assert(LivestockPanelScript != null, "LOAD.4 LivestockPanel loads")
	if GameStateScript == null or PanelScript == null or StatusPanelScript == null or LivestockPanelScript == null:
		return
	_test_player_flow(GameStateScript, PanelScript)
	_test_status_panel_binding(GameStateScript, StatusPanelScript)
	_test_save_restart_ui_consistency(GameStateScript, PanelScript, LivestockPanelScript)


func _test_player_flow(GameStateScript, PanelScript) -> void:
	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()
	var state: Dictionary = gs.get_rescue_ui_state()
	_assert(bool(state.get("has_candidate", false)), "FLOW.1 dock has real RescueSystem candidate")

	var panel = PanelScript.new()
	panel.setup(gs)
	panel.update_display()
	_assert(panel.candidate_label.text.find("待救助") >= 0, "FLOW.2 dock panel displays candidate")
	_assert(panel.bring_back_btn.disabled == false, "FLOW.3 bring-back button enabled when slot empty and RP enough")

	var accepted: Dictionary = gs.bring_back_current_rescue()
	panel.update_display()
	_assert(bool(accepted.get("success", false)), "FLOW.4 bring-back calls RescueSystem and succeeds")
	state = gs.get_rescue_ui_state()
	_assert(bool(state.get("has_active", false)), "FLOW.5 unique rescue slot occupied")
	_assert(panel.slot_label.text.find("唯一救助位") >= 0 and panel.slot_label.text.find("恢复中") >= 0, "FLOW.6 rescue slot UI shows recovering")

	var elapsed: float = 0.0
	var ready: bool = false
	while elapsed <= 920.0:
		gs._update_rescue_playable(10.0)
		elapsed += 10.0
		state = gs.get_rescue_ui_state()
		if bool(state.get("ready_to_release", false)):
			ready = true
			break
	_first_loop_seconds = elapsed
	panel.update_display()
	print("[M14-T02] first loop probe progress=%.2f target=%.0f" % [float(state.get("recovery_progress", 0.0)), float(state.get("target_recovery_seconds", 0.0))])
	_assert(ready, "FLOW.7 rescue becomes ready to release")
	_assert(elapsed >= 600.0 and elapsed <= 900.0, "FLOW.8 first loop duration within 10-15 minutes (%.0fs)" % elapsed)
	_assert(panel.release_btn.disabled == false, "FLOW.9 release button enabled at 100 percent")

	var rep_before: int = int(state.get("ecological_reputation", 0))
	var rp_before: float = float(state.get("reef_points", 0.0))
	var release: Dictionary = gs.release_ready_rescue()
	panel.update_display()
	state = gs.get_rescue_ui_state()
	_assert(bool(release.get("success", false)), "FLOW.10 release calls RescueSystem settlement")
	_assert(not bool(state.get("has_active", true)), "FLOW.11 rescue slot clears after release")
	_assert(int(state.get("ecological_reputation", 0)) > rep_before, "FLOW.12 ecological reputation increases")
	_assert(float(state.get("reef_points", 0.0)) > rp_before, "FLOW.13 small RP reward increases balance")
	_assert(not Dictionary(state.get("codex_rescue_marks", {})).is_empty(), "FLOW.14 codex rescued mark appears")
	_assert(panel.feedback_label.text.find("放归成功") >= 0, "FLOW.15 settlement feedback shown")


func _test_status_panel_binding(GameStateScript, StatusPanelScript) -> void:
	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()
	var status_panel = StatusPanelScript.new()
	status_panel._ready()
	status_panel.configure_dock_controls([], [], gs.get_device_state(), {"rescue": Callable()}, false)
	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_assert(status_panel.rescue_button != null and status_panel.rescue_button.text.find("码头") >= 0, "BIND.1 dock entry exists")
	_assert(status_panel.rescue_button.text.find("*") >= 0, "BIND.2 dock entry shows pending rescue")
	gs.bring_back_current_rescue()
	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_assert(status_panel.rescue_button.tooltip_text.find("占用") >= 0, "BIND.3 dock entry shows rescue in progress")
	while not bool(gs.get_rescue_ui_state().get("ready_to_release", false)):
		gs._update_rescue_playable(30.0)
	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_assert(status_panel.rescue_button.text.find("放归") >= 0, "BIND.4 dock entry shows ready to release")
	gs.release_ready_rescue()
	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_assert(status_panel.rescue_reputation_label.text.find("生态声望") >= 0 and status_panel.rescue_reputation_label.text.find("0") < 0, "BIND.5 reputation display updates")


func _test_save_restart_ui_consistency(GameStateScript, PanelScript, LivestockPanelScript) -> void:
	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()
	gs.bring_back_current_rescue()
	gs._update_rescue_playable(120.0)
	var saved_rescue: Dictionary = gs.rescue_system.export_state()
	var saved_economy: Dictionary = gs.economy_system.export_state()

	var reloaded = GameStateScript.new()
	reloaded.initialize()
	reloaded.rescue_system.import_state(saved_rescue)
	reloaded.economy_system.import_state(saved_economy)
	reloaded.reef_points = reloaded.economy_system.get_reef_points()
	var panel = PanelScript.new()
	panel.setup(reloaded)
	panel.update_display()
	var state: Dictionary = reloaded.get_rescue_ui_state()
	_assert(bool(state.get("has_active", false)), "SAVEUI.1 reloaded UI still shows occupied rescue slot")
	_assert(float(state.get("recovery_progress", 0.0)) > 0.0, "SAVEUI.2 reloaded UI keeps recovery progress")

	while not bool(reloaded.get_rescue_ui_state().get("ready_to_release", false)):
		reloaded._update_rescue_playable(30.0)
	reloaded.release_ready_rescue()
	var saved_after_release: Dictionary = reloaded.rescue_system.export_state()
	var saved_economy_after_release: Dictionary = reloaded.economy_system.export_state()
	var reloaded_final = GameStateScript.new()
	reloaded_final.initialize()
	reloaded_final.rescue_system.import_state(saved_after_release)
	reloaded_final.economy_system.import_state(saved_economy_after_release)
	reloaded_final.reef_points = reloaded_final.economy_system.get_reef_points()
	var final_state: Dictionary = reloaded_final.get_rescue_ui_state()
	_assert(not bool(final_state.get("has_active", true)), "SAVEUI.3 reloaded post-release UI shows empty slot")
	_assert(int(final_state.get("ecological_reputation", 0)) > 0, "SAVEUI.4 reputation persists after restart")
	_assert(not Dictionary(final_state.get("codex_rescue_marks", {})).is_empty(), "SAVEUI.5 rescued codex mark persists")

	var livestock_panel = LivestockPanelScript.new()
	livestock_panel.setup(reloaded_final)
	livestock_panel.update_display()
	_assert(livestock_panel.rescue_codex_label.text.find("已救助") >= 0, "SAVEUI.6 livestock/codex area shows rescued badge")


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M14-T02 Rescue UI: %d/%d" % [_passed, _passed + _failed])
	print("  first_loop_duration_seconds=%.0f" % _first_loop_seconds)
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  M14_T02_RESCUE_FIRST_PLAYABLE_RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
