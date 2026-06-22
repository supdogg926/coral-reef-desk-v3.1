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
	_set_line("data", "milestone", "当前阶段：M10 生物商店与容量循环")


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

	_set_line("water", "summary", "水质状态：%s｜水质评分 %.1f" % [localized_status, water_quality_score])
	_set_line("water", "temperature", "温度 %.1f℃｜盐度 %.1f｜pH %.2f" % [temperature, salinity, ph])
	_set_line("water", "nutrients", "NO3 %.2f｜PO4 %.3f" % [nitrate, phosphate])
	_set_line("water", "minerals", "KH %.1f｜Ca %.0f" % [alkalinity, calcium])
	_set_line("dynamic", "simulation", "模拟：自动运行中｜倍率：1秒=10分钟")
	_set_line("dynamic", "time_tick", "时间：%s｜更新：第%d次" % [_format_game_time(elapsed_game_minutes), chemistry_tick_count])


func update_livestock_economy_debug(livestock_debug: Dictionary, economy_debug: Dictionary) -> void:
	var livestock_count: int = int(livestock_debug.get("livestock_count", 0))
	var capacity_used: float = float(livestock_debug.get("capacity_used", 0.0))
	var max_capacity: float = float(livestock_debug.get("max_capacity", 30.0))
	var capacity_status: String = _localize_capacity_status(String(livestock_debug.get("capacity_status", "normal")))
	var health_modifier: float = float(livestock_debug.get("health_modifier", 0.0))
	var water_quality_mult: float = float(livestock_debug.get("water_quality_multiplier", 1.0))
	var base_income: float = float(livestock_debug.get("total_base_income_per_hour", 0.0))
	var effective_income: float = float(livestock_debug.get("total_effective_income_per_hour", 0.0))
	var reef_value: float = float(economy_debug.get("reef_value", livestock_debug.get("reef_value", 0.0)))
	var reef_points: float = float(economy_debug.get("reef_points", 0.0))
	var income_rate: float = float(economy_debug.get("income_rate_per_game_hour", livestock_debug.get("income_rate_per_game_hour", 0.0)))

	_set_line("livestock", "count", "生物数量：%d｜缸等级：%d" % [livestock_count, int(livestock_debug.get("tank_level", 1))])
	_set_line("livestock", "capacity", "容量：%.1f/%.1f｜状态：%s" % [capacity_used, max_capacity, capacity_status])
	_set_line("livestock", "value", "缸价值：%.1f｜基础收益：%.2f/h" % [reef_value, base_income])
	_set_line("livestock", "points", "Reef Points：%.1f" % [reef_points])
	_set_line("livestock", "income", "有效收益：%.2f/h｜水质倍率：%.2f" % [effective_income, water_quality_mult])
	_set_line("livestock", "modifiers", "健康系数：%.2f｜实际收益：%.2f/h" % [health_modifier, income_rate])


func update_unlock_debug(unlock_debug: Dictionary) -> void:
	var current_stage: String = String(unlock_debug.get("current_stage", "初级玩家"))
	var next_target: String = String(unlock_debug.get("next_unlock_target", "解锁中级设备预览"))
	var progress: float = float(unlock_debug.get("unlock_progress", 0.0)) * 100.0
	var unlocked_items: Array = _string_array_from(unlock_debug.get("unlocked_preview_items", []))
	var locked_items: Array = _string_array_from(unlock_debug.get("locked_preview_items", []))
	var warehouse_text: String = "暂无"
	if not unlocked_items.is_empty():
		while unlocked_items.size() > 4:
			unlocked_items.pop_back()
		warehouse_text = _join_preview_items(unlocked_items, "/")
	else:
		while locked_items.size() > 4:
			locked_items.pop_back()
		if not locked_items.is_empty():
			warehouse_text = _join_preview_items(locked_items, "/") + "(锁)"
	var t2_unlocked: bool = bool(unlock_debug.get("unlocked_states", {}).get("tier2_equipment_preview", false))
	var wh_status: String = "预览" if t2_unlocked else "锁定"
	_set_line("dynamic", "stage", "阶段：%s" % [current_stage])
	_set_line("dynamic", "target", "目标：%s" % [next_target])
	_set_line("dynamic", "progress", "进度：%.0f%%" % [progress])
	_set_line("dynamic", "warehouse", "仓库：%s｜%s" % [warehouse_text, wh_status])
	_set_line("dynamic", "advanced", "高级：未解锁")


