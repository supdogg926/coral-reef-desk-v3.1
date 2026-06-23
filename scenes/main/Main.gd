extends Control

@onready var status_panel: StatusPanel = %StatusPanel

var game_state: GameState = null
var shop_panel: ShopPanel = null
var livestock_panel: LivestockPanel = null
var shop_btn: Button = null
var livestock_btn: Button = null
var panel_status_label: Label = null
var maintenance_feedback_label: Label = null
var maintenance_balance_label: Label = null
var maintenance_buttons: Dictionary = {}
var maintenance_button_base_texts: Dictionary = {}
var maintenance_button_costs: Dictionary = {}
var device_buttons: Dictionary = {}
var device_button_base_texts: Dictionary = {}
var _panels_setup_done: bool = false
var _livestock_refresh_timer: float = 0.0
var _maintenance_button_refresh_timer: float = 0.0
const LIVESTOCK_REFRESH_INTERVAL: float = 0.5
const MAINTENANCE_BUTTON_REFRESH_INTERVAL: float = 0.5
const SAFE_LEFT_MARGIN: int = 40
const SAFE_RIGHT_MARGIN: int = 18
const SAFE_TOP_MARGIN: int = 36
const SAFE_BOTTOM_MARGIN: int = 24
var _alive_tick: int = 0
var _alive_timer: float = 0.0


func _ready() -> void:
	game_state = GameState.new()
	game_state.initialize()
	_update_status_labels()
	_setup_panels()


func _process(delta: float) -> void:
	if game_state == null:
		return
	game_state.update(delta)
	_update_status_labels()
	if _is_dev_debug_ui_enabled():
		_alive_timer += delta
	if _is_dev_debug_ui_enabled() and _alive_timer >= 1.0:
		_alive_timer = 0.0
		_alive_tick += 1
		print("[HEARTBEAT] tick=%d" % _alive_tick)
		if panel_status_label != null:
			panel_status_label.text = "tick=%d" % _alive_tick
	if livestock_panel != null and livestock_panel.visible:
		_livestock_refresh_timer += delta
		if _livestock_refresh_timer >= LIVESTOCK_REFRESH_INTERVAL:
			_livestock_refresh_timer = 0.0
			livestock_panel.update_display()
	_maintenance_button_refresh_timer += delta
	if _maintenance_button_refresh_timer >= MAINTENANCE_BUTTON_REFRESH_INTERVAL:
		_maintenance_button_refresh_timer = 0.0
		_update_maintenance_button_states()
		_update_device_button_states()


func _setup_panels() -> void:
	if _panels_setup_done:
		return
	var root_margin: MarginContainer = null
	var layout: VBoxContainer = null
	for child in get_children():
		if child is MarginContainer:
			root_margin = child
			for sub in child.get_children():
				if sub is VBoxContainer:
					layout = sub
					break
	if layout == null:
		return
	_apply_safe_screen_margins(root_margin)
	_stabilize_main_layout(layout)

	var btn_bar: PanelContainer = PanelContainer.new()
	btn_bar.name = "M11PrototypeEntryBar"
	btn_bar.custom_minimum_size = Vector2(0, 66)
	btn_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar_style: StyleBoxFlat = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.15, 0.18, 0.20, 1.0)
	bar_style.set_border_width_all(0)
	bar_style.set_corner_radius_all(4)
	btn_bar.add_theme_stylebox_override("panel", bar_style)
	var bar_margin: MarginContainer = MarginContainer.new()
	bar_margin.add_theme_constant_override("margin_left", 8)
	bar_margin.add_theme_constant_override("margin_top", 4)
	bar_margin.add_theme_constant_override("margin_right", 8)
	bar_margin.add_theme_constant_override("margin_bottom", 4)
	btn_bar.add_child(bar_margin)
	var bar_column: VBoxContainer = VBoxContainer.new()
	bar_column.add_theme_constant_override("separation", 3)
	bar_margin.add_child(bar_column)
	var bar_row: HBoxContainer = HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 5)
	bar_column.add_child(bar_row)
	var device_row: HBoxContainer = HBoxContainer.new()
	device_row.add_theme_constant_override("separation", 5)
	bar_column.add_child(device_row)

	shop_btn = Button.new()
	shop_btn.text = "生物商店"
	shop_btn.custom_minimum_size = Vector2(92, 30)
	shop_btn.add_theme_font_size_override("font_size", 12)
	shop_btn.pressed.connect(_toggle_shop)
	bar_row.add_child(shop_btn)

	livestock_btn = Button.new()
	livestock_btn.text = "我的生物"
	livestock_btn.custom_minimum_size = Vector2(92, 30)
	livestock_btn.add_theme_font_size_override("font_size", 12)
	livestock_btn.pressed.connect(_toggle_livestock)
	bar_row.add_child(livestock_btn)

	_add_water_maintenance_controls(bar_row)

	if _is_dev_debug_ui_enabled():
		var reset_btn: Button = Button.new()
		reset_btn.text = "重置M10测试存档"
		reset_btn.custom_minimum_size = Vector2(130, 30)
		reset_btn.add_theme_font_size_override("font_size", 11)
		reset_btn.add_theme_color_override("font_color", Color(0.95, 0.70, 0.40))
		reset_btn.pressed.connect(_reset_test_save)
		bar_row.add_child(reset_btn)

		var manual_save_btn: Button = Button.new()
		manual_save_btn.text = "手动保存测试"
		manual_save_btn.custom_minimum_size = Vector2(110, 30)
		manual_save_btn.add_theme_font_size_override("font_size", 11)
		manual_save_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.40))
		manual_save_btn.pressed.connect(_manual_save_test)
		bar_row.add_child(manual_save_btn)

		panel_status_label = Label.new()
		panel_status_label.text = ""
		panel_status_label.add_theme_font_size_override("font_size", 10)
		panel_status_label.add_theme_color_override("font_color", Color(0.60, 0.85, 0.70))
		bar_row.add_child(panel_status_label)

	_add_device_controls(device_row)
	layout.add_child(btn_bar)

	var title_index: int = -1
	for i in range(layout.get_child_count()):
		var child: Node = layout.get_child(i)
		if child.name == "TitleBar":
			title_index = i
			break
	if title_index >= 0:
		layout.move_child(btn_bar, min(title_index + 1, layout.get_child_count() - 1))

	shop_panel = ShopPanel.new()
	shop_panel.hide()
	add_child(shop_panel)
	shop_panel.setup(game_state)

	livestock_panel = LivestockPanel.new()
	livestock_panel.hide()
	add_child(livestock_panel)
	livestock_panel.setup(game_state)

	_panels_setup_done = true
	_update_maintenance_button_states()
	_update_device_button_states()


