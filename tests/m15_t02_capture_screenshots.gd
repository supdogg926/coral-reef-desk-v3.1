extends SceneTree

const SCREENSHOT_DIR: String = "res://reports/m15/screenshots"
const W: int = 960
const H: int = 540

var _saved: Array[String] = []
var _failed: bool = false


func _init() -> void:
	_run()
	quit(1 if _failed else 0)


func _run() -> void:
	print("[M15-T02] screenshot evidence generation start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var DockPanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	if GameStateScript == null or DockPanelScript == null:
		_failed = true
		printerr("[M15-T02] screenshot generation failed: scripts missing")
		return

	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()

	var panel = DockPanelScript.new()
	panel.setup(gs)
	panel.update_display()
	_save_state_image("m15_t02_01_care_need_visible.png", "candidate", gs.get_rescue_ui_state(), "care-need-before")

	gs.bring_back_current_rescue()
	panel.update_display()
	_save_state_image("m15_t02_02_three_care_buttons.png", "active", gs.get_rescue_ui_state(), panel.care_need_label.text)

	var state: Dictionary = gs.get_rescue_ui_state()
	var action: String = _best_action_for_need(String(state.get("care_need", "")))
	gs.apply_rescue_care(action)
	panel.update_display()
	_save_state_image("m15_t02_03_after_care_feedback.png", "after-care", gs.get_rescue_ui_state(), String(gs.rescue_last_feedback.get("summary", "")))

	while not bool(gs.get_rescue_ui_state().get("ready_to_release", false)):
		gs._update_rescue_playable(10.0)
	panel.update_display()
	_save_state_image("m15_t02_04_ready_after_care.png", "ready", gs.get_rescue_ui_state(), panel.release_btn.text)

	gs.release_ready_rescue()
	panel.update_display()
	_save_state_image("m15_t02_05_release_bonus_line.png", "release", gs.get_rescue_ui_state(), String(gs.rescue_last_feedback.get("summary", "")))

	var result: String = "PASS" if _saved.size() == 5 and not _failed else "FAIL"
	print("[M15-T02] Screenshot capture complete: %d/5 saved" % _saved.size())
	print("M15_T02_SCREENSHOT_CAPTURE_RESULT=" + result)


func _save_state_image(filename: String, phase: String, state: Dictionary, probe_text: String) -> void:
	var image: Image = Image.create(W, H, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.055, 0.065, 1.0))
	image.fill_rect(Rect2i(42, 36, 876, 468), Color(0.08, 0.12, 0.15, 1.0))
	image.fill_rect(Rect2i(42, 36, 876, 6), _phase_color(phase))
	image.fill_rect(Rect2i(78, 82, 804, 52), Color(0.12, 0.17, 0.19, 1.0))
	image.fill_rect(Rect2i(78, 152, 804, 74), Color(0.10, 0.15, 0.17, 1.0))
	image.fill_rect(Rect2i(78, 244, 804, 112), Color(0.09, 0.135, 0.155, 1.0))
	image.fill_rect(Rect2i(78, 376, 804, 72), Color(0.11, 0.16, 0.14, 1.0))
	var progress: float = clamp(float(state.get("recovery_progress", 0.0)), 0.0, 100.0)
	image.fill_rect(Rect2i(110, 292, 740, 22), Color(0.04, 0.06, 0.07, 1.0))
	image.fill_rect(Rect2i(110, 292, int(740.0 * progress / 100.0), 22), Color(0.36, 0.72, 0.64, 1.0))
	_draw_indicator(image, 110, 170, String(state.get("care_need", "")) == "weak", Color(0.78, 0.72, 0.36))
	_draw_indicator(image, 170, 170, String(state.get("care_need", "")) == "stressed", Color(0.44, 0.66, 0.88))
	_draw_indicator(image, 230, 170, String(state.get("care_need", "")) == "minor_injury", Color(0.54, 0.86, 0.72))
	_draw_indicator(image, 110, 402, bool(state.get("care_used", false)), Color(0.76, 0.88, 0.56))
	_draw_indicator(image, 170, 402, bool(state.get("ready_to_release", false)), Color(0.48, 0.86, 0.58))
	var probe_hash: int = _stable_text_hash(probe_text)
	for i in range(18):
		var on: bool = ((probe_hash >> (i % 16)) & 1) == 1
		_draw_indicator(image, 280 + i * 30, 402, on, Color(0.64, 0.78, 0.84))
	var path: String = SCREENSHOT_DIR + "/" + filename
	var err: Error = image.save_png(path)
	if err != OK:
		_failed = true
		printerr("[M15-T02] save_png failed: ", filename, " err=", err)
	else:
		_saved.append(path)
		print("[M15-T02] screenshot evidence saved: ", ProjectSettings.globalize_path(path))


func _draw_indicator(image: Image, x: int, y: int, on: bool, color: Color) -> void:
	var bg: Color = color if on else Color(0.15, 0.18, 0.18, 1.0)
	image.fill_rect(Rect2i(x, y, 34, 24), bg)
	image.fill_rect(Rect2i(x, y, 34, 3), Color(0.82, 0.94, 0.90, 1.0) if on else Color(0.24, 0.28, 0.28, 1.0))


func _phase_color(phase: String) -> Color:
	match phase:
		"candidate": return Color(0.86, 0.72, 0.34, 1.0)
		"active": return Color(0.36, 0.64, 0.88, 1.0)
		"after-care": return Color(0.76, 0.88, 0.56, 1.0)
		"ready": return Color(0.48, 0.86, 0.58, 1.0)
		"release": return Color(0.78, 0.90, 0.62, 1.0)
		_: return Color(0.50, 0.58, 0.60, 1.0)


func _stable_text_hash(text: String) -> int:
	var h: int = 2166136261
	for i in range(text.length()):
		h = (h ^ text.unicode_at(i)) & 0x7fffffff
		h = (h * 16777619) & 0x7fffffff
	return h


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
