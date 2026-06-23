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
var last_maintenance_runtime_summary: String = "未维护"
var device_states: Dictionary = {
	"return_pump": true,
	"wave_pump": true,
	"main_light": true,
	"reserve": false,
}
var last_device_runtime_summary: String = "设备：默认运行"
const MAINTENANCE_ACTION_RULES: Dictionary = {
	"water_change_10": {"cost": 20.0, "cooldown_sec": 10.0, "risk_message": "无"},
	"clean_filter": {"cost": 15.0, "cooldown_sec": 8.0, "risk_message": "无"},
	"dose_buffer": {"cost": 12.0, "cooldown_sec": 12.0, "risk_message": "KH偏高请谨慎"},
	"top_off": {"cost": 8.0, "cooldown_sec": 6.0, "risk_message": "无"},
	"travel_prep": {"cost": 60.0, "cooldown_sec": 30.0, "risk_message": "无"},
}
const DEVICE_DEFINITIONS: Dictionary = {
	"return_pump": {"display_name": "水泵", "default_enabled": true},
	"wave_pump": {"display_name": "造浪", "default_enabled": true},
	"main_light": {"display_name": "主灯", "default_enabled": true},
	"reserve": {"display_name": "预留", "default_enabled": false},
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
	var effects_summary: Dictionary = equipment_system.get_equipment_effects_summary()
	_apply_device_effects_to_equipment_summary(effects_summary)
	water_chemistry_system.simulate_tick(simulation_delta_seconds, effects_summary)
	_recalculate_debug_scores()
	_update_livestock_and_economy(simulation_delta_seconds)
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
	var display_name: String = _get_device_display_name(device_id)
	var state_text: String = "ON" if enabled else "OFF"
	var risk_message: String = String(effect_summary.get("risk_message", "无"))
	var summary: String = "%s：%s｜%s" % [display_name, state_text, String(effect_summary.get("summary", "设备影响：无"))]
	if not risk_message.is_empty() and risk_message != "无":
		summary += "｜风险：" + risk_message
	last_device_runtime_summary = summary
	var result: Dictionary = _build_device_result(device_id, true, enabled, summary, "ok")
	result["risk_message"] = risk_message
	result["income_multiplier"] = float(effect_summary.get("income_multiplier", 1.0))
	result["income_effect"] = float(effect_summary.get("income_effect", 0.0))
	result["water_quality_effect"] = float(effect_summary.get("water_quality_effect", 0.0))
	result["stability_effect"] = float(effect_summary.get("stability_effect", 0.0))
	result["device_nitrate_drift_per_day"] = float(effect_summary.get("device_nitrate_drift_per_day", 0.0))
	result["device_phosphate_drift_per_day"] = float(effect_summary.get("device_phosphate_drift_per_day", 0.0))
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
	var income_multiplier: float = 1.0
	var stability_effect: float = 0.0
	var water_quality_effect: float = 0.0
	var device_water_quality_penalty: float = 0.0
	var nitrate_drift_per_day: float = 0.0
	var phosphate_drift_per_day: float = 0.0
	var risks: Array[String] = []

	if not bool(device_states.get("return_pump", true)):
		income_multiplier *= 0.85
		stability_effect -= 8.0
		water_quality_effect -= 10.0
		device_water_quality_penalty += 10.0
		nitrate_drift_per_day += 0.35
		phosphate_drift_per_day += 0.006
		risks.append("水泵关闭，过滤循环不足")
	if not bool(device_states.get("wave_pump", true)):
		income_multiplier *= 0.90
		stability_effect -= 5.0
		water_quality_effect -= 3.0
		device_water_quality_penalty += 3.0
		risks.append("造浪不足，生物舒适度下降")
	if not bool(device_states.get("main_light", true)):
		income_multiplier *= 0.65
		stability_effect -= 2.0
		risks.append("主灯关闭，光照不足，收益降低")

	var risk_message: String = "无"
	if not risks.is_empty():
		risk_message = _join_device_risks(risks)
	var clamped_income_multiplier: float = clamp(income_multiplier, 0.10, 1.0)
	return {
		"income_multiplier": clamp(income_multiplier, 0.10, 1.0),
		"income_effect": clamped_income_multiplier - 1.0,
		"stability_effect": stability_effect,
		"water_quality_effect": water_quality_effect,
		"device_water_quality_penalty": device_water_quality_penalty,
		"device_nitrate_drift_per_day": nitrate_drift_per_day,
		"device_phosphate_drift_per_day": phosphate_drift_per_day,
		"risk_message": risk_message,
		"risk_messages": risks.duplicate(),
		"summary": _format_device_effect_summary(
			clamped_income_multiplier,
			stability_effect,
			water_quality_effect,
			nitrate_drift_per_day,
			phosphate_drift_per_day
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
	_update_unlocks()
	reef_points = economy_system.get_reef_points() if economy_system != null else reef_points
	_pending_save_after_maintenance = true
	_maintenance_save_timer = 0.0
	print("[M11 PROTOTYPE] water maintenance success label=", result.get("label", ""), " delta=", result.get("delta_summary", ""))
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
	}


func _apply_device_effects_to_equipment_summary(effects_summary: Dictionary) -> void:
	var device_effects: Dictionary = get_device_effect_summary()
	effects_summary["device_water_quality_penalty"] = float(device_effects.get("device_water_quality_penalty", 0.0))
	effects_summary["device_nitrate_drift_per_day"] = float(device_effects.get("device_nitrate_drift_per_day", 0.0))
	effects_summary["device_phosphate_drift_per_day"] = float(device_effects.get("device_phosphate_drift_per_day", 0.0))


func _join_device_risks(risks: Array[String]) -> String:
	var text: String = ""
	for risk in risks:
		if not text.is_empty():
			text += "；"
		text += risk
	return text


func _format_device_effect_summary(income_multiplier: float, stability_effect: float, water_quality_effect: float, nitrate_drift_per_day: float, phosphate_drift_per_day: float) -> String:
	return "收益倍率 x%.2f｜稳定分 %+.0f｜水质评分 %+.0f｜NO3 %+.2f/日｜PO4 %+.3f/日" % [
		income_multiplier,
		stability_effect,
		water_quality_effect,
		nitrate_drift_per_day,
		phosphate_drift_per_day,
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
	return unlock_system.get_debug_state()


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
	stability_score = clamp(50.0 + float(effects_summary.get("stability_bonus", 0.0)) + float(device_effects.get("stability_effect", 0.0)), 0.0, 100.0)
	carrying_capacity_score = 10.0 + float(effects_summary.get("carrying_capacity_bonus", 0.0))
	maintenance_load = float(effects_summary.get("maintenance_load", 0.0))


func _update_livestock_and_economy(delta_seconds: float) -> void:
	if livestock_system == null or economy_system == null or water_chemistry_system == null:
		return
	var water_state: Dictionary = water_chemistry_system.get_debug_state()
	var equipment_mult: float = 1.0 + (stability_score - 50.0) * 0.004
	var device_effects: Dictionary = get_device_effect_summary()
	var device_income_mult: float = float(device_effects.get("income_multiplier", 1.0))
	var income_rate: float = livestock_system.calculate_income_rate(water_state, equipment_mult) * device_income_mult
	var current_reef_value: float = livestock_system.calculate_reef_value(water_state)
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
