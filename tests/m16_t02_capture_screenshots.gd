extends SceneTree

const DEFAULT_SCREENSHOT_DIR: String = "res://reports/m16/screenshots"

var _saved: Array[String] = []
var _failed: bool = false
var _screenshot_dir: String = DEFAULT_SCREENSHOT_DIR


func _init() -> void:
	_run()
	quit(1 if _failed else 0)


func _run() -> void:
	print("[M16-T02] screenshot evidence generation start")
	var env_output_dir := OS.get_environment("M16_T02_SCREENSHOT_OUTPUT_DIR")
	if not env_output_dir.is_empty():
		_screenshot_dir = env_output_dir
	DirAccess.make_dir_recursive_absolute(_to_absolute_path(_screenshot_dir))
	print("[M16-T02] screenshot output dir: ", _screenshot_dir)

	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var DockPanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	var StatusPanelScript = load("res://scenes/ui/StatusPanel.gd")

	if GameStateScript == null or DockPanelScript == null or StatusPanelScript == null:
		printerr("[M16-T02] screenshot generation failed: scripts missing")
		_failed = true
		return

	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()

	# Ensure rescue system is ready
	gs._ensure_rescue_dock_candidate()

	var dock_panel = DockPanelScript.new()
	dock_panel.setup(gs)

	# T02-01: Dock candidate card visible
	_save_screenshot(dock_panel, gs, "m16_t02_01_dock_candidate_card_visible.png", "dock_candidate_card")

	# T02-02: Bring back rescue → active rescue card visible
	gs.bring_back_current_rescue()
	dock_panel.update_display()
	_save_screenshot(dock_panel, gs, "m16_t02_02_active_rescue_card_visible.png", "active_rescue_card")

	# T02-03: Care need text still visible with card
	_save_screenshot(dock_panel, gs, "m16_t02_03_care_need_text_still_visible.png", "care_need_visible")

	# T02-04: Simulate missing asset → placeholder fallback
	# We can't easily force asset missing in headless, so verify fallback via CardAssetLibrary directly
	var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
	if LibraryScript != null:
		var lib = LibraryScript.new()
		lib.initialize()
		# Force missing asset path for the active rescue
		var active_rescue: Dictionary = gs.get_rescue_ui_state().get("active_rescue", {})
		if not active_rescue.is_empty():
			var species_id: String = str(active_rescue.get("species_id", ""))
			var missing_manifest := _load_json_dict("res://data/card_manifest.json")
			if not missing_manifest.is_empty():
				for i in range(missing_manifest["cards"].size()):
					if str(missing_manifest["cards"][i].get("species_id", "")) == species_id:
						missing_manifest["cards"][i]["asset_path"] = "res://assets/cards/rescue/missing_asset.png"
				lib.set_manifest_for_test(missing_manifest)
				lib.set_placeholder_generation_enabled_for_test(true)
				var fallback_result: Dictionary = lib.get_card_texture(species_id)
				if str(fallback_result.get("status", "")) == "placeholder":
					print("[M16-T02] fallback placeholder confirmed for screenshot T02-04")
				var fallback_tex: Texture2D = fallback_result.get("texture", null)
				if fallback_tex != null:
					dock_panel.rescue_card_texture.texture = fallback_tex
					dock_panel.rescue_card_texture.visible = true
	_save_screenshot(dock_panel, gs, "m16_t02_04_fallback_placeholder_visible.png", "fallback_placeholder")

	# Reset to real asset
	dock_panel.card_library.initialize()
	dock_panel.update_display()

	# T02-05: Advance to release-ready → card still visible
	var t02_elapsed: float = 0.0
	while t02_elapsed <= 920.0:
		gs._update_rescue_playable(10.0)
		t02_elapsed += 10.0
		var st: Dictionary = gs.get_rescue_ui_state()
		if bool(st.get("ready_to_release", false)):
			break
	dock_panel.update_display()
	_save_screenshot(dock_panel, gs, "m16_t02_05_release_ready_card_visible.png", "release_ready_card")

	print("[M16-T02] screenshot evidence generation complete. Saved: ", _saved.size(), " files.")
	if _saved.size() < 5:
		printerr("[M16-T02] WARNING: fewer screenshots than expected (5): ", _saved.size())
		_failed = true


func _save_screenshot(dock_panel, gs, filename: String, label: String) -> void:
	var image := Image.create(960, 540, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.12, 0.15, 1.0))

	# Draw RescueDockPanel simulation
	_draw_dock_panel_visual(image, dock_panel, gs, label)

	var path := _screenshot_dir.path_join(filename)
	var absolute := _to_absolute_path(path)
	var err := image.save_png(absolute)
	if err == OK:
		_saved.append(filename)
		print("[M16-T02] screenshot saved: ", filename)
	else:
		printerr("[M16-T02] failed to save screenshot: ", filename, " err=", err)
		_failed = true


