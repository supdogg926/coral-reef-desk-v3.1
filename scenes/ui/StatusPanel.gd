class_name StatusPanel
extends PanelContainer

var section_labels: Dictionary = {}

const WATER_DEVIATION_TARGETS: Dictionary = {
	"temperature": 25.0,
	"salinity": 35.0,
	"ph": 8.20,
	"nitrate": 2.00,
	"phosphate": 0.030,
	"alkalinity": 8.3,
	"calcium": 430.0,
}


func _ready() -> void:
	custom_minimum_size = Vector2(0, 142)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	var raw_device_state: Variant = game_state_debug.get("device", {})
	var device_state: Dictionary = raw_device_state if raw_device_state is Dictionary else {}
	var raw_device_effect: Variant = game_state_debug.get("device_effect", {})
	var device_effect: Dictionary = raw_device_effect if raw_device_effect is Dictionary else {}
	var device_filter_line: String = _format_device_filter_line(device_effect)
	var device_comfort_line: String = _format_device_comfort_line(device_state, device_effect)
	var device_light_line: String = _format_device_light_line(device_effect)
	var device_risk: String = String(device_effect.get("risk_message", "无"))
	if device_risk.is_empty():
		device_risk = "无"

	_set_line("system", "tier", "初级设备 %d/%d｜稳定度 %.1f" % [tier1_enabled_count, tier1_total_count, stability_score])
	_set_line("system", "capacity", "承载力 %.1f｜维护负担 %.1f" % [carrying_capacity_score, maintenance_load])
	_set_line("system", "plumbing", device_filter_line)
	_set_line("system", "comfort", device_comfort_line)
	_set_line("system", "reserved", "%s｜风险：%s｜预留T2 %d/T3 %d｜仓%d｜锁%d" % [device_light_line, device_risk, tier2_reserved_count, tier3_reserved_count, warehouse_count, locked_count])


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
	var maintenance_label: String = String(water_debug.get("last_maintenance_action_label", "无"))
	var maintenance_delta: String = String(water_debug.get("last_maintenance_delta_summary", "维护：无"))
	var maintenance_runtime_summary: String = String(water_debug.get("last_maintenance_runtime_summary", ""))

	_set_line("water", "summary", "水质状态：%s｜水质评分 %.1f" % [localized_status, water_quality_score])
	_set_line("water", "readings_core", "当前：温 %.1f℃｜盐 %.1f｜pH %.2f" % [temperature, salinity, ph])
	_set_line("water", "readings_chemistry", "营养/矿物：NO3 %.2f｜PO4 %.3f｜KH %.1f｜Ca %.0f" % [nitrate, phosphate, alkalinity, calcium])
	_update_water_deviation_summary(water_debug)
	if maintenance_runtime_summary.is_empty() or maintenance_runtime_summary == "未维护":
		_set_line("water", "maintenance", "最近维护：%s｜%s" % [maintenance_label, maintenance_delta])
	else:
		_set_line("water", "maintenance", "最近维护：" + maintenance_runtime_summary)
	_set_line("dynamic", "simulation", "模拟：自动运行中｜倍率：1秒=10分钟")
	_set_line("dynamic", "time_tick", "时间：%s｜更新：第%d次" % [_format_game_time(elapsed_game_minutes), chemistry_tick_count])


