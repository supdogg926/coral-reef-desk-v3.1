class_name LivestockPanel
extends PanelContainer

var game_state: GameState = null
var summary_label: Label = null
var item_list: VBoxContainer = null
var detail_label: Label = null
var status_label: Label = null
var confirm_panel: PanelContainer = null
var confirm_label: Label = null
var release_btn: Button = null
var _built: bool = false
var _selected_livestock_id: String = ""
var _selected_livestock_name: String = ""
var _confirm_livestock_id: String = ""


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.16, 0.95)
	style.border_color = Color(0.40, 0.55, 0.60)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func setup(gs: GameState) -> void:
	game_state = gs
	if not _built:
		_build_ui()
		_built = true


func update_display() -> void:
	if not _built:
		return
	if game_state == null:
		return
	var ls: LivestockSystem = game_state.livestock_system
	if ls == null:
		return
	var ls_debug: Dictionary = ls.get_debug_state()
	if summary_label != null:
		summary_label.text = "共%d个生物｜容量%.1f/%.1f｜基础收益%.2f/h｜有效收益%.2f/h" % [
			int(ls_debug.get("livestock_count", 0)),
			float(ls_debug.get("capacity_used", 0)),
			float(ls_debug.get("max_capacity", 30)),
			float(ls_debug.get("total_base_income_per_hour", 0)),
			float(ls_debug.get("total_effective_income_per_hour", 0)),
		]
	if item_list != null:
		for row_child in item_list.get_children():
			row_child.queue_free()
		var raw_owned: Variant = ls_debug.get("owned_livestock", [])
		var owned: Array = []
		if raw_owned is Array:
			owned = raw_owned
		for entry in owned:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry
			var is_locked: bool = bool(d.get("locked", false))
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			item_list.add_child(row)

			var livestock_id: String = String(d.get("id", ""))
			var name_str: String = String(d.get("species_name", "?"))
			var cat_str: String = _category_display_name(String(d.get("category", "?")))
			var rarity_str: String = String(d.get("rarity", "?"))
			var size_val: float = float(d.get("size_cm", 0))
			var mat_val: float = float(d.get("maturity_percent", 0))
			var hp_val: float = float(d.get("health_percent", 100))
			var inc_val: float = float(d.get("base_income_per_hour", 0))
			var slot_val: float = float(d.get("tank_slot_cost", 0))
			var lock_text: String = "[锁]" if is_locked else "[活]"
			if is_locked:
				inc_val = 0.0

			var info: Label = Label.new()
			info.text = "%s｜%s｜%s｜%.1f｜%.0f%%｜%.0f%%｜%.2f/h｜%.1f｜%s" % [name_str, cat_str, rarity_str, size_val, mat_val, hp_val, inc_val, slot_val, lock_text]
			info.add_theme_font_size_override("font_size", 9)
			var label_color: Color = Color(0.60, 0.60, 0.65) if is_locked else Color(0.78, 0.84, 0.82)
			info.add_theme_color_override("font_color", label_color)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			var select_btn: Button = Button.new()
			select_btn.text = "详情"
			select_btn.custom_minimum_size = Vector2(48, 22)
			select_btn.add_theme_font_size_override("font_size", 9)
			select_btn.disabled = is_locked or livestock_id.is_empty()
			select_btn.pressed.connect(_on_select_livestock.bind(livestock_id))
			row.add_child(select_btn)

	if not _selected_livestock_id.is_empty() and _get_selected_entry().is_empty():
		_selected_livestock_id = ""
		_selected_livestock_name = ""
		_hide_confirm()
	_update_detail_display()


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
	title.text = "我的生物"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	root.add_child(title)

	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 10)
	summary_label.add_theme_color_override("font_color", Color(0.70, 0.85, 0.80))
	root.add_child(summary_label)

	var header: Label = Label.new()
	header.text = "名称｜分类｜稀有度｜尺寸cm｜成熟%｜健康%｜收益/h｜容量｜状态"
	header.add_theme_font_size_override("font_size", 9)
	header.add_theme_color_override("font_color", Color(0.55, 0.65, 0.60))
	root.add_child(header)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 2)
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_list)

	detail_label = Label.new()
	detail_label.text = "选择一只生物查看详情"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 10)
	detail_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.86))
	root.add_child(detail_label)

	release_btn = Button.new()
	release_btn.text = "放归/移除"
	release_btn.custom_minimum_size = Vector2(0, 26)
	release_btn.add_theme_font_size_override("font_size", 10)
	release_btn.disabled = true
	release_btn.pressed.connect(_on_release_pressed)
	root.add_child(release_btn)

	confirm_panel = PanelContainer.new()
	var confirm_style: StyleBoxFlat = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.16, 0.14, 0.10, 0.96)
	confirm_style.border_color = Color(0.86, 0.62, 0.32)
	confirm_style.set_border_width_all(1)
	confirm_style.set_corner_radius_all(4)
	confirm_panel.add_theme_stylebox_override("panel", confirm_style)
	confirm_panel.hide()
	root.add_child(confirm_panel)

	var confirm_margin: MarginContainer = MarginContainer.new()
	confirm_margin.add_theme_constant_override("margin_left", 8)
	confirm_margin.add_theme_constant_override("margin_top", 6)
	confirm_margin.add_theme_constant_override("margin_right", 8)
	confirm_margin.add_theme_constant_override("margin_bottom", 6)
	confirm_panel.add_child(confirm_margin)

	var confirm_root: VBoxContainer = VBoxContainer.new()
	confirm_root.add_theme_constant_override("separation", 4)
	confirm_margin.add_child(confirm_root)

	confirm_label = Label.new()
	confirm_label.add_theme_font_size_override("font_size", 10)
	confirm_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.64))
	confirm_root.add_child(confirm_label)

	var confirm_row: HBoxContainer = HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 6)
	confirm_root.add_child(confirm_row)

	var cancel_btn: Button = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(72, 24)
	cancel_btn.add_theme_font_size_override("font_size", 10)
	cancel_btn.pressed.connect(_on_release_cancelled)
	confirm_row.add_child(cancel_btn)

	var confirm_btn: Button = Button.new()
	confirm_btn.text = "确认放归"
	confirm_btn.custom_minimum_size = Vector2(88, 24)
	confirm_btn.add_theme_font_size_override("font_size", 10)
	confirm_btn.pressed.connect(_on_release_confirmed)
	confirm_row.add_child(confirm_btn)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.90, 0.76))
	root.add_child(status_label)

	var close_btn: Button = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(0, 26)
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.pressed.connect(_on_close)
	root.add_child(close_btn)

	if game_state != null:
		update_display()