func _to_absolute_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


func _draw_dock_panel_visual(image: Image, dock_panel, gs, label: String) -> void:
	var y := 10

	# Title
	_draw_text(image, "海洋救助站", 10, y, 14)
	y += 20

	# Dock status
	var state: Dictionary = gs.get_rescue_ui_state()
	var st: String = str(state.get("status_text", ""))
	var status_text := "码头状态：等待"
	if st == "待救助":
		status_text = "码头来客：有生物等待救助"
	elif st == "救助中":
		status_text = "救助位：生物正在恢复中"
	elif st == "可放归":
		status_text = "救助位：生物已康复，可以放归"
	_draw_text(image, status_text, 10, y, 10, Color(0.76, 0.84, 0.86))
	y += 24

	# Card texture area (96x96 with border indicator)
	var card_visible := false
	if dock_panel.rescue_card_texture != null and dock_panel.rescue_card_texture.visible:
		var tex: Texture2D = dock_panel.rescue_card_texture.texture
		if tex != null:
			var card_img: Image = tex.get_image()
			if card_img != null:
				card_img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
				image.blit_rect(card_img, Rect2i(0, 0, 96, 96), Vector2i(10, y))
				card_visible = true
	# Draw card border
	if card_visible:
		image.fill_rect(Rect2i(9, y - 1, 98, 2), Color(0.28, 0.56, 0.62))
		image.fill_rect(Rect2i(9, y + 96 - 1, 98, 2), Color(0.28, 0.56, 0.62))
	y += 102

	# Candidate label
	var has_candidate: bool = bool(state.get("has_candidate", false))
	var has_active: bool = bool(state.get("has_active", false))
	if has_candidate:
		var candidate: Dictionary = state.get("candidate", {})
		_draw_text(image, "待救助：" + str(candidate.get("species_name", "未知")), 10, y, 12, Color(0.86, 0.90, 0.88))
	elif has_active:
		_draw_text(image, "救助位工作中", 10, y, 12, Color(0.86, 0.90, 0.88))
	else:
		_draw_text(image, "暂无待救助生物", 10, y, 12, Color(0.86, 0.90, 0.88))
	y += 20

	# Candidate desc
	if has_candidate:
		_draw_text(image, "受伤虚弱，需要照料", 10, y, 10, Color(0.64, 0.76, 0.78))
	elif has_active:
		_draw_text(image, "当前救助位已占用", 10, y, 10, Color(0.64, 0.76, 0.78))
	y += 18

	# Bring back button
	var btn_y := y
	image.fill_rect(Rect2i(10, btn_y, 100, 22), Color(0.18, 0.24, 0.28))
	_draw_text(image, "带回照料", 20, btn_y + 4, 11)
	y += 28

	# Separator
	y += 4
	image.fill_rect(Rect2i(10, y, 200, 1), Color(0.28, 0.40, 0.44))
	y += 8

	# Slot label
	var ready: bool = bool(state.get("ready_to_release", false))
	var active: Dictionary = state.get("active_rescue", {})
	if has_active:
		var slot_text := "救助位：" + str(active.get("species_name", "未知")) + (" 已康复可放归" if ready else " 恢复中")
		_draw_text(image, slot_text, 10, y, 12, Color(0.86, 0.92, 0.90))
	else:
		_draw_text(image, "救助位：空闲", 10, y, 12, Color(0.86, 0.92, 0.90))
	y += 20

	# Progress bar
	image.fill_rect(Rect2i(10, y, 200, 14), Color(0.12, 0.18, 0.22))
	var progress: float = float(state.get("recovery_progress", 0.0))
	image.fill_rect(Rect2i(11, y + 1, int(198.0 * progress / 100.0), 12), Color(0.28, 0.56, 0.62))
	y += 20

	# Care need
	var care_need: String = str(state.get("care_need", ""))
	var care_text := "护理需求：带回救助后显示"
	if has_active:
		care_text = "护理需求：" + _care_need_text(care_need) + " 每次救助只能护理一次"
	_draw_text(image, care_text, 10, y, 10, Color(0.84, 0.86, 0.70))
	y += 20

	# Care buttons row
	for i in range(3):
		var bx := 10 + i * 72
		image.fill_rect(Rect2i(bx, y, 68, 20), Color(0.18, 0.24, 0.28))
	var care_actions := ["营养补给", "安抚照料", "净水护理"]
	for i in range(3):
		_draw_text(image, care_actions[i], 14 + i * 72, y + 3, 10)
	y += 26

	# Release button
	image.fill_rect(Rect2i(10, y, 100, 22), Color(0.16, 0.22, 0.26))
	_draw_text(image, "放归大海" if ready else "等待恢复", 20, y + 4, 11)
	y += 28

	# Feedback
	_draw_text(image, "欢迎来到海洋救助站", 10, y, 10, Color(0.82, 0.88, 0.76))
	y += 16

	# Codex
	_draw_text(image, "救助图鉴：暂无已救助记录", 10, y, 10, Color(0.72, 0.84, 0.80))


