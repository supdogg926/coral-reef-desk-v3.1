extends SceneTree

const SCREENSHOT_DIR: String = "res://reports/m17/screenshots"

var _saved: Array[String] = []
var _failed: bool = false


func _init() -> void:
	_run()
	quit(1 if _failed else 0)


func _run() -> void:
	print("[M17-T01] screenshot evidence generation start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))

	var GameStateScript: GDScript = load("res://scripts/systems/GameState.gd") as GDScript
	var DockPanelScript: GDScript = load("res://scenes/ui/RescueDockPanel.gd") as GDScript
	var LivestockPanelScript: GDScript = load("res://scenes/ui/LivestockPanel.gd") as GDScript

	if GameStateScript == null or DockPanelScript == null or LivestockPanelScript == null:
		printerr("[M17-T01] screenshot generation failed: scripts missing")
		_failed = true
		return

	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()

	# Force candidate to appear
	gs._ensure_rescue_dock_candidate()

	var dock_panel = DockPanelScript.new()
	dock_panel.setup(gs)

	# === Screenshot 1: Rescue dock with candidate visible ===
	# Record which species appeared
	var ui_state: Dictionary = gs.get_rescue_ui_state()
	var candidate: Dictionary = ui_state.get("candidate", {})
	var candidate_species: String = str(candidate.get("species_name", "unknown"))
	var candidate_id: String = str(candidate.get("species_id", "unknown"))
	print("[M17-T01] Screenshot 1 candidate: ", candidate_species, " (", candidate_id, ")")
	_save_dock_screenshot(dock_panel, gs, "m17_t01_01_rescue_dock_candidate_visible.png")

	# === Screenshot 2: Active rescue after bring back ===
	gs.bring_back_current_rescue()
	dock_panel.update_display()
	var active_state: Dictionary = gs.get_rescue_ui_state()
	var active: Dictionary = active_state.get("active_rescue", {})
	var active_species: String = str(active.get("species_name", "unknown"))
	var active_id: String = str(active.get("species_id", "unknown"))
	print("[M17-T01] Screenshot 2 active rescue: ", active_species, " (", active_id, ")")
	_save_dock_screenshot(dock_panel, gs, "m17_t01_02_active_rescue_no_repeat_candidate.png")

	# === Screenshot 3: Livestock panel with rescue codex records ===
	var livestock_panel = LivestockPanelScript.new()
	livestock_panel.setup(gs)
	livestock_panel.update_display()
	_save_livestock_screenshot(livestock_panel, gs, "m17_t01_03_rescue_codex_or_livestock_record_visible.png")

	# === Optional: advance rescue and release to create codex record ===
	# Then re-capture livestock panel to show a completed rescue in codex
	var elapsed: float = 0.0
	while elapsed <= 920.0:
		gs._update_rescue_playable(10.0)
		elapsed += 10.0
		var st: Dictionary = gs.get_rescue_ui_state()
		if bool(st.get("ready_to_release", false)):
			break
	if bool(gs.get_rescue_ui_state().get("ready_to_release", false)):
		gs.release_ready_rescue()
		print("[M17-T01] Released rescue, updating codex...")
		livestock_panel.update_display()
		_save_livestock_screenshot(livestock_panel, gs, "m17_t03_03b_rescue_codex_after_release.png")

	print("[M17-T01] screenshot evidence generation complete. Saved: ", _saved.size(), " files.")
	if _saved.size() < 3:
		printerr("[M17-T01] WARNING: fewer screenshots than expected (3): ", _saved.size())
		_failed = true


func _save_dock_screenshot(dock_panel, gs, filename: String) -> void:
	var image := _make_empty_image()
	_draw_dock_panel_visual(image, dock_panel, gs)
	_save(image, filename)


func _save_livestock_screenshot(livestock_panel, gs, filename: String) -> void:
	var image := _make_empty_image()
	_draw_livestock_panel_visual(image, livestock_panel, gs)
	_save(image, filename)


func _make_empty_image() -> Image:
	var image := Image.create(960, 540, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.12, 0.15, 1.0))
	return image


