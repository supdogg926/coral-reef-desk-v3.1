class_name StatusPanel
extends PanelContainer

var section_labels: Dictionary = {}
var dock_control_slots: Dictionary = {}
var timeline_labels: Array[Label] = []
var rp_display_label: Label = null
var dock_body: Control = null
var collapsed_bar: Control = null
var _last_timeline_count: int = -1
var _last_timeline_text: String = ""

const TITLE_FONT_SIZE: int = 10
const BODY_FONT_SIZE: int = 8
const KEY_FONT_SIZE: int = 10
const PRIMARY_FONT_SIZE: int = 12
const DOCK_HEIGHT: int = 104
const COLLAPSED_DOCK_HEIGHT: int = 26
const PANEL_BG_COLOR: Color = Color(0.105, 0.115, 0.125)
const PANEL_BORDER_COLOR: Color = Color(0.24, 0.28, 0.30)
const CARD_BG_COLOR: Color = Color(0.135, 0.148, 0.158)
const CARD_BORDER_COLOR: Color = Color(0.25, 0.29, 0.31)
const METRIC_BG_COLOR: Color = Color(0.095, 0.108, 0.118)
const TITLE_TEXT_COLOR: Color = Color(0.86, 0.90, 0.90)
const BODY_TEXT_COLOR: Color = Color(0.66, 0.72, 0.72)
const KEY_TEXT_COLOR: Color = Color(0.82, 0.88, 0.86)
const MUTED_TEXT_COLOR: Color = Color(0.50, 0.56, 0.56)
const STATUS_OK_COLOR: Color = Color(0.58, 0.82, 0.68)
const STATUS_WARN_COLOR: Color = Color(0.88, 0.76, 0.44)
const STATUS_BAD_COLOR: Color = Color(0.92, 0.45, 0.40)
const STATUS_IDLE_COLOR: Color = Color(0.60, 0.65, 0.65)

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
	custom_minimum_size = Vector2(0, DOCK_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	_build_status_layout()
	_set_default_text()


func update_counts(species_count: int, equipment_count: int, task_count: int, event_count: int, load_status: String, error_count: int) -> void:
	_set_line("status", "data", "物种%d  设备%d" % [species_count, equipment_count])
	_set_line("status", "validation", "%s  E%d" % [load_status, error_count])


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
	var filter_efficiency: float = float(device_effect.get("filter_efficiency_percent", 100.0))
	var water_flow: float = float(device_effect.get("water_flow_percent", device_effect.get("flow_comfort_score", 100.0)))

	_set_status_line("water", "water_flow", "%.0f%%" % water_flow, _score_color(water_flow, 80.0, 50.0))
	_set_status_line("water", "filter_efficiency", "%.0f%%" % filter_efficiency, _score_color(filter_efficiency, 80.0, 50.0))


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

	_set_status_line("water", "water_primary", "%.0f" % water_quality_score, _water_status_color(water_status, water_quality_score))
	_set_water_delta_tag("water", "temperature", temperature, WATER_DEVIATION_TARGETS.get("temperature", 25.0), 1, "°", 0.5, 1.5)
	_set_water_delta_tag("water", "ph", ph, WATER_DEVIATION_TARGETS.get("ph", 8.2), 2, "", 0.15, 0.35)
	_set_water_delta_tag("water", "alkalinity", alkalinity, WATER_DEVIATION_TARGETS.get("alkalinity", 8.3), 1, "", 0.5, 1.0)
	_set_water_delta_tag("water", "calcium", calcium, WATER_DEVIATION_TARGETS.get("calcium", 430.0), 0, "", 30.0, 60.0)
	_set_water_delta_tag("water", "salinity", salinity, WATER_DEVIATION_TARGETS.get("salinity", 35.0), 1, "", 1.0, 3.0)
	_set_range_tag("water", "nitrate", nitrate, 2, 1.0, 10.0, 20.0)
	_set_range_tag("water", "phosphate", phosphate, 3, 0.010, 0.100, 0.200)
	# 色温 slider value updated via dock_control_slots
	_set_line("status", "time_tick", _format_game_time(elapsed_game_minutes))


func update_livestock_economy_debug(livestock_debug: Dictionary, economy_debug: Dictionary) -> void:
	var livestock_count: int = int(livestock_debug.get("livestock_count", 0))
	var fish_count: int = int(livestock_debug.get("fish_count", 0))
	var coral_count: int = int(livestock_debug.get("coral_count", 0))
	var crustacean_count: int = int(livestock_debug.get("crustacean_count", livestock_debug.get("other_livestock_count", 0)))
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

	if rp_display_label != null:
		rp_display_label.text = "%.0f  +%.2f/h" % [reef_points, income_rate]
		rp_display_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.86))
	_set_status_line("livestock", "comfort_primary", "%.0f" % comfort_score, _score_color(comfort_score, 80.0, 55.0))
	_set_status_line("livestock", "load_primary", "%.1f/%.1f" % [bio_load, system_capacity], _load_color(bio_load, system_capacity))
	_set_status_line("livestock", "revenue_primary", "%.2fx" % revenue_multiplier, _multiplier_color(revenue_multiplier))
	_set_status_line("livestock", "fish_count", "%d" % fish_count, KEY_TEXT_COLOR)
	_set_status_line("livestock", "coral_count", "%d" % coral_count, KEY_TEXT_COLOR)
	_set_status_line("livestock", "crustacean_count", "%d" % crustacean_count, STATUS_IDLE_COLOR if crustacean_count <= 0 else KEY_TEXT_COLOR)
	var algae_count_display: int = int(livestock_debug.get("algae_count", 0))
	_set_status_line("livestock", "algae_count", "%d" % algae_count_display, STATUS_IDLE_COLOR if algae_count_display <= 0 else KEY_TEXT_COLOR)


