class_name M19ResultPanel
extends PanelContainer

var _service: BlueGuardianService = null
var _species_image: TextureRect = null
var _species_name: Label = null
var _badge_label: Label = null
var _region_label: Label = null
var _category_label: Label = null
var _desc_label: Label = null
var _keep_effect_label: Label = null
var _release_reward_label: Label = null
var _keep_btn: Button = null
var _release_btn: Button = null

const SHELL := M19SharedTheme.SHELL_S


func setup(service: BlueGuardianService) -> void:
	_service = service
	if _service != null:
		_service.state_changed.connect(_on_state_changed)
	_build()


func _build() -> void:
	custom_minimum_size = SHELL.size
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -SHELL.size.x / 2.0; offset_top = -SHELL.size.y / 2.0
	offset_right = SHELL.size.x / 2.0; offset_bottom = SHELL.size.y / 2.0

	add_theme_stylebox_override("panel", M19SharedTheme.make_shell_style())

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
	M19SharedTheme.make_title_bar(inner, "救助结果", Callable(self, "_on_close"))

	# Two-column B (species card + fields)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)

	# Left: species image card
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(320, 0)
	content.add_child(left)

	_species_image = M19SharedTheme.make_image_slot(M19SharedTheme.SLOT_A, "SpeciesMainImage")
	left.add_child(_species_image)

	_species_name = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_species_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_species_name)

	_badge_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_GOLD)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_badge_label)

	var vsep := VSeparator.new()
	vsep.add_theme_constant_override("separation", 1)
	content.add_child(vsep)

	# Right: result fields
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)

	var field_grid := GridContainer.new()
	field_grid.columns = 2
	field_grid.add_theme_constant_override("h_separation", 16)
	field_grid.add_theme_constant_override("v_separation", 4)
	right.add_child(field_grid)

	_add_field_row(field_grid, "来源区域")
	_region_label = field_grid.get_child(field_grid.get_child_count() - 1) as Label

	_add_field_row(field_grid, "生态类别")
	_category_label = field_grid.get_child(field_grid.get_child_count() - 1) as Label

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	# Description
	_desc_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_MUTED)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_desc_label)

	# Effects
	_keep_effect_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_GREEN)
	_keep_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_keep_effect_label)

	_release_reward_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_GOLD)
	right.add_child(_release_reward_label)

	# Action bar
	var action := M19SharedTheme.make_action_bar(inner)
	_keep_btn = M19SharedTheme.make_secondary_button("留在海缸")
	_keep_btn.pressed.connect(_on_keep)
	action.add_child(_keep_btn)

	_release_btn = M19SharedTheme.make_primary_button("放归")
	_release_btn.pressed.connect(_on_release)
	action.add_child(_release_btn)

	var close_btn := M19SharedTheme.make_text_button("关闭")
	close_btn.pressed.connect(_on_close)
	action.add_child(close_btn)


func _add_field_row(grid: GridContainer, label_text: String) -> void:
	grid.add_child(M19SharedTheme.make_label(label_text, M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	grid.add_child(M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY))


func _refresh() -> void:
	if _service == null:
		return
	_service.ensure_voyage_settled_if_due()
	if _service.get_state() != BlueGuardianService.VoyageState.RESULT_PENDING:
		hide()
		return

	var data := _service.get_pending_result_data()
	var sid: String = _service.get_pending_species_id()

	_species_name.text = data.get("display_name", sid)
	_desc_label.text = data.get("description", "救助生物")

	# Image
	var tex := M19SharedTheme.load_species_texture(sid)
	if tex != null:
		_species_image.texture = tex

	# Badge
	var ids: Array = _service.get_collection_ids()
	var is_new := not ids.has(sid)
	if is_new:
		_badge_label.text = "首次发现"
		_badge_label.add_theme_color_override("font_color", M19SharedTheme.TEXT_GOLD)
	else:
		_badge_label.text = "再次相遇"
		_badge_label.add_theme_color_override("font_color", M19SharedTheme.TEXT_ACCENT)

	# Region
	_region_label.text = BlueGuardianConfig.get_species_region(sid)
	_category_label.text = BlueGuardianConfig.get_species_rarity_tier(sid)

	# Effects
	_keep_effect_label.text = "留在海缸可获得持续收益"
	_release_reward_label.text = "放归获得 %.0f 朵浪花" % BlueGuardianConfig.get_release_pulse(sid)

	# Capacity check
	var cap_full := false
	if _service.livestock_gw != null:
		var cap: Dictionary = _service.livestock_gw.get_debug_state()
		cap_full = float(cap.get("current_capacity_used", 0.0)) >= float(cap.get("max_capacity", 30.0))
	_keep_btn.disabled = cap_full
	_keep_btn.tooltip_text = "海缸容量不足" if cap_full else ""


func _on_keep() -> void:
	if _service == null:
		return
	var r := _service.keep_pending_result()
	if r.get("success", false):
		_refresh()
	else:
		_desc_label.text = "操作失败：" + str(r.get("error", ""))

func _on_release() -> void:
	if _service == null:
		return
	var r := _service.release_pending_result()
	if r.get("success", false):
		_refresh()
	else:
		_desc_label.text = "放归失败"

func _on_state_changed() -> void:
	_refresh()

func _on_close() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_refresh()