func _stabilize_main_layout(layout: VBoxContainer) -> void:
	layout.add_theme_constant_override("separation", 3)
	for child in layout.get_children():
		if child.name == "DisplayTankView" and child is Control:
			var display: Control = child
			display.custom_minimum_size = Vector2(0, 260)
			display.size_flags_vertical = Control.SIZE_EXPAND_FILL
			display.size_flags_stretch_ratio = 3.0
		elif child.name == "SumpView" and child is Control:
			var sump: Control = child
			sump.custom_minimum_size = Vector2(0, 112)
			sump.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sump.size_flags_stretch_ratio = 1.2
		elif child == status_panel:
			status_panel.custom_minimum_size = Vector2(0, 142)
			status_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			status_panel.size_flags_stretch_ratio = 1.4


func _apply_safe_screen_margins(root_margin: MarginContainer) -> void:
	if root_margin == null:
		return
	root_margin.add_theme_constant_override("margin_left", SAFE_LEFT_MARGIN)
	root_margin.add_theme_constant_override("margin_right", SAFE_RIGHT_MARGIN)
	root_margin.add_theme_constant_override("margin_top", SAFE_TOP_MARGIN)
	root_margin.add_theme_constant_override("margin_bottom", SAFE_BOTTOM_MARGIN)


func _on_shop_purchase() -> void:
	_update_status_labels()
	if livestock_panel != null and livestock_panel.visible:
		livestock_panel.update_display()
	_livestock_refresh_timer = 0.0


func _reset_test_save() -> void:
	if game_state == null or game_state.save_system == null:
		return
	game_state.save_system.clear_save()
	shop_panel.hide()
	livestock_panel.hide()
	game_state = null
	game_state = GameState.new()
	game_state.initialize()
	_update_status_labels()
	if panel_status_label != null:
		panel_status_label.text = "存档已重置，已恢复6个初始生物"
	print("[RESET] save cleared, GameState reinitialized")


func _manual_save_test() -> void:
	if game_state == null:
		return
	print("[MANUAL SAVE] calling _perform_autosave")
	game_state._perform_autosave()
	print("[MANUAL SAVE] _perform_autosave returned")
	if panel_status_label != null:
		panel_status_label.text = "手动保存完成"


func _is_dev_debug_ui_enabled() -> bool:
	return OS.is_debug_build()


func _toggle_shop() -> void:
	if shop_panel == null:
		return
	if shop_panel.visible:
		shop_panel.hide()
		shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if panel_status_label != null:
			panel_status_label.text = ""
	else:
		livestock_panel.hide()
		livestock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		shop_panel.anchor_left = 0.04
		shop_panel.anchor_right = 0.96
		shop_panel.anchor_top = 0.10
		shop_panel.anchor_bottom = 0.90
		shop_panel.offset_left = 0.0
		shop_panel.offset_right = 0.0
		shop_panel.offset_top = 0.0
		shop_panel.offset_bottom = 0.0
		shop_panel.update_display()
		shop_panel.show()
		if shop_panel.get_parent() != null:
			shop_panel.get_parent().move_child(shop_panel, shop_panel.get_parent().get_child_count() - 1)
		if panel_status_label != null:
			panel_status_label.text = "已打开：生物商店"