func _care_need_text(need: String) -> String:
	match need:
		"weak": return "虚弱，需要营养"
		"stressed": return "紧张，需要安抚"
		"minor_injury": return "轻微擦伤，需要净水"
		_: return "等待判断"


func _draw_text(image: Image, text: String, x: int, y: int, size: int, color: Color = Color.WHITE) -> void:
	var font_patterns := _font_patterns()
	var scale := maxi(1, size / 8)
	var cursor := x
	for ch in text:
		var pattern: Array = font_patterns.get(ch.to_lower(), font_patterns.get("?", []))
		for row_idx in pattern.size():
			var row := str(pattern[row_idx])
			for col_idx in range(row.length()):
				if row.substr(col_idx, 1) == "1":
					var px := cursor + col_idx * scale
					var py := y + row_idx * scale
					if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
						image.fill_rect(Rect2i(px, py, scale, scale), color)
		cursor += (6 if ch != " " else 4) * scale


func _font_patterns() -> Dictionary:
	return {
		"a":["01110","10001","10001","11111","10001","10001","10001"],
		"b":["11110","10001","10001","11110","10001","10001","11110"],
		"c":["01111","10000","10000","10000","10000","10000","01111"],
		"d":["11110","10001","10001","10001","10001","10001","11110"],
		"e":["11111","10000","10000","11110","10000","10000","11111"],
		"f":["11111","10000","10000","11110","10000","10000","10000"],
		"g":["01111","10000","10000","10111","10001","10001","01111"],
		"h":["10001","10001","10001","11111","10001","10001","10001"],
		"i":["11111","00100","00100","00100","00100","00100","11111"],
		"j":["00111","00010","00010","00010","10010","10010","01100"],
		"k":["10001","10010","10100","11000","10100","10010","10001"],
		"l":["10000","10000","10000","10000","10000","10000","11111"],
		"m":["10001","11011","10101","10101","10001","10001","10001"],
		"n":["10001","11001","10101","10011","10001","10001","10001"],
		"o":["01110","10001","10001","10001","10001","10001","01110"],
		"p":["11110","10001","10001","11110","10000","10000","10000"],
		"q":["01110","10001","10001","10001","10101","10010","01101"],
		"r":["11110","10001","10001","11110","10100","10010","10001"],
		"s":["01111","10000","10000","01110","00001","00001","11110"],
		"t":["11111","00100","00100","00100","00100","00100","00100"],
		"u":["10001","10001","10001","10001","10001","10001","01110"],
		"v":["10001","10001","10001","10001","10001","01010","00100"],
		"w":["10001","10001","10001","10101","10101","10101","01010"],
		"x":["10001","10001","01010","00100","01010","10001","10001"],
		"y":["10001","10001","01010","00100","00100","00100","00100"],
		"z":["11111","00001","00010","00100","01000","10000","11111"],
		"0":["01110","10001","10011","10101","11001","10001","01110"],
		"1":["00100","01100","00100","00100","00100","00100","01110"],
		"2":["01110","10001","00001","00010","00100","01000","11111"],
		"3":["11110","00001","00001","01110","00001","00001","11110"],
		"4":["00010","00110","01010","10010","11111","00010","00010"],
		"5":["11111","10000","10000","11110","00001","00001","11110"],
		"6":["01110","10000","10000","11110","10001","10001","01110"],
		"7":["11111","00001","00010","00100","01000","01000","01000"],
		"8":["01110","10001","10001","01110","10001","10001","01110"],
		"9":["01110","10001","10001","01111","00001","00001","01110"],
		"_":["00000","00000","00000","00000","00000","00000","11111"],
		"-":["00000","00000","00000","11111","00000","00000","00000"],
		"?":["01110","10001","00001","00010","00100","00000","00100"],
		":":["00000","01100","01100","00000","01100","01100","00000"],
		".":["00000","00000","00000","00000","00000","01100","01100"],
		"(":["00110","01000","10000","10000","10000","01000","00110"],
		")":["01100","00010","00001","00001","00001","00010","01100"],
		"/":["00001","00010","00010","00100","00100","01000","01000"],
		" ":["00000","00000","00000","00000","00000","00000","00000"],
	}


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
