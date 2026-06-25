class_name GameState
extends RefCounted

var initialized: bool = false
var milestone: String = "M11 prototype biomanage and water maintenance"
var reef_points: float = 0.0
var unlocked_tier: int = 1
var time_system: TimeSystem = null
var economy_system: EconomySystem = null
var equipment_system: EquipmentSystem = null
var equipment_placement_system: EquipmentPlacementSystem = null
var water_chemistry_system: WaterChemistrySystem = null
var livestock_system: LivestockSystem = null
var unlock_system: UnlockSystem = null
var save_system: SaveSystem = null
var action_timeline: ActionTimeline = null
var stability_score: float = 50.0
var carrying_capacity_score: float = 10.0
var maintenance_load: float = 0.0
var _prev_reef_value: float = 0.0
var _prev_income_rate: float = 0.0
var _prev_health_modifier: float = 1.0
var _prev_water_income_modifier: float = 1.0
var delta_reef_value: float = 0.0
var delta_income_rate: float = 0.0
var delta_health_modifier: float = 0.0
var delta_water_income_modifier: float = 0.0
var _autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL: float = 60.0
var save_loaded: bool = false
var offline_summary: Dictionary = {}
var _pending_save_after_purchase: bool = false
var _purchase_save_timer: float = 0.0
const PURCHASE_SAVE_DELAY: float = 2.0
var _pending_save_after_livestock_change: bool = false
var _livestock_change_save_timer: float = 0.0
const LIVESTOCK_CHANGE_SAVE_DELAY: float = 2.0
var _pending_save_after_maintenance: bool = false
var _maintenance_save_timer: float = 0.0
const MAINTENANCE_SAVE_DELAY: float = 2.0
var _save_in_progress: bool = false
var _maintenance_cooldown_until_msec: Dictionary = {}
var _feeding_cooldown_until_msec: Dictionary = {}
var last_maintenance_runtime_summary: String = "未维护"
var last_feeding_runtime_summary: String = "喂食 无"
var filter_condition_percent: float = 100.0
var maintenance_relief_remaining_game_seconds: float = 0.0
var player_experience: float = 0.0
var player_level: int = 1
var successful_maintenance_count: int = 0
var feeding_action_count: int = 0
var device_states: Dictionary = {
	"return_pump": true,
	"wave_pump": true,
	"main_light": true,
	"reserve": false,
}
var last_device_runtime_summary: String = "设备：默认运行"
var light_intensity: int = 100
var light_color_temp: int = 50
var _last_logged_light_intensity: int = 100
var _last_logged_light_color_temp: int = 50
const MAINTENANCE_ACTION_RULES: Dictionary = {
	"water_change_10": {"cost": 20.0, "cooldown_sec": 10.0, "risk_message": "无"},
	"clean_filter": {"cost": 15.0, "cooldown_sec": 8.0, "risk_message": "无"},
	"dose_buffer": {"cost": 12.0, "cooldown_sec": 12.0, "risk_message": "KH偏高请谨慎"},
	"top_off": {"cost": 8.0, "cooldown_sec": 6.0, "risk_message": "无"},
	"travel_prep": {"cost": 60.0, "cooldown_sec": 30.0, "risk_message": "无"},
}
const FEEDING_ACTION_RULES: Dictionary = {
	"coral_food": {"label": "喂珊瑚粮", "short_label": "喂珊瑚粮", "cooldown_sec": 8.0},
	"fish_food": {"label": "喂鱼粮", "short_label": "喂鱼粮", "cooldown_sec": 8.0},
}
const DEVICE_DEFINITIONS: Dictionary = {
	"return_pump": {"display_name": "水泵", "default_enabled": true},
	"wave_pump": {"display_name": "造浪", "default_enabled": true},
	"main_light": {"display_name": "主灯", "default_enabled": true},
	"reserve": {"display_name": "未来设备", "default_enabled": false},
}


func initialize() -> void:
	time_system = TimeSystem.new()
	time_system.initialize()

	economy_system = EconomySystem.new()
	economy_system.initialize()

	equipment_system = EquipmentSystem.new()
	equipment_system.initialize()

	equipment_placement_system = EquipmentPlacementSystem.new()
	equipment_placement_system.initialize()

	water_chemistry_system = WaterChemistrySystem.new()
	water_chemistry_system.initialize()

	livestock_system = LivestockSystem.new()
	livestock_system.initialize()

	unlock_system = UnlockSystem.new()
	unlock_system.initialize()

	save_system = SaveSystem.new()
	save_system.initialize()

	action_timeline = ActionTimeline.new()

	_try_load_game()

	_recalculate_debug_scores()
	_update_livestock_and_economy(0.0)
	_update_unlocks()
	_autosave_timer = 0.0
	_prev_reef_value = float(economy_system.reef_value)
	_prev_income_rate = float(economy_system.income_rate_per_game_hour)
	initialized = true


func update(delta_seconds: float) -> void:
	if time_system == null or equipment_system == null or water_chemistry_system == null:
		return
	var simulation_delta_seconds: float = time_system.update_time(delta_seconds)
	_update_runtime_operation_state(simulation_delta_seconds)
	var effects_summary: Dictionary = equipment_system.get_equipment_effects_summary()
	_apply_device_effects_to_equipment_summary(effects_summary)
	water_chemistry_system.simulate_tick(simulation_delta_seconds, effects_summary)
	_recalculate_debug_scores()
	_update_livestock_and_economy(simulation_delta_seconds)
	_check_timeline_system_events()
	_update_player_progress(simulation_delta_seconds)
	_update_unlocks()
	_autosave_timer += delta_seconds
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		print("[SAVE] regular autosave firing")
		_perform_autosave()
		_autosave_timer = 0.0
	if _pending_save_after_purchase:
		_purchase_save_timer += delta_seconds
		if _purchase_save_timer >= PURCHASE_SAVE_DELAY:
			print("[SAVE] delayed autosave start timer=%.1f" % _autosave_timer)
			_perform_autosave()
			_autosave_timer = 0.0
			print("[SAVE] delayed autosave done, timer reset")
			_pending_save_after_purchase = false
			_purchase_save_timer = 0.0
	if _pending_save_after_livestock_change:
		_livestock_change_save_timer += delta_seconds
		if _livestock_change_save_timer >= LIVESTOCK_CHANGE_SAVE_DELAY:
			print("[M11 PROTOTYPE] delayed autosave after livestock release")
			_perform_autosave()
			_autosave_timer = 0.0
			_pending_save_after_livestock_change = false
			_livestock_change_save_timer = 0.0
	if _pending_save_after_maintenance:
		_maintenance_save_timer += delta_seconds
		if _maintenance_save_timer >= MAINTENANCE_SAVE_DELAY:
			print("[M11 PROTOTYPE] delayed autosave after water maintenance")
			_perform_autosave()
			_autosave_timer = 0.0
			_pending_save_after_maintenance = false
			_maintenance_save_timer = 0.0


func get_system_stability_score() -> float:
	return stability_score


func get_carrying_capacity_score() -> float:
	return carrying_capacity_score


func get_water_chemistry_debug_state() -> Dictionary:
	if water_chemistry_system == null:
		return {}
	var water_debug: Dictionary = water_chemistry_system.get_debug_state()
	if time_system != null:
		var time_debug: Dictionary = time_system.get_debug_state()
		water_debug["elapsed_game_minutes"] = int(time_debug.get("elapsed_game_minutes", 0))
		water_debug["elapsed_game_time_text"] = String(time_debug.get("elapsed_game_time_text", "Day 1 00:00"))
		water_debug["last_delta_seconds"] = float(time_debug.get("last_delta_seconds", 0.0))
	water_debug["last_maintenance_runtime_summary"] = last_maintenance_runtime_summary
	water_debug["maintenance_currency"] = "RP"
	water_debug["maintenance_balance"] = economy_system.get_reef_points() if economy_system != null else 0.0
	return water_debug


func get_water_maintenance_actions() -> Array:
	if water_chemistry_system == null:
		return []
	var actions: Array = []
	for raw_action in water_chemistry_system.get_maintenance_actions():
		if not raw_action is Dictionary:
			continue
		var action: Dictionary = raw_action.duplicate()
		var action_id: String = String(action.get("id", ""))
		var rule: Dictionary = _get_maintenance_rule(action_id)
		action["cost"] = float(rule.get("cost", 0.0))
		action["cooldown_sec"] = float(rule.get("cooldown_sec", 0.0))
		actions.append(action)
	return actions


