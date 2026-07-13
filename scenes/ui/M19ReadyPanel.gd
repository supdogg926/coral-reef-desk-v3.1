class_name M19ReadyPanel
extends PanelContainer

var _service: BlueGuardianService = null
var _dock_label: Label = null
var _status_label: Label = null
var _balance_label: Label = null
var _cost_label: Label = null
var _region_label: Label = null
var _ecology_label: Label = null
var _region_image: TextureRect = null
var _launch_btn: Button = null
var _hint_label: Label = null

const SHELL := M19SharedTheme.SHELL_S
const CHROME_SHELL := "res://assets/m19/ui/chrome/shell_02_ready_empty.png"


func setup(service: BlueGuardianService) -> void:
	_service = service
	_build()
	_refresh()


func _build() -> void:
	custom_minimum_size = SHELL.size
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -SHELL.size.x / 2.0
	offset_top = -SHELL.size.y / 2.0
	offset_right = SHELL.size.x / 2.0
	offset_bottom = SHELL.size.y / 2.0

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
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	margin.add_child(inner)

	# Title bar
	M19SharedTheme.make_title_bar(inner, "蓝色守护", Callable(self, "_on_close"))
	inner.get_child(inner.get_child_count() - 1)  # separator already added

	# Two-column content
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)

	# Left column: region image + name + ecology
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(320, 0)
	content.add_child(left)

	_region_image = M19SharedTheme.make_image_slot(Vector2(300, 220), "RegionImage")
	left.add_child(_region_image)

	_region_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_region_label)

	_ecology_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED)
	_ecology_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_ecology_label)

	# Separator between columns
	var vsep := VSeparator.new()
	vsep.add_theme_constant_override("separation", 1)
	content.add_child(vsep)

	# Right column: info grid
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)

	# Status + dock info
	var info_grid := GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 16)
	info_grid.add_theme_constant_override("v_separation", 6)
	info_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(info_grid)

	info_grid.add_child(M19SharedTheme.make_label("当前码头", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	info_grid.add_child(M19SharedTheme.make_label("守护艇", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))

	_dock_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_status_label = M19SharedTheme.make_label("待命", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_ACCENT)
	info_grid.add_child(_dock_label)
	info_grid.add_child(_status_label)

	info_grid.add_child(M19SharedTheme.make_label("浪花余额", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	info_grid.add_child(M19SharedTheme.make_label("启航消耗", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))

	_balance_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_LARGE_NUMBER, M19SharedTheme.TEXT_GOLD)
	_cost_label = M19SharedTheme.make_label("100朵", M19SharedTheme.FONT_LARGE_NUMBER, M19SharedTheme.TEXT_MUTED)
	info_grid.add_child(_balance_label)
	info_grid.add_child(_cost_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	# Hint
	_hint_label = M19SharedTheme.make_label("守护艇将带回一只需要帮助的海洋生物", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_MUTED)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_hint_label)

	# Action bar
	var action := M19SharedTheme.make_action_bar(inner)
	_launch_btn = M19SharedTheme.make_primary_button("启航救助")
	_launch_btn.pressed.connect(_on_launch)
	action.add_child(_launch_btn)

	var close_btn := M19SharedTheme.make_secondary_button("关闭")
	close_btn.pressed.connect(_on_close)
	action.add_child(close_btn)


func _refresh() -> void:
	if _service == null:
		return
	_dock_label.text = _service.get_dock_display_name()
	_status_label.text = "待命"

	var ws: EconomySystem = _service.economy
	if ws != null:
		_balance_label.text = "%.0f朵" % ws.get_waves_balance()
	_cost_label.text = "%.0f朵" % BlueGuardianConfig.WAVE_COST

	# Region info
	var dock_name := _service.get_dock_display_name()
	_region_label.text = dock_name

	# Get ecology tags from dock species
	var docks := BlueGuardianConfig.get_region_docks()
	var tags: String = ""
	for d in docks:
		if str(d.get("display_name", "")) == dock_name:
			var species: Array = d.get("species", [])
			var categories: Array[String] = []
			for sid in species:
				var cat := BlueGuardianConfig.get_species_rarity_tier(str(sid))
				if not categories.has(cat):
					categories.append(cat)
			tags = "本区常见生态：" + ", ".join(categories)
			break
	_ecology_label.text = tags

	# Button state
	var deny := _service.get_launch_deny_reason()
	_launch_btn.disabled = (deny != BlueGuardianService.LaunchDenyReason.NONE)
	match deny:
		BlueGuardianService.LaunchDenyReason.VOYAGING:
			_launch_btn.tooltip_text = "守护艇正在航行中"
		BlueGuardianService.LaunchDenyReason.INSUFFICIENT_WAVES:
			_launch_btn.tooltip_text = "浪花不足"
		BlueGuardianService.LaunchDenyReason.PENDING_UNRESOLVED:
			_launch_btn.tooltip_text = "请先处理本次救助结果"


func _on_launch() -> void:
	if _service == null:
		return
	var result := _service.launch_voyage()
	if result.get("success", false):
		_refresh()


func _on_close() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
