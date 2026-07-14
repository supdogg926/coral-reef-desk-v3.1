class_name M19VoyagingPanel
extends PanelContainer

var _service: BlueGuardianService = null
var _countdown_label: Label = null
var _progress_bar: ProgressBar = null
var _region_label: Label = null
var _sequence_label: Label = null
var _voyage_image: TextureRect = null
var _refresh_timer: float = 0.0
var _last_remaining: int = -1

const SHELL := M19SharedTheme.SHELL_S
const CHROME_SHELL := "res://assets/m19/ui/chrome/shell_03_voyaging_empty.png"


func setup(service: BlueGuardianService) -> void:
	_service = service
	_build()


func _build() -> void:
	# Transparent panel — chrome shell provides all visual background
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	custom_minimum_size = SHELL.size
	# Position at contract: SHELL_S = (260,100,760,520)
	anchor_left = 0.0; anchor_right = 0.0; anchor_top = 0.0; anchor_bottom = 0.0
	offset_left = SHELL.position.x; offset_top = SHELL.position.y
	offset_right = SHELL.position.x + SHELL.size.x; offset_bottom = SHELL.position.y + SHELL.size.y

	# Freeze shell plate
	var shell_tr := TextureRect.new()
	shell_tr.name = "ShellPlate"
	shell_tr.position = Vector2.ZERO
	shell_tr.size = SHELL.size
	shell_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shell_tr.stretch_mode = TextureRect.STRETCH_KEEP
	shell_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CHROME_SHELL):
		shell_tr.texture = ResourceLoader.load(CHROME_SHELL, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	add_child(shell_tr)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20); margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20); margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	margin.add_child(inner)

	# Title bar
	M19SharedTheme.make_title_bar(inner, "蓝色守护", Callable(self, "_on_close"))

	# Two-column content
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)

	# Left: voyage image
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(320, 0)
	content.add_child(left)

	_voyage_image = M19SharedTheme.make_image_slot(Vector2(300, 220), "VoyageImage")
	left.add_child(_voyage_image)

	_region_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_region_label)

	_sequence_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED)
	_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_sequence_label)

	var vsep := VSeparator.new()
	vsep.add_theme_constant_override("separation", 1)
	content.add_child(vsep)

	# Right: countdown + status
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 16)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(right)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer_top)

	_countdown_label = M19SharedTheme.make_label("00:00", M19SharedTheme.FONT_COUNTDOWN, M19SharedTheme.TEXT_ACCENT)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_countdown_label)

	_progress_bar = M19SharedTheme.make_progress_bar()
	right.add_child(_progress_bar)

	var status_label := M19SharedTheme.make_label("守护艇正在执行救助航行", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(status_label)

	var note_label := M19SharedTheme.make_label("关闭页面后，航行仍会继续", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_MUTED)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(note_label)

	var spacer_bot := Control.new()
	spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer_bot)

	# Action bar
	var action := M19SharedTheme.make_action_bar(inner)
	var codex_btn := M19SharedTheme.make_text_button("查看图鉴")
	action.add_child(codex_btn)

	var close_btn := M19SharedTheme.make_secondary_button("关闭")
	close_btn.pressed.connect(_on_close)
	action.add_child(close_btn)


func _process(delta: float) -> void:
	if _service == null or not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_service.ensure_voyage_settled_if_due()
		_refresh()


func _refresh() -> void:
	if _service == null:
		return
	var remaining := _service.get_remaining_seconds()
	var total := float(BlueGuardianConfig.VOYAGE_DURATION_SECONDS)
	_last_remaining = remaining

	var mins := remaining / 60
	var secs := remaining % 60
	_countdown_label.text = "%02d:%02d" % [mins, secs]

	_progress_bar.max_value = total
	_progress_bar.value = max(0.0, total - float(remaining))

	_region_label.text = _service.get_dock_display_name()
	var seq := _service.get_voyage_sequence()
	_sequence_label.text = "第 %d 次航行" % seq if seq > 0 else ""


func _on_close() -> void:
	hide()
	var p = get_parent()
	if p != null and p.has_method("_hide_all_secondary_panels"):
		p._hide_all_secondary_panels()


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