func _toggle_livestock() -> void:
	if livestock_panel == null:
		return
	if livestock_panel.visible:
		livestock_panel.hide()
		livestock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if panel_status_label != null:
			panel_status_label.text = ""
	else:
		shop_panel.hide()
		shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		livestock_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		livestock_panel.update_display()
		livestock_panel.anchor_left = 0.04
		livestock_panel.anchor_right = 0.96
		livestock_panel.anchor_top = 0.10
		livestock_panel.anchor_bottom = 0.90
		livestock_panel.offset_left = 0.0
		livestock_panel.offset_right = 0.0
		livestock_panel.offset_top = 0.0
		livestock_panel.offset_bottom = 0.0
		livestock_panel.show()
		if livestock_panel.get_parent() != null:
			livestock_panel.get_parent().move_child(livestock_panel, livestock_panel.get_parent().get_child_count() - 1)
		if panel_status_label != null:
			panel_status_label.text = "已打开：我的生物"


func _add_water_maintenance_controls(bar_row: HBoxContainer) -> void:
	if game_state == null:
		return
	maintenance_buttons.clear()
	maintenance_button_base_texts.clear()
	maintenance_button_costs.clear()
	maintenance_balance_label = null
	var separator: VSeparator = VSeparator.new()
	separator.custom_minimum_size = Vector2(4, 24)
	bar_row.add_child(separator)

	var title_label: Label = Label.new()
	title_label.text = "水质维护"
	title_label.custom_minimum_size = Vector2(54, 24)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(0.74, 0.86, 0.88))
	bar_row.add_child(title_label)

	maintenance_balance_label = Label.new()
	maintenance_balance_label.text = "RP 0"
	maintenance_balance_label.custom_minimum_size = Vector2(58, 24)
	maintenance_balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	maintenance_balance_label.add_theme_font_size_override("font_size", 11)
	maintenance_balance_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	bar_row.add_child(maintenance_balance_label)

	for raw_action in game_state.get_water_maintenance_actions():
		if not raw_action is Dictionary:
			continue
		var action: Dictionary = raw_action
		var action_id: String = String(action.get("id", ""))
		var action_cost: float = float(action.get("cost", 0.0))
		var button: Button = Button.new()
		var base_text: String = "%s %.0fRP" % [String(action.get("short_label", action.get("label", action_id))), action_cost]
		button.text = base_text
		button.tooltip_text = String(action.get("description", ""))
		button.custom_minimum_size = Vector2(86, 30)
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_on_water_maintenance_pressed.bind(action_id))
		bar_row.add_child(button)
		maintenance_buttons[action_id] = button
		maintenance_button_base_texts[action_id] = base_text
		maintenance_button_costs[action_id] = action_cost

	maintenance_feedback_label = Label.new()
	maintenance_feedback_label.text = "未维护"
	maintenance_feedback_label.custom_minimum_size = Vector2(164, 24)
	maintenance_feedback_label.clip_text = true
	maintenance_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	maintenance_feedback_label.add_theme_font_size_override("font_size", 10)
	maintenance_feedback_label.add_theme_color_override("font_color", Color(0.68, 0.88, 0.84))
	bar_row.add_child(maintenance_feedback_label)


func _add_device_controls(device_row: HBoxContainer) -> void:
	if game_state == null:
		return
	device_buttons.clear()
	device_button_base_texts.clear()

	var title_label: Label = Label.new()
	title_label.text = "设备控制"
	title_label.custom_minimum_size = Vector2(54, 24)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(0.74, 0.86, 0.88))
	device_row.add_child(title_label)

	var device_order: Array[String] = ["return_pump", "wave_pump", "main_light", "reserve"]
	for device_id in device_order:
		var state: Dictionary = game_state.get_device_state()
		var raw_devices: Variant = state.get("devices", {})
		var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
		var raw_device: Variant = devices.get(device_id, {})
		var device_info: Dictionary = raw_device if raw_device is Dictionary else {}
		var display_name: String = String(device_info.get("display_name", device_id))
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(78, 26)
		button.add_theme_font_size_override("font_size", 11)
		button.tooltip_text = "切换%s（prototype运行时状态，不写入存档）" % display_name
		button.pressed.connect(_on_device_pressed.bind(device_id))
		device_row.add_child(button)
		device_buttons[device_id] = button
		device_button_base_texts[device_id] = display_name


