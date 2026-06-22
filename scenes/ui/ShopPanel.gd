class_name ShopPanel
extends PanelContainer

var game_state: GameState = null
var status_label: Label = null
var item_list: VBoxContainer = null
var _built: bool = false
var _on_purchase_callback: Callable = Callable()


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.14, 0.95)
	style.border_color = Color(0.35, 0.55, 0.50)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func setup(gs: GameState, on_purchase: Callable = Callable()) -> void:
	game_state = gs
	_on_purchase_callback = on_purchase
	if not _built:
		_build_ui()
		_built = true


func update_display() -> void:
	if not _built:
		return
	if game_state == null or item_list == null:
		return
	for row_child in item_list.get_children():
		row_child.queue_free()
	var ls: LivestockSystem = game_state.livestock_system
	if ls == null:
		return
	var shop_items: Array[Dictionary] = ls.get_shop_items()
	var debug_label: Label = get_node_or_null("MarginContainer/VBoxContainer/DebugCount") as Label
	if debug_label != null:
		debug_label.text = "商店商品数：%d" % shop_items.size()
	if shop_items.is_empty():
		if status_label != null:
			status_label.text = "错误：商店数据为空"
			status_label.add_theme_color_override("font_color", Color(0.95, 0.50, 0.40))
		return
	for item in shop_items:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		item_list.add_child(row)

		var info: Label = Label.new()
		var name_str: String = String(item.get("species_name", "?"))
		var cat_str: String = String(item.get("category", "?"))
		var rarity_str: String = String(item.get("rarity", "?"))
		var price: float = float(item.get("price", 0))
		var size_min: float = float(item.get("size_min", 0))
		var size_max: float = float(item.get("size_max", 0))
		var slot: float = float(item.get("tank_slot_cost", 0))
		var income: float = float(item.get("base_income_per_hour", 0))
		info.text = "%s｜%s｜%s｜RP%.0f｜%.0f-%.0fcm｜%.1f格｜%.2f/h" % [name_str, cat_str, rarity_str, price, size_min, size_max, slot, income]
		info.add_theme_font_size_override("font_size", 9)
		info.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var buy_btn: Button = Button.new()
		buy_btn.text = "带回家"
		buy_btn.custom_minimum_size = Vector2(48, 22)
		buy_btn.add_theme_font_size_override("font_size", 9)
		var item_id: String = String(item.get("id", ""))
		buy_btn.pressed.connect(_make_buy_callback(item_id))
		row.add_child(buy_btn)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

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
	title.text = "生物商店"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	root.add_child(title)

	var header: Label = Label.new()
	header.text = "名称｜分类｜稀有度｜价格｜尺寸｜容量｜收益/h"
	header.add_theme_font_size_override("font_size", 9)
	header.add_theme_color_override("font_color", Color(0.60, 0.70, 0.65))
	root.add_child(header)

	var debug_count: Label = Label.new()
	debug_count.text = "商店商品数：--"
	debug_count.add_theme_font_size_override("font_size", 10)
	debug_count.add_theme_color_override("font_color", Color(0.60, 0.85, 0.70))
	debug_count.name = "DebugCount"
	root.add_child(debug_count)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 2)
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_list)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.90, 0.70, 0.40))
	root.add_child(status_label)

	var close_btn: Button = Button.new()
	close_btn.text = "关闭商店"
	close_btn.custom_minimum_size = Vector2(0, 26)
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.pressed.connect(_on_close)
	root.add_child(close_btn)

	if game_state != null:
		update_display()


func _make_buy_callback(shop_id: String) -> Callable:
	return func(): _on_buy(shop_id)


func _on_buy(shop_id: String) -> void:
	if game_state == null:
		return
	var result: Dictionary = game_state.buy_livestock_from_shop(shop_id)
	if result.get("success", false):
		status_label.text = "购买成功：%s｜RP-%d｜生物数：%d｜容量：%.1f/%.1f" % [
			result.get("species_name", ""),
			int(result.get("price", 0)),
			int(result.get("new_count", 0)),
			float(result.get("capacity_used", 0)),
			float(result.get("max_capacity", 30.0)),
		]
		status_label.add_theme_color_override("font_color", Color(0.50, 0.90, 0.55))
		update_display()
		if _on_purchase_callback.is_valid():
			_on_purchase_callback.call()
	else:
		var err: String = String(result.get("error", "unknown"))
		if err == "capacity_exceeded":
			status_label.text = "容量不足，无法带回家"
		elif err == "insufficient_rp":
			status_label.text = "Reef Points 不足，需要 RP%d｜当前 RP%d" % [int(result.get("price", 0)), int(result.get("current_rp", 0))]
		else:
			status_label.text = "购买失败：%s" % err
		status_label.add_theme_color_override("font_color", Color(0.95, 0.50, 0.40))


func _on_close() -> void:
	hide()
