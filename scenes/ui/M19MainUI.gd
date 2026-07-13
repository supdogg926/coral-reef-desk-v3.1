class_name M19MainUI
extends Control
# M19-T2 01 Main Interface — built from master section textures + real Godot controls

var game_state: GameState = null

# Section TextureRects (visual from master)
var _tank_bg: TextureRect = null
var _sump_bg: TextureRect = null
var _gauges_bg: TextureRect = null
var _knobs_bg: TextureRect = null
var _devices_bg: TextureRect = null
var _right_panel: TextureRect = null
var _top_bar: TextureRect = null

# Dynamic labels
var _waves_label: Label = null
var _temp_label: Label = null
var _time_label: Label = null
var _date_label: Label = null
var _day_label: Label = null
var _bg_status_label: Label = null
var _bg_countdown_label: Label = null
var _bg_dock_label: Label = null
var _timeline_list: RichTextLabel = null

# Gauge labels
var _gauge_labels: Array[Label] = []

# Device buttons (4x4)
var _device_btns: Array[Button] = []

# Entry buttons
var _bg_entry_btn: Button = null
var _catalog_btn: Button = null
var _release_btn: Button = null
var _settings_btn: Button = null

var _refresh_timer: float = 0.0


func setup(p_game_state: GameState) -> void:
	game_state = p_game_state
	_clear_old_ui()
	_build()


func _clear_old_ui() -> void:
	# Remove old geometric drawing nodes
	for child in get_children():
		if child is ColorRect or child is MarginContainer:
			var name_str := str(child.name)
			if "Background" in name_str or "RootMargin" in name_str:
				child.queue_free()
	for child in get_children():
		var ns := str(child.name)
		if "DisplayTankView" in ns or "SumpView" in ns or "PipeNetworkView" in ns:
			child.queue_free()


