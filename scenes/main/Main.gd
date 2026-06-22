extends Control

@onready var status_panel: StatusPanel = %StatusPanel

var game_state: GameState = null
var shop_panel: ShopPanel = null
var livestock_panel: LivestockPanel = null
var shop_btn: Button = null
var livestock_btn: Button = null
var _panels_setup_done: bool = false


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
		livestock_panel.refresh()
	if shop_panel != null and shop_panel.visible:
		shop_panel.setup(game_state)


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
	layout.add_child(btn_bar)

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

	shop_panel = ShopPanel.new()
	shop_panel.hide()
	add_child(shop_panel)
	shop_panel.setup(game_state)

	livestock_panel = LivestockPanel.new()
	livestock_panel.hide()
	add_child(livestock_panel)
	livestock_panel.setup(game_state)

	_panels_setup_done = true


func _toggle_shop() -> void:
	if shop_panel == null:
		return
	if shop_panel.visible:
		shop_panel.hide()
	else:
		livestock_panel.hide()
		shop_panel.setup(game_state)
		shop_panel.anchor_left = 0.03
		shop_panel.anchor_right = 0.97
		shop_panel.anchor_top = 0.55
		shop_panel.anchor_bottom = 0.98
		shop_panel.offset_left = 0.0
		shop_panel.offset_right = 0.0
		shop_panel.offset_top = 0.0
		shop_panel.offset_bottom = 0.0
		shop_panel.show()


func _toggle_livestock() -> void:
	if livestock_panel == null:
		return
	if livestock_panel.visible:
		livestock_panel.hide()
	else:
		shop_panel.hide()
		livestock_panel.setup(game_state)
		livestock_panel.anchor_left = 0.03
		livestock_panel.anchor_right = 0.97
		livestock_panel.anchor_top = 0.55
		livestock_panel.anchor_bottom = 0.98
		livestock_panel.offset_left = 0.0
		livestock_panel.offset_right = 0.0
		livestock_panel.offset_top = 0.0
		livestock_panel.offset_bottom = 0.0
		livestock_panel.show()


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