func get_feeding_actions() -> Array:
	var actions: Array = []
	for feed_id in ["coral_food", "fish_food"]:
		var raw_rule: Variant = FEEDING_ACTION_RULES.get(feed_id, {})
		if not raw_rule is Dictionary:
			continue
		var rule: Dictionary = raw_rule
		actions.append({
			"id": feed_id,
			"label": String(rule.get("label", feed_id)),
			"short_label": String(rule.get("short_label", feed_id)),
			"cooldown_sec": float(rule.get("cooldown_sec", 0.0)),
		})
	return actions


func get_maintenance_action_state(action_id: String) -> Dictionary:
	var rule: Dictionary = _get_maintenance_rule(action_id)
	var cost: float = float(rule.get("cost", 0.0))
	var cooldown_sec: float = float(rule.get("cooldown_sec", 0.0))
	var remaining_cooldown: float = _get_maintenance_remaining_cooldown(action_id)
	var current_balance: float = economy_system.get_reef_points() if economy_system != null else 0.0
	var reason: String = "ok"
	var can_execute: bool = true
	if rule.is_empty():
		can_execute = false
		reason = "unknown_action"
	elif remaining_cooldown > 0.0:
		can_execute = false
		reason = "cooldown"
	elif current_balance < cost:
		can_execute = false
		reason = "insufficient_funds"
	return {
		"action_id": action_id,
		"cost": cost,
		"cooldown_sec": cooldown_sec,
		"remaining_cooldown": remaining_cooldown,
		"can_execute": can_execute,
		"reason": reason,
		"current_balance": current_balance,
	}


func get_maintenance_cooldown_remaining(action_id: String) -> float:
	return _get_maintenance_remaining_cooldown(action_id)


func get_maintenance_cost(action_id: String) -> float:
	var rule: Dictionary = _get_maintenance_rule(action_id)
	return float(rule.get("cost", 0.0))


func get_feeding_action_state(feed_id: String) -> Dictionary:
	var raw_rule: Variant = FEEDING_ACTION_RULES.get(feed_id, {})
	var rule: Dictionary = raw_rule if raw_rule is Dictionary else {}
	var remaining_cooldown: float = _get_feeding_remaining_cooldown(feed_id)
	var reason: String = "ok"
	if rule.is_empty():
		reason = "unknown_feed"
	elif remaining_cooldown > 0.0:
		reason = "cooldown"
	return {
		"feed_id": feed_id,
		"cooldown_sec": float(rule.get("cooldown_sec", 0.0)),
		"remaining_cooldown": remaining_cooldown,
		"can_execute": not rule.is_empty() and remaining_cooldown <= 0.0,
		"reason": reason,
	}


func toggle_device(device_id: String) -> Dictionary:
	if not DEVICE_DEFINITIONS.has(device_id):
		return _build_device_result(device_id, false, false, "未知设备", "unknown_device")
	return set_device_enabled(device_id, not bool(device_states.get(device_id, false)))


func set_device_enabled(device_id: String, enabled: bool) -> Dictionary:
	if not DEVICE_DEFINITIONS.has(device_id):
		return _build_device_result(device_id, false, false, "未知设备", "unknown_device")
	device_states[device_id] = enabled
	var effect_summary: Dictionary = get_device_effect_summary()
	if water_chemistry_system != null:
		water_chemistry_system.apply_device_effect_summary(effect_summary)
	_recalculate_debug_scores()
	_update_livestock_and_economy(0.0)
	_update_unlocks()
	var risk_message: String = String(effect_summary.get("risk_message", "无"))
	var summary: String = _format_device_toggle_summary(device_id, enabled, effect_summary)
	if not risk_message.is_empty() and risk_message != "无":
		summary += "｜风险：" + risk_message
	summary += "｜" + _format_bio_load_runtime_summary("设备开启后系统压力下降" if enabled else "设备关闭后系统压力上升")
	last_device_runtime_summary = summary
	var dev_tl: Dictionary = _format_device_timeline_text(device_id, enabled)
	_timeline_log_player(String(dev_tl.get("text", "")), dev_tl.get("color", ActionTimeline.COLOR_PLAYER))
	var result: Dictionary = _build_device_result(device_id, true, enabled, summary, "ok")
	result["risk_message"] = risk_message
	result["income_multiplier"] = float(effect_summary.get("income_multiplier", 1.0))
	result["income_effect"] = float(effect_summary.get("income_effect", 0.0))
	result["water_quality_effect"] = float(effect_summary.get("water_quality_effect", 0.0))
	result["stability_effect"] = float(effect_summary.get("stability_effect", 0.0))
	result["device_nitrate_drift_per_day"] = float(effect_summary.get("device_nitrate_drift_per_day", 0.0))
	result["device_phosphate_drift_per_day"] = float(effect_summary.get("device_phosphate_drift_per_day", 0.0))
	result["filter_efficiency_percent"] = float(effect_summary.get("filter_efficiency_percent", 100.0))
	result["water_flow_percent"] = float(effect_summary.get("water_flow_percent", 100.0))
	result["flow_comfort_score"] = float(effect_summary.get("flow_comfort_score", 100.0))
	result["comfort_score"] = float(effect_summary.get("comfort_score", 100.0))
	result["comfort_health_modifier"] = float(effect_summary.get("comfort_health_modifier", 1.0))
	result["wave_comfort_effect"] = float(effect_summary.get("wave_comfort_effect", 0.0))
	result["light_income_percent"] = float(effect_summary.get("light_income_percent", 100.0))
	return result


func get_device_state() -> Dictionary:
	_ensure_device_state_defaults()
	var devices: Dictionary = {}
	for device_id in DEVICE_DEFINITIONS.keys():
		devices[device_id] = {
			"device_id": device_id,
			"display_name": _get_device_display_name(device_id),
			"enabled": bool(device_states.get(device_id, false)),
		}
	return {
		"devices": devices,
		"last_device_runtime_summary": last_device_runtime_summary,
	}


