class_name StatusPanel
extends PanelContainer

var section_labels: Dictionary = {}


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.15)
	style.border_color = Color(0.32, 0.38, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	_build_status_layout()
	_set_default_text()


func update_counts(species_count: int, equipment_count: int, task_count: int, event_count: int, load_status: String, error_count: int) -> void:
	_set_line("data", "data", "数据：物种%d｜设备%d｜任务%d｜事件%d" % [species_count, equipment_count, task_count, event_count])
	_set_line("data", "validation", "校验：load=%s｜errors=%d" % [load_status, error_count])
	_set_line("data", "milestone", "当前阶段：M7 基础解锁进度系统")


func update_equipment_debug(game_state_debug: Dictionary) -> void:
	var raw_equipment_debug: Variant = game_state_debug.get("equipment", {})
	var equipment_debug: Dictionary = {}
	if raw_equipment_debug is Dictionary:
		equipment_debug = raw_equipment_debug
	var tier1_enabled_count: int = int(equipment_debug.get("tier1_enabled_count", 0))
	var tier1_total_count: int = int(equipment_debug.get("tier1_total_count", 0))
	var tier2_reserved_count: int = int(equipment_debug.get("tier2_reserved_count", 0))
	var tier3_reserved_count: int = int(equipment_debug.get("tier3_reserved_count", 0))
	var warehouse_count: int = int(equipment_debug.get("warehouse_count", 0))
	var locked_count: int = int(equipment_debug.get("locked_count", 0))
	var stability_score: float = float(game_state_debug.get("stability_score", 0.0))
	var carrying_capacity_score: float = float(game_state_debug.get("carrying_capacity_score", 0.0))
	var maintenance_load: float = float(game_state_debug.get("maintenance_load", 0.0))

	_set_line("system", "tier", "初级设备 %d/%d｜稳定度 %.1f" % [tier1_enabled_count, tier1_total_count, stability_score])
	_set_line("system", "capacity", "承载力 %.1f｜维护负担 %.1f" % [carrying_capacity_score, maintenance_load])
	_set_line("system", "plumbing", "管路：隐式连接｜管路玩法：关闭")
	_set_line("system", "reserved", "预留：T2 %d｜T3 %d｜仓库%d｜锁定%d" % [tier2_reserved_count, tier3_reserved_count, warehouse_count, locked_count])


func update_water_chemistry_debug(water_debug: Dictionary) -> void:
	var temperature: float = float(water_debug.get("temperature", 0.0))
	var salinity: float = float(water_debug.get("salinity", 0.0))
	var ph: float = float(water_debug.get("ph", 0.0))
	var nitrate: float = float(water_debug.get("nitrate", 0.0))
	var phosphate: float = float(water_debug.get("phosphate", 0.0))
	var alkalinity: float = float(water_debug.get("alkalinity", 0.0))
	var calcium: float = float(water_debug.get("calcium", 0.0))
	var water_quality_score: float = float(water_debug.get("water_quality_score", 0.0))
	var water_status: String = String(water_debug.get("water_status", "UNKNOWN"))
	var localized_status: String = _localize_water_status(water_status)
	var chemistry_tick_count: int = int(water_debug.get("chemistry_tick_count", 0))
	var elapsed_game_minutes: int = int(water_debug.get("elapsed_game_minutes", 0))
	var last_delta: String = String(water_debug.get("last_parameter_delta_summary", "NO3 +0.000 / PO4 +0.0000 / pH +0.000"))

	_set_line("water", "summary", "水质状态：%s｜水质评分 %.1f" % [localized_status, water_quality_score])
	_set_line("water", "temperature", "温度 %.1f℃｜盐度 %.1f｜pH %.2f" % [temperature, salinity, ph])
	_set_line("water", "nutrients", "NO3 %.2f｜PO4 %.3f" % [nitrate, phosphate])
	_set_line("water", "minerals", "KH %.1f｜Ca %.0f" % [alkalinity, calcium])
	_set_line("dynamic", "simulation", "模拟：自动运行中｜时间倍率：1秒=10分钟")
	_set_line("dynamic", "time", "游戏时间：%s" % [_format_game_time(elapsed_game_minutes)])
	_set_line("dynamic", "tick", "水质更新：第%d次" % [chemistry_tick_count])
	_set_line("dynamic", "delta", "最近变化：%s" % [last_delta])


func update_livestock_economy_debug(livestock_debug: Dictionary, economy_debug: Dictionary) -> void:
	var livestock_count: int = int(livestock_debug.get("livestock_count", 0))
	var capacity_used: float = float(livestock_debug.get("capacity_used", 0.0))
	var capacity_limit: float = float(livestock_debug.get("capacity_limit", 0.0))
	var capacity_status: String = _localize_capacity_status(String(livestock_debug.get("capacity_status", "normal")))
	var health_modifier: float = float(livestock_debug.get("health_modifier", 0.0))
	var reef_value: float = float(economy_debug.get("reef_value", livestock_debug.get("reef_value", 0.0)))
	var reef_points: float = float(economy_debug.get("reef_points", 0.0))
	var income_rate: float = float(economy_debug.get("income_rate_per_game_hour", livestock_debug.get("income_rate_per_game_hour", 0.0)))
	var water_income_modifier: float = float(livestock_debug.get("water_income_modifier", 0.0))

	_set_line("livestock", "count", "生物数量：%d" % [livestock_count])
	_set_line("livestock", "capacity", "承载使用：%.1f/%.1f｜承载状态：%s" % [capacity_used, capacity_limit, capacity_status])
	_set_line("livestock", "value", "珊瑚缸价值：%.1f" % [reef_value])
	_set_line("livestock", "points", "Reef Points：%.1f" % [reef_points])
	_set_line("livestock", "income", "收益速度：%.2f/游戏小时" % [income_rate])
	_set_line("livestock", "modifiers", "生物健康系数：%.2f｜水质收益系数：%.2f" % [health_modifier, water_income_modifier])


func update_unlock_debug(unlock_debug: Dictionary) -> void:
	var current_stage: String = String(unlock_debug.get("current_stage", "初级玩家"))
	var next_target: String = String(unlock_debug.get("next_unlock_target", "解锁中级设备预览"))
	var progress: float = float(unlock_debug.get("unlock_progress", 0.0)) * 100.0
	var unlocked_items: Array = _string_array_from(unlock_debug.get("unlocked_preview_items", []))
	var locked_items: Array = _string_array_from(unlock_debug.get("locked_preview_items", []))
	var unlocked_text: String = "Tier 1 运行"
	if not unlocked_items.is_empty():
		unlocked_text = _join_preview_items(unlocked_items, " / ")
	while locked_items.size() > 4:
		locked_items.pop_back()
	var preview_items: Array = unlocked_items if not unlocked_items.is_empty() else locked_items
	var preview_text: String = _join_preview_items(preview_items, " / ")
	if preview_text.is_empty():
		preview_text = "暂无"
	_set_line("dynamic", "stage", "玩家阶段：%s" % [current_stage])
	_set_line("dynamic", "target", "下个目标：%s" % [next_target])
	_set_line("dynamic", "progress", "解锁进度：%.0f%%" % [progress])
	_set_line("dynamic", "unlocked", "已解锁：%s" % [unlocked_text])
	_set_line("dynamic", "preview", "预览设备：%s" % [preview_text])
	_set_line("dynamic", "advanced", "高级系统：未解锁")


func _build_status_layout() -> void:
	section_labels.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var title: Label = _make_label("状态总览", 12, true)
	root.add_child(title)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	_create_section(grid, "data", "数据与阶段", ["data", "validation", "milestone"])
	_create_section(grid, "water", "水质", ["summary", "temperature", "nutrients", "minerals"])
	_create_section(grid, "system", "系统", ["tier", "capacity", "plumbing", "reserved"])
	_create_section(grid, "livestock", "生物与收益", ["count", "capacity", "value", "points", "income", "modifiers"])
	_create_section(grid, "dynamic", "动态确认", ["simulation", "time", "tick", "delta", "stage", "target", "progress", "unlocked", "preview", "advanced"])


func _create_section(parent: Control, section_id: String, title_text: String, line_ids: Array[String]) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(205, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	parent.add_child(box)

	var title: Label = _make_label(title_text, 11, true)
	box.add_child(title)

	var lines: Dictionary = {}
	for line_id in line_ids:
		var label: Label = _make_label("", 10, false)
		box.add_child(label)
		lines[line_id] = label
	section_labels[section_id] = lines


func _make_label(text: String, font_size: int, is_title: bool) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_title:
		label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.92))
	else:
		label.add_theme_color_override("font_color", Color(0.74, 0.82, 0.82))
	return label


