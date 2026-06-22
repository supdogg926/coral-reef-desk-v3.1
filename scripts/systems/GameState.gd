class_name GameState
extends RefCounted

var initialized: bool = false
var milestone: String = "M10 livestock shop tank capacity core loop"
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
const AUTOSAVE_INTERVAL: float = 10.0
var save_loaded: bool = false
var offline_summary: Dictionary = {}


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
	water_chemistry_system.simulate_tick(simulation_delta_seconds, effects_summary)
	_recalculate_debug_scores()
	_update_livestock_and_economy(simulation_delta_seconds)
	_update_unlocks()
	_autosave_timer += delta_seconds
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_perform_autosave()
		_autosave_timer = 0.0


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
	return water_debug


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
	stability_score = 50.0 + float(effects_summary.get("stability_bonus", 0.0))
	carrying_capacity_score = 10.0 + float(effects_summary.get("carrying_capacity_bonus", 0.0))
	maintenance_load = float(effects_summary.get("maintenance_load", 0.0))


func _update_livestock_and_economy(delta_seconds: float) -> void:
	if livestock_system == null or economy_system == null or water_chemistry_system == null:
		return
	var water_state: Dictionary = water_chemistry_system.get_debug_state()
	var equipment_mult: float = 1.0 + (stability_score - 50.0) * 0.004
	var income_rate: float = livestock_system.calculate_income_rate(water_state, equipment_mult)
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
	if livestock_system == null or economy_system == null:
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
	return {
		"success": true,
		"species_name": purchase_entry["species_name"],
		"price": price,
		"new_count": livestock_system.get_livestock_count(),
		"capacity_used": livestock_system.get_capacity_used(),
	}


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
	var economy_state: Dictionary = economy_system.export_state() if economy_system != null else {}
	var water_state: Dictionary = water_chemistry_system.export_state() if water_chemistry_system != null else {}
	var time_state: Dictionary = time_system.export_state() if time_system != null else {}
	var unlock_state: Dictionary = unlock_system.export_state() if unlock_system != null else {}
	var livestock_state: Dictionary = livestock_system.export_state() if livestock_system != null else {}
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
	save_system.save_game(save_dict)