func get_device_effect_summary() -> Dictionary:
	_ensure_device_state_defaults()
	var return_pump_on: bool = bool(device_states.get("return_pump", true))
	var wave_pump_on: bool = bool(device_states.get("wave_pump", true))
	var main_light_on: bool = bool(device_states.get("main_light", true))
	var income_multiplier: float = 1.0
	var stability_effect: float = 0.0
	var water_quality_effect: float = 0.0
	var device_water_quality_penalty: float = 0.0
	var nitrate_drift_per_day: float = 0.0
	var phosphate_drift_per_day: float = 0.0
	var water_flow_percent: float = _calculate_water_flow_percent(return_pump_on, wave_pump_on)
	var filter_efficiency_percent: float = _calculate_filter_efficiency_percent(return_pump_on, water_flow_percent)
	var comfort_score: float = clamp(45.0 + water_flow_percent * 0.55, 0.0, 100.0)
	var comfort_health_modifier: float = 1.0
	var wave_comfort_effect: float = 0.0
	var light_income_percent: float = 100.0
	var risks: Array[String] = []

	if not return_pump_on:
		income_multiplier *= 0.85
		stability_effect -= 8.0
		water_quality_effect -= 10.0
		device_water_quality_penalty += 10.0
		nitrate_drift_per_day += 0.35
		phosphate_drift_per_day += 0.006
		comfort_score -= 5.0
		comfort_health_modifier -= 0.03
		risks.append("水泵关闭，过滤循环不足")
	if not wave_pump_on:
		income_multiplier *= 0.90
		stability_effect -= 5.0
		water_quality_effect -= 3.0
		device_water_quality_penalty += 3.0
		comfort_health_modifier -= 0.12
		wave_comfort_effect = -0.12
		risks.append("造浪不足，生物舒适度下降")
	if water_flow_percent <= 0.0:
		income_multiplier *= 0.65
		stability_effect -= 18.0
		device_water_quality_penalty += 16.0
		nitrate_drift_per_day += 0.65
		phosphate_drift_per_day += 0.012
		comfort_score = 0.0
		comfort_health_modifier -= 0.18
		risks.append("水流为0，系统循环停止")
	if not main_light_on:
		income_multiplier *= 0.65
		stability_effect -= 2.0
		light_income_percent = 65.0
		risks.append("主灯关闭，光照不足，收益降低")
	if filter_efficiency_percent < 55.0:
		device_water_quality_penalty += 8.0
		nitrate_drift_per_day += 0.45
		phosphate_drift_per_day += 0.007
		risks.append("过滤低，建议清滤")
	elif filter_efficiency_percent < 80.0:
		device_water_quality_penalty += 3.0
		nitrate_drift_per_day += 0.18
		phosphate_drift_per_day += 0.003
	var livestock_pressure: Dictionary = _get_livestock_pollution_pressure()
	nitrate_drift_per_day += float(livestock_pressure.get("nitrate", 0.0))
	phosphate_drift_per_day += float(livestock_pressure.get("phosphate", 0.0))

	var risk_message: String = "无"
	if not risks.is_empty():
		risk_message = _join_device_risks(risks)
	var clamped_income_multiplier: float = clamp(income_multiplier, 0.10, 1.0)
	var clamped_comfort_score: float = clamp(comfort_score, 0.0, 100.0)
	var clamped_comfort_health_modifier: float = clamp(comfort_health_modifier, 0.50, 1.0)
	return {
		"income_multiplier": clamp(income_multiplier, 0.10, 1.0),
		"income_effect": clamped_income_multiplier - 1.0,
		"stability_effect": stability_effect,
		"water_quality_effect": water_quality_effect,
		"device_water_quality_penalty": device_water_quality_penalty,
		"device_nitrate_drift_per_day": nitrate_drift_per_day,
		"device_phosphate_drift_per_day": phosphate_drift_per_day,
		"bio_load_nitrate_drift_per_day": float(livestock_pressure.get("nitrate", 0.0)),
		"bio_load_phosphate_drift_per_day": float(livestock_pressure.get("phosphate", 0.0)),
		"filter_efficiency_percent": filter_efficiency_percent,
		"water_flow_percent": water_flow_percent,
		"flow_comfort_score": water_flow_percent,
		"comfort_score": clamped_comfort_score,
		"comfort_health_modifier": clamped_comfort_health_modifier,
		"wave_comfort_effect": wave_comfort_effect,
		"light_income_percent": light_income_percent,
		"filter_condition_percent": filter_condition_percent,
		"maintenance_relief": _get_maintenance_relief_power(),
		"risk_message": risk_message,
		"risk_messages": risks.duplicate(),
		"summary": _format_device_effect_summary(
			clamped_income_multiplier,
			stability_effect,
			water_quality_effect,
			nitrate_drift_per_day,
			phosphate_drift_per_day,
			filter_efficiency_percent,
			water_flow_percent,
			clamped_comfort_health_modifier,
			wave_comfort_effect,
			light_income_percent
		),
	}


func apply_water_maintenance_action(action_id: String) -> Dictionary:
	print("[M11 PROTOTYPE] water maintenance request action_id=", action_id)
	if water_chemistry_system == null or economy_system == null:
		return {"success": false, "error": "system_unavailable", "action_id": action_id}
	var result: Dictionary = _try_perform_maintenance(action_id)
	if not bool(result.get("success", false)):
		print("[M11 PROTOTYPE] water maintenance failed reason=", result.get("reason", "unknown"))
		return result
	_recalculate_debug_scores()
	_update_livestock_and_economy(0.0)
	_add_maintenance_progress(action_id)
	_update_unlocks()
	var comfort_summary: String = _format_bio_load_runtime_summary("维护后舒适度恢复")
	last_maintenance_runtime_summary += "｜" + comfort_summary
	result["summary"] = String(result.get("summary", "")) + "｜" + comfort_summary
	result["comfort_score"] = float(livestock_system.get_debug_state().get("comfort_score", 100.0)) if livestock_system != null else 100.0
	result["revenue_multiplier"] = float(livestock_system.get_debug_state().get("revenue_multiplier", 1.0)) if livestock_system != null else 1.0
	reef_points = economy_system.get_reef_points() if economy_system != null else reef_points
	_pending_save_after_maintenance = true
	_maintenance_save_timer = 0.0
	print("[M11 PROTOTYPE] water maintenance success label=", result.get("label", ""), " delta=", result.get("delta_summary", ""))
	if action_timeline != null:
		action_timeline.reset_neglect()
		var maint_tl: Dictionary = _format_maintenance_timeline_text(action_id, result)
		_timeline_log_player(String(maint_tl.get("text", "")), maint_tl.get("color", ActionTimeline.COLOR_PLAYER))
	return result


func apply_feeding_action(feed_id: String) -> Dictionary:
	if water_chemistry_system == null:
		return {"success": false, "error": "system_unavailable", "feed_id": feed_id, "summary": "喂食 不可用"}
	var raw_rule: Variant = FEEDING_ACTION_RULES.get(feed_id, {})
	var rule: Dictionary = raw_rule if raw_rule is Dictionary else {}
	if rule.is_empty():
		return {"success": false, "error": "unknown_feed", "feed_id": feed_id, "summary": "喂食 未知"}
	var remaining: float = _get_feeding_remaining_cooldown(feed_id)
	if remaining > 0.0:
		last_feeding_runtime_summary = "喂食 冷却"
		return {"success": false, "error": "cooldown", "feed_id": feed_id, "remaining_cooldown": remaining, "summary": "喂食 冷却"}
	var fish_count: int = int(livestock_system.get_debug_state().get("fish_count", 0)) if livestock_system != null else 0
	var coral_count: int = int(livestock_system.get_debug_state().get("coral_count", 0)) if livestock_system != null else 0
	var result: Dictionary = water_chemistry_system.apply_feeding(feed_id, fish_count, coral_count)
	if not bool(result.get("success", false)):
		return result
	_feeding_cooldown_until_msec[feed_id] = Time.get_ticks_msec() + int(float(rule.get("cooldown_sec", 8.0)) * 1000.0)
	feeding_action_count += 1
	filter_condition_percent = max(filter_condition_percent - 3.0, 25.0)
	if feed_id == "fish_food":
		last_feeding_runtime_summary = "鱼粮 +NO3/+PO4"
	else:
		last_feeding_runtime_summary = "珊瑚粮 +PO4/+NO3"
	last_maintenance_runtime_summary = last_feeding_runtime_summary
	_recalculate_debug_scores()
	_update_livestock_and_economy(0.0)
	_add_player_experience(6.0)
	_update_unlocks()
	result["summary"] = last_feeding_runtime_summary
	result["filter_condition_percent"] = filter_condition_percent
	var feed_label: String = "喂魚糧" if feed_id == "fish_food" else "喂珊瑚糧"
	var d_no3: float = float(result.get("delta_nitrate", 0.0))
	var d_po4: float = float(result.get("delta_phosphate", 0.0))
	_timeline_log_player("%s" % feed_label, ActionTimeline.COLOR_PLAYER)
	return result


func _try_perform_maintenance(action_id: String) -> Dictionary:
	var rule: Dictionary = _get_maintenance_rule(action_id)
	if rule.is_empty():
		return _build_maintenance_failure(action_id, "unknown_action", "未知维护操作", 0.0, 0.0, 0.0)

	var cost: float = float(rule.get("cost", 0.0))
	var cooldown_sec: float = float(rule.get("cooldown_sec", 0.0))
	var remaining_cooldown: float = _get_maintenance_remaining_cooldown(action_id)
	if remaining_cooldown > 0.0:
		return _build_maintenance_failure(
			action_id,
			"cooldown",
			"维护冷却中，剩余 %.0f 秒" % ceil(remaining_cooldown),
			cost,
			cooldown_sec,
			remaining_cooldown
		)

	if economy_system == null or not economy_system.spend_reef_points(cost):
		var current_balance: float = economy_system.get_reef_points() if economy_system != null else 0.0
		return _build_maintenance_failure(
			action_id,
			"insufficient_funds",
			"金币不足，无法执行维护",
			cost,
			cooldown_sec,
			0.0,
			current_balance
		)

	var result: Dictionary = water_chemistry_system.apply_maintenance_action(action_id)
	if not bool(result.get("success", false)):
		economy_system.add_reef_points(cost)
		return _build_maintenance_failure(action_id, String(result.get("error", "unknown")), "维护失败", cost, cooldown_sec, 0.0)

	_maintenance_cooldown_until_msec[action_id] = Time.get_ticks_msec() + int(cooldown_sec * 1000.0)
	_apply_runtime_maintenance_effect(action_id)
	var current_balance: float = economy_system.get_reef_points()
	var summary: String = "%s｜消耗 %.0fRP｜余额%.0fRP｜冷却 %.0fs｜%s" % [
		String(result.get("result_text", result.get("label", action_id))),
		cost,
		current_balance,
		cooldown_sec,
		String(result.get("delta_summary", "")),
	]
	last_maintenance_runtime_summary = summary
	result["action_name"] = String(result.get("label", action_id))
	result["cost"] = cost
	result["cooldown_sec"] = cooldown_sec
	result["remaining_cooldown"] = cooldown_sec
	result["reason"] = "ok"
	result["summary"] = summary
	result["risk_message"] = String(rule.get("risk_message", "无"))
	result["reef_points"] = current_balance
	return result


