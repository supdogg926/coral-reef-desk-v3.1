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
		printerr("[M15-T02] FAIL: ", label)


func _run_tests() -> void:
	print("[M15-T02] Care playable UI verification start")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var PanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	_assert(GameStateScript != null, "LOAD.1 GameState loads")
	_assert(PanelScript != null, "LOAD.2 RescueDockPanel loads")
	if GameStateScript == null or PanelScript == null:
		return
	_test_care_ui_first_loop(GameStateScript, PanelScript)


func _test_care_ui_first_loop(GameStateScript, PanelScript) -> void:
	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()

	var panel = PanelScript.new()
	panel.setup(gs)
	panel.update_display()
	_assert(panel.care_need_label != null, "UI.1 care need label exists")
	_assert(panel.nutrition_btn != null and panel.soothe_btn != null and panel.purify_btn != null, "UI.2 three care buttons exist")
	_assert(panel.nutrition_btn.text == "营养补给", "UI.3 nutrition button visible")
	_assert(panel.soothe_btn.text == "安抚照料", "UI.4 soothe button visible")
	_assert(panel.purify_btn.text == "净水护理", "UI.5 purify button visible")

	var accepted: Dictionary = gs.bring_back_current_rescue()
	panel.update_display()
	_assert(bool(accepted.get("success", false)), "FLOW.1 bring-back succeeds")
	var state: Dictionary = gs.get_rescue_ui_state()
	var care_need: String = String(state.get("care_need", ""))
	_assert(care_need in ["weak", "stressed", "minor_injury"], "FLOW.2 care_need visible in UI state")
	_assert(panel.care_need_label.text.find("护理需求") >= 0 and panel.care_need_label.text.find("每次救助只能护理一次") >= 0, "FLOW.3 care need copy visible")
	_assert(not panel.nutrition_btn.disabled and not panel.soothe_btn.disabled and not panel.purify_btn.disabled, "FLOW.4 care buttons enabled before care")

	var action: String = _best_action_for_need(care_need)
	_press_care_button(panel, action)
	panel.update_display()
	state = gs.get_rescue_ui_state()
	_assert(bool(state.get("care_used", false)), "FLOW.5 care_used updates after click")
	_assert(panel.nutrition_btn.disabled and panel.soothe_btn.disabled and panel.purify_btn.disabled, "FLOW.6 care buttons disabled after care")
	var feedback: Dictionary = state.get("last_feedback", {}) if state.get("last_feedback", {}) is Dictionary else {}
	_assert(String(feedback.get("summary", "")).find("恢复速度") >= 0, "FLOW.7 care feedback shown")

	var before_active: String = JSON.stringify(gs.rescue_system.get_debug_state().get("active_rescue", {}))
	var second: Dictionary = gs.apply_rescue_care(_different_action(action))
	var after_active: String = JSON.stringify(gs.rescue_system.get_debug_state().get("active_rescue", {}))
	_assert(not bool(second.get("success", true)) and String(second.get("error", "")) == "care_already_used", "FLOW.8 second care returns care_already_used")
	_assert(before_active == after_active, "FLOW.9 second care does not mutate state")

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
	_assert(ready, "FLOW.10 rescue becomes ready")
	_assert(elapsed <= 900.0, "FLOW.11 first loop duration <= 900s (%.0fs)" % elapsed)

	var released: Dictionary = gs.release_ready_rescue()
	state = gs.get_rescue_ui_state()
	var summary: String = String(released.get("summary", ""))
	_assert(bool(released.get("success", false)), "FLOW.12 release succeeds")
	_assert(summary.find("放归成功！") >= 0 and summary.find("已回归大海") >= 0 and summary.find("生态声望") >= 0 and summary.find("图鉴已标记救助") >= 0, "FLOW.13 M14 release copy preserved")
	_assert(summary.find("悉心照料加成 RP +1") >= 0, "FLOW.14 care bonus line appended")
	_assert(summary.find("评级") < 0 and summary.find("失败") < 0 and summary.find("普通放归") < 0, "FLOW.15 no explicit rating/failure copy")


func _press_care_button(panel, action: String) -> void:
	match action:
		"nutrition":
			panel.nutrition_btn.pressed.emit()
		"soothe":
			panel.soothe_btn.pressed.emit()
		"purify":
			panel.purify_btn.pressed.emit()


func _best_action_for_need(need: String) -> String:
	match need:
		"weak":
			return "nutrition"
		"stressed":
			return "soothe"
		"minor_injury":
			return "purify"
		_:
			return "nutrition"


func _different_action(action: String) -> String:
	if action != "nutrition":
		return "nutrition"
	return "soothe"


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M15-T02 Care UI: %d/%d" % [_passed, _passed + _failed])
	print("  first_loop_duration_seconds=%.0f" % _first_loop_seconds)
	if _failed > 0:
		for err in _errors:
			print("    ", err)
	print("  M15_T02_CARE_PLAYABLE_UI_RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