func update_delta_debug(water_debug: Dictionary, delta_debug: Dictionary) -> void:
	var d_temp: float = float(water_debug.get("delta_temperature", 0.0))
	var d_sal: float = float(water_debug.get("delta_salinity", 0.0))
	var d_ph: float = float(water_debug.get("delta_ph", 0.0))
	var d_no3: float = float(water_debug.get("delta_nitrate", 0.0))
	var d_po4: float = float(water_debug.get("delta_phosphate", 0.0))
	var d_kh: float = float(water_debug.get("delta_alkalinity", 0.0))
	var d_ca: float = float(water_debug.get("delta_calcium", 0.0))
	var d_quality: float = float(water_debug.get("delta_water_quality_score", 0.0))
	var d_rp: float = float(delta_debug.get("reef_points", 0.0))
	var d_value: float = float(delta_debug.get("reef_value", 0.0))
	var d_income: float = float(delta_debug.get("income_rate", 0.0))
	var d_health: float = float(delta_debug.get("health_modifier", 0.0))
	var d_water_income: float = float(delta_debug.get("water_income_modifier", 0.0))

	var water_delta_a: String = "水变A：温%+.2f 盐%+.2f pH%+.3f NO3%+.3f" % [
		d_temp, d_sal, d_ph, d_no3,
	]
	var water_delta_b: String = "水变B：PO4%+.4f KH%+.2f Ca%+.1f 评%+.2f" % [
		d_po4, d_kh, d_ca, d_quality,
	]
	var economy_delta_a: String = "收变A：RP%+.2f 价值%+.2f 收益%+.3f" % [
		d_rp, d_value, d_income,
	]
	var economy_delta_b: String = "收变B：健康%+.3f 水质收益%+.3f" % [
		d_health, d_water_income,
	]
	_set_line("dynamic", "water_delta_a", water_delta_a)
	_set_line("dynamic", "water_delta_b", water_delta_b)
	_set_line("dynamic", "economy_delta_a", economy_delta_a)
	_set_line("dynamic", "economy_delta_b", economy_delta_b)


func update_save_debug(save_debug: Dictionary, save_loaded: bool, offline_summary: Dictionary) -> void:
	var save_exists: bool = bool(save_debug.get("save_exists", false))
	var last_save_time: int = int(save_debug.get("last_save_unix_time", 0))
	var load_status: String = "已加载" if save_loaded else ("新游戏" if not save_exists else "就绪")
	var auto_status: String = "开启"
	var last_save_text: String = "--:--:--"
	if last_save_time > 0:
		var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(float(last_save_time))
		last_save_text = "%02d:%02d:%02d" % [time_dict.get("hour", 0), time_dict.get("minute", 0), time_dict.get("second", 0)]
	var save_line: String = "存档：%s｜自动存档：%s｜最近：%s" % [load_status, auto_status, last_save_text]
	_set_line("dynamic", "save_status", save_line)

	var offline_applied: bool = bool(offline_summary.get("applied", false))
	if offline_applied:
		var offline_sec: float = float(offline_summary.get("offline_seconds", 0.0))
		var offline_income: float = float(offline_summary.get("offline_income", 0.0))
		var offline_text: String = ""
		if offline_sec >= 3600.0:
			offline_text = "离线时长：%.1f小时" % (offline_sec / 3600.0)
		else:
			offline_text = "离线时长：%d分钟" % int(offline_sec / 60.0)
		offline_text += "｜离线收益：+%.1f RP" % offline_income
		_set_line("dynamic", "save_offline", offline_text)
	else:
		_set_line("dynamic", "save_offline", "离线：无")


