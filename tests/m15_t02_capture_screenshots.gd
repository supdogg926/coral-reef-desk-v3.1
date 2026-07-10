extends SceneTree

const SCREENSHOT_DIR: String = "res://reports/m15/screenshots"
const W: int = 960
const H: int = 540
const FIXED_CARE_NEED: String = "weak"
const FIXED_CARE_ACTION: String = "nutrition"
const FIXED_WATER_QUALITY: float = 40.0
const FIXED_COMFORT_SCORE: float = 40.0

var _saved: Array[String] = []
var _failed: bool = false
var _errors: Array[String] = []
var _background: ColorRect = null
var _panel = null
var _gs = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[M15-T02] viewport screenshot evidence generation start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	get_root().size = Vector2i(W, H)

	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var DockPanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	if GameStateScript == null or DockPanelScript == null:
		_fail("LOAD.1 scripts missing")
		_finish()
		return

	_gs = GameStateScript.new()
	_gs.initialize()
	_reset_to_clean_test_state(_gs)
	_gs.economy_system.add_reef_points(20.0)
	_gs.reef_points = _gs.economy_system.get_reef_points()
	_gs._ensure_rescue_dock_candidate()

	_background = ColorRect.new()
	_background.name = "M15ViewportCaptureBackground"
	_background.color = Color(0.035, 0.055, 0.065, 1.0)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(_background)

	_panel = DockPanelScript.new()
	_panel.name = "M15ViewportCaptureRescueDockPanel"
	_panel.position = Vector2(40, 24)
	_panel.custom_minimum_size = Vector2(880, 492)
	_panel.size = Vector2(880, 492)
	get_root().add_child(_panel)
	_panel.setup(_gs)
	_panel.update_display()
	await _capture_state("m15_t02_01_care_need_visible.png", "_assert_candidate_state")

	_gs.bring_back_current_rescue()
	_force_fixed_care_need()
	_panel.update_display()
	await _capture_state("m15_t02_02_three_care_buttons.png", "_assert_active_buttons_state")

	_panel.nutrition_btn.pressed.emit()
	_panel.update_display()
	await _capture_state("m15_t02_03_after_care_feedback.png", "_assert_after_care_state")

	var guard: int = 0
	while not bool(_gs.get_rescue_ui_state().get("ready_to_release", false)) and guard < 120:
		_advance_rescue_for_fixed_test_environment(10.0)
		guard += 1
	_panel.update_display()
	await _capture_state("m15_t02_04_ready_after_care.png", "_assert_ready_state")

	_gs.release_ready_rescue()
	_panel.update_display()
	await _capture_state("m15_t02_05_release_bonus_line.png", "_assert_release_state")

	print("[M15-T02] Screenshot capture complete: %d/5 saved" % _saved.size())
	print("M15_T02_VIEWPORT_CAPTURE_SOURCE=PASS")
	print("M15_T02_UI_SEMANTIC_ASSERTIONS=%s" % ("PASS" if _errors.is_empty() else "FAIL"))
	print("M15_T02_SCREENSHOT_CAPTURE_RESULT=%s" % ("PASS" if _saved.size() == 5 and not _failed else "FAIL"))
	_finish()


func _capture_state(filename: String, assertion_method: String) -> void:
	call(assertion_method)
	await _wait_for_render()
	var image: Image = get_root().get_texture().get_image()
	var path: String = SCREENSHOT_DIR + "/" + filename
	var err: Error = image.save_png(path)
	if err != OK:
		_fail("SAVE.1 save_png failed: %s err=%s" % [filename, err])
	else:
		_saved.append(path)
		print("[M15-T02] viewport screenshot saved: ", ProjectSettings.globalize_path(path))


func _wait_for_render() -> void:
	await process_frame
	await process_frame
	await process_frame


func _force_fixed_care_need() -> void:
	var active: Dictionary = _gs.rescue_system.active_rescue
	active["care_need"] = FIXED_CARE_NEED
	active["care_used"] = false
	active["care_action_taken"] = ""
	active["care_score"] = 0.0
	_gs.rescue_system.active_rescue = active


