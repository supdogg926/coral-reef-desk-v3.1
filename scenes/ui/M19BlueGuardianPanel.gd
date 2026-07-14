class_name M19BlueGuardianPanel
extends PanelContainer
# M19 02/03 Shared Blue Guardian Panel — READY + VOYAGING states
# PlateLayer: freeze chrome shell, switched by state
# FactLayer: dynamic controls from manifest

var _service: BlueGuardianService = null

# Shell
var _chrome_plate: TextureRect = null
var _chrome_loaded: bool = false
const SHELL_READY := "res://assets/m19/ui/chrome/shell_02_ready_empty.png"
const SHELL_VOYAGING := "res://assets/m19/ui/chrome/shell_03_voyaging_empty.png"
const SHELL_S := Vector2(760, 520)

# Fact controls
var _title_label: Label = null
var _close_btn: Button = null
var _region_image: TextureRect = null
var _region_name: Label = null
var _guardian_status: Label = null
var _wave_balance: Label = null
var _voyage_cost: Label = null
var _eta_label: Label = null
var _countdown_label: Label = null
var _progress_bar: ProgressBar = null
var _message_primary: Label = null
var _message_secondary: Label = null
var _voyage_count: Label = null
var _primary_action_btn: Button = null
var _codex_btn: Button = null
var _refresh_timer: float = 0.0
var _last_state: int = -1

const TEXT_PRIMARY := Color(0.82, 0.90, 0.92)
const TEXT_MUTED := Color(0.50, 0.58, 0.60)
const TEXT_ACCENT := Color(0.52, 0.80, 0.92)
const TEXT_GOLD := Color(0.96, 0.78, 0.42)


func setup(service: BlueGuardianService) -> void:
	_service = service
	if _service != null:
		_service.state_changed.connect(_on_state_changed)
	_build()


func _build() -> void:
	anchor_left = 0.0; anchor_right = 0.0; anchor_top = 0.0; anchor_bottom = 0.0
	# Transparent panel — chrome shell provides all visual background
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	offset_left = 260; offset_top = 100
	offset_right = 260 + SHELL_S.x; offset_bottom = 100 + SHELL_S.y
	mouse_filter = Control.MOUSE_FILTER_STOP

	_chrome_plate = TextureRect.new()
	_chrome_plate.name = "ShellPlate"
	_chrome_plate.size = SHELL_S
	_chrome_plate.position = Vector2.ZERO
	_chrome_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chrome_plate.stretch_mode = TextureRect.STRETCH_KEEP
	_chrome_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chrome_plate)

	var fl = Control.new()
	fl.name = "FactLayer"
	fl.size = SHELL_S
	fl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(fl)

	# Common: title (42,25,570,48)
	_title_label = _lbl("蓝色守护", 20, TEXT_ACCENT)
	_title_label.position = Vector2(42, 25)
	_title_label.size = Vector2(570, 48)
	fl.add_child(_title_label)

	# Common: close (682,24,52,52)
	_close_btn = Button.new()
	_close_btn.position = Vector2(682, 24)
	_close_btn.size = Vector2(52, 52)
	_close_btn.flat = true
	_close_btn.pressed.connect(_on_close)
	fl.add_child(_close_btn)

	# READY state controls (page 02 manifest)
	# region_image (42,105,320,215)
	_region_image = TextureRect.new()
	_region_image.position = Vector2(42, 105)
	_region_image.size = Vector2(320, 215)
	_region_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_region_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fl.add_child(_region_image)

	# region_name (42,325,320,38)
	_region_name = _lbl("", 16, TEXT_PRIMARY)
	_region_name.position = Vector2(42, 325)
	_region_name.size = Vector2(320, 38)
	_region_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.add_child(_region_name)

	# Ready fields (right column, page 02)
	# guardian_status (395,110,325,48)
	_guardian_status = _lbl("守护艇 · 待命", 15, TEXT_ACCENT)
	_guardian_status.position = Vector2(395, 110)
	_guardian_status.size = Vector2(325, 48)
	fl.add_child(_guardian_status)

	# wave_balance (395,168,325,48)
	_wave_balance = _lbl("", 15, TEXT_GOLD)
	_wave_balance.position = Vector2(395, 168)
	_wave_balance.size = Vector2(325, 48)
	fl.add_child(_wave_balance)

	# voyage_cost (395,226,325,48)
	_voyage_cost = _lbl("", 15, TEXT_MUTED)
	_voyage_cost.position = Vector2(395, 226)
	_voyage_cost.size = Vector2(325, 48)
	fl.add_child(_voyage_cost)

	# eta (395,284,325,48)
	_eta_label = _lbl("", 14, TEXT_MUTED)
	_eta_label.position = Vector2(395, 284)
	_eta_label.size = Vector2(325, 48)
	fl.add_child(_eta_label)

	# rescue_summary (395,342,325,48)
	var rescue_summary = _lbl("", 12, TEXT_MUTED)
	rescue_summary.position = Vector2(395, 342)
	rescue_summary.size = Vector2(325, 48)
	rescue_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fl.add_child(rescue_summary)

	# VOYAGING controls (page 03 manifest)
	# countdown (405,145,300,72)
	_countdown_label = _lbl("00:00", 48, TEXT_ACCENT)
	_countdown_label.position = Vector2(405, 145)
	_countdown_label.size = Vector2(300, 72)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.visible = false
	fl.add_child(_countdown_label)

	# progress (405,225,300,28)
	_progress_bar = ProgressBar.new()
	_progress_bar.position = Vector2(405, 225)
	_progress_bar.size = Vector2(300, 28)
	_progress_bar.visible = false
	fl.add_child(_progress_bar)

	# message_primary (405,275,300,34)
	_message_primary = _lbl("守护艇正在执行救助航行", 15, TEXT_PRIMARY)
	_message_primary.position = Vector2(405, 275)
	_message_primary.size = Vector2(300, 34)
	_message_primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_primary.visible = false
	fl.add_child(_message_primary)

	# message_secondary (405,315,300,34)
	_message_secondary = _lbl("关闭页面后，航行仍会继续", 13, TEXT_MUTED)
	_message_secondary.position = Vector2(405, 315)
	_message_secondary.size = Vector2(300, 34)
	_message_secondary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_secondary.visible = false
	fl.add_child(_message_secondary)

	# voyage_count (405,365,300,34)
	_voyage_count = _lbl("", 13, TEXT_MUTED)
	_voyage_count.position = Vector2(405, 365)
	_voyage_count.size = Vector2(300, 34)
	_voyage_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voyage_count.visible = false
	fl.add_child(_voyage_count)

	# READY: primary_action (220,451,320,54) — Launch button
	_primary_action_btn = _btn("启航救助", TEXT_ACCENT)
	_primary_action_btn.position = Vector2(220, 451)
	_primary_action_btn.size = Vector2(320, 54)
	_primary_action_btn.pressed.connect(_on_launch)
	fl.add_child(_primary_action_btn)

	# VOYAGING: codex_button (48,447,240,52)
	_codex_btn = _btn("查看图鉴", TEXT_MUTED)
	_codex_btn.position = Vector2(48, 447)
	_codex_btn.size = Vector2(240, 52)
	_codex_btn.visible = false
	fl.add_child(_codex_btn)
	_codex_btn.pressed.connect(_on_codex)

	_load_chrome(BlueGuardianService.VoyageState.READY)
	_refresh()