func update_unlock_debug(unlock_debug: Dictionary) -> void:
	var current_stage: String = String(unlock_debug.get("current_stage", "初级玩家"))
	var next_target: String = String(unlock_debug.get("next_unlock_target", "解锁中级设备预览"))
	var progress: float = float(unlock_debug.get("unlock_progress", 0.0)) * 100.0
	var player_level: int = int(unlock_debug.get("player_level", 1))
	var level_progress: float = float(unlock_debug.get("player_level_progress", 0.0)) * 100.0
	var goal_label: String = String(unlock_debug.get("current_goal_label", "维护稳定"))
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
	_set_line("status", "phase", "Lv%d %.0f%%" % [player_level, level_progress])
	_set_line("status", "validation", goal_label)


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

	var econ_line_a: String = "结算 +%.5f/tick｜+%.2f/h" % [current_rp_per_tick, income_rate]
	var econ_line_b: String = "倍率 水质%.2f｜舒适%.2f｜健康%.2f" % [water_mult, revenue_mult, health_mod]

	# Delta values are represented by compact water tags and RP/h, not long text rows.


func update_save_debug(save_debug: Dictionary, save_loaded: bool, offline_summary: Dictionary) -> void:
	var save_exists: bool = bool(save_debug.get("save_exists", false))
	var last_save_time: int = int(save_debug.get("last_save_unix_time", 0))
	var load_status: String = "已加载" if save_loaded else ("新游戏" if not save_exists else "就绪")
	var auto_status: String = "开启"
	var last_save_text: String = "--:--:--"
	if last_save_time > 0:
		var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(float(last_save_time))
		last_save_text = "%02d:%02d:%02d" % [time_dict.get("hour", 0), time_dict.get("minute", 0), time_dict.get("second", 0)]
	var save_line: String = "已保存" if last_save_time > 0 else ("自动" if save_loaded else "未保存")
	_set_line("status", "save_status", save_line)

	var offline_applied: bool = bool(offline_summary.get("applied", false))
	if offline_applied:
		var offline_sec: float = float(offline_summary.get("offline_seconds", 0.0))
		var offline_income: float = float(offline_summary.get("offline_income", 0.0))
		var offline_text: String = ""
		if offline_sec >= 3600.0:
			offline_text = "离线时长：%.1f小时" % (offline_sec / 3600.0)
		else:
			offline_text = "离线时长：%d分钟" % int(offline_sec / 60.0)
		offline_text += "｜离线 +%.1f RP" % offline_income
		_set_line("status", "save_offline", offline_text)
	else:
		_set_line("status", "save_offline", "离线 无")


func _build_status_layout() -> void:
	section_labels.clear()
	dock_control_slots.clear()
	dock_body = null
	collapsed_bar = null
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	dock_body = HBoxContainer.new()
	dock_body.add_theme_constant_override("separation", 5)
	dock_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(dock_body)

	collapsed_bar = HBoxContainer.new()
	collapsed_bar.visible = false
	collapsed_bar.add_theme_constant_override("separation", 6)
	collapsed_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collapsed_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.add_child(collapsed_bar)

	var restore_spacer: Control = Control.new()
	restore_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collapsed_bar.add_child(restore_spacer)
	var restore_button: Button = _make_dock_button("控制", Vector2(58, 18))
	restore_button.tooltip_text = "恢复底部控制 Dock"
	restore_button.pressed.connect(_set_observation_mode.bind(false))
	collapsed_bar.add_child(restore_button)

	_create_entry_system_section(dock_body)
	_create_core_status_section(dock_body)
	_create_operations_section(dock_body)
	_create_timeline_section(dock_body)