func update_livestock_economy_debug(livestock_debug: Dictionary, economy_debug: Dictionary) -> void:
	var livestock_count: int = int(livestock_debug.get("livestock_count", 0))
	var fish_count: int = int(livestock_debug.get("fish_count", 0))
	var coral_count: int = int(livestock_debug.get("coral_count", 0))
	var capacity_used: float = float(livestock_debug.get("capacity_used", 0.0))
	var max_capacity: float = float(livestock_debug.get("max_capacity", 30.0))
	var capacity_status: String = _localize_capacity_status(String(livestock_debug.get("capacity_status", "normal")))
	var health_modifier: float = float(livestock_debug.get("health_modifier", 0.0))
	var water_quality_mult: float = float(livestock_debug.get("water_quality_multiplier", 1.0))
	var bio_load: float = float(livestock_debug.get("bio_load", capacity_used))
	var system_capacity: float = float(livestock_debug.get("system_capacity", max_capacity))
	var comfort_score: float = float(livestock_debug.get("comfort_score", 100.0))
	var comfort_status: String = String(livestock_debug.get("comfort_status", "良好"))
	var revenue_multiplier: float = float(livestock_debug.get("revenue_multiplier", 1.0))
	var current_rp_per_tick: float = float(livestock_debug.get("current_rp_per_tick", 0.0))
	var base_income: float = float(livestock_debug.get("total_base_income_per_hour", 0.0))
	var effective_income: float = float(livestock_debug.get("total_effective_income_per_hour", 0.0))
	var reef_value: float = float(economy_debug.get("reef_value", livestock_debug.get("reef_value", 0.0)))
	var reef_points: float = float(economy_debug.get("reef_points", 0.0))
	var income_rate: float = float(economy_debug.get("income_rate_per_game_hour", livestock_debug.get("income_rate_per_game_hour", 0.0)))

	_set_line("livestock", "count", "生物数量：%d｜鱼%d｜珊瑚%d｜缸等级：%d" % [livestock_count, fish_count, coral_count, int(livestock_debug.get("tank_level", 1))])
	_set_line("livestock", "capacity", "生物负载：%.1f｜系统容量：%.1f｜槽位 %.1f/%.1f" % [bio_load, system_capacity, capacity_used, max_capacity])
	_set_line("livestock", "value", "缸价值：%.1f｜基础收益：%.2f/h" % [reef_value, base_income])
	_set_line("livestock", "points", "资源：RP %.0f｜当前RP产出 %.5f/tick｜收益 %.2f/h" % [reef_points, current_rp_per_tick, income_rate])
	_set_line("livestock", "income", "舒适度：%.0f/100 %s｜收益倍率：%.2fx｜水质倍率：%.2f" % [comfort_score, comfort_status, revenue_multiplier, water_quality_mult])
	_set_line("livestock", "modifiers", "状态：%s｜健康系数：%.2f｜修正后收益：%.2f/h" % [capacity_status, health_modifier, effective_income])


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


func update_delta_debug(water_debug: Dictionary, delta_debug: Dictionary, economy_debug: Dictionary, livestock_debug: Dictionary) -> void:
	var income_rate: float = float(economy_debug.get("income_rate_per_game_hour", 0.0))
	var rp_per_sec: float = income_rate / 3600.0
	var base_income: float = float(livestock_debug.get("total_base_income_per_hour", 0.0))
	var effective_income: float = float(livestock_debug.get("total_effective_income_per_hour", 0.0))
	var water_mult: float = float(livestock_debug.get("water_quality_multiplier", 1.0))
	var health_mod: float = float(livestock_debug.get("health_modifier", 1.0))
	var revenue_mult: float = float(livestock_debug.get("revenue_multiplier", 1.0))
	var current_rp_per_tick: float = float(livestock_debug.get("current_rp_per_tick", 0.0))
	var bio_feedback: String = String(livestock_debug.get("last_bio_load_feedback", "舒适度良好，收益维持正常"))

	var sim_delta: float = float(water_debug.get("last_delta_seconds", 0.0))
	var sim_delta_safe: float = max(sim_delta, 0.001)
	var to_per_min: float = 60.0 / sim_delta_safe
	var to_per_hour: float = 3600.0 / sim_delta_safe

	var tick_count: int = int(water_debug.get("chemistry_tick_count", 0))
	var d_temp: float = float(water_debug.get("delta_temperature", 0.0))
	var d_sal: float = float(water_debug.get("delta_salinity", 0.0))
	var d_ph: float = float(water_debug.get("delta_ph", 0.0))
	var d_no3: float = float(water_debug.get("delta_nitrate", 0.0))
	var d_po4: float = float(water_debug.get("delta_phosphate", 0.0))
	var d_kh: float = float(water_debug.get("delta_alkalinity", 0.0))
	var d_ca: float = float(water_debug.get("delta_calcium", 0.0))

	var water_min_line: String
	var water_hour_line: String
	if tick_count > 0 and sim_delta > 0.0:
		water_min_line = "水变/min：NO3%+.4f PO4%+.5f pH%+.4f T%+.3f" % [
			d_no3 * to_per_min, d_po4 * to_per_min, d_ph * to_per_min, d_temp * to_per_min,
		]
		water_hour_line = "水变/h：NO3%+.3f PO4%+.4f KH%+.2f Ca%+.1f S%+.2f" % [
			d_no3 * to_per_hour, d_po4 * to_per_hour, d_kh * to_per_hour, d_ca * to_per_hour, d_sal * to_per_hour,
		]
	else:
		water_min_line = "水变：稳定｜等待首次水质更新"
		water_hour_line = "水变：稳定｜%d次更新后显示" % tick_count

	var econ_line_a: String = "结算：每tick+%.5f RP｜每秒+%.5f RP｜每小时+%.2f RP" % [current_rp_per_tick, rp_per_sec, income_rate]
	var econ_line_b: String = "收益：基础%.2f/h｜修正%.2f/h｜水质%.2f｜舒适%.2f｜健康%.2f" % [base_income, effective_income, water_mult, revenue_mult, health_mod]

	_set_line("dynamic", "water_delta_a", water_min_line)
	_set_line("dynamic", "water_delta_b", water_hour_line)
	_set_line("dynamic", "economy_delta_a", econ_line_a)
	_set_line("dynamic", "economy_delta_b", econ_line_b)
	_set_line("dynamic", "bio_feedback", bio_feedback)


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

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "StatusScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	var title: Label = _make_label("状态总览", 11, true)
	root.add_child(title)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	_create_section(row, "data", "数据与阶段", 18, ["data", "validation", "milestone"])
	_create_section(row, "water", "水质", 22, [
		"summary",
		"readings_core", "readings_chemistry",
		"deviation_core", "deviation_nutrients", "deviation_minerals",
		"maintenance",
	])
	_create_section(row, "system", "系统", 18, ["tier", "capacity", "plumbing", "comfort", "reserved"])
	_create_section(row, "livestock", "生物与收益", 20, ["count", "capacity", "value", "points", "income", "modifiers"])
	_create_section(row, "dynamic", "动态确认", 26, [
		"simulation", "time_tick",
		"water_delta_a", "water_delta_b",
		"economy_delta_a", "economy_delta_b", "bio_feedback",
		"save_status", "save_offline",
		"stage", "target", "progress",
		"warehouse", "advanced",
	])