func _set_default_text() -> void:
	_set_line("data", "data", "数据：物种161｜设备28｜任务10｜事件7")
	_set_line("data", "validation", "校验：load=OK｜errors=0")
	_set_line("data", "milestone", "当前阶段：M7 基础解锁进度系统")
	_set_line("water", "summary", "水质状态：正常｜水质评分 100.0")
	_set_line("water", "temperature", "温度 25.1℃｜盐度 35.0｜pH 8.20")
	_set_line("water", "nutrients", "NO3 2.60｜PO4 0.030")
	_set_line("water", "minerals", "KH 8.3｜Ca 430")
	_set_line("system", "tier", "初级设备 7/7｜稳定度 92.0")
	_set_line("system", "capacity", "承载力 27.0｜维护负担 12.0")
	_set_line("system", "plumbing", "管路：隐式连接｜管路玩法：关闭")
	_set_line("system", "reserved", "预留：T2 4｜T3 5｜仓库0｜锁定9")
	_set_line("livestock", "count", "生物数量：6")
	_set_line("livestock", "capacity", "承载使用：18.0/27.0｜承载状态：正常")
	_set_line("livestock", "value", "珊瑚缸价值：59.0")
	_set_line("livestock", "points", "Reef Points：0.0")
	_set_line("livestock", "income", "收益速度：2.36/游戏小时")
	_set_line("livestock", "modifiers", "生物健康系数：1.00｜水质收益系数：1.00")
	_set_line("dynamic", "simulation", "模拟：自动运行中｜时间倍率：1秒=10分钟")
	_set_line("dynamic", "time", "游戏时间：第1天 00:00")
	_set_line("dynamic", "tick", "水质更新：第0次")
	_set_line("dynamic", "delta", "最近变化：NO3 +0.000 / PO4 +0.0000 / pH +0.000")
	_set_line("dynamic", "stage", "玩家阶段：初级玩家")
	_set_line("dynamic", "target", "下个目标：解锁中级设备预览")
	_set_line("dynamic", "progress", "解锁进度：0%")
	_set_line("dynamic", "unlocked", "已解锁：Tier 1 运行")
	_set_line("dynamic", "preview", "预览设备：暂无")
	_set_line("dynamic", "advanced", "高级系统：未解锁")