func _create_timeline_section(parent: Control) -> void:
	timeline_labels.clear()
	var box: VBoxContainer = _create_card(parent, "timeline", "时间线", 1.30)
	_add_title_label(box, "时间线")
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	box.add_child(scroll)
	var scroll_vbox: VBoxContainer = VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 1)
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)
	dock_control_slots["timeline_scroll_vbox"] = scroll_vbox
	dock_control_slots["timeline_scroll"] = scroll




func update_stage_objectives(stage_obj_debug: Dictionary) -> void:
	if stage_obj_debug.is_empty():
		return
	var completed: int = int(stage_obj_debug.get("completed_count", 0))
	var total: int = int(stage_obj_debug.get("total_count", 6))
	var all_done: bool = bool(stage_obj_debug.get("all_completed", false))
	var active_obj: Dictionary = stage_obj_debug.get("active_objective", {})
	if all_done:
		_set_line("status", "validation", "✓ 所有目标完成 %d/%d" % [completed, total])
	elif not active_obj.is_empty():
		_set_line("status", "validation", "目标 %d/%d: %s" % [completed + 1, total, String(active_obj.get("title", ""))])
	else:
		_set_line("status", "validation", "目标 %d/%d" % [completed, total])

func update_timeline(entries: Array) -> void:
	var scroll_vbox: Control = dock_control_slots.get("timeline_scroll_vbox", null)
	if scroll_vbox == null:
		return

	var total: int = entries.size()
	var last_text: String = ""
	if total > 0:
		var last_entry: Variant = entries[total - 1]
		if last_entry is Dictionary:
			last_text = String(last_entry.get("text", ""))

	# Skip rebuild if nothing changed (entries are append-only, immutable once added)
	if total == _last_timeline_count and last_text == _last_timeline_text:
		return

	_last_timeline_count = total
	_last_timeline_text = last_text

	# Clear all existing labels
	for child in scroll_vbox.get_children():
		scroll_vbox.remove_child(child)
		child.queue_free()
	timeline_labels.clear()

	# Render up to ActionTimeline.MAX_ENTRIES (200) as real labels
	var show_count: int = clampi(total, 0, 200)
	if show_count == 0:
		var placeholder: Label = _make_label("暂无事件", 8, false)
		placeholder.add_theme_color_override("font_color", Color(0.50, 0.56, 0.56))
		scroll_vbox.add_child(placeholder)
		timeline_labels.append(placeholder)
		return
	var start_idx: int = max(total - show_count, 0)
	for i in range(show_count):
		var raw_entry: Variant = entries[start_idx + i]
		if raw_entry is Dictionary:
			var label: Label = _make_label(String(raw_entry.get("text", "")), 8, false)
			var entry_color: Color = raw_entry.get("color", Color(0.60, 0.66, 0.66))
			label.add_theme_color_override("font_color", entry_color)
			scroll_vbox.add_child(label)
			timeline_labels.append(label)

	# Scroll to bottom so latest entry is visible; user can scroll up for history
	var scroll: ScrollContainer = dock_control_slots.get("timeline_scroll", null) as ScrollContainer
	if scroll != null:
		scroll.set_deferred("scroll_vertical", scroll.get_v_scroll_bar().max_value)

func _create_section(parent: Control, section_id: String, title_text: String, stretch_ratio: float, line_ids: Array[String]) -> void:
	var box: VBoxContainer = _create_card(parent, section_id, title_text, stretch_ratio)

	var title: Label = _make_label(title_text, TITLE_FONT_SIZE, true)
	box.add_child(title)

	var lines: Dictionary = {}
	for line_id in line_ids:
		var label: Label = _make_label("", _get_line_font_size(section_id, line_id), false, _is_key_line(section_id, line_id))
		box.add_child(label)
		lines[line_id] = label
	section_labels[section_id] = lines


func _create_status_section(parent: Control) -> void:
	var box: VBoxContainer = _create_card(parent, "status", "状态", 1.0)
	var lines: Dictionary = {}
	_add_title_label(box, "状态")
	lines["rp_primary"] = _add_line(box, "", PRIMARY_FONT_SIZE, true)
	lines["income_short"] = _add_line(box, "", KEY_FONT_SIZE, true)
	lines["phase"] = _add_line(box, "", BODY_FONT_SIZE, false)
	lines["save_status"] = _add_line(box, "", BODY_FONT_SIZE, false)
	lines["time_tick"] = _add_line(box, "", BODY_FONT_SIZE, false)
	lines["simulation"] = _add_line(box, "", BODY_FONT_SIZE, false)
	lines["data"] = _add_line(box, "", BODY_FONT_SIZE, false)
	section_labels["status"] = lines