func _build_maintenance_failure(action_id: String, reason: String, summary: String, cost: float, cooldown_sec: float, remaining_cooldown: float, current_balance: float = -1.0) -> Dictionary:
	var action_name: String = _get_maintenance_action_name(action_id)
	var display_summary: String = summary
	if reason == "cooldown":
		display_summary = "%s｜冷却中 %.0fs" % [action_name, ceil(remaining_cooldown)]
	elif reason == "insufficient_funds":
		display_summary = "%s｜余额不足｜需要%.0fRP｜当前%.0fRP" % [action_name, cost, current_balance]
	last_maintenance_runtime_summary = display_summary
	return {
		"success": false,
		"action_id": action_id,
		"action_name": action_name,
		"label": action_name,
		"cost": cost,
		"cooldown_sec": cooldown_sec,
		"remaining_cooldown": remaining_cooldown,
		"reason": reason,
		"error": reason,
		"summary": display_summary,
		"risk_message": "无",
		"current_balance": current_balance,
	}


func _get_maintenance_rule(action_id: String) -> Dictionary:
	var raw_rule: Variant = MAINTENANCE_ACTION_RULES.get(action_id, {})
	if raw_rule is Dictionary:
		return raw_rule
	return {}


func _get_maintenance_remaining_cooldown(action_id: String) -> float:
	var cooldown_until: int = int(_maintenance_cooldown_until_msec.get(action_id, 0))
	var now_msec: int = Time.get_ticks_msec()
	return max(float(cooldown_until - now_msec) / 1000.0, 0.0)


func _get_feeding_remaining_cooldown(feed_id: String) -> float:
	var cooldown_until: int = int(_feeding_cooldown_until_msec.get(feed_id, 0))
	var now_msec: int = Time.get_ticks_msec()
	return max(float(cooldown_until - now_msec) / 1000.0, 0.0)


func _get_maintenance_action_name(action_id: String) -> String:
	if water_chemistry_system != null:
		for raw_action in water_chemistry_system.get_maintenance_actions():
			if raw_action is Dictionary and String(raw_action.get("id", "")) == action_id:
				return String(raw_action.get("label", action_id))
	return action_id


func _ensure_device_state_defaults() -> void:
	for device_id in DEVICE_DEFINITIONS.keys():
		if not device_states.has(device_id):
			var definition: Dictionary = DEVICE_DEFINITIONS.get(device_id, {})
			device_states[device_id] = bool(definition.get("default_enabled", false))


func _get_device_display_name(device_id: String) -> String:
	var definition: Dictionary = DEVICE_DEFINITIONS.get(device_id, {})
	return String(definition.get("display_name", device_id))


func _build_device_result(device_id: String, success: bool, enabled: bool, summary: String, reason: String) -> Dictionary:
	return {
		"success": success,
		"device_id": device_id,
		"display_name": _get_device_display_name(device_id),
		"enabled": enabled,
		"summary": summary,
		"reason": reason,
		"risk_message": "无",
		"income_multiplier": 1.0,
		"income_effect": 0.0,
		"water_quality_effect": 0.0,
		"stability_effect": 0.0,
		"filter_efficiency_percent": 100.0,
		"water_flow_percent": 100.0,
		"flow_comfort_score": 100.0,
		"comfort_score": 100.0,
		"comfort_health_modifier": 1.0,
		"wave_comfort_effect": 0.0,
		"light_income_percent": 100.0,
	}


func _apply_device_effects_to_equipment_summary(effects_summary: Dictionary) -> void:
	var device_effects: Dictionary = get_device_effect_summary()
	effects_summary["device_water_quality_penalty"] = float(device_effects.get("device_water_quality_penalty", 0.0))
	effects_summary["device_nitrate_drift_per_day"] = float(device_effects.get("device_nitrate_drift_per_day", 0.0))
	effects_summary["device_phosphate_drift_per_day"] = float(device_effects.get("device_phosphate_drift_per_day", 0.0))
	effects_summary["bio_load_nitrate_drift_per_day"] = float(device_effects.get("bio_load_nitrate_drift_per_day", 0.0))
	effects_summary["bio_load_phosphate_drift_per_day"] = float(device_effects.get("bio_load_phosphate_drift_per_day", 0.0))
	effects_summary["maintenance_relief"] = float(device_effects.get("maintenance_relief", 0.0))
	effects_summary["flow"] = float(effects_summary.get("flow", 0.0)) * float(device_effects.get("water_flow_percent", 100.0)) / 100.0
	effects_summary["oxygenation"] = float(effects_summary.get("oxygenation", 0.0)) * float(device_effects.get("water_flow_percent", 100.0)) / 100.0
	effects_summary["nutrient_export"] = float(effects_summary.get("nutrient_export", 0.0)) * float(device_effects.get("filter_efficiency_percent", 100.0)) / 100.0
	effects_summary["bio_filtration"] = float(effects_summary.get("bio_filtration", 0.0)) * float(device_effects.get("filter_efficiency_percent", 100.0)) / 100.0


func _calculate_water_flow_percent(return_pump_on: bool, wave_pump_on: bool) -> float:
	if return_pump_on and wave_pump_on:
		return 100.0
	if return_pump_on:
		return 65.0
	if wave_pump_on:
		return 45.0
	return 0.0


func _calculate_filter_efficiency_percent(return_pump_on: bool, water_flow_percent: float) -> float:
	var pump_factor: float = 1.0 if return_pump_on else 0.25
	var flow_factor: float = clamp(water_flow_percent / 100.0, 0.0, 1.0)
	return clamp(filter_condition_percent * pump_factor * (0.55 + flow_factor * 0.45), 0.0, 100.0)


func _get_livestock_pollution_pressure() -> Dictionary:
	if livestock_system == null:
		return {"nitrate": 0.0, "phosphate": 0.0}
	var ls_debug: Dictionary = livestock_system.get_debug_state()
	var fish_count_value: int = int(ls_debug.get("fish_count", 0))
	var coral_count_value: int = int(ls_debug.get("coral_count", 0))
	var bio_load_ratio_value: float = float(ls_debug.get("bio_load_ratio", 0.0))
	return {
		"nitrate": float(fish_count_value) * 0.10 + max(bio_load_ratio_value - 0.45, 0.0) * 0.70,
		"phosphate": float(coral_count_value) * 0.0012 + max(bio_load_ratio_value - 0.45, 0.0) * 0.010,
	}


func _get_maintenance_relief_power() -> float:
	if maintenance_relief_remaining_game_seconds <= 0.0:
		return 0.0
	return clamp(maintenance_relief_remaining_game_seconds / 86400.0, 0.0, 3.0) * 10.0


func _update_runtime_operation_state(simulation_delta_seconds: float) -> void:
	var days: float = max(simulation_delta_seconds, 0.0) / 86400.0
	if days <= 0.0:
		return
	var load_ratio: float = 0.0
	if livestock_system != null:
		load_ratio = float(livestock_system.get_debug_state().get("bio_load_ratio", 0.0))
	var feed_pressure: float = min(float(feeding_action_count) * 0.02, 0.20)
	var decay_per_day: float = 1.4 + load_ratio * 1.5 + feed_pressure
	filter_condition_percent = clamp(filter_condition_percent - decay_per_day * days, 20.0, 100.0)
	maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds - max(simulation_delta_seconds, 0.0), 0.0)


func _apply_runtime_maintenance_effect(action_id: String) -> void:
	match action_id:
		"water_change_10":
			filter_condition_percent = min(filter_condition_percent + 8.0, 100.0)
			maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds, 21600.0)
		"clean_filter":
			filter_condition_percent = 100.0
			maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds, 28800.0)
		"dose_buffer":
			maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds, 14400.0)
		"top_off":
			maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds, 10800.0)
		"travel_prep":
			filter_condition_percent = 100.0
			maintenance_relief_remaining_game_seconds = max(maintenance_relief_remaining_game_seconds, 259200.0)


