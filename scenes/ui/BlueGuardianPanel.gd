class_name BlueGuardianPanel
extends PanelContainer

var _service: BlueGuardianService = null
var _title_label: Label = null
var _dock_label: Label = null
var _status_label: Label = null
var _timer_label: Label = null
var _balance_label: Label = null
var _cost_label: Label = null
var _action_btn: Button = null
var _keep_btn: Button = null
var _release_btn: Button = null
var _result_image: TextureRect = null
var _result_name: Label = null
var _result_desc: Label = null
var _result_new_label: Label = null

var _ready_section: Control = null
var _voyaging_section: Control = null
var _result_section: Control = null
var _catalog_section: Control = null

var _last_state: int = -1
var _last_remaining: int = -1
var _refresh_timer: float = 0.0

const BG_COLOR := Color(0.08, 0.12, 0.16)
const CARD_BG := Color(0.12, 0.15, 0.19)
const TEXT_COLOR := Color(0.82, 0.88, 0.86)
const MUTED_COLOR := Color(0.50, 0.56, 0.56)
const ACCENT_COLOR := Color(0.58, 0.78, 0.88)


func setup(service: BlueGuardianService) -> void:
	_service = service
	if _service != null:
		_service.state_changed.connect(_on_state_changed)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	custom_minimum_size = Vector2(360, 400)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(0.20, 0.28, 0.32)
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_title_label = _lbl("蓝色守护", 18, ACCENT_COLOR)
	vbox.add_child(_title_label)

	# READY section
	_ready_section = VBoxContainer.new()
	_ready_section.add_theme_constant_override("separation", 6)
	vbox.add_child(_ready_section)

	_dock_label = _lbl("", 13, MUTED_COLOR)
	_ready_section.add_child(_dock_label)
	_status_label = _lbl("守护艇：待命", 14, TEXT_COLOR)
	_ready_section.add_child(_status_label)

	var bal_row := HBoxContainer.new()
	bal_row.add_theme_constant_override("separation", 16)
	_ready_section.add_child(bal_row)
	_balance_label = _lbl("", 13, TEXT_COLOR)
	bal_row.add_child(_balance_label)
	_cost_label = _lbl("", 13, MUTED_COLOR)
	bal_row.add_child(_cost_label)

	_action_btn = _btn("启航救助", ACCENT_COLOR)
	_action_btn.pressed.connect(_on_action)
	_ready_section.add_child(_action_btn)

	# VOYAGING section
	_voyaging_section = VBoxContainer.new()
	_voyaging_section.add_theme_constant_override("separation", 6)
	_voyaging_section.visible = false
	vbox.add_child(_voyaging_section)

	_timer_label = _lbl("", 24, ACCENT_COLOR)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voyaging_section.add_child(_timer_label)
	var voyaging_status := _lbl("守护艇正在航行中", 14, TEXT_COLOR)
	voyaging_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voyaging_section.add_child(voyaging_status)

	# RESULT section
	_result_section = VBoxContainer.new()
	_result_section.add_theme_constant_override("separation", 6)
	_result_section.visible = false
	vbox.add_child(_result_section)

	_result_image = TextureRect.new()
	_result_image.custom_minimum_size = Vector2(200, 140)
	_result_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_result_section.add_child(_result_image)

	_result_new_label = _lbl("", 12, Color(0.96, 0.72, 0.36))
	_result_section.add_child(_result_new_label)
	_result_name = _lbl("", 16, TEXT_COLOR)
	_result_section.add_child(_result_name)
	_result_desc = _lbl("", 12, MUTED_COLOR)
	_result_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_section.add_child(_result_desc)

	var result_btns := HBoxContainer.new()
	result_btns.add_theme_constant_override("separation", 8)
	result_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_section.add_child(result_btns)
	_keep_btn = _btn("留在海缸", Color(0.58, 0.82, 0.68))
	_keep_btn.pressed.connect(_on_keep)
	result_btns.add_child(_keep_btn)
	_release_btn = _btn("放归", Color(0.88, 0.72, 0.52))
	_release_btn.pressed.connect(_on_release)
	result_btns.add_child(_release_btn)

	# CATALOG section
	_catalog_section = VBoxContainer.new()
	_catalog_section.add_theme_constant_override("separation", 4)
	_catalog_section.visible = false
	vbox.add_child(_catalog_section)

	var cat_title := _lbl("救助图鉴", 14, ACCENT_COLOR)
	_catalog_section.add_child(cat_title)
	var _catalog_list := _lbl("", 12, MUTED_COLOR)
	_catalog_list.name = "CatalogList"
	_catalog_section.add_child(_catalog_list)

	# Bottom buttons
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom_row)
	var cat_btn := _btn("图鉴", MUTED_COLOR)
	cat_btn.pressed.connect(_toggle_catalog)
	bottom_row.add_child(cat_btn)
	var close_btn := _btn("关闭", MUTED_COLOR)
	close_btn.pressed.connect(func(): hide())
	bottom_row.add_child(close_btn)