func _build_status_layout() -> void:
	section_labels.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var title: Label = _make_label("状态总览", 11, true)
	root.add_child(title)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	_create_section(row, "data", "数据与阶段", 18, ["data", "validation", "milestone"])
	_create_section(row, "water", "水质", 18, ["summary", "temperature", "nutrients", "minerals"])
	_create_section(row, "system", "系统", 18, ["tier", "capacity", "plumbing", "reserved"])
	_create_section(row, "livestock", "生物与收益", 20, ["count", "capacity", "value", "points", "income", "modifiers"])
	_create_section(row, "dynamic", "动态确认", 26, [
		"simulation", "time_tick",
		"water_delta_a", "water_delta_b",
		"economy_delta_a", "economy_delta_b",
		"save_status", "save_offline",
		"stage", "target", "progress",
		"warehouse", "advanced",
	])


func _create_section(parent: Control, section_id: String, title_text: String, stretch_ratio: float, line_ids: Array[String]) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = stretch_ratio
	box.add_theme_constant_override("separation", 1)
	parent.add_child(box)

	var title: Label = _make_label(title_text, 10, true)
	box.add_child(title)

	var lines: Dictionary = {}
	for line_id in line_ids:
		var label: Label = _make_label("", 9, false)
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
	_set_line("data", "milestone", "当前阶段：M10 生物商店与容量循环")
	_set_line("water", "summary", "水质状态：正常｜水质评分 100.0")
	_set_line("water", "temperature", "温度 25.1℃｜盐度 35.0｜pH 8.20")
	_set_line("water", "nutrients", "NO3 2.60｜PO4 0.030")
	_set_line("water", "minerals", "KH 8.3｜Ca 430")
	_set_line("system", "tier", "初级设备 7/7｜稳定度 92.0")
	_set_line("system", "capacity", "承载力 27.0｜维护负担 12.0")
	_set_line("system", "plumbing", "管路：隐式连接｜管路玩法：关闭")
	_set_line("system", "reserved", "预留：T2 4｜T3 5｜仓库0｜锁定9")
	_set_line("livestock", "count", "生物数量：6｜缸等级：1")
	_set_line("livestock", "capacity", "容量：18.0/30.0｜状态：正常")
	_set_line("livestock", "value", "缸价值：59.0｜基础收益：2.36/h")
	_set_line("livestock", "points", "Reef Points：0.0")
	_set_line("livestock", "income", "有效收益：2.36/h｜水质倍率：1.00")
	_set_line("livestock", "modifiers", "健康系数：1.00｜实际收益：2.36/h")
	_set_line("dynamic", "simulation", "模拟：自动运行中｜倍率：1秒=10分钟")
	_set_line("dynamic", "time_tick", "时间：第1天 00:00｜更新：第0次")
	_set_line("dynamic", "water_delta_a", "水变A：温+0.00 盐+0.00 pH+0.000 NO3+0.000")
	_set_line("dynamic", "water_delta_b", "水变B：PO4+0.0000 KH+0.00 Ca+0.0 评+0.00")
	_set_line("dynamic", "economy_delta_a", "收变A：RP+0.00 价值+0.00 收益+0.000")
	_set_line("dynamic", "economy_delta_b", "收变B：健康+0.000 水质收益+0.000")
	_set_line("dynamic", "save_status", "存档：新游戏｜自动存档：开启｜最近：--:--:--")
	_set_line("dynamic", "save_offline", "离线：无")
	_set_line("dynamic", "stage", "阶段：初级玩家")
	_set_line("dynamic", "target", "目标：解锁中级设备预览")
	_set_line("dynamic", "progress", "进度：0%")
	_set_line("dynamic", "warehouse", "仓库：暂无｜锁定")
	_set_line("dynamic", "advanced", "高级：未解锁")


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