func _create_entry_system_section(parent: Control) -> void:
	var box: VBoxContainer = _create_card(parent, "entry_system", "系统", 1.05)
	_add_title_label(box, "系统")

	var entry_grid: GridContainer = GridContainer.new()
	entry_grid.columns = 2
	entry_grid.add_theme_constant_override("h_separation", 4)
	entry_grid.add_theme_constant_override("v_separation", 3)
	entry_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(entry_grid)
	dock_control_slots["entry"] = entry_grid

	var system_grid: GridContainer = GridContainer.new()
	system_grid.columns = 3
	system_grid.add_theme_constant_override("h_separation", 4)
	system_grid.add_theme_constant_override("v_separation", 3)
	system_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(system_grid)
	dock_control_slots["system"] = system_grid

	var status_lines: Dictionary = {}
	var info_grid: GridContainer = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 4)
	info_grid.add_theme_constant_override("v_separation", 2)
	info_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(info_grid)

	# RP capsule - full card width
	var rp_panel: PanelContainer = PanelContainer.new()
	rp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rp_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.123, 0.132), Color(0.18, 0.21, 0.22), 3))
	box.add_child(rp_panel)
	var rp_margin: MarginContainer = MarginContainer.new()
	rp_margin.add_theme_constant_override("margin_left", 4)
	rp_margin.add_theme_constant_override("margin_top", 2)
	rp_margin.add_theme_constant_override("margin_right", 4)
	rp_margin.add_theme_constant_override("margin_bottom", 2)
	rp_panel.add_child(rp_margin)
	var rp_box: VBoxContainer = VBoxContainer.new()
	rp_box.add_theme_constant_override("separation", 0)
	rp_margin.add_child(rp_box)
	var rp_title: Label = _make_label("RP", 7, false)
	rp_title.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	rp_box.add_child(rp_title)
	rp_display_label = _make_label("0  +0.00/h", KEY_FONT_SIZE, false, true)
	rp_display_label.clip_text = false
	rp_display_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rp_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rp_box.add_child(rp_display_label)

	status_lines["phase"] = _create_secondary_tile(info_grid, "等级")
	status_lines["time_tick"] = _create_secondary_tile(info_grid, "时间")
	status_lines["save_status"] = _create_secondary_tile(info_grid, "任务")
	status_lines["validation"] = _create_secondary_tile(info_grid, "消息")
	section_labels["status"] = status_lines


func _create_core_status_section(parent: Control) -> void:
	var box: VBoxContainer = _create_card(parent, "core_status", "核心状态", 2.45)
	_add_title_label(box, "核心状态")

	var metric_grid: GridContainer = GridContainer.new()
	metric_grid.columns = 4
	metric_grid.add_theme_constant_override("h_separation", 4)
	metric_grid.add_theme_constant_override("v_separation", 2)
	metric_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(metric_grid)

	var status_lines: Dictionary = section_labels.get("status", {})
	var water_lines: Dictionary = {}
	water_lines["water_primary"] = _create_metric_tile(metric_grid, "水质")
	var livestock_lines: Dictionary = {}
	livestock_lines["comfort_primary"] = _create_metric_tile(metric_grid, "舒适度")
	livestock_lines["load_primary"] = _create_metric_tile(metric_grid, "生物负载")
	livestock_lines["revenue_primary"] = _create_metric_tile(metric_grid, "收益倍率")

	var secondary_grid: GridContainer = GridContainer.new()
	secondary_grid.columns = 4
	secondary_grid.add_theme_constant_override("h_separation", 4)
	secondary_grid.add_theme_constant_override("v_separation", 2)
	secondary_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(secondary_grid)

	water_lines["temperature"] = _create_secondary_tile(secondary_grid, "温度")
	water_lines["ph"] = _create_secondary_tile(secondary_grid, "pH")
	water_lines["alkalinity"] = _create_secondary_tile(secondary_grid, "KH")
	water_lines["calcium"] = _create_secondary_tile(secondary_grid, "Ca")
	water_lines["salinity"] = _create_secondary_tile(secondary_grid, "盐度")
	water_lines["nitrate"] = _create_secondary_tile(secondary_grid, "NO3")
	water_lines["phosphate"] = _create_secondary_tile(secondary_grid, "PO4")
	water_lines["water_flow"] = _create_secondary_tile(secondary_grid, "水流")
	water_lines["filter_efficiency"] = _create_secondary_tile(secondary_grid, "过滤")
	livestock_lines["coral_count"] = _create_secondary_tile(secondary_grid, "珊瑚")
	livestock_lines["fish_count"] = _create_secondary_tile(secondary_grid, "鱼")
	livestock_lines["crustacean_count"] = _create_secondary_tile(secondary_grid, "甲壳")
	livestock_lines["algae_count"] = _create_secondary_tile(secondary_grid, "藻类")

	section_labels["status"] = status_lines

	section_labels["water"] = water_lines
	section_labels["livestock"] = livestock_lines


