extends Control

@onready var status_panel: StatusPanel = %StatusPanel

var game_state: GameState = null
var shop_panel: ShopPanel = null
var livestock_panel: LivestockPanel = null
var shop_btn: Button = null
var livestock_btn: Button = null
var panel_status_label: Label = null
var _panels_setup_done: bool = false
var _livestock_refresh_timer: float = 0.0
const LIVESTOCK_REFRESH_INTERVAL: float = 0.5


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
	if livestock_panel != null and livestock_panel.visible:
		_livestock_refresh_timer += delta
		if _livestock_refresh_timer >= LIVESTOCK_REFRESH_INTERVAL:
			_livestock_refresh_timer = 0.0
			livestock_panel.update_display()


func _setup_panels() -> void:
	if _panels_setup_done:
		return
	var layout: VBoxContainer = null
	for child in get_children():
		if child is MarginContainer:
			for sub in child.get_children():
				if sub is VBoxContainer:
					layout = sub
					break
	if layout == null:
		return

	var btn_bar: PanelContainer = PanelContainer.new()
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
	var bar_row: HBoxContainer = HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	bar_margin.add_child(bar_row)

	shop_btn = Button.new()
	shop_btn.text = "生物商店"
	shop_btn.custom_minimum_size = Vector2(100, 30)
	shop_btn.add_theme_font_size_override("font_size", 12)
	shop_btn.pressed.connect(_toggle_shop)
	bar_row.add_child(shop_btn)

	livestock_btn = Button.new()
	livestock_btn.text = "我的生物"
	livestock_btn.custom_minimum_size = Vector2(100, 30)
	livestock_btn.add_theme_font_size_override("font_size", 12)
	livestock_btn.pressed.connect(_toggle_livestock)
	bar_row.add_child(livestock_btn)

	panel_status_label = Label.new()
	panel_status_label.text = ""
	panel_status_label.add_theme_font_size_override("font_size", 10)
	panel_status_label.add_theme_color_override("font_color", Color(0.60, 0.85, 0.70))
	bar_row.add_child(panel_status_label)

	layout.add_child(btn_bar)

	var status_index: int = btn_bar.get_index()
	for i in range(layout.get_child_count()):
		var child: Node = layout.get_child(i)
		if child == status_panel:
			status_index = i
			break
	if btn_bar.get_index() > status_index and status_index >= 0 and status_index < layout.get_child_count():
		layout.move_child(btn_bar, status_index)

	shop_panel = ShopPanel.new()
	shop_panel.hide()
	add_child(shop_panel)
	shop_panel.setup(game_state, Callable(self, "_on_shop_purchase"))

	livestock_panel = LivestockPanel.new()
	livestock_panel.hide()
	add_child(livestock_panel)
	livestock_panel.setup(game_state)

	_panels_setup_done = true


func _on_shop_purchase() -> void:
	_update_status_labels()
	if livestock_panel != null and livestock_panel.visible:
		livestock_panel.update_display()
	_livestock_refresh_timer = 0.0


func _toggle_shop() -> void:
	if shop_panel == null:
		return
	if shop_panel.visible:
		shop_panel.hide()
		if panel_status_label != null:
			panel_status_label.text = ""
	else:
		livestock_panel.hide()
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
		if panel_status_label != null:
			panel_status_label.text = ""
	else:
		shop_panel.hide()
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
	status_panel.update_delta_debug(water_delta_state, delta_state, game_state.get_economy_debug_state())
	status_panel.update_save_debug(
		game_state.get_save_debug_state(),
		game_state.save_loaded,
		game_state.offline_summary,
	)