func _add_maintenance_progress(action_id: String) -> void:
	successful_maintenance_count += 1
	match action_id:
		"travel_prep":
			_add_player_experience(30.0)
		"clean_filter":
			_add_player_experience(18.0)
		_:
			_add_player_experience(14.0)


func _update_player_progress(simulation_delta_seconds: float) -> void:
	if simulation_delta_seconds <= 0.0 or water_chemistry_system == null or livestock_system == null or economy_system == null:
		return
	var water_debug: Dictionary = water_chemistry_system.get_debug_state()
	var water_quality: float = float(water_debug.get("water_quality_score", 100.0))
	var income_rate: float = float(economy_system.get_debug_state().get("income_rate_per_game_hour", 0.0))
	var livestock_count: int = int(livestock_system.get_debug_state().get("livestock_count", 0))
	var devices_running: bool = bool(device_states.get("return_pump", true)) and bool(device_states.get("wave_pump", true)) and bool(device_states.get("main_light", true))
	if water_quality >= 85.0 and stability_score >= 80.0 and income_rate > 0.0 and livestock_count > 0 and devices_running:
		_add_player_experience((simulation_delta_seconds / 3600.0) * 0.15)


func _add_player_experience(amount: float) -> void:
	player_experience = max(player_experience + max(amount, 0.0), 0.0)
	player_level = clamp(int(floor(player_experience / 120.0)) + 1, 1, 10)


func _get_player_level_progress() -> float:
	if player_level >= 10:
		return 1.0
	var level_start: float = float(player_level - 1) * 120.0
	return clamp((player_experience - level_start) / 120.0, 0.0, 1.0)


func _get_current_goal_label() -> String:
	if water_chemistry_system != null:
		var water_debug: Dictionary = water_chemistry_system.get_debug_state()
		var status: String = String(water_debug.get("water_status", "OK"))
		if status != "OK":
			return "维护稳定"
	if player_level < 3:
		return "维护稳定"
	if unlock_system != null and not bool(unlock_system.get_debug_state().get("unlocked_states", {}).get("tier2_equipment_preview", false)):
		return "解锁中"
	return "未解锁"


func _join_device_risks(risks: Array[String]) -> String:
	var text: String = ""
	for risk in risks:
		if not text.is_empty():
			text += "；"
		text += risk
	return text


func _format_device_effect_summary(income_multiplier: float, stability_effect: float, water_quality_effect: float, nitrate_drift_per_day: float, phosphate_drift_per_day: float, filter_efficiency_percent: float, comfort_score: float, comfort_health_modifier: float, wave_comfort_effect: float, light_income_percent: float) -> String:
	return "过滤 %.0f%%｜NO3 %+.2f/日｜PO4 %+.3f/日｜水质评分 %+.0f｜水流舒适度 %.0f%%｜健康系数 %.2f｜造浪 %+.2f｜光照 %.0f%%｜收益倍率 x%.2f｜稳定 %+.0f" % [
		filter_efficiency_percent,
		nitrate_drift_per_day,
		phosphate_drift_per_day,
		water_quality_effect,
		comfort_score,
		comfort_health_modifier,
		wave_comfort_effect,
		light_income_percent,
		income_multiplier,
		stability_effect,
	]


func _format_device_toggle_summary(device_id: String, enabled: bool, device_effect: Dictionary) -> String:
	var state_text: String = "ON" if enabled else "OFF"
	if device_id == "wave_pump":
		return "造浪%s：水流舒适度 %.0f%%｜健康系数 %.2f｜造浪 %+.2f" % [
			state_text,
			float(device_effect.get("water_flow_percent", 100.0)),
			float(device_effect.get("comfort_health_modifier", 1.0)),
			float(device_effect.get("wave_comfort_effect", 0.0)),
		]
	if device_id == "return_pump":
		return "水泵%s：过滤 %.0f%%｜水流舒适度 %.0f%%｜NO3 %+.2f/日｜PO4 %+.3f/日" % [
			state_text,
			float(device_effect.get("filter_efficiency_percent", 100.0)),
			float(device_effect.get("water_flow_percent", 100.0)),
			float(device_effect.get("device_nitrate_drift_per_day", 0.0)),
			float(device_effect.get("device_phosphate_drift_per_day", 0.0)),
		]
	if device_id == "main_light":
		return "主灯%s：光照收益 %.0f%%｜收益倍率 x%.2f" % [
			state_text,
			float(device_effect.get("light_income_percent", 100.0)),
			float(device_effect.get("income_multiplier", 1.0)),
		]
	var display_name: String = _get_device_display_name(device_id)
	return "%s：%s｜%s" % [display_name, state_text, String(device_effect.get("summary", "设备影响：无"))]


func _format_bio_load_runtime_summary(prefix: String) -> String:
	if livestock_system == null:
		return prefix
	var ls_debug: Dictionary = livestock_system.get_debug_state()
	return "%s｜生物负载 %.1f/%.1f｜压力 %.1f｜舒适度 %.0f｜收益倍率 %.2fx" % [
		prefix,
		float(ls_debug.get("bio_load", 0.0)),
		float(ls_debug.get("system_capacity", 0.0)),
		float(ls_debug.get("system_pressure", 0.0)),
		float(ls_debug.get("comfort_score", 100.0)),
		float(ls_debug.get("revenue_multiplier", 1.0)),
	]


func get_livestock_debug_state() -> Dictionary:
	if livestock_system == null:
		return {}
	return livestock_system.get_debug_state()


func get_economy_debug_state() -> Dictionary:
	if economy_system == null:
		return {}
	return economy_system.get_debug_state()


func get_unlock_debug_state() -> Dictionary:
	if unlock_system == null:
		return {}
	var debug_state: Dictionary = unlock_system.get_debug_state()
	debug_state["player_level"] = player_level
	debug_state["player_level_progress"] = _get_player_level_progress()
	debug_state["player_experience"] = player_experience
	debug_state["current_goal_label"] = _get_current_goal_label()
	return debug_state


func get_debug_state() -> Dictionary:
	var time_debug: Dictionary = {}
	var economy_debug: Dictionary = {}
	var equipment_debug: Dictionary = {}
	var placement_debug: Dictionary = {}
	var chemistry_debug: Dictionary = {}
	var livestock_debug: Dictionary = {}
	var unlock_debug: Dictionary = {}
	if time_system != null:
		time_debug = time_system.get_debug_state()
	if economy_system != null:
		economy_debug = economy_system.get_debug_state()
	if equipment_system != null:
		equipment_debug = equipment_system.get_debug_state()
	if equipment_placement_system != null:
		placement_debug = equipment_placement_system.get_debug_state()
	if water_chemistry_system != null:
		chemistry_debug = water_chemistry_system.get_debug_state()
	if livestock_system != null:
		livestock_debug = livestock_system.get_debug_state()
	if unlock_system != null:
		unlock_debug = unlock_system.get_debug_state()

	var economy_delta_debug: Dictionary = {}
	if economy_system != null:
		economy_delta_debug = {
			"delta_reef_points": economy_system.delta_reef_points,
		}

	var save_debug: Dictionary = {}
	if save_system != null:
		save_debug = save_system.get_debug_state()

	return {
		"system": "GameState",
		"initialized": initialized,
		"milestone": milestone,
		"reef_points": reef_points,
		"unlocked_tier": unlocked_tier,
		"stability_score": stability_score,
		"carrying_capacity_score": carrying_capacity_score,
		"maintenance_load": maintenance_load,
		"time": time_debug,
		"economy": economy_debug,
		"equipment": equipment_debug,
		"device": get_device_state(),
		"device_effect": get_device_effect_summary(),
		"placement": placement_debug,
		"water_chemistry": chemistry_debug,
		"livestock": livestock_debug,
		"unlock": unlock_debug,
		"save": save_debug,
		"save_loaded": save_loaded,
		"offline_summary": offline_summary.duplicate(),
		"delta": {
			"reef_points": economy_delta_debug.get("delta_reef_points", 0.0),
			"reef_value": delta_reef_value,
			"income_rate": delta_income_rate,
			"health_modifier": delta_health_modifier,
			"water_income_modifier": delta_water_income_modifier,
		},
	}