func _create_operations_section(parent: Control) -> void:
	var box: VBoxContainer = _create_card(parent, "operations", "操作控制", 1.55)
	_add_title_label(box, "操作控制")

	var ops_grid: GridContainer = GridContainer.new()
	ops_grid.columns = 5
	ops_grid.add_theme_constant_override("h_separation", 4)
	ops_grid.add_theme_constant_override("v_separation", 3)
	ops_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(ops_grid)
	dock_control_slots["maintenance"] = ops_grid

	dock_control_slots["maintenance_feedback_parent"] = box
	dock_control_slots["devices"] = ops_grid

	var ops_lines: Dictionary = {}
	section_labels["operations"] = ops_lines

	# 光照 slider row
	var light_intensity_row: HBoxContainer = HBoxContainer.new()
	light_intensity_row.add_theme_constant_override("separation", 4)
	light_intensity_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(light_intensity_row)
	var li_label: Label = Label.new()
	li_label.text = "光照"
	li_label.add_theme_font_size_override("font_size", 8)
	li_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	li_label.custom_minimum_size = Vector2(28, 16)
	light_intensity_row.add_child(li_label)
	var light_intensity_slider: HSlider = HSlider.new()
	light_intensity_slider.min_value = 0
	light_intensity_slider.max_value = 100
	light_intensity_slider.value = 100
	light_intensity_slider.step = 1
	light_intensity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_intensity_slider.custom_minimum_size = Vector2(60, 14)
	light_intensity_row.add_child(light_intensity_slider)
	var li_value_label: Label = Label.new()
	li_value_label.text = "100"
	li_value_label.add_theme_font_size_override("font_size", 8)
	li_value_label.add_theme_color_override("font_color", KEY_TEXT_COLOR)
	li_value_label.custom_minimum_size = Vector2(24, 16)
	light_intensity_row.add_child(li_value_label)
	dock_control_slots["light_intensity_slider"] = light_intensity_slider
	dock_control_slots["light_intensity_value"] = li_value_label

	# 色温 slider row
	var light_temp_row: HBoxContainer = HBoxContainer.new()
	light_temp_row.add_theme_constant_override("separation", 4)
	light_temp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(light_temp_row)
	var lt_label: Label = Label.new()
	lt_label.text = "色温"
	lt_label.add_theme_font_size_override("font_size", 8)
	lt_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	lt_label.custom_minimum_size = Vector2(28, 16)
	light_temp_row.add_child(lt_label)
	var light_temp_slider: HSlider = HSlider.new()
	light_temp_slider.min_value = 0
	light_temp_slider.max_value = 100
	light_temp_slider.value = 50
	light_temp_slider.step = 1
	light_temp_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_temp_slider.custom_minimum_size = Vector2(60, 14)
	light_temp_row.add_child(light_temp_slider)
	var lt_value_label: Label = Label.new()
	lt_value_label.text = "50"
	lt_value_label.add_theme_font_size_override("font_size", 8)
	lt_value_label.add_theme_color_override("font_color", KEY_TEXT_COLOR)
	lt_value_label.custom_minimum_size = Vector2(24, 16)
	light_temp_row.add_child(lt_value_label)
	dock_control_slots["light_temp_slider"] = light_temp_slider
	dock_control_slots["light_temp_value"] = lt_value_label