func _create_section(parent: Control, section_id: String, title_text: String, stretch_ratio: float, line_ids: Array[String]) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = stretch_ratio
	box.add_theme_constant_override("separation", 0)
	parent.add_child(box)

	var title: Label = _make_label(title_text, 9, true)
	box.add_child(title)

	var lines: Dictionary = {}
	for line_id in line_ids:
		var label: Label = _make_label("", 8, false)
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
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if is_title:
		label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.92))
	else:
		label.add_theme_color_override("font_color", Color(0.74, 0.82, 0.82))
	return label


func _format_device_state_line(device_state: Dictionary, device_effect: Dictionary) -> String:
	var raw_devices: Variant = device_state.get("devices", {})
	var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
	var parts: Array[String] = []
	for device_id in ["return_pump", "wave_pump", "main_light"]:
		var raw_device: Variant = devices.get(device_id, {})
		var device_info: Dictionary = raw_device if raw_device is Dictionary else {}
		var display_name: String = String(device_info.get("display_name", device_id))
		var enabled: bool = bool(device_info.get("enabled", false))
		parts.append("%s%s" % [display_name, "ON" if enabled else "OFF"])
	return _join_short_parts(parts)


func _format_device_filter_line(device_effect: Dictionary) -> String:
	var filter_efficiency: float = float(device_effect.get("filter_efficiency_percent", 100.0))
	var nitrate_drift: float = float(device_effect.get("device_nitrate_drift_per_day", 0.0))
	var phosphate_drift: float = float(device_effect.get("device_phosphate_drift_per_day", 0.0))
	var water_quality_effect: float = float(device_effect.get("water_quality_effect", 0.0))
	return "过滤效率 %.0f%%｜NO3 %+.2f/日｜PO4 %+.3f/日｜水质评分 %+.0f" % [
		filter_efficiency,
		nitrate_drift,
		phosphate_drift,
		water_quality_effect,
	]