func _recalculate_debug_scores() -> void:
	if equipment_system == null:
		return
	var effects_summary: Dictionary = equipment_system.get_equipment_effects_summary()
	var device_effects: Dictionary = get_device_effect_summary()
	var water_score: float = 100.0
	var ph_value: float = 8.2
	var kh_value: float = 8.3
	if water_chemistry_system != null:
		var water_debug: Dictionary = water_chemistry_system.get_debug_state()
		water_score = float(water_debug.get("water_quality_score", 100.0))
		ph_value = float(water_debug.get("ph", 8.2))
		kh_value = float(water_debug.get("alkalinity", 8.3))
	var filter_efficiency: float = float(device_effects.get("filter_efficiency_percent", 100.0))
	var flow_percent: float = float(device_effects.get("water_flow_percent", 100.0))
	var chemistry_penalty: float = abs(ph_value - 8.2) * 18.0 + abs(kh_value - 8.3) * 3.0
	stability_score = clamp(
		42.0
		+ float(effects_summary.get("stability_bonus", 0.0))
		+ float(device_effects.get("stability_effect", 0.0))
		+ (water_score - 70.0) * 0.24
		+ (filter_efficiency - 70.0) * 0.16
		+ (flow_percent - 70.0) * 0.18
		+ _get_maintenance_relief_power() * 0.25
		- chemistry_penalty,
		0.0,
		100.0
	)
	carrying_capacity_score = 10.0 + float(effects_summary.get("carrying_capacity_bonus", 0.0))
	maintenance_load = float(effects_summary.get("maintenance_load", 0.0))


func _update_livestock_and_economy(delta_seconds: float) -> void:
	if livestock_system == null or economy_system == null or water_chemistry_system == null:
		return
	var water_state: Dictionary = water_chemistry_system.get_debug_state()
	var equipment_mult: float = 1.0 + (stability_score - 50.0) * 0.004
	var device_effects: Dictionary = get_device_effect_summary()
	livestock_system.update_bio_load_metrics({
		"water_quality_score": float(water_state.get("water_quality_score", 100.0)),
		"stability_score": stability_score,
		"carrying_capacity_score": carrying_capacity_score,
		"maintenance_load": maintenance_load,
		"device_effects": device_effects,
		"last_maintenance_action_id": String(water_state.get("last_maintenance_action_id", "")),
	})
	var device_income_mult: float = float(device_effects.get("income_multiplier", 1.0))
	var income_rate: float = livestock_system.calculate_income_rate(water_state, equipment_mult) * device_income_mult
	var current_reef_value: float = livestock_system.calculate_reef_value(water_state)
	livestock_system.set_runtime_income_result(income_rate, delta_seconds)
	var ls_debug: Dictionary = livestock_system.get_debug_state()
	var current_health: float = float(ls_debug.get("health_modifier", 1.0))
	var current_water_mult: float = float(ls_debug.get("water_quality_multiplier", 1.0))
	economy_system.reef_value = current_reef_value
	economy_system.update_income(delta_seconds, income_rate)
	reef_points = economy_system.get_reef_points()
	delta_reef_value = current_reef_value - _prev_reef_value
	delta_income_rate = income_rate - _prev_income_rate
	delta_health_modifier = current_health - _prev_health_modifier
	delta_water_income_modifier = current_water_mult - _prev_water_income_modifier
	_prev_reef_value = current_reef_value
	_prev_income_rate = income_rate
	_prev_health_modifier = current_health
	_prev_water_income_modifier = current_water_mult


func _update_unlocks() -> void:
	if unlock_system == null or economy_system == null:
		return
	unlock_system.update_unlocks(economy_system.get_debug_state())


func get_save_debug_state() -> Dictionary:
	if save_system == null:
		return {}
	return save_system.get_debug_state()


func buy_livestock_from_shop(shop_id: String) -> Dictionary:
	print("[BUY] gs.buy start shop_id=", shop_id)
	if livestock_system == null or economy_system == null:
		print("[BUY] gs.buy system unavailable")
		return {"success": false, "error": "system_unavailable"}
	var shop_entry: Dictionary = livestock_system.get_shop_entry(shop_id)
	if shop_entry.is_empty():
		return {"success": false, "error": "item_not_found", "shop_id": shop_id}
	var price: float = float(shop_entry.get("price", 0.0))
	if not economy_system.spend_reef_points(price):
		return {"success": false, "error": "insufficient_rp", "price": price, "current_rp": economy_system.get_reef_points()}
	var purchase_entry: Dictionary = {
		"id": "%s_%d" % [shop_id, Time.get_unix_time_from_system()],
		"species_name": String(shop_entry.get("species_name", "")),
		"category": String(shop_entry.get("category", "")),
		"rarity": String(shop_entry.get("rarity", "普通")),
		"size_cm": float(shop_entry.get("size_min", 3.0)),
		"maturity_percent": 0.0,
		"health_percent": 100.0,
		"base_income_per_hour": float(shop_entry.get("base_income_per_hour", 0.0)),
		"tank_slot_cost": float(shop_entry.get("tank_slot_cost", 1.0)),
		"locked": false,
		"water_sensitivity": float(shop_entry.get("water_sensitivity", 0.4)),
	}
	if not livestock_system.add_livestock(purchase_entry):
		economy_system.add_reef_points(price)
		return {"success": false, "error": "capacity_exceeded", "price": price, "capacity_used": livestock_system.get_capacity_used(), "max_capacity": livestock_system.get_max_capacity()}
	reef_points = economy_system.get_reef_points()
	_update_livestock_and_economy(0.0)
	_update_unlocks()
	print("[BUY] gs.buy setting pending save flag")
	_pending_save_after_purchase = true
	_purchase_save_timer = 0.0
	if action_timeline != null:
		var bname: String = String(purchase_entry.get("species_name", ""))
		var bcat: String = livestock_system._normalize_livestock_category(String(purchase_entry.get("category", ""))) if livestock_system != null else "other"
		if not bname.is_empty():
			var bqty: int = livestock_system._get_entry_quantity(purchase_entry) if livestock_system != null else 1
			var cap_used: float = livestock_system.get_capacity_used()
			var cap_max: float = livestock_system.get_max_capacity()
			var cap_display: String = "%.0f/%.0f" % [cap_used, cap_max]
			var label: String = "购买入缸 " + bname
			if bcat == "fish":
				label += " 鱼 +%d" % bqty
			elif bcat == "coral":
				label += " 珊瑚 +%d" % bqty
			label += " RP-%d 容量 %s" % [int(price), cap_display]
			_timeline_log_player(label, ActionTimeline.COLOR_POSITIVE)
	print("[BUY] gs.buy about to return success")
	return {
		"success": true,
		"species_name": purchase_entry["species_name"],
		"price": price,
		"new_count": livestock_system.get_livestock_count(),
		"capacity_used": livestock_system.get_capacity_used(),
		"max_capacity": livestock_system.get_max_capacity(),
		"base_income_per_hour": float(livestock_system.get_debug_state().get("total_base_income_per_hour", 0.0)),
		"effective_income_per_hour": float(livestock_system.get_debug_state().get("total_effective_income_per_hour", 0.0)),
		"reef_points": reef_points,
	}


func release_owned_livestock(livestock_id: String) -> Dictionary:
	print("[M11 PROTOTYPE] release request livestock_id=", livestock_id)
	if livestock_system == null or economy_system == null:
		return {"success": false, "error": "system_unavailable", "livestock_id": livestock_id}
	var before_effective_income: float = float(livestock_system.get_debug_state().get("total_effective_income_per_hour", 0.0))
	var result: Dictionary = livestock_system.release_livestock(livestock_id)
	if not bool(result.get("success", false)):
		print("[M11 PROTOTYPE] release failed error=", result.get("error", "unknown"))
		return result
	_update_livestock_and_economy(0.0)
	_update_unlocks()
	var ls_debug: Dictionary = livestock_system.get_debug_state()
	result["effective_income_per_hour"] = float(ls_debug.get("total_effective_income_per_hour", 0.0))
	result["old_effective_income_per_hour"] = before_effective_income
	result["reef_value"] = float(economy_system.reef_value)
	reef_points = economy_system.get_reef_points()
	_pending_save_after_livestock_change = true
	_livestock_change_save_timer = 0.0
	if action_timeline != null:
		var rname: String = String(result.get("species_name", ""))
		if not rname.is_empty():
			var rcat: String = livestock_system._normalize_livestock_category(String(result.get("category", ""))) if livestock_system != null else "other"
			var released_cap: float = float(result.get("released_capacity", 0.0))
			var cap_used: float = float(result.get("capacity_used", livestock_system.get_capacity_used()))
			var cap_max: float = float(result.get("max_capacity", livestock_system.get_max_capacity()))
			var cap_display: String = "%.0f/%.0f" % [cap_used, cap_max]
			var rlabel: String = "放归 " + rname
			if rcat == "fish":
				rlabel += " 鱼 -1"
			elif rcat == "coral":
				rlabel += " 珊瑚 -1"
			rlabel += " 释放%.0f 容量 %s" % [released_cap, cap_display]
			_timeline_log_player(rlabel, ActionTimeline.COLOR_CAUTION)
	print("[M11 PROTOTYPE] release success name=", result.get("species_name", ""), " count=", result.get("new_count", 0))
	return result