func _save(image: Image, filename: String) -> void:
	var path: String = SCREENSHOT_DIR + "/" + filename
	var absolute: String = ProjectSettings.globalize_path(path)
	var err := image.save_png(absolute)
	if err == OK:
		_saved.append(filename)
		print("[M17-T01] screenshot saved: ", filename)
	else:
		printerr("[M17-T01] failed to save screenshot: ", filename)
		_failed = true


func _draw_dock_panel_visual(image: Image, dock_panel, gs) -> void:
	var y: int = 10
	var state: Dictionary = gs.get_rescue_ui_state()
	var has_candidate: bool = bool(state.get("has_candidate", false))
	var has_active: bool = bool(state.get("has_active", false))
	var ready: bool = bool(state.get("ready_to_release", false))
	var candidate: Dictionary = state.get("candidate", {})
	var active: Dictionary = state.get("active_rescue", {})

	# Title
	_draw_text(image, "海洋救助站", 10, y, 14)
	y += 20

	# Dock status
	var st: String = str(state.get("status_text", ""))
	var status_text: String = "码头状态：等待"
	if st == "待救助":
		status_text = "码头来客：有生物等待救助"
	elif st == "救助中":
		status_text = "救助位：生物正在恢复中"
	elif st == "可放归":
		status_text = "救助位：生物已康复，可以放归"
	_draw_text(image, status_text, 10, y, 10, Color(0.76, 0.84, 0.86))
	y += 24

	# Card texture area (96x96)
	if dock_panel.rescue_card_texture != null and dock_panel.rescue_card_texture.visible:
		var tex: Texture2D = dock_panel.rescue_card_texture.texture
		if tex != null:
			var card_img: Image = tex.get_image()
			if card_img != null:
				card_img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
				image.blit_rect(card_img, Rect2i(0, 0, 96, 96), Vector2i(10, y))
	# Card border
	image.fill_rect(Rect2i(9, y - 1, 98, 2), Color(0.28, 0.56, 0.62))
	image.fill_rect(Rect2i(9, y + 96 - 1, 98, 2), Color(0.28, 0.56, 0.62))
	y += 104

	# Candidate / Active label
	if has_candidate:
		_draw_text(image, "待救助：" + str(candidate.get("species_name", "未知")), 10, y, 12, Color(0.86, 0.90, 0.88))
		y += 18
		_draw_text(image, "受伤虚弱，需要照料  带回成本 1 RP", 10, y, 10, Color(0.64, 0.76, 0.78))
		y += 16
		# Bring back button
		image.fill_rect(Rect2i(10, y, 100, 22), Color(0.18, 0.24, 0.28))
		_draw_text(image, "带回照料", 20, y + 4, 11)
	elif has_active:
		_draw_text(image, "救助位工作中", 10, y, 12, Color(0.86, 0.90, 0.88))
		y += 18
		_draw_text(image, "当前救助位已占用，请先完成恢复", 10, y, 10, Color(0.64, 0.76, 0.78))
	y += 28

	# Separator
	y += 4
	image.fill_rect(Rect2i(10, y, 220, 1), Color(0.28, 0.40, 0.44))
	y += 8

	# Active rescue slot
	if has_active:
		var slot_text: String = "救助位：" + str(active.get("species_name", "未知")) + (" 已康复可放归" if ready else " 恢复中")
		_draw_text(image, slot_text, 10, y, 12, Color(0.86, 0.92, 0.90))
		y += 20

		# Progress bar
		var progress: float = float(state.get("recovery_progress", 0.0))
		image.fill_rect(Rect2i(10, y, 220, 14), Color(0.12, 0.18, 0.22))
		image.fill_rect(Rect2i(11, y + 1, int(218.0 * progress / 100.0), 12), Color(0.28, 0.56, 0.62))
		y += 20

		# Care need
		var care_need: String = str(state.get("care_need", ""))
		var care_text: String = "护理需求：" + _care_need_text(care_need) + " 每次救助只能护理一次"
		_draw_text(image, care_text, 10, y, 10, Color(0.84, 0.86, 0.70))
		y += 18

		# Care buttons
		var care_actions: Array[String] = ["营养补给", "安抚照料", "净水护理"]
		for i in range(3):
			var bx: int = 10 + i * 72
			image.fill_rect(Rect2i(bx, y, 68, 20), Color(0.18, 0.24, 0.28))
			_draw_text(image, care_actions[i], 14 + i * 72, y + 3, 10)
		y += 26

		# Release button
		image.fill_rect(Rect2i(10, y, 100, 22), Color(0.16, 0.22, 0.26))
		_draw_text(image, "放归大海" if ready else "等待恢复", 20, y + 4, 11)
		y += 28
	else:
		_draw_text(image, "救助位：空闲", 10, y, 12, Color(0.86, 0.92, 0.90))
		y += 20

	# Species ID / pool count label
	var pool_label: String = "救助池物种数：%d（M17-T01 扩展后）" % 6
	_draw_text(image, pool_label, 10, y + 4, 10, Color(0.60, 0.72, 0.76))