func _format_device_comfort_line(device_state: Dictionary, device_effect: Dictionary) -> String:
	var raw_devices: Variant = device_state.get("devices", {})
	var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
	var raw_wave: Variant = devices.get("wave_pump", {})
	var wave_info: Dictionary = raw_wave if raw_wave is Dictionary else {}
	var wave_enabled: bool = bool(wave_info.get("enabled", true))
	var wave_text: String = "造浪ON" if wave_enabled else "造浪OFF"
	var comfort_score: float = float(device_effect.get("flow_comfort_score", device_effect.get("comfort_score", 100.0)))
	var health_modifier: float = float(device_effect.get("comfort_health_modifier", 1.0))
	var wave_effect: float = float(device_effect.get("wave_comfort_effect", 0.0))
	return "%s：水流舒适度 %.0f/100｜健康系数 %.2f｜造浪影响 %+.2f" % [
		wave_text,
		comfort_score,
		health_modifier,
		wave_effect,
	]


func _format_device_light_line(device_effect: Dictionary) -> String:
	var income_multiplier: float = float(device_effect.get("income_multiplier", 1.0))
	var stability_effect: float = float(device_effect.get("stability_effect", 0.0))
	var light_income_percent: float = float(device_effect.get("light_income_percent", 100.0))
	return "光照收益 %.0f%%｜收益倍率 x%.2f｜稳定 %+.0f" % [
		light_income_percent,
		income_multiplier,
		stability_effect,
	]


func _join_short_parts(parts: Array[String]) -> String:
	var text: String = ""
	for part in parts:
		if not text.is_empty():
			text += "｜"
		text += part
	return text


func _set_default_text() -> void:
	_set_line("data", "data", "数据：物种161｜设备28｜任务10｜事件7")
	_set_line("data", "validation", "校验：load=OK｜errors=0")
	_set_line("data", "milestone", "当前阶段：M10 生物商店与容量循环")
	_set_line("water", "summary", "水质状态：正常｜水质评分 100.0")
	_set_line("water", "readings_core", "当前：温 25.1℃｜盐 35.0｜pH 8.20")
	_set_line("water", "readings_chemistry", "营养/矿物：NO3 2.60｜PO4 0.030｜KH 8.3｜Ca 430")
	_set_line("water", "deviation_core", "偏差：温 +0.1｜盐 +0.0｜pH +0.00")
	_set_line("water", "deviation_nutrients", "营养偏差：NO3 +0.60｜PO4 +0.000")
	_set_line("water", "deviation_minerals", "矿物偏差：KH +0.0｜Ca +0｜全部正常")
	_set_line("water", "maintenance", "最近维护：无｜维护：无")
	_set_line("system", "tier", "初级设备 7/7｜稳定度 92.0")
	_set_line("system", "capacity", "承载力 27.0｜维护负担 12.0")
	_set_line("system", "plumbing", "过滤效率 100%｜NO3 +0.00/日｜PO4 +0.000/日｜水质评分 +0")
	_set_line("system", "comfort", "造浪ON：水流舒适度 100/100｜健康系数 1.00｜造浪影响 +0.00")
	_set_line("system", "reserved", "光照收益 100%｜收益倍率 x1.00｜稳定 +0｜风险：无｜预留T2 4/T3 5")
	_set_line("livestock", "count", "生物数量：6｜鱼2｜珊瑚3｜缸等级：1")
	_set_line("livestock", "capacity", "生物负载：23.4｜系统容量：39.2｜槽位 18.0/30.0")
	_set_line("livestock", "value", "缸价值：59.0｜基础收益：2.36/h")
	_set_line("livestock", "points", "资源：RP 0｜当前RP产出 0.00000/tick｜收益 0.00/h")
	_set_line("livestock", "income", "舒适度：100/100 优秀｜收益倍率：1.10x｜水质倍率：1.00")
	_set_line("livestock", "modifiers", "状态：正常｜健康系数：1.00｜修正后收益：2.60/h")
	_set_line("dynamic", "simulation", "模拟：自动运行中｜倍率：1秒=10分钟")
	_set_line("dynamic", "time_tick", "时间：第1天 00:00｜更新：第0次")
	_set_line("dynamic", "water_delta_a", "水变/min：等待首次更新...")
	_set_line("dynamic", "water_delta_b", "水变/h：等待首次更新...")
	_set_line("dynamic", "economy_delta_a", "结算：每tick+0.00000 RP｜每秒+0.00000 RP｜每小时+0.00 RP")
	_set_line("dynamic", "economy_delta_b", "收益：基础0.00/h｜修正0.00/h｜水质1.00｜舒适1.00｜健康1.00")
	_set_line("dynamic", "bio_feedback", "舒适度良好，收益维持正常")
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