func _reset_to_clean_test_state(gs) -> void:
	gs.time_system.initialize()
	gs.economy_system.initialize()
	gs.water_chemistry_system.initialize()
	gs.livestock_system.initialize()
	gs.unlock_system.initialize()
	gs.stage_objective_system.initialize()
	gs.rescue_system.initialize(1401)
	gs.rescue_last_feedback = {}
	gs.save_loaded = false
	gs.offline_summary = {}
	gs._recalculate_debug_scores()
	gs._update_livestock_and_economy(0.0)
	gs._update_unlocks()


func _advance_rescue_for_fixed_test_environment(real_delta_seconds: float) -> void:
	var active: Dictionary = _gs.rescue_system.get_debug_state().get("active_rescue", {})
	if active.is_empty() or float(active.get("recovery_progress", 0.0)) >= 100.0:
		return
	var playable: Dictionary = _gs.rescue_system.config.get("first_playable", {})
	var target_seconds: float = max(float(playable.get("target_recovery_seconds", 720.0)), 1.0)
	var base_rate: float = max(float(active.get("recovery_rate_base", 30.0)), 1.0)
	var scale: float = max(real_delta_seconds, 0.0) / target_seconds * (100.0 / base_rate)
	var event: Dictionary = _gs.rescue_system.advance_active_rescue_for_ui(_gs._get_current_rescue_day(), FIXED_WATER_QUALITY, FIXED_COMFORT_SCORE, scale)
	if String(event.get("type", "")) == "recovery_ready":
		_gs.rescue_last_feedback = {"success": true, "summary": "救助生物已完全康复！请前往码头将其放归大海", "type": "recovery_ready"}


func _assert_candidate_state() -> void:
	_assert(_panel.care_need_label != null and _panel.care_need_label.visible, "UI.1 care need label visible")
	_assert(_panel.care_need_label.text.find("带回救助后显示") >= 0, "UI.2 candidate care placeholder visible")


func _assert_active_buttons_state() -> void:
	_assert(_panel.care_need_label != null and _panel.care_need_label.visible, "UI.3 active care need label visible")
	_assert(_panel.care_need_label.text.find("虚弱，需要营养") >= 0, "UI.4 fixed care need text visible")
	_assert(_panel.nutrition_btn != null and _panel.nutrition_btn.visible and _panel.nutrition_btn.text == "营养补给", "UI.5 nutrition button visible")
	_assert(_panel.soothe_btn != null and _panel.soothe_btn.visible and _panel.soothe_btn.text == "安抚照料", "UI.6 soothe button visible")
	_assert(_panel.purify_btn != null and _panel.purify_btn.visible and _panel.purify_btn.text == "净水护理", "UI.7 purify button visible")
	_assert(not _panel.nutrition_btn.disabled and not _panel.soothe_btn.disabled and not _panel.purify_btn.disabled, "UI.8 care buttons enabled before care")


func _assert_after_care_state() -> void:
	_assert(_panel.nutrition_btn.disabled and _panel.soothe_btn.disabled and _panel.purify_btn.disabled, "UI.9 care buttons disabled after care")
	_assert(_panel.feedback_label != null and _panel.feedback_label.text.find("恢复速度") >= 0, "UI.10 care feedback visible")


func _assert_ready_state() -> void:
	_assert(bool(_gs.get_rescue_ui_state().get("ready_to_release", false)), "UI.11 rescue ready before ready screenshot")
	_assert(_panel.release_btn != null and _panel.release_btn.text == "放归大海", "UI.12 release button ready")
	_assert(_panel.care_need_label.text.find("每次救助只能护理一次") >= 0, "UI.13 one-care copy retained")


func _assert_release_state() -> void:
	_assert(_panel.feedback_label != null and _panel.feedback_label.text.find("放归成功！") >= 0, "UI.14 M14 release copy visible")
	_assert(_panel.feedback_label.text.find("悉心照料加成 RP +1") >= 0, "UI.15 care bonus line visible")
	_assert(_panel.feedback_label.text.find("评级") < 0 and _panel.feedback_label.text.find("失败") < 0, "UI.16 no rating or failure copy")


func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)


func _fail(label: String) -> void:
	_failed = true
	_errors.append(label)
	printerr("[M15-T02] FAIL: ", label)


func _finish() -> void:
	if not _errors.is_empty():
		for err in _errors:
			print("[M15-T02] semantic assertion failed: ", err)
	quit(1 if _failed else 0)