func _on_water_maintenance_pressed(action_id: String) -> void:
	if game_state == null:
		return
	var result: Dictionary = game_state.apply_water_maintenance_action(action_id)
	_update_status_labels()
	_update_maintenance_button_states()
	_update_maintenance_balance_label()
	if bool(result.get("success", false)):
		var label: String = String(result.get("label", action_id))
		var delta_summary: String = String(result.get("summary", result.get("delta_summary", "")))
		if maintenance_feedback_label != null:
			maintenance_feedback_label.text = delta_summary
		if panel_status_label != null:
			panel_status_label.text = "水质维护完成：" + label
	else:
		var error_text: String = String(result.get("summary", result.get("error", "unknown")))
		if maintenance_feedback_label != null:
			maintenance_feedback_label.text = error_text
		if panel_status_label != null:
			panel_status_label.text = "水质维护失败：" + error_text


func _update_maintenance_button_states() -> void:
	if game_state == null:
		return
	_update_maintenance_balance_label()
	for action_id in maintenance_buttons.keys():
		var raw_button: Variant = maintenance_buttons.get(action_id, null)
		if not raw_button is Button:
			continue
		var button: Button = raw_button
		var base_text: String = String(maintenance_button_base_texts.get(action_id, action_id))
		var state: Dictionary = game_state.get_maintenance_action_state(String(action_id))
		var remaining: float = float(state.get("remaining_cooldown", 0.0))
		var reason: String = String(state.get("reason", "ok"))
		if remaining > 0.0:
			button.disabled = true
			button.text = "%s（%ds）" % [base_text, int(ceil(remaining))]
		elif reason == "insufficient_funds":
			button.disabled = true
			button.text = "%s（余额不足）" % [base_text]
		else:
			button.disabled = false
			button.text = base_text


func _update_maintenance_balance_label() -> void:
	if maintenance_balance_label == null or game_state == null:
		return
	var balance: float = 0.0
	if game_state.economy_system != null:
		balance = game_state.economy_system.get_reef_points()
	maintenance_balance_label.text = "RP %.0f" % balance


func _on_device_pressed(device_id: String) -> void:
	if game_state == null:
		return
	var result: Dictionary = game_state.toggle_device(device_id)
	_update_status_labels()
	_update_device_button_states()
	if panel_status_label != null:
		panel_status_label.text = String(result.get("summary", "设备状态已更新"))


func _update_device_button_states() -> void:
	if game_state == null:
		return
	var state: Dictionary = game_state.get_device_state()
	var raw_devices: Variant = state.get("devices", {})
	var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
	for device_id in device_buttons.keys():
		var raw_button: Variant = device_buttons.get(device_id, null)
		if not raw_button is Button:
			continue
		var button: Button = raw_button
		var raw_device: Variant = devices.get(device_id, {})
		var device_info: Dictionary = raw_device if raw_device is Dictionary else {}
		var display_name: String = String(device_button_base_texts.get(device_id, device_info.get("display_name", device_id)))
		var enabled: bool = bool(device_info.get("enabled", false))
		button.disabled = false
		button.text = "%s:%s" % [display_name, "ON" if enabled else "OFF"]
		if enabled:
			button.add_theme_color_override("font_color", Color(0.78, 0.92, 0.86))
		else:
			button.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))


func _update_status_labels() -> void:
	var species_count: int = DataRegistry.get_species_count()
	var equipment_count: int = DataRegistry.get_equipment_count()
	var task_count: int = DataRegistry.get_task_count()
	var event_count: int = DataRegistry.get_event_count()
	var errors: Array[String] = DataRegistry.get_load_errors()
	var load_status: String = "OK" if DataRegistry.is_loaded_ok() else "ERROR"

	status_panel.update_counts(
		species_count,
		equipment_count,
		task_count,
		event_count,
		load_status,
		errors.size(),
	)
	var game_state_debug: Dictionary = game_state.get_debug_state()
	status_panel.update_equipment_debug(game_state_debug)
	status_panel.update_water_chemistry_debug(game_state.get_water_chemistry_debug_state())
	status_panel.update_livestock_economy_debug(
		game_state.get_livestock_debug_state(),
		game_state.get_economy_debug_state(),
	)
	status_panel.update_unlock_debug(game_state.get_unlock_debug_state())
	var water_delta_state: Dictionary = game_state.get_water_chemistry_debug_state()
	var delta_state: Dictionary = game_state.get_debug_state().get("delta", {})
	status_panel.update_delta_debug(water_delta_state, delta_state, game_state.get_economy_debug_state(), game_state.get_livestock_debug_state())
	status_panel.update_save_debug(
		game_state.get_save_debug_state(),
		game_state.save_loaded,
		game_state.offline_summary,
	)