func _process(delta: float) -> void:
	if _service == null or not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_service.ensure_voyage_settled_if_due()
		_refresh()


func _refresh() -> void:
	if _service == null: return
	var state: int = _service.get_state()
	if state != _last_state:
		_load_chrome(state)
		_last_state = state

	var is_ready = (state == BlueGuardianService.VoyageState.READY)
	var is_voyaging = (state == BlueGuardianService.VoyageState.VOYAGING)

	# Common
	_region_name.text = _service.get_dock_display_name()

	# Ready controls visibility
	_guardian_status.visible = is_ready
	_wave_balance.visible = is_ready
	_voyage_cost.visible = is_ready
	_eta_label.visible = is_ready
	_primary_action_btn.visible = is_ready

	# Voyaging controls visibility
	_countdown_label.visible = is_voyaging
	_progress_bar.visible = is_voyaging
	_message_primary.visible = is_voyaging
	_message_secondary.visible = is_voyaging
	_voyage_count.visible = is_voyaging
	_codex_btn.visible = is_voyaging

	if is_ready:
		var ws = _service.economy
		var bal: float = ws.get_waves_balance() if ws != null else 0.0
		_wave_balance.text = "浪花 %.0f 朵" % bal
		_voyage_cost.text = "消耗 %.0f 朵" % BlueGuardianConfig.WAVE_COST
		_eta_label.text = "预计 %.0f 秒" % BlueGuardianConfig.VOYAGE_DURATION_SECONDS
		var deny = _service.get_launch_deny_reason()
		_primary_action_btn.disabled = (deny != BlueGuardianService.LaunchDenyReason.NONE)

	if is_voyaging:
		var remaining: int = _service.get_remaining_seconds()
		var total: int = BlueGuardianConfig.VOYAGE_DURATION_SECONDS
		_countdown_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]
		_progress_bar.max_value = float(total)
		_progress_bar.value = max(0.0, float(total - remaining))
		var seq: int = _service.get_voyage_sequence()
		_voyage_count.text = "第 %d 次航行" % seq if seq > 0 else ""


func _load_chrome(state: int) -> void:
	var path: String = SHELL_READY if state == BlueGuardianService.VoyageState.READY else SHELL_VOYAGING
	if ResourceLoader.exists(path):
		_chrome_plate.texture = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
		_chrome_loaded = true


func _on_launch() -> void:
	if _service == null: return
	_service.launch_voyage()
	_refresh()


func _on_state_changed() -> void:
	_refresh()


func _on_codex() -> void:
	var p = get_parent()
	if p != null and p.has_method("_open_catalog_view"):
		p._open_catalog_view()


func _on_close() -> void:
	hide()
	var p = get_parent()
	if p != null and p.has_method("_hide_all_secondary_panels"):
		p._hide_all_secondary_panels()


func _on_visibility_changed() -> void:
	if visible: _refresh()


func _lbl(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _btn(text: String, fg: Color) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", fg)
	return b
