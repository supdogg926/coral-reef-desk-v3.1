class_name M19ReleasePanel
extends PanelContainer

var _livestock_sys = null
var _economy_sys = null
var _livestock_list: ItemList = null
var _main_image: TextureRect = null
var _species_name: Label = null
var _comfort_label: Label = null
var _health_label: Label = null
var _income_label: Label = null
var _reward_label: Label = null
var _status_label: Label = null
var _keep_btn: Button = null
var _release_btn: Button = null
var _filter_buttons: Dictionary = {}
var _current_filter: String = "全部"
var _selected_entry: Dictionary = {}
var _selected_idx: int = -1

const SHELL := M19SharedTheme.SHELL_L
const CHROME_SHELL := "res://assets/m19/ui/chrome/shell_06_release_empty.png"
const FILTERS := ["全部", "可放归", "观察中"]


func setup(livestock_sys, economy_sys) -> void:
	_livestock_sys = livestock_sys
	_economy_sys = economy_sys
	_build()


func _build() -> void:
	custom_minimum_size = SHELL.size
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -SHELL.size.x / 2.0; offset_top = -SHELL.size.y / 2.0
	offset_right = SHELL.size.x / 2.0; offset_bottom = SHELL.size.y / 2.0

	# Freeze shell plate
	var shell_tr := TextureRect.new()
	shell_tr.name = "Shell05Plate"
	shell_tr.position = Vector2.ZERO
	shell_tr.size = SHELL.size
	shell_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shell_tr.stretch_mode = TextureRect.STRETCH_KEEP
	shell_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CHROME_SHELL):
		shell_tr.texture = ResourceLoader.load(CHROME_SHELL, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	add_child(shell_tr)

	# Hide old visual containers — freeze shell replaces them
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

	M19SharedTheme.make_title_bar(inner, "放归", Callable(self, "_on_close"))

	# Filter row
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	inner.add_child(filter_row)
	for f in FILTERS:
		var fb := M19SharedTheme.make_text_button(f)
		fb.pressed.connect(_on_filter.bind(f))
		filter_row.add_child(fb)
		_filter_buttons[f] = fb

	# Two-column content
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)

	# Left: livestock list
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(260, 0)
	content.add_child(left)

	_livestock_list = ItemList.new()
	_livestock_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_livestock_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_livestock_list.item_selected.connect(_on_livestock_selected)
	left.add_child(_livestock_list)

	# Center: main image
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 8)
	center.custom_minimum_size = Vector2(320, 0)
	content.add_child(center)

	_main_image = M19SharedTheme.make_image_slot(M19SharedTheme.SLOT_A, "ReleaseMainImage")
	center.add_child(_main_image)

	_species_name = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_species_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_species_name)

	_status_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_ACCENT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_status_label)

	# Right: detail fields
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)

	var info_grid := GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 12)
	info_grid.add_theme_constant_override("v_separation", 4)
	right.add_child(info_grid)

	info_grid.add_child(M19SharedTheme.make_label("舒适度", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_comfort_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY)
	info_grid.add_child(_comfort_label)

	info_grid.add_child(M19SharedTheme.make_label("健康状态", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_health_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY)
	info_grid.add_child(_health_label)

	info_grid.add_child(M19SharedTheme.make_label("留缸贡献", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_income_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_GOLD)
	info_grid.add_child(_income_label)

	info_grid.add_child(M19SharedTheme.make_label("放归回响", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_reward_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_GOLD)
	info_grid.add_child(_reward_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	# Action bar
	var action := M19SharedTheme.make_action_bar(inner)
	_keep_btn = M19SharedTheme.make_secondary_button("继续留养")
	_keep_btn.pressed.connect(_on_close)
	action.add_child(_keep_btn)

	_release_btn = M19SharedTheme.make_primary_button("确认放归")
	_release_btn.pressed.connect(_on_release)
	action.add_child(_release_btn)

	var close_btn := M19SharedTheme.make_text_button("关闭")
	close_btn.pressed.connect(_on_close)
	action.add_child(close_btn)

	_refresh_list()

	
	# Hide ALL old visual containers — only freeze shell + its children should be visible
	for child in get_children():
		if child is VBoxContainer or child is MarginContainer or child is HBoxContainer:
			if child.name != "FactLayer" and child.name != "HitLayer":
				child.visible = false
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _refresh_list() -> void:
	_livestock_list.clear()
	if _livestock_sys == null:
		return

	var debug: Dictionary = _livestock_sys.get_debug_state()
	var livestock: Array = debug.get("owned_livestock", [])
	for i in range(livestock.size()):
		var entry: Dictionary = livestock[i]
		if bool(entry.get("locked", false)):
			continue

		var is_rescue := bool(entry.get("is_rescue", false))
		var rescue_status := str(entry.get("rescue_status", "none"))
		var health := float(entry.get("health_percent", 100.0))

		# Apply filter
		var can_release := health >= 70.0 and rescue_status == "healthy"
		var in_observation := not can_release or rescue_status != "healthy"

		if _current_filter == "可放归" and not can_release:
			continue
		if _current_filter == "观察中" and not in_observation:
			continue

		var name := str(entry.get("species_name", entry.get("id", "未知")))
		var display := name
		if is_rescue:
			display += " [救]" if rescue_status == "healthy" else " [观察]"

		var idx := _livestock_list.add_item(display)
		_livestock_list.set_item_metadata(idx, {"index": i, "entry": entry})
		if not can_release:
			_livestock_list.set_item_custom_fg_color(idx, M19SharedTheme.TEXT_MUTED)


func _on_livestock_selected(idx: int) -> void:
	var meta: Dictionary = _livestock_list.get_item_metadata(idx)
	_selected_entry = meta.get("entry", {})
	_selected_idx = meta.get("index", -1)

	var name := str(_selected_entry.get("species_name", "未知"))
	_species_name.text = name

	var health := float(_selected_entry.get("health_percent", 100.0))
	_health_label.text = "%.0f%%" % health

	var comfort := float(_livestock_sys.get_debug_state().get("comfort_score", 100.0))
	_comfort_label.text = "%.0f" % comfort

	var income := float(_selected_entry.get("base_income_per_hour", 0.0))
	if income > 0:
		_income_label.text = "%.1f朵/小时" % income
	else:
		_income_label.text = "—"

	var species_id := _extract_species_id()
	var reward: float = float(BlueGuardianConfig.get_release_pulse(species_id)) if species_id != "" else 15.0
	_reward_label.text = "%.0f朵浪花" % reward

	# Image
	if species_id != "":
		var tex := M19SharedTheme.load_species_texture(species_id)
		if tex != null:
			_main_image.texture = tex
		else:
			_main_image.texture = null

	# Status and eligibility
	var rescue_status := str(_selected_entry.get("rescue_status", "none"))
	var can_release := health >= 70.0 and rescue_status == "healthy"
	_status_label.text = "可放归" if can_release else "仍在恢复观察中"
	_status_label.add_theme_color_override("font_color", M19SharedTheme.TEXT_GREEN if can_release else M19SharedTheme.TEXT_WARN)

	_release_btn.disabled = not can_release
	_release_btn.tooltip_text = "该生物仍需观察，暂时不能放归" if not can_release else ""


func _extract_species_id() -> String:
	var entry_id := str(_selected_entry.get("id", ""))
	# Entry IDs from rescue look like "species_id_TIMESTAMP"
	var parts := entry_id.split("_")
	if parts.size() >= 2:
		# Try to reconstruct: the id format is species_id_timestamp
		# e.g. cleaner_shrimp_1752422400
		var last_part := parts[parts.size() - 1]
		if last_part.is_valid_int():
			parts.remove_at(parts.size() - 1)
			return "_".join(parts)
	return entry_id


func _on_release() -> void:
	if _livestock_sys == null or _selected_entry.is_empty():
		return
	var entry_id := str(_selected_entry.get("id", ""))
	var result: Dictionary = _livestock_sys.release_livestock(entry_id)
	if result.get("success", false):
		_selected_entry = {}
		_selected_idx = -1
		_main_image.texture = null
		_species_name.text = ""
		_refresh_list()
	else:
		_status_label.text = "放归失败：" + str(result.get("error", ""))


func _on_filter(filter: String) -> void:
	_current_filter = filter
	_refresh_list()
	for f in _filter_buttons:
		var btn: Button = _filter_buttons[f]
		btn.add_theme_color_override("font_color", M19SharedTheme.TEXT_ACCENT if f == filter else M19SharedTheme.TEXT_MUTED)


func _on_close() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()