func _try_load_game() -> void:
	if save_system == null:
		return
	if not save_system.has_save_file():
		save_loaded = false
		offline_summary = {}
		return
	var save_data: Dictionary = save_system.load_game()
	if save_data.is_empty():
		save_loaded = false
		return
	save_loaded = true
	_apply_save_state(save_data)
	var current_time: int = int(Time.get_unix_time_from_system())
	var last_time: int = save_system.get_last_save_timestamp()
	var offline_seconds: float = save_system.calculate_offline_seconds(current_time, last_time)
	if offline_seconds > 1.0:
		_apply_offline_progression(offline_seconds)


func _apply_save_state(save_data: Dictionary) -> void:
	var raw_economy: Variant = save_data.get("economy", {})
	if raw_economy is Dictionary and economy_system != null:
		economy_system.import_state(raw_economy)
	var raw_water: Variant = save_data.get("water_chemistry", {})
	if raw_water is Dictionary and water_chemistry_system != null:
		water_chemistry_system.import_state(raw_water)
	var raw_time: Variant = save_data.get("time", {})
	if raw_time is Dictionary and time_system != null:
		time_system.import_state(raw_time)
	var raw_unlocks: Variant = save_data.get("unlocks", {})
	if raw_unlocks is Dictionary and unlock_system != null:
		unlock_system.import_state(raw_unlocks)
		unlock_system.recalculate_from_reef_points(economy_system.total_reef_points_earned if economy_system != null else 0.0)
	var raw_livestock: Variant = save_data.get("livestock", {})
	if raw_livestock is Dictionary and livestock_system != null:
		if raw_livestock.has("owned_livestock"):
			livestock_system.import_state(raw_livestock)
	reef_points = economy_system.reef_points if economy_system != null else 0.0


func _apply_offline_progression(offline_seconds: float) -> void:
	var offline_game_seconds: float = offline_seconds * time_system.debug_time_scale
	var offline_game_hours: float = offline_game_seconds / 3600.0
	var income_rate: float = economy_system.income_rate_per_game_hour if economy_system != null else 0.0
	var offline_income: float = income_rate * offline_game_hours
	if economy_system != null:
		economy_system.apply_offline_income(offline_income)
	var effects_summary: Dictionary = equipment_system.get_equipment_effects_summary() if equipment_system != null else {}
	_update_runtime_operation_state(offline_game_seconds)
	_apply_device_effects_to_equipment_summary(effects_summary)
	if water_chemistry_system != null:
		water_chemistry_system.apply_offline_drift(offline_game_hours, effects_summary)
	if time_system != null:
		time_system.apply_offline_time(offline_game_seconds / time_system.debug_time_scale)
	reef_points = economy_system.reef_points if economy_system != null else 0.0
	if unlock_system != null and economy_system != null:
		unlock_system.recalculate_from_reef_points(economy_system.total_reef_points_earned)
	offline_summary = {
		"offline_seconds": offline_seconds,
		"offline_game_hours": offline_game_hours,
		"offline_income": offline_income,
		"applied": true,
	}




func _format_timeline_time() -> String:
	if time_system == null:
		return "D1 00:00"
	var elapsed: int = int(time_system.get_debug_state().get("elapsed_game_minutes", 0))
	var day: int = int(floor(float(elapsed) / 1440.0)) + 1
	var mins: int = elapsed % 1440
	var h: int = int(floor(float(mins) / 60.0))
	var m: int = mins % 60
	return "D%d %02d:%02d" % [day, h, m]


func _timeline_log_player(text: String, color: Color = ActionTimeline.COLOR_PLAYER) -> void:
	if action_timeline == null:
		return
	var time_text: String = _format_timeline_time()
	action_timeline.add_player_action(time_text + " " + text, color)


func _timeline_log_system(text: String, color: Color = ActionTimeline.COLOR_CAUTION) -> void:
	if action_timeline == null:
		return
	var time_text: String = _format_timeline_time()
	action_timeline.add_system_event(time_text + " " + text, color)


func _format_maintenance_timeline_text(action_id: String, _result: Dictionary) -> Dictionary:
	match action_id:
		"water_change_10":
			return {"text": "换水完成 NO3 PO4下降", "color": ActionTimeline.COLOR_POSITIVE}
		"clean_filter":
			return {"text": "清理过滤完成 效率恢复", "color": ActionTimeline.COLOR_POSITIVE}
		"dose_buffer":
			return {"text": "补KH KH\u2191 pH稳", "color": ActionTimeline.COLOR_POSITIVE}
		"top_off":
			var sal_delta: float = float(_result.get("delta_salinity", 0.0))
			if abs(sal_delta) > 0.001:
				return {"text": "补水 盐度%+.1f 回稳" % sal_delta, "color": ActionTimeline.COLOR_POSITIVE}
			return {"text": "补水 盐度回稳", "color": ActionTimeline.COLOR_POSITIVE}
		"travel_prep":
			return {"text": "出门 托管维护", "color": ActionTimeline.COLOR_POSITIVE}
		_:
			return {"text": String(_result.get("label", action_id)), "color": ActionTimeline.COLOR_PLAYER}


func _format_device_timeline_text(device_id: String, enabled: bool) -> Dictionary:
	var display: String = _get_device_display_name(device_id)
	var state: String = "ON" if enabled else "OFF"
	match device_id:
		"return_pump":
			if enabled:
				return {"text": "循环泵开启 水流恢复", "color": ActionTimeline.COLOR_POSITIVE}
			else:
				return {"text": "循环泵关闭 水流过滤减弱", "color": ActionTimeline.COLOR_CAUTION}
		"wave_pump":
			if enabled:
				return {"text": "造浪泵开启", "color": ActionTimeline.COLOR_POSITIVE}
			else:
				return {"text": "造浪泵关闭 舒适度降低", "color": ActionTimeline.COLOR_CAUTION}
		"main_light":
			if enabled:
				return {"text": "主灯开启", "color": ActionTimeline.COLOR_POSITIVE}
			else:
				return {"text": "主灯关闭 收益降低", "color": ActionTimeline.COLOR_CAUTION}
		_:
			return {"text": "%s%s" % [display, state], "color": ActionTimeline.COLOR_PLAYER}