func _set_line(section_id: String, line_id: String, text: String) -> void:
	var raw_section: Variant = section_labels.get(section_id, {})
	if not raw_section is Dictionary:
		return
	var section: Dictionary = raw_section
	var raw_label: Variant = section.get(line_id, null)
	if raw_label is Label:
		var label: Label = raw_label
		label.text = text


func _string_array_from(raw_value: Variant) -> Array:
	var result: Array = []
	if raw_value is Array:
		var values: Array = raw_value
		for item in values:
			result.append(String(item))
	return result


func _join_preview_items(items: Array, separator: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for item in items:
		var text: String = String(item)
		if not text.is_empty():
			parts.append(text)
	return separator.join(parts)


func _localize_water_status(water_status: String) -> String:
	if water_status == "OK":
		return "正常"
	if water_status == "WARNING":
		return "警告"
	if water_status == "CRITICAL":
		return "危险"
	return water_status


func _localize_capacity_status(capacity_status: String) -> String:
	if capacity_status == "normal":
		return "正常"
	if capacity_status == "full":
		return "已满"
	if capacity_status == "overloaded":
		return "超载"
	return capacity_status


func _format_game_time(elapsed_game_minutes: int) -> String:
	var safe_minutes: int = max(elapsed_game_minutes, 0)
	var day_index: int = int(floor(float(safe_minutes) / 1440.0)) + 1
	var minutes_in_day: int = safe_minutes % 1440
	var hour: int = int(floor(float(minutes_in_day) / 60.0))
	var minute: int = minutes_in_day % 60
	return "第%d天 %02d:%02d" % [day_index, hour, minute]