func _build() -> void:
	anchor_left = 0.0; anchor_right = 1.0; anchor_top = 0.0; anchor_bottom = 1.0

	# ── Dark background ──
	var dark := _make_tex("res://assets/m19/ui/01_dark_bg.png", 0, 0, 1280, 720)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	# ── Top bar ──
	_top_bar = _make_tex("res://assets/m19/ui/01_top_bar.png", 0, 0, 1280, 42)
	add_child(_top_bar)
	# Title overlay
	var title := Label.new()
	title.text = "ReefIdleV3 · M19 Blue Guardian"
	title.position = Vector2(12, 10)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.78, 0.90, 0.94))
	add_child(title)

	# ── Main tank ──
	_tank_bg = _make_tex("res://assets/m19/ui/01_main_tank_bg.png", 8, 46, 1041, 352)
	add_child(_tank_bg)

	# ── Sump ──
	_sump_bg = _make_tex("res://assets/m19/ui/01_sump_bg.png", 8, 402, 1041, 143)
	add_child(_sump_bg)

	# ── Bottom controls ──
	# Gauges (left)
	_gauges_bg = _make_tex("res://assets/m19/ui/01_gauges_bg.png", 8, 550, 375, 162)
	add_child(_gauges_bg)

	# Knobs (center)
	_knobs_bg = _make_tex("res://assets/m19/ui/01_knobs_bg.png", 388, 550, 306, 162)
	add_child(_knobs_bg)

	# Device matrix (right)
	_devices_bg = _make_tex("res://assets/m19/ui/01_devices_bg.png", 698, 550, 359, 162)
	add_child(_devices_bg)

	# ── Right info panel ──
	_right_panel = _make_tex("res://assets/m19/ui/01_right_panel.png", 1054, 0, 226, 720)
	add_child(_right_panel)

	# ── Right panel: dynamic labels ──
	var rp := Vector2(1066, 8)
	var label_color := Color(0.50, 0.80, 0.88)
	var muted_color := Color(0.45, 0.55, 0.58)

	# Header area
	var header := Label.new()
	header.text = "ReefIdle V3"
	header.position = rp + Vector2(4, 36)
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", label_color)
	add_child(header)

	var build := Label.new()
	build.text = "M19-T2 · UI Candidate"
	build.position = rp + Vector2(4, 52)
	build.add_theme_font_size_override("font_size", 8)
	build.add_theme_color_override("font_color", muted_color)
	add_child(build)

	# Waves balance
	_waves_label = Label.new()
	_waves_label.text = "浪花 0"
	_waves_label.position = rp + Vector2(4, 80)
	_waves_label.add_theme_font_size_override("font_size", 12)
	_waves_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.36))
	add_child(_waves_label)

	# System info
	_temp_label = Label.new(); _temp_label.position = rp + Vector2(4, 108); _temp_label.add_theme_font_size_override("font_size", 10); _temp_label.add_theme_color_override("font_color", label_color); add_child(_temp_label)
	_time_label = Label.new(); _time_label.position = rp + Vector2(4, 124); _time_label.add_theme_font_size_override("font_size", 10); _time_label.add_theme_color_override("font_color", label_color); add_child(_time_label)
	_date_label = Label.new(); _date_label.position = rp + Vector2(4, 140); _date_label.add_theme_font_size_override("font_size", 10); _date_label.add_theme_color_override("font_color", muted_color); add_child(_date_label)
	_day_label = Label.new(); _day_label.position = rp + Vector2(4, 156); _day_label.add_theme_font_size_override("font_size", 10); _day_label.add_theme_color_override("font_color", muted_color); add_child(_day_label)

	# Blue Guardian status section
	var bg_header := Label.new()
	bg_header.text = "蓝色守护"
	bg_header.position = rp + Vector2(4, 190)
	bg_header.add_theme_font_size_override("font_size", 11)
	bg_header.add_theme_color_override("font_color", label_color)
	add_child(bg_header)

	_bg_status_label = Label.new(); _bg_status_label.position = rp + Vector2(4, 208); _bg_status_label.add_theme_font_size_override("font_size", 9); _bg_status_label.add_theme_color_override("font_color", muted_color); add_child(_bg_status_label)
	_bg_countdown_label = Label.new(); _bg_countdown_label.position = rp + Vector2(4, 222); _bg_countdown_label.add_theme_font_size_override("font_size", 9); _bg_countdown_label.add_theme_color_override("font_color", muted_color); add_child(_bg_countdown_label)
	_bg_dock_label = Label.new(); _bg_dock_label.position = rp + Vector2(4, 236); _bg_dock_label.add_theme_font_size_override("font_size", 9); _bg_dock_label.add_theme_color_override("font_color", muted_color); add_child(_bg_dock_label)

	# Timeline
	_timeline_list = RichTextLabel.new()
	_timeline_list.position = rp + Vector2(2, 270)
	_timeline_list.size = Vector2(220, 200)
	_timeline_list.bbcode_enabled = true
	_timeline_list.scroll_active = false
	_timeline_list.add_theme_font_size_override("font_size", 8)
	_timeline_list.add_theme_color_override("default_color", muted_color)
	add_child(_timeline_list)

	# ── Bottom entry buttons ──
	# Catalog button (lower right panel)
	_catalog_btn = Button.new()
	_catalog_btn.text = "图鉴"
	_catalog_btn.position = rp + Vector2(8, 500)
	_catalog_btn.size = Vector2(64, 28)
	_catalog_btn.add_theme_font_size_override("font_size", 10)
	_catalog_btn.add_theme_color_override("font_color", label_color)
	_catalog_btn.flat = true
	add_child(_catalog_btn)

	_release_btn = Button.new()
	_release_btn.text = "放归"
	_release_btn.position = rp + Vector2(78, 500)
	_release_btn.size = Vector2(64, 28)
	_release_btn.add_theme_font_size_override("font_size", 10)
	_release_btn.add_theme_color_override("font_color", label_color)
	_release_btn.flat = true
	add_child(_release_btn)

	_settings_btn = Button.new()
	_settings_btn.text = "设置"
	_settings_btn.position = rp + Vector2(148, 500)
	_settings_btn.size = Vector2(64, 28)
	_settings_btn.add_theme_font_size_override("font_size", 10)
	_settings_btn.add_theme_color_override("font_color", muted_color)
	_settings_btn.flat = true
	add_child(_settings_btn)

	# ── Gauge labels ──
	# Positioned over the gauges section
	var gauge_names := ["温度", "盐度", "NO3", "PO4", "pH", "KH", "Ca"]
	var gauge_x := [24, 74, 124, 174, 224, 274, 324]
	for i in range(7):
		var gl := Label.new()
		gl.text = gauge_names[i] + "\n--"
		gl.position = Vector2(float(gauge_x[i]), 558)
		gl.add_theme_font_size_override("font_size", 8)
		gl.add_theme_color_override("font_color", Color(0.50, 0.78, 0.86))
		_gauge_labels.append(gl)
		add_child(gl)

	# ── Device button overlays (invisible buttons over each device cell) ──
	var device_labels := [
		"换水", "清滤", "KH", "补水",
		"清杂藻", "更换滤材", "喂鱼粮", "喂珊瑚粮",
		"蛋分", "杀菌灯", "加热棒", "冷水机",
		"煮豆机", "钙反", "卷纸机", "KHA"
	]
	for row in range(4):
		for col in range(4):
			var idx := row * 4 + col
			var bx := 706 + col * 87
			var by := 558 + row * 38
			var btn := Button.new()
			btn.text = device_labels[idx] if idx < device_labels.size() else ""
			btn.position = Vector2(float(bx), float(by))
			btn.size = Vector2(82, 34)
			btn.add_theme_font_size_override("font_size", 9)
			btn.add_theme_color_override("font_color", Color(0.50, 0.78, 0.86))
			btn.flat = true
			btn.name = "DeviceBtn_" + device_labels[idx] if idx < device_labels.size() else "DeviceBtn_" + str(idx)
			_device_btns.append(btn)
			add_child(btn)

	# ── Blue Guardian entry button (overlay) ──
	_bg_entry_btn = Button.new()
	_bg_entry_btn.text = "蓝色守护"
	_bg_entry_btn.position = Vector2(1066, 175)
	_bg_entry_btn.size = Vector2(200, 30)
	_bg_entry_btn.add_theme_font_size_override("font_size", 11)
	_bg_entry_btn.add_theme_color_override("font_color", Color(0.92, 0.78, 0.36))
	_bg_entry_btn.flat = true
	add_child(_bg_entry_btn)

	# Signal forwarding — will be connected by Main.gd
	print("[M19MainUI] Built: tank=%dx%d sump=%dx%d gauges=%dx%d knobs=%dx%d devices=%dx%d right=%dx%d" % [
		1041, 352, 1041, 143, 375, 162, 306, 162, 359, 162, 226, 720])