func _check_timeline_system_events() -> void:
	if action_timeline == null:
		return
	var wcs: WaterChemistrySystem = water_chemistry_system
	var ls: LivestockSystem = livestock_system
	if wcs == null or ls == null:
		return
	var water_status: String = String(wcs.get_debug_state().get("water_status", "OK"))
	var comfort_score: float = float(ls.get_debug_state().get("comfort_score", 100.0))
	var revenue_mult: float = float(ls.get_debug_state().get("revenue_multiplier", 1.0))
	var device_effects: Dictionary = get_device_effect_summary()
	var filter_pct: float = float(device_effects.get("filter_efficiency_percent", 100.0))
	var flow_pct: float = float(device_effects.get("water_flow_percent", 100.0))
	var no3: float = float(wcs.get_debug_state().get("nitrate", 0.0))
	var po4: float = float(wcs.get_debug_state().get("phosphate", 0.0))

	# Water quality tier change
	if action_timeline.should_log_water_status(water_status):
		if water_status == "CRITICAL":
			_timeline_log_system("水质恶化 危险", ActionTimeline.COLOR_CRITICAL)
			if maintenance_relief_remaining_game_seconds <= 0.0 and action_timeline.should_log_neglect():
				_timeline_log_system("长期未维护 水质恶化", ActionTimeline.COLOR_CRITICAL)
		elif water_status == "WARNING":
			_timeline_log_system("水质下降 警告", ActionTimeline.COLOR_CAUTION)
		elif water_status == "OK":
			_timeline_log_system("水质恢复 正常", ActionTimeline.COLOR_POSITIVE)

	# Comfort tier change
	var comfort_tier: String
	if comfort_score >= 90.0:
		comfort_tier = "优秀"
	elif comfort_score >= 75.0:
		comfort_tier = "良好"
	elif comfort_score >= 60.0:
		comfort_tier = "中等"
	elif comfort_score >= 40.0:
		comfort_tier = "偏低"
	else:
		comfort_tier = "危险"
	if action_timeline.should_log_comfort_tier(comfort_tier):
		var comfort_color: Color = ActionTimeline.COLOR_POSITIVE if comfort_score >= 75.0 else (ActionTimeline.COLOR_CAUTION if comfort_score >= 40.0 else ActionTimeline.COLOR_CRITICAL)
		_timeline_log_system("舒适度 " + comfort_tier, comfort_color)

	# Revenue multiplier tier change
	var revenue_tier: String
	if revenue_mult >= 1.10:
		revenue_tier = "max"
	elif revenue_mult >= 1.00:
		revenue_tier = "normal"
	elif revenue_mult >= 0.90:
		revenue_tier = "reduced"
	elif revenue_mult >= 0.75:
		revenue_tier = "low"
	else:
		revenue_tier = "min"
	if action_timeline.should_log_revenue_tier(revenue_tier):
		var revenue_color: Color = ActionTimeline.COLOR_POSITIVE if revenue_mult >= 1.00 else (ActionTimeline.COLOR_CAUTION if revenue_mult >= 0.75 else ActionTimeline.COLOR_CRITICAL)
		_timeline_log_system("收益倍率 %.2fx" % revenue_mult, revenue_color)

	# Filter significant drop
	var filter_tier: String
	if filter_pct >= 80.0:
		filter_tier = "ok"
	elif filter_pct >= 55.0:
		filter_tier = "low"
	else:
		filter_tier = "critical"
	if action_timeline.should_log_filter_tier(filter_tier):
		if filter_tier == "critical":
			_timeline_log_system("过滤效率低 %.0f%% 需清理" % filter_pct, ActionTimeline.COLOR_CRITICAL)
		elif filter_tier == "low":
			_timeline_log_system("过滤效率下降 %.0f%%" % filter_pct, ActionTimeline.COLOR_CAUTION)

	# Flow zero
	var flow_zero: bool = flow_pct <= 0.0
	if action_timeline.should_log_flow_zero(flow_zero):
		if flow_zero:
			_timeline_log_system("水流中断 循环停止", ActionTimeline.COLOR_CRITICAL)
		else:
			_timeline_log_system("水流恢复 循环正常", ActionTimeline.COLOR_POSITIVE)

	# NO3 unsafe
	var no3_unsafe: bool = no3 > 20.0
	if action_timeline.should_log_no3_unsafe(no3_unsafe):
		if no3_unsafe:
			_timeline_log_system("NO3偏高 %.1f 超出安全范围" % no3, ActionTimeline.COLOR_CAUTION)
		else:
			_timeline_log_system("NO3恢复安全范围", ActionTimeline.COLOR_POSITIVE)

	# PO4 unsafe
	var po4_unsafe: bool = po4 > 0.20
	if action_timeline.should_log_po4_unsafe(po4_unsafe):
		if po4_unsafe:
			_timeline_log_system("PO4偏高 %.3f 超出安全范围" % po4, ActionTimeline.COLOR_CAUTION)
		else:
			_timeline_log_system("PO4恢复安全范围", ActionTimeline.COLOR_POSITIVE)



func seed_timeline_for_test() -> void:
	if action_timeline == null:
		return
	var test_events: Array[Dictionary] = [
		{"text": "D1 08:00 系统启动", "color": ActionTimeline.COLOR_PLAYER},
		{"text": "D1 08:05 水泵ON 水流\u2191", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 08:10 造浪ON", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 08:15 主灯ON", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 09:20 喂鱼粮 NO3+0.55 PO4+0.010", "color": ActionTimeline.COLOR_PLAYER},
		{"text": "D1 12:00 换水 降NO3/PO4", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 14:30 清滤 过滤\u2191", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 16:00 补KH KH\u2191 pH稳", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D1 18:30 喂珊瑚粮 NO3+0.22 PO4+0.022", "color": ActionTimeline.COLOR_PLAYER},
		{"text": "D2 08:00 水质下降 警告", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D2 08:05 NO3偏高 25.0 超出安全范围", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D2 09:00 水泵OFF 水流\u2193 过滤\u2193", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D2 09:05 水流中断 循环停止", "color": ActionTimeline.COLOR_CRITICAL},
		{"text": "D2 10:00 水质恶化 危险", "color": ActionTimeline.COLOR_CRITICAL},
		{"text": "D2 10:01 未维护 水质恶化", "color": ActionTimeline.COLOR_CRITICAL},
		{"text": "D2 10:30 舒适度 偏低", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D2 11:00 收益倍率 0.75x", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D2 12:00 水泵ON 水流\u2191", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 12:05 水流恢复", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 13:00 清滤 过滤\u2191", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 14:00 补水 盐度-0.2 回稳", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 15:00 换水 降NO3/PO4", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 16:00 NO3恢复安全范围", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 17:00 水质恢复 正常", "color": ActionTimeline.COLOR_POSITIVE},
		{"text": "D2 18:00 PO4偏高 0.250 超出安全范围", "color": ActionTimeline.COLOR_CAUTION},
		{"text": "D3 08:00 喂鱼粮 NO3+0.60 PO4+0.012", "color": ActionTimeline.COLOR_PLAYER},
	]
	for ev in test_events:
		action_timeline.entries.append(ev)
	while action_timeline.entries.size() > ActionTimeline.MAX_ENTRIES:
		action_timeline.entries.pop_front()

func get_timeline_entries(count: int = 200) -> Array:
	if action_timeline == null:
		return []
	return action_timeline.get_recent(count)



func set_light_intensity(value: int) -> void:
	light_intensity = clamp(value, 0, 100)
	if action_timeline != null and light_intensity != _last_logged_light_intensity:
		_last_logged_light_intensity = light_intensity
		var time_text: String = _format_timeline_time()
		action_timeline.add_player_action(time_text + " 光照 " + str(light_intensity), ActionTimeline.COLOR_PLAYER)


func set_light_color_temp(value: int) -> void:
	light_color_temp = clamp(value, 0, 100)
	if action_timeline != null and light_color_temp != _last_logged_light_color_temp:
		_last_logged_light_color_temp = light_color_temp
		var time_text: String = _format_timeline_time()
		action_timeline.add_player_action(time_text + " 色温 " + str(light_color_temp), ActionTimeline.COLOR_PLAYER)


func get_light_state() -> Dictionary:
	return {
		"light_intensity": light_intensity,
		"light_color_temp": light_color_temp,
	}

func _perform_autosave() -> void:
	if save_system == null:
		return
	if _save_in_progress:
		print("[SAVE] skipped: already in progress")
		return
	_save_in_progress = true
	print("[SAVE] perform_autosave start")
	var economy_state: Dictionary = economy_system.export_state() if economy_system != null else {}
	print("[SAVE] economy export ok")
	var water_state: Dictionary = water_chemistry_system.export_state() if water_chemistry_system != null else {}
	print("[SAVE] water export ok")
	var time_state: Dictionary = time_system.export_state() if time_system != null else {}
	print("[SAVE] time export ok")
	var unlock_state: Dictionary = unlock_system.export_state() if unlock_system != null else {}
	print("[SAVE] unlock export ok")
	var livestock_state: Dictionary = livestock_system.export_state() if livestock_system != null else {}
	var ls_count: int = 0
	var raw_ls: Variant = livestock_state.get("owned_livestock", [])
	if raw_ls is Array:
		ls_count = raw_ls.size()
	print("[SAVE] livestock export ok count=", ls_count)
	var equipment_state: Dictionary = {
		"tier1_installed": true,
		"tier2_preview": unlock_system.unlocked_states.get("tier2_equipment_preview", false) if unlock_system != null else false,
		"tier3_locked": true,
	}
	var save_dict: Dictionary = {
		"economy": economy_state,
		"water_chemistry": water_state,
		"time": time_state,
		"unlocks": unlock_state,
		"livestock": livestock_state,
		"equipment": equipment_state,
	}
	print("[SAVE] calling save_game with keys=", save_dict.keys())
	var ok: bool = save_system.save_game(save_dict)
	print("[SAVE] save_game returned=", ok)
	_save_in_progress = false
