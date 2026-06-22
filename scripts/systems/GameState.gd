class_name GameState
extends RefCounted

var initialized: bool = false
var milestone: String = "M8 equipment warehouse preview and full delta display"
var reef_points: float = 0.0
var unlocked_tier: int = 1
var time_system: TimeSystem = null
var economy_system: EconomySystem = null
var equipment_system: EquipmentSystem = null
var equipment_placement_system: EquipmentPlacementSystem = null
var water_chemistry_system: WaterChemistrySystem = null
var livestock_system: LivestockSystem = null
var unlock_system: UnlockSystem = null
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

	_recalculate_debug_scores()
	_update_livestock_and_economy(0.0)
	_update_unlocks()
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
	var current_reef_value: float = livestock_system.calculate_reef_value(water_state, carrying_capacity_score)
	var income_rate: float = livestock_system.calculate_income_rate(water_state, carrying_capacity_score)
	var current_health: float = float(livestock_system.get_debug_state().get("health_modifier", 1.0))
	var current_water_income: float = float(livestock_system.get_debug_state().get("water_income_modifier", 1.0))
	economy_system.reef_value = current_reef_value
	economy_system.update_income(delta_seconds, income_rate)
	reef_points = economy_system.get_reef_points()
	delta_reef_value = current_reef_value - _prev_reef_value
	delta_income_rate = income_rate - _prev_income_rate
	delta_health_modifier = current_health - _prev_health_modifier
	delta_water_income_modifier = current_water_income - _prev_water_income_modifier
	_prev_reef_value = current_reef_value
	_prev_income_rate = income_rate
	_prev_health_modifier = current_health
	_prev_water_income_modifier = current_water_income


func _update_unlocks() -> void:
	if unlock_system == null or economy_system == null:
		return
	unlock_system.update_unlocks(economy_system.get_debug_state())