func _make_tex(path: String, x: float, y: float, w: float, h: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.position = Vector2(x, y)
	tr.size = Vector2(w, h)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	return tr


func _process(_delta: float) -> void:
	if game_state == null:
		return
	_refresh_timer += _delta
	if _refresh_timer < 1.0:
		return
	_refresh_timer = 0.0
	_refresh_dynamic_data()


func _refresh_dynamic_data() -> void:
	# Waves
	if game_state.economy_system != null:
		var w := game_state.economy_system.get_waves_balance()
		_waves_label.text = "浪花 %.0f" % w

	# Temperature
	_temp_label.text = "水温 26.2°C"

	# Time / Date
	var dt := Time.get_datetime_dict_from_system()
	_time_label.text = "%02d:%02d" % [dt.hour, dt.minute]
	_date_label.text = "%d-%02d-%02d" % [dt.year, dt.month, dt.day]
	var days := ["日", "一", "二", "三", "四", "五", "六"]
	_day_label.text = "星期" + days[dt.weekday]

	# Blue Guardian status
	if game_state.blue_guardian_service != null:
		var svc = game_state.blue_guardian_service
		svc.ensure_voyage_settled_if_due()
		var state: int = svc.get_state()
		match state:
			BlueGuardianService.VoyageState.READY:
				_bg_status_label.text = "状态: 待命中"
				_bg_countdown_label.text = ""
			BlueGuardianService.VoyageState.VOYAGING:
				_bg_status_label.text = "状态: 航行中"
				var rem: int = svc.get_remaining_seconds()
				_bg_countdown_label.text = "返航倒计时: %02d:%02d" % [rem/60, rem%60]
			BlueGuardianService.VoyageState.RESULT_PENDING:
				_bg_status_label.text = "状态: 有新的救助结果"
				_bg_countdown_label.text = "点击蓝色守护查看"
		_bg_dock_label.text = "码头: " + svc.get_dock_display_name()

	# Timeline (last 5 events)
	var rescue := game_state.rescue_system
	if rescue != null:
		var raw_events: Variant = rescue.get_debug_state().get("event_log", [])
		var events: Array = raw_events if raw_events is Array else []
		var text := "[center][b]系统日志[/b][/center]\n"
		var start: int = max(0, events.size() - 6)
		for i in range(start, events.size()):
			var ev = events[i]
			text += "[color=#708890]· %s[/color]\n" % str(ev.get("type", "")).replace("_", " ")
		_timeline_list.text = text
