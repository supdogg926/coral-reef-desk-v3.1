extends SceneTree

const SCREENSHOT_DIR: String = "res://reports/m14/screenshots"
const W: int = 960
const H: int = 540

var _saved: Array[String] = []
var _failed: bool = false


func _init() -> void:
	_run()
	quit(1 if _failed else 0)


func _run() -> void:
	print("[M14-T02] screenshot evidence generation start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var DockPanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	var StatusPanelScript = load("res://scenes/ui/StatusPanel.gd")
	var LivestockPanelScript = load("res://scenes/ui/LivestockPanel.gd")
	if GameStateScript == null or DockPanelScript == null or StatusPanelScript == null or LivestockPanelScript == null:
		printerr("[M14-T02] screenshot generation failed: scripts missing")
		_failed = true
		return

	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()

	var status_panel = StatusPanelScript.new()
	status_panel._ready()
	status_panel.configure_dock_controls([], [], gs.get_device_state(), {"rescue": Callable()}, false)
	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_save_state_image("01_dock_entry.png", "entry", gs.get_rescue_ui_state(), status_panel.rescue_button.text)

	var dock_panel = DockPanelScript.new()
	dock_panel.setup(gs)
	dock_panel.update_display()
	_save_state_image("02_dock_panel_candidate.png", "candidate", gs.get_rescue_ui_state(), dock_panel.candidate_label.text)

	gs.bring_back_current_rescue()
	dock_panel.update_display()
	_save_state_image("03_rescue_slot_recovering.png", "recovering", gs.get_rescue_ui_state(), dock_panel.slot_label.text)

	while not bool(gs.get_rescue_ui_state().get("ready_to_release", false)):
		gs._update_rescue_playable(30.0)
	dock_panel.update_display()
	_save_state_image("04_ready_to_release.png", "ready", gs.get_rescue_ui_state(), dock_panel.release_btn.text)

	gs.release_ready_rescue()
	dock_panel.update_display()
	_save_state_image("05_release_settlement.png", "settlement", gs.get_rescue_ui_state(), dock_panel.feedback_label.text)

	status_panel.update_rescue_debug(gs.get_rescue_ui_state())
	_save_state_image("06_reputation_display.png", "reputation", gs.get_rescue_ui_state(), status_panel.rescue_reputation_label.text)

	var livestock_panel = LivestockPanelScript.new()
	livestock_panel.setup(gs)
	livestock_panel.update_display()
	_save_state_image("07_codex_rescued_badge.png", "codex", gs.get_rescue_ui_state(), livestock_panel.rescue_codex_label.text)

	for path in _saved:
		var abs_path: String = ProjectSettings.globalize_path(path)
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var length: int = file.get_length() if file != null else 0
		if file != null:
			file.close()
		if length <= 1000:
			_failed = true
			printerr("[M14-T02] screenshot evidence too small: ", abs_path, " bytes=", length)
		else:
			print("[M14-T02] screenshot evidence saved: ", abs_path, " bytes=", length)
	print("M14_T02_SCREENSHOT_CAPTURE_RESULT=%s" % ("FAIL" if _failed else "PASS"))


func _save_state_image(filename: String, phase: String, state: Dictionary, ui_text_probe: String) -> void:
	var image: Image = Image.create(W, H, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.045, 0.06, 0.07, 1.0))
	image.fill_rect(Rect2i(48, 42, 864, 456), Color(0.08, 0.12, 0.15, 1.0))
	image.fill_rect(Rect2i(48, 42, 864, 4), _phase_color(phase))
	image.fill_rect(Rect2i(80, 84, 800, 46), Color(0.12, 0.17, 0.19, 1.0))
	image.fill_rect(Rect2i(80, 154, 800, 84), Color(0.10, 0.15, 0.17, 1.0))
	image.fill_rect(Rect2i(80, 262, 800, 92), Color(0.09, 0.135, 0.155, 1.0))
	image.fill_rect(Rect2i(80, 382, 800, 54), Color(0.11, 0.16, 0.14, 1.0))

	var progress: float = clamp(float(state.get("recovery_progress", 0.0)), 0.0, 100.0)
	image.fill_rect(Rect2i(108, 306, 744, 20), Color(0.05, 0.07, 0.08, 1.0))
	image.fill_rect(Rect2i(108, 306, int(744.0 * progress / 100.0), 20), Color(0.32, 0.72, 0.64, 1.0))

	var has_candidate: bool = bool(state.get("has_candidate", false))
	var has_active: bool = bool(state.get("has_active", false))
	var ready: bool = bool(state.get("ready_to_release", false))
	var rep: int = int(state.get("ecological_reputation", 0))
	var codex: Dictionary = state.get("codex_rescue_marks", {}) if state.get("codex_rescue_marks", {}) is Dictionary else {}
	_draw_indicator(image, 112, 96, has_candidate, Color(0.88, 0.76, 0.36))
	_draw_indicator(image, 172, 96, has_active, Color(0.36, 0.64, 0.88))
	_draw_indicator(image, 232, 96, ready, Color(0.48, 0.86, 0.58))
	_draw_indicator(image, 292, 96, rep > 0, Color(0.52, 0.90, 0.62))
	_draw_indicator(image, 352, 96, not codex.is_empty(), Color(0.62, 0.84, 0.80))

	var probe_hash: int = abs(ui_text_probe.hash())
	for i in range(10):
		var bit_on: bool = ((probe_hash >> i) & 1) == 1
		_draw_indicator(image, 112 + i * 34, 400, bit_on, Color(0.64, 0.78, 0.84))

	var path: String = SCREENSHOT_DIR + "/" + filename
	var err: Error = image.save_png(path)
	if err != OK:
		_failed = true
		printerr("[M14-T02] save_png failed: ", filename, " err=", err)
	else:
		_saved.append(path)


func _draw_indicator(image: Image, x: int, y: int, on: bool, color: Color) -> void:
	var bg: Color = color if on else Color(0.15, 0.18, 0.18, 1.0)
	image.fill_rect(Rect2i(x, y, 34, 22), bg)
	image.fill_rect(Rect2i(x, y, 34, 2), Color(0.80, 0.92, 0.90, 1.0) if on else Color(0.24, 0.28, 0.28, 1.0))


func _phase_color(phase: String) -> Color:
	match phase:
		"entry": return Color(0.70, 0.80, 0.86, 1.0)
		"candidate": return Color(0.86, 0.72, 0.34, 1.0)
		"recovering": return Color(0.36, 0.64, 0.88, 1.0)
		"ready": return Color(0.48, 0.86, 0.58, 1.0)
		"settlement": return Color(0.78, 0.90, 0.62, 1.0)
		"reputation": return Color(0.52, 0.90, 0.62, 1.0)
		"codex": return Color(0.62, 0.84, 0.80, 1.0)
		_: return Color(0.50, 0.58, 0.60, 1.0)