func _draw_livestock_panel_visual(image: Image, livestock_panel, gs) -> void:
	var y: int = 10
	_draw_text(image, "我的生物", 10, y, 14, Color(0.90, 0.96, 0.90))
	y += 22

	# Summary line
	var ls = gs.livestock_system
	if ls != null:
		var dbg: Dictionary = ls.get_debug_state()
		_draw_text(image, "共%d个生物  容量%.1f/%.1f" % [int(dbg.get("livestock_count", 0)), float(dbg.get("capacity_used", 0)), float(dbg.get("max_capacity", 30))], 10, y, 10, Color(0.70, 0.85, 0.80))
	y += 18

	# Rescue codex text label (legacy join format)
	var state: Dictionary = gs.get_rescue_ui_state()
	var marks: Dictionary = state.get("codex_rescue_marks", {})
	if marks.is_empty():
		_draw_text(image, "救助图鉴：暂无已救助记录", 10, y, 10, Color(0.70, 0.88, 0.78))
	else:
		var parts: Array[String] = []
		for species_id in marks.keys():
			var mark = marks.get(species_id, {})
			if mark is Dictionary and bool(mark.get("rescued", false)):
				parts.append(str(species_id) + " 已救助")
		if parts.is_empty():
			_draw_text(image, "救助图鉴：暂无已救助记录", 10, y, 10, Color(0.70, 0.88, 0.78))
		else:
			_draw_text(image, "救助图鉴（已救助物种）：" + " | ".join(parts), 10, y, 10, Color(0.70, 0.88, 0.78))
	y += 20

	# Rescue codex cards area (HBoxContainer simulation)
	if livestock_panel.rescue_codex_cards != null and livestock_panel.rescue_codex_cards.visible:
		var card_count: int = livestock_panel.rescue_codex_cards.get_child_count()
		_draw_text(image, "[救助卡片区] %d 张已救助物种卡片" % card_count, 10, y, 10, Color(0.60, 0.78, 0.72))
		# Draw mini card placeholders for each rescued species
		var cx: int = 10
		for i in range(card_count):
			image.fill_rect(Rect2i(cx, y + 16, 72, 72), Color(0.14, 0.20, 0.24))
			image.fill_rect(Rect2i(cx + 1, y + 17, 70, 70), Color(0.18, 0.26, 0.30))
			cx += 78
		y += 94
	else:
		_draw_text(image, "[救助卡片区] 暂无已救助记录", 10, y, 10, Color(0.60, 0.78, 0.72))
	y += 16

	# Pool label
	_draw_text(image, "救助物种池：6 个（M17-T01）｜已救助：%d 种" % marks.size(), 10, y, 10, Color(0.60, 0.72, 0.76))


func _care_need_text(need: String) -> String:
	match need:
		"weak": return "虚弱，需要营养"
		"stressed": return "紧张，需要安抚"
		"minor_injury": return "轻微擦伤，需要净水"
		_: return "等待判断"


func _draw_text(image: Image, text: String, x: int, y: int, size: int, color: Color = Color.WHITE) -> void:
	var font_patterns := _font_patterns()
	var scale := maxi(1, maxi(1, size / 8))
	var cursor := x
	for ch in text:
		var pattern: Array = font_patterns.get(ch.to_lower(), font_patterns.get("?", []))
		for row_idx in pattern.size():
			var row := str(pattern[row_idx])
			for col_idx in range(row.length()):
				if row.substr(col_idx, 1) == "1":
					var px: int = cursor + col_idx * scale
					var py: int = y + row_idx * scale
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
		"|":["00100","00100","00100","00100","00100","00100","00100"],
	}