func configure_dock_controls(maintenance_actions: Array, feeding_actions: Array, device_state: Dictionary, callbacks: Dictionary, show_debug_controls: bool) -> Dictionary:
	var result: Dictionary = {
		"shop_btn": null,
		"livestock_btn": null,
		"panel_status_label": null,
		"maintenance_feedback_label": null,
		"maintenance_balance_label": null,
		"maintenance_buttons": {},
		"maintenance_button_base_texts": {},
		"maintenance_button_costs": {},
		"feeding_buttons": {},
		"feeding_button_base_texts": {},
		"device_buttons": {},
		"device_button_base_texts": {},
	}

	var entry_parent: Control = dock_control_slots.get("entry", null)
	if entry_parent != null:
		_clear_container_children(entry_parent)
		var shop_button: Button = _make_dock_button("商店")
		_connect_button(shop_button, callbacks.get("shop", Callable()))
		entry_parent.add_child(shop_button)
		result["shop_btn"] = shop_button

		var livestock_button: Button = _make_dock_button("生物")
		_connect_button(livestock_button, callbacks.get("livestock", Callable()))
		entry_parent.add_child(livestock_button)
		result["livestock_btn"] = livestock_button


	var system_parent: Control = dock_control_slots.get("system", null)
	if system_parent != null:
		_clear_container_children(system_parent)
		var observe_button: Button = _make_dock_button("观赏")
		observe_button.tooltip_text = "隐藏底部 Dock，进入观赏区"
		observe_button.pressed.connect(_set_observation_mode.bind(true))
		system_parent.add_child(observe_button)

		if show_debug_controls:
			var save_button: Button = _make_dock_button("保存")
			save_button.add_theme_color_override("font_color", Color(0.76, 0.80, 0.66))
			_connect_button(save_button, callbacks.get("save", Callable()))
			system_parent.add_child(save_button)

			var reset_button: Button = _make_dock_button("重置")
			reset_button.add_theme_color_override("font_color", Color(0.82, 0.70, 0.60))
			_connect_button(reset_button, callbacks.get("reset", Callable()))
			system_parent.add_child(reset_button)

		var status_label: Label = _create_secondary_tile(system_parent, "tick")
		status_label.text = "0"
		result["panel_status_label"] = status_label


	var maintenance_parent: Control = dock_control_slots.get("maintenance", null)
	var maintenance_buttons: Dictionary = {}
	var maintenance_base_texts: Dictionary = {}
	var maintenance_costs: Dictionary = {}
	if maintenance_parent != null:
		_clear_container_children(maintenance_parent)
		for raw_action in maintenance_actions:
			if not raw_action is Dictionary:
				continue
			var action: Dictionary = raw_action
			var action_id: String = String(action.get("id", ""))
			var action_cost: float = float(action.get("cost", 0.0))
			var base_text: String = "%s %.0fRP" % [String(action.get("short_label", action.get("label", action_id))), action_cost]
			var button: Button = _make_dock_button(base_text, Vector2(74, 18))
			button.tooltip_text = String(action.get("description", ""))
			_connect_button(button, callbacks.get("maintenance", Callable()).bind(action_id))
			maintenance_parent.add_child(button)
			maintenance_buttons[action_id] = button
			maintenance_base_texts[action_id] = base_text
			maintenance_costs[action_id] = action_cost
	result["maintenance_buttons"] = maintenance_buttons
	result["maintenance_button_base_texts"] = maintenance_base_texts
	result["maintenance_button_costs"] = maintenance_costs

	# maintenance_feedback_label moved to timeline; operations keeps only short tags
	result["maintenance_feedback_label"] = null

	var device_parent: Control = dock_control_slots.get("devices", null)
	var device_buttons_result: Dictionary = {}
	var device_base_texts: Dictionary = {}
	var feeding_buttons_result: Dictionary = {}
	var feeding_base_texts: Dictionary = {}
	if device_parent != null:
		var raw_devices: Variant = device_state.get("devices", {})
		var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
		for device_id in ["return_pump", "wave_pump", "main_light"]:
			var raw_device: Variant = devices.get(device_id, {})
			var device_info: Dictionary = raw_device if raw_device is Dictionary else {}
			var display_name: String = String(device_info.get("display_name", device_id))
			var button: Button = _make_dock_button(display_name, Vector2(74, 18))
			button.tooltip_text = "切换%s（prototype运行时状态，不写入存档）" % display_name
			_connect_button(button, callbacks.get("device", Callable()).bind(device_id))
			device_parent.add_child(button)
			device_buttons_result[device_id] = button
			device_base_texts[device_id] = display_name
		for raw_feed in feeding_actions:
			if not raw_feed is Dictionary:
				continue
			var feed: Dictionary = raw_feed
			var feed_id: String = String(feed.get("id", ""))
			var base_text: String = String(feed.get("short_label", feed.get("label", feed_id)))
			var feed_button: Button = _make_dock_button(base_text, Vector2(74, 18))
			feed_button.tooltip_text = "%s 主动喂食，增加 NO3/PO4" % String(feed.get("label", base_text))
			_connect_button(feed_button, callbacks.get("feed", Callable()).bind(feed_id))
			device_parent.add_child(feed_button)
			feeding_buttons_result[feed_id] = feed_button
			feeding_base_texts[feed_id] = base_text
	result["device_buttons"] = device_buttons_result
	result["device_button_base_texts"] = device_base_texts
	result["feeding_buttons"] = feeding_buttons_result
	result["feeding_button_base_texts"] = feeding_base_texts
	return result


func _connect_button(button: Button, callback: Callable) -> void:
	if callback.is_valid():
		button.pressed.connect(callback)


func _make_dock_button(text: String, min_size: Vector2 = Vector2(54, 18)) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color(0.80, 0.86, 0.84))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.18, 0.20, 0.21), Color(0.32, 0.36, 0.37)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.22, 0.245, 0.255), Color(0.42, 0.48, 0.49)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.155, 0.165), Color(0.44, 0.52, 0.52)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.125, 0.135, 0.142), Color(0.20, 0.22, 0.23)))
	return button


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style



func _clear_container_children(container: Control) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _set_observation_mode(enabled: bool) -> void:
	if dock_body != null:
		dock_body.visible = not enabled
	if collapsed_bar != null:
		collapsed_bar.visible = enabled
	custom_minimum_size = Vector2(0, COLLAPSED_DOCK_HEIGHT if enabled else DOCK_HEIGHT)