func _update_water_deviation_summary(water_debug: Dictionary) -> void:
	var core_parts: PackedStringArray = PackedStringArray([
		_build_absolute_deviation_part("温", water_debug, "temperature", 1, 0.5, 1.5),
		_build_absolute_deviation_part("盐", water_debug, "salinity", 1, 1.0, 3.0),
		_build_absolute_deviation_part("pH", water_debug, "ph", 2, 0.15, 0.35),
	])
	var nutrient_parts: PackedStringArray = PackedStringArray([
		_build_range_deviation_part("NO3", water_debug, "nitrate", 2),
		_build_range_deviation_part("PO4", water_debug, "phosphate", 3),
	])
	var mineral_parts: PackedStringArray = PackedStringArray([
		_build_absolute_deviation_part("KH", water_debug, "alkalinity", 1, 0.5, 1.0),
		_build_absolute_deviation_part("Ca", water_debug, "calcium", 0, 30.0, 60.0),
	])
	_set_line("water", "deviation_core", "偏差：" + "｜".join(core_parts))
	_set_line("water", "deviation_nutrients", "营养偏差：" + "｜".join(nutrient_parts))
	_set_line("water", "deviation_minerals", "矿物偏差：" + "｜".join(mineral_parts))


func _build_absolute_deviation_part(label: String, water_debug: Dictionary, key: String, delta_decimals: int, normal_limit: float, caution_limit: float) -> String:
	var target: float = float(WATER_DEVIATION_TARGETS.get(key, 0.0))
	if not water_debug.has(key):
		return "%s --" % label

	var value: float = float(water_debug.get(key, target))
	var delta: float = value - target
	var status: String = _classify_absolute_deviation(delta, normal_limit, caution_limit)
	return "%s %s %s" % [
		label,
		_format_signed_number(delta, delta_decimals),
		status,
	]


func _build_range_deviation_part(label: String, water_debug: Dictionary, key: String, delta_decimals: int) -> String:
	var target: float = float(WATER_DEVIATION_TARGETS.get(key, 0.0))
	if not water_debug.has(key):
		return "%s --" % label

	var value: float = float(water_debug.get(key, target))
	var delta: float = value - target
	var status: String = _classify_range_deviation(key, value)
	return "%s %s %s" % [
		label,
		_format_signed_number(delta, delta_decimals),
		status,
	]


func _classify_absolute_deviation(delta: float, normal_limit: float, caution_limit: float) -> String:
	var magnitude: float = abs(delta)
	if magnitude <= normal_limit:
		return "正常"
	if magnitude <= caution_limit:
		return "偏高" if delta > 0.0 else "偏低"
	return "危险偏高" if delta > 0.0 else "危险偏低"


func _classify_range_deviation(key: String, value: float) -> String:
	if key == "nitrate":
		if value < 0.5:
			return "过低/过净"
		if value < 1.0:
			return "偏低"
		if value <= 10.0:
			return "正常"
		if value <= 20.0:
			return "注意偏高"
		return "偏高"
	if key == "phosphate":
		if value < 0.005:
			return "过低/过净"
		if value < 0.010:
			return "偏低"
		if value <= 0.100:
			return "正常"
		if value <= 0.200:
			return "注意偏高"
		return "偏高"
	return "正常"


func _format_number(value: float, decimals: int) -> String:
	if decimals <= 0:
		return "%.0f" % value
	if decimals == 1:
		return "%.1f" % value
	if decimals == 2:
		return "%.2f" % value
	if decimals == 3:
		return "%.3f" % value
	return "%.4f" % value


func _format_signed_number(value: float, decimals: int) -> String:
	if decimals <= 0:
		return "%+.0f" % value
	if decimals == 1:
		return "%+.1f" % value
	if decimals == 2:
		return "%+.2f" % value
	if decimals == 3:
		return "%+.3f" % value
	return "%+.4f" % value


func _format_game_time(elapsed_game_minutes: int) -> String:
	var safe_minutes: int = max(elapsed_game_minutes, 0)
	var day_index: int = int(floor(float(safe_minutes) / 1440.0)) + 1
	var minutes_in_day: int = safe_minutes % 1440
	var hour: int = int(floor(float(minutes_in_day) / 60.0))
	var minute: int = minutes_in_day % 60
	return "第%d天 %02d:%02d" % [day_index, hour, minute]
