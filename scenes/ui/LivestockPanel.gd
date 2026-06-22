class_name LivestockPanel
extends PanelContainer

var game_state: GameState = null


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.16, 0.95)
	style.border_color = Color(0.40, 0.55, 0.60)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func setup(gs: GameState) -> void:
	game_state = gs
	refresh()


func refresh() -> void:
	for child in get_children():
		child.queue_free()
	_build_ui()


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = "我的生物"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	root.add_child(title)

	var summary: Label = Label.new()
	summary.add_theme_font_size_override("font_size", 10)
	summary.add_theme_color_override("font_color", Color(0.70, 0.85, 0.80))
	root.add_child(summary)

	var header: Label = Label.new()
	header.text = "名称｜分类｜稀有度｜尺寸cm｜成熟%｜健康%｜收益/h｜容量"
	header.add_theme_font_size_override("font_size", 9)
	header.add_theme_color_override("font_color", Color(0.55, 0.65, 0.60))
	root.add_child(header)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var item_list: VBoxContainer = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 2)
	scroll.add_child(item_list)

	if game_state == null:
		return
	var ls: LivestockSystem = game_state.livestock_system
	if ls == null:
		return
	var ls_debug: Dictionary = ls.get_debug_state()
	summary.text = "共%d个生物｜容量%.1f/%.1f｜基础收益%.2f/h｜有效收益%.2f/h" % [
		int(ls_debug.get("livestock_count", 0)),
		float(ls_debug.get("capacity_used", 0)),
		float(ls_debug.get("max_capacity", 30)),
		float(ls_debug.get("total_base_income_per_hour", 0)),
		float(ls_debug.get("total_effective_income_per_hour", 0)),
	]

	var raw_owned: Variant = ls_debug.get("owned_livestock", [])
	var owned: Array = []
	if raw_owned is Array:
		owned = raw_owned
	for entry in owned:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if bool(d.get("locked", false)):
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		item_list.add_child(row)

		var name_str: String = String(d.get("species_name", "?"))
		var cat_str: String = String(d.get("category", "?"))
		var rarity_str: String = String(d.get("rarity", "?"))
		var size_val: float = float(d.get("size_cm", 0))
		var mat_val: float = float(d.get("maturity_percent", 0))
		var hp_val: float = float(d.get("health_percent", 100))
		var inc_val: float = float(d.get("base_income_per_hour", 0))
		var slot_val: float = float(d.get("tank_slot_cost", 0))

		var info: Label = Label.new()
		info.text = "%s｜%s｜%s｜%.1f｜%.0f%%｜%.0f%%｜%.2f/h｜%.1f" % [name_str, cat_str, rarity_str, size_val, mat_val, hp_val, inc_val, slot_val]
		info.add_theme_font_size_override("font_size", 9)
		info.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

	var close_btn: Button = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(0, 26)
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.pressed.connect(_on_close)
	root.add_child(close_btn)


func _on_close() -> void:
	hide()