func _process(delta: float) -> void:
	if _service == null or not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_service.ensure_voyage_settled_if_due()
		var remaining := _service.get_remaining_seconds()
		var state := _service.get_state()
		if remaining != _last_remaining or state != _last_state:
			_refresh()


func _refresh() -> void:
	if _service == null:
		return
	var state := _service.get_state()
	_last_state = state

	_ready_section.visible = (state == BlueGuardianService.VoyageState.READY)
	_voyaging_section.visible = (state == BlueGuardianService.VoyageState.VOYAGING)
	_result_section.visible = (state == BlueGuardianService.VoyageState.RESULT_PENDING)

	_dock_label.text = "当前码头：" + _service.get_dock_display_name()

	if _economy() != null:
		_balance_label.text = "浪花余额：%.0f朵" % _economy().get_waves_balance()
	_cost_label.text = "启航消耗：%.0f朵" % BlueGuardianConfig.WAVE_COST

	if state == BlueGuardianService.VoyageState.READY:
		var deny := _service.get_launch_deny_reason()
		_action_btn.disabled = (deny != BlueGuardianService.LaunchDenyReason.NONE)
		match deny:
			BlueGuardianService.LaunchDenyReason.VOYAGING:
				_action_btn.tooltip_text = "守护艇正在航行中"
			BlueGuardianService.LaunchDenyReason.INSUFFICIENT_WAVES:
				_action_btn.tooltip_text = "浪花不足，继续经营海缸即可积累浪花"
			BlueGuardianService.LaunchDenyReason.PENDING_UNRESOLVED:
				_action_btn.tooltip_text = "请先处理本次救助结果"
			_:
				_action_btn.tooltip_text = ""

	if state == BlueGuardianService.VoyageState.VOYAGING:
		var remaining := _service.get_remaining_seconds()
		_last_remaining = remaining
		var mins := remaining / 60
		var secs := remaining % 60
		_timer_label.text = "%02d:%02d" % [mins, secs]

	if state == BlueGuardianService.VoyageState.RESULT_PENDING:
		var data: Dictionary = _service.get_pending_result_data()
		_result_name.text = data.get("display_name", "")
		_result_desc.text = data.get("description", "")
		var sid: String = _service.get_pending_species_id()
		var is_new: bool = not _service.get_collection_ids().has(sid)
		_result_new_label.text = "新图鉴记录！" if is_new else ""
		_load_result_image(sid)

		var cap_full: bool = _check_capacity_full()
		_keep_btn.disabled = cap_full
		_keep_btn.tooltip_text = "海缸容量不足，可以先放归一只生物" if cap_full else ""


func _on_state_changed() -> void:
	_refresh()


func _on_action() -> void:
	if _service == null:
		return
	var result := _service.launch_voyage()
	if result.get("success", false):
		_refresh()
	else:
		var deny: Variant = result.get("deny_reason", -1)
		if deny == BlueGuardianService.LaunchDenyReason.INSUFFICIENT_WAVES:
			_action_btn.tooltip_text = "浪花不足！"
		_status_label.text = "启航失败"


func _on_keep() -> void:
	if _service == null:
		return
	var result := _service.keep_in_tank()
	if result.get("success", false):
		_refresh()
	else:
		_result_desc.text = "操作失败：" + str(result.get("error", "unknown"))


func _on_release() -> void:
	if _service == null:
		return
	var result := _service.release_pending()
	if result.get("success", false):
		_refresh()
	else:
		_result_desc.text = "放归失败"


func _toggle_catalog() -> void:
	_catalog_section.visible = not _catalog_section.visible
	if _catalog_section.visible and _service != null:
		var ids: Array = _service.get_collection_ids()
		var cat_text := "已救助：%d\n" % ids.size()
		for sid in ids:
			var name: String = str(sid).replace("_", " ").capitalize()
			cat_text += "  " + name + "\n"
		var list_node := _catalog_section.get_node_or_null("CatalogList")
		if list_node is Label:
			list_node.text = cat_text


func _load_result_image(species_id: String) -> void:
	if _result_image == null:
		return
	var lib = _get_card_library()
	if lib != null and lib.has_method("get_card_texture"):
		var tex_result: Variant = lib.call("get_card_texture", species_id)
		if tex_result is Dictionary and tex_result.get("success", false):
			var tex = tex_result.get("texture", null)
			if tex != null:
				_result_image.texture = tex
				return
	_result_image.texture = null


func _check_capacity_full() -> bool:
	if _livestock_sys() != null:
		var cap: Dictionary = _livestock_sys().get_debug_state()
		return float(cap.get("current_capacity_used", 0.0)) >= float(cap.get("max_capacity", 30.0))
	return false


func _economy() -> EconomySystem:
	if _service != null and _service._economy_system != null:
		return _service._economy_system
	return null


func _livestock_sys() -> RefCounted:
	if _service != null:
		return _service._livestock_system
	return null


func _get_card_library() -> RefCounted:
	if _service != null:
		return _service._card_asset_library
	return null


func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 32)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", color)
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(4)
	s.set_border_width_all(1)
	s.border_color = Color(0.22, 0.28, 0.30)
	b.add_theme_stylebox_override("normal", s)
	return b