func _show_maintenance_hint() -> void:
	_set_line("operations", "maintenance", "维护操作集中在底部 Dock 中")


func _create_card(parent: Control, section_id: String, title_text: String, stretch_ratio: float) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = section_id + "_Card"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch_ratio
	panel.add_theme_stylebox_override("panel", _make_panel_style(CARD_BG_COLOR, CARD_BORDER_COLOR, 3))
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return box


func _add_title_label(parent: Control, text: String) -> Label:
	var label: Label = _make_label(text, TITLE_FONT_SIZE, true)
	label.add_theme_color_override("font_color", TITLE_TEXT_COLOR)
	parent.add_child(label)
	return label


func _add_line(parent: Control, text: String, font_size: int, is_key: bool) -> Label:
	var label: Label = _make_label(text, font_size, false, is_key)
	parent.add_child(label)
	return label


func _create_metric_tile(parent: Control, title_text: String) -> Label:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_panel_style(METRIC_BG_COLOR, Color(0.18, 0.22, 0.23), 3))
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	var title: Label = _make_label(title_text, 7, false)
	title.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	box.add_child(title)

	var value: Label = _make_label("", PRIMARY_FONT_SIZE, false, true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(value)
	return value


func _create_secondary_tile(parent: Control, title_text: String) -> Label:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.123, 0.132), Color(0.18, 0.21, 0.22), 3))
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	var title: Label = _make_label(title_text, 7, false)
	title.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	box.add_child(title)

	var value: Label = _make_label("", KEY_FONT_SIZE, false, true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(value)
	return value


func _make_panel_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _make_label(text: String, font_size: int, is_title: bool, is_key: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("line_spacing", 0)
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if is_title:
		label.add_theme_color_override("font_color", TITLE_TEXT_COLOR)
	elif is_key:
		label.add_theme_color_override("font_color", KEY_TEXT_COLOR)
	else:
		label.add_theme_color_override("font_color", BODY_TEXT_COLOR)
	return label


func _get_line_font_size(section_id: String, line_id: String) -> int:
	return KEY_FONT_SIZE if _is_key_line(section_id, line_id) else BODY_FONT_SIZE


func _is_key_line(section_id: String, line_id: String) -> bool:
	if section_id == "livestock" and line_id in ["capacity", "points", "income"]:
		return true
	if section_id == "dynamic" and line_id in ["economy_delta_a", "bio_feedback"]:
		return true
	if section_id == "water" and line_id == "summary":
		return true
	return false


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
	var water_quality_effect: float = float(device_effect.get("water_quality_effect", 0.0))
	return "过滤 %.0f%%  水质 %+.0f" % [
		filter_efficiency,
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
	return "%s｜水流 %.0f｜健康 %.2f｜造浪 %+.2f" % [
		wave_text,
		comfort_score,
		health_modifier,
		wave_effect,
	]


func _format_device_light_line(device_effect: Dictionary) -> String:
	var income_multiplier: float = float(device_effect.get("income_multiplier", 1.0))
	var stability_effect: float = float(device_effect.get("stability_effect", 0.0))
	var light_income_percent: float = float(device_effect.get("light_income_percent", 100.0))
	return "光照 %.0f%%｜收益 x%.2f｜稳定 %+.0f" % [
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
	_set_line("status", "income_short", "+0.00 /h")
	_set_line("status", "phase", "Lv1 0%")
	_set_line("status", "save_status", "未保存")
	_set_line("status", "time_tick", "第1天 00:00")
	_set_line("status", "simulation", "模拟运行｜1秒=10分钟")
	_set_line("status", "data", "仓库 暂无｜锁定")
	_set_line("status", "validation", "\u2014")
	_set_line("status", "save_offline", "离线 无")
	_set_status_line("water", "water_primary", "100", STATUS_OK_COLOR)
	_set_status_line("water", "temperature", "25.1° +0.1", STATUS_OK_COLOR)
	_set_status_line("water", "ph", "8.20 OK", STATUS_OK_COLOR)
	_set_status_line("water", "alkalinity", "8.3 OK", STATUS_OK_COLOR)
	_set_status_line("water", "calcium", "430 OK", STATUS_OK_COLOR)
	_set_status_line("water", "salinity", "35.0 OK", STATUS_OK_COLOR)
	_set_status_line("water", "water_flow", "100%", STATUS_OK_COLOR)
	_set_status_line("water", "filter_efficiency", "100%", STATUS_OK_COLOR)
	_set_status_line("water", "nitrate", "2.60 OK", STATUS_OK_COLOR)
	_set_status_line("water", "phosphate", "0.030 OK", STATUS_OK_COLOR)
	_set_line("water", "deviation_minerals", "矿物偏差：KH +0.0｜Ca +0｜全部正常")
	_set_status_line("livestock", "comfort_primary", "100", STATUS_OK_COLOR)
	_set_status_line("livestock", "load_primary", "23.4/39.2", STATUS_OK_COLOR)
	_set_status_line("livestock", "revenue_primary", "1.10x", STATUS_OK_COLOR)
	_set_status_line("livestock", "fish_count", "0", KEY_TEXT_COLOR)
	_set_status_line("livestock", "coral_count", "0", KEY_TEXT_COLOR)
	_set_status_line("livestock", "crustacean_count", "0", STATUS_IDLE_COLOR)
	_set_status_line("livestock", "reserve_metric", "\u2014", STATUS_IDLE_COLOR)
	_set_status_line("livestock", "algae_count", "\u2014", STATUS_IDLE_COLOR)
	_set_line("livestock", "secondary", "倍率 水质1.00｜舒适1.10｜健康1.00")
	_set_line("livestock", "value", "缸价值 59.0｜状态 正常")
	_set_status_line("operations", "device_filter", "100%", STATUS_OK_COLOR)
	_set_status_line("operations", "device_comfort", "100%", STATUS_OK_COLOR)

	_set_status_line("operations", "maintenance", "\u2014", STATUS_IDLE_COLOR)
	_set_status_line("operations", "bio_feedback", "无", STATUS_IDLE_COLOR)


func _set_line(section_id: String, line_id: String, text: String) -> void:
	var raw_section: Variant = section_labels.get(section_id, {})
	if not raw_section is Dictionary:
		return
	var section: Dictionary = raw_section
	var raw_label: Variant = section.get(line_id, null)
	if raw_label is Label:
		var label: Label = raw_label
		label.text = text


func _set_status_line(section_id: String, line_id: String, text: String, color: Color) -> void:
	var raw_section: Variant = section_labels.get(section_id, {})
	if not raw_section is Dictionary:
		return
	var section: Dictionary = raw_section
	var raw_label: Variant = section.get(line_id, null)
	if raw_label is Label:
		var label: Label = raw_label
		label.text = text
		label.add_theme_color_override("font_color", color)


func _set_water_delta_tag(section_id: String, line_id: String, value: float, target: float, decimals: int, unit: String, ok_delta: float, warn_delta: float) -> void:
	var delta: float = value - target
	var color: Color = _delta_color(delta, ok_delta, warn_delta)
	var text: String = "%s%s %s" % [_format_number(value, decimals), unit, _format_delta_text(delta, decimals)]
	_set_status_line(section_id, line_id, text, color)


func _set_range_tag(section_id: String, line_id: String, value: float, decimals: int, low_ok: float, high_ok: float, high_warn: float) -> void:
	var status: String = "OK"
	var color: Color = STATUS_OK_COLOR
	if value < low_ok:
		status = "LOW"
		color = STATUS_WARN_COLOR
	elif value > high_warn:
		status = "HIGH"
		color = STATUS_BAD_COLOR
	elif value > high_ok:
		status = "偏高"
		color = STATUS_WARN_COLOR
	_set_status_line(section_id, line_id, "%s %s" % [_format_number(value, decimals), status], color)


func _format_delta_text(delta: float, decimals: int) -> String:
	if abs(delta) < 0.0001:
		return "OK"
	return _format_signed_number(delta, decimals)


func _delta_color(delta: float, ok_delta: float, warn_delta: float) -> Color:
	var magnitude: float = abs(delta)
	if magnitude <= ok_delta:
		return STATUS_OK_COLOR
	if magnitude <= warn_delta:
		return STATUS_WARN_COLOR
	return STATUS_BAD_COLOR


func _score_color(value: float, ok_min: float, warn_min: float) -> Color:
	if value >= ok_min:
		return STATUS_OK_COLOR
	if value >= warn_min:
		return STATUS_WARN_COLOR
	return STATUS_BAD_COLOR


func _water_status_color(water_status: String, score: float) -> Color:
	if water_status == "CRITICAL" or score < 55.0:
		return STATUS_BAD_COLOR
	if water_status == "WARNING" or score < 80.0:
		return STATUS_WARN_COLOR
	return STATUS_OK_COLOR


func _load_color(load: float, capacity: float) -> Color:
	if capacity <= 0.0:
		return STATUS_IDLE_COLOR
	var ratio: float = load / capacity
	if ratio <= 0.75:
		return STATUS_OK_COLOR
	if ratio <= 1.0:
		return STATUS_WARN_COLOR
	return STATUS_BAD_COLOR


func _multiplier_color(multiplier: float) -> Color:
	if multiplier >= 1.0:
		return STATUS_OK_COLOR
	if multiplier >= 0.85:
		return STATUS_WARN_COLOR
	return STATUS_BAD_COLOR


func _compact_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max(max_chars - 1, 0)) + "…"


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