func _category_display_name(raw: String) -> String:
	match raw:
		"coral": return "珊瑚"
		"fish": return "鱼"
		"crustacean": return "甲壳"
		"algae": return "藻类"
		"invertebrate": return "无脊椎"
		_: return raw


func _on_close() -> void:
	hide()


func _on_select_livestock(livestock_id: String) -> void:
	_selected_livestock_id = livestock_id
	var entry: Dictionary = _get_selected_entry()
	_selected_livestock_name = String(entry.get("species_name", ""))
	_hide_confirm()
	_update_detail_display()
	_pulse_detail()


func _on_release_pressed() -> void:
	if _selected_livestock_id.is_empty():
		return
	var entry: Dictionary = _get_selected_entry()
	if entry.is_empty():
		_selected_livestock_id = ""
		_update_detail_display()
		return
	_confirm_livestock_id = _selected_livestock_id
	_selected_livestock_name = String(entry.get("species_name", ""))
	if confirm_label != null:
		confirm_label.text = "确认放归 %s？此原型会从当前鱼缸移除它，不发奖励。" % _selected_livestock_name
	if confirm_panel != null:
		confirm_panel.modulate.a = 0.0
		confirm_panel.scale = Vector2(0.98, 0.98)
		confirm_panel.show()
		var tween: Tween = create_tween()
		tween.tween_property(confirm_panel, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(confirm_panel, "scale", Vector2.ONE, 0.12)
	if release_btn != null:
		release_btn.text = "等待确认..."
		release_btn.disabled = true


func _on_release_cancelled() -> void:
	_confirm_livestock_id = ""
	_hide_confirm()
	_update_detail_display()
	if status_label != null:
		status_label.text = "已取消放归"
		status_label.add_theme_color_override("font_color", Color(0.90, 0.76, 0.52))


func _on_release_confirmed() -> void:
	if game_state == null or _confirm_livestock_id.is_empty():
		return
	var released_name: String = _selected_livestock_name
	var result: Dictionary = game_state.release_owned_livestock(_confirm_livestock_id)
	if bool(result.get("success", false)):
		released_name = String(result.get("species_name", released_name))
		_selected_livestock_id = ""
		_selected_livestock_name = ""
		_confirm_livestock_id = ""
		_hide_confirm()
		update_display()
		if status_label != null:
			status_label.text = "已放归 %s｜数量：%d｜容量：%.1f/%.1f｜基础收益：%.2f/h" % [
				released_name,
				int(result.get("new_count", 0)),
				float(result.get("capacity_used", 0.0)),
				float(result.get("max_capacity", 30.0)),
				float(result.get("base_income_per_hour", 0.0)),
			]
			status_label.add_theme_color_override("font_color", Color(0.56, 0.95, 0.68))
			_pulse_status()
	else:
		if status_label != null:
			status_label.text = "放归失败：%s" % String(result.get("error", "unknown"))
			status_label.add_theme_color_override("font_color", Color(0.95, 0.50, 0.42))
		_hide_confirm()
	_update_detail_display()


func _get_selected_entry() -> Dictionary:
	if game_state == null or game_state.livestock_system == null or _selected_livestock_id.is_empty():
		return {}
	return game_state.livestock_system.get_livestock_snapshot(_selected_livestock_id)


func _update_detail_display() -> void:
	var entry: Dictionary = _get_selected_entry()
	if entry.is_empty():
		if detail_label != null:
			detail_label.text = "选择一只生物查看详情"
		if release_btn != null:
			release_btn.text = "放归/移除"
			release_btn.disabled = true
		return
	var status_text: String = "活跃" if not bool(entry.get("locked", false)) else "锁定"
	if detail_label != null:
		detail_label.text = "详情：%s｜稀有度：%s｜容量占用：%.1f｜收益：%.2f/h｜当前状态：%s" % [
			String(entry.get("species_name", "?")),
			String(entry.get("rarity", "普通")),
			float(entry.get("tank_slot_cost", 0.0)),
			float(entry.get("base_income_per_hour", 0.0)),
			status_text,
		]
	if release_btn != null:
		release_btn.text = "放归/移除"
		release_btn.disabled = bool(entry.get("locked", false))


func _hide_confirm() -> void:
	if confirm_panel != null:
		confirm_panel.hide()
	if release_btn != null:
		release_btn.text = "放归/移除"
		release_btn.disabled = _selected_livestock_id.is_empty()


func _pulse_detail() -> void:
	if detail_label == null:
		return
	detail_label.scale = Vector2(1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(detail_label, "scale", Vector2(1.015, 1.015), 0.08)
	tween.tween_property(detail_label, "scale", Vector2.ONE, 0.10)


func _pulse_status() -> void:
	if status_label == null:
		return
	status_label.modulate.a = 0.35
	var tween: Tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.18)
