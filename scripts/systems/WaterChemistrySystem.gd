class_name WaterChemistrySystem
extends RefCounted

const TARGET_TEMPERATURE: float = 25.1
const TARGET_SALINITY: float = 35.0
const TARGET_PH: float = 8.20
const TARGET_NITRATE: float = 2.6
const TARGET_PHOSPHATE: float = 0.03
const TARGET_ALKALINITY: float = 8.3
const TARGET_CALCIUM: float = 430.0

var initialized: bool = false
var temperature: float = TARGET_TEMPERATURE
var salinity: float = TARGET_SALINITY
var ph: float = TARGET_PH
var nitrate: float = TARGET_NITRATE
var phosphate: float = TARGET_PHOSPHATE
var alkalinity: float = TARGET_ALKALINITY
var calcium: float = TARGET_CALCIUM
var system_stability: float = 50.0
var water_quality_score: float = 100.0
var water_status: String = "OK"
var parameter_status: Dictionary = {}
var chemistry_tick_count: int = 0
var accumulated_simulation_seconds: float = 0.0
var last_chemistry_update_time: float = 0.0
var last_parameter_delta_summary: String = "NO3 +0.00 / PO4 +0.000 / pH +0.00"
var delta_temperature: float = 0.0
var delta_salinity: float = 0.0
var delta_ph: float = 0.0
var delta_nitrate: float = 0.0
var delta_phosphate: float = 0.0
var delta_alkalinity: float = 0.0
var delta_calcium: float = 0.0
var delta_water_quality_score: float = 0.0
var _prev_water_quality_score: float = 100.0


func initialize() -> void:
	reset_to_initial_values()
	initialized = true


func reset_to_initial_values() -> void:
	temperature = TARGET_TEMPERATURE
	salinity = TARGET_SALINITY
	ph = TARGET_PH
	nitrate = TARGET_NITRATE
	phosphate = TARGET_PHOSPHATE
	alkalinity = TARGET_ALKALINITY
	calcium = TARGET_CALCIUM
	system_stability = 50.0
	chemistry_tick_count = 0
	accumulated_simulation_seconds = 0.0
	last_chemistry_update_time = 0.0
	last_parameter_delta_summary = "NO3 +0.00 / PO4 +0.000 / pH +0.00"
	delta_temperature = 0.0
	delta_salinity = 0.0
	delta_ph = 0.0
	delta_nitrate = 0.0
	delta_phosphate = 0.0
	delta_alkalinity = 0.0
	delta_calcium = 0.0
	delta_water_quality_score = 0.0
	_prev_water_quality_score = 100.0
	parameter_status = calculate_parameter_status()
	water_quality_score = calculate_water_quality_score()
	water_status = get_water_status()


func simulate_tick(delta_seconds: float, equipment_effects_summary: Dictionary) -> void:
	var before_temperature: float = temperature
	var before_salinity: float = salinity
	var before_ph: float = ph
	var before_nitrate: float = nitrate
	var before_phosphate: float = phosphate
	var before_alkalinity: float = alkalinity
	var before_calcium: float = calcium
	var before_quality: float = water_quality_score
	apply_natural_drift(delta_seconds)
	apply_equipment_stabilization(equipment_effects_summary, delta_seconds)
	_clamp_debug_ranges()
	chemistry_tick_count += 1
	accumulated_simulation_seconds += max(delta_seconds, 0.0)
	last_chemistry_update_time = accumulated_simulation_seconds
	parameter_status = calculate_parameter_status()
	water_quality_score = calculate_water_quality_score()
	water_status = get_water_status()
	delta_temperature = temperature - before_temperature
	delta_salinity = salinity - before_salinity
	delta_ph = ph - before_ph
	delta_nitrate = nitrate - before_nitrate
	delta_phosphate = phosphate - before_phosphate
	delta_alkalinity = alkalinity - before_alkalinity
	delta_calcium = calcium - before_calcium
	delta_water_quality_score = water_quality_score - before_quality
	_prev_water_quality_score = water_quality_score
	last_parameter_delta_summary = _format_delta_summary(delta_nitrate, delta_phosphate, delta_ph)


func apply_natural_drift(delta_seconds: float) -> void:
	var days: float = max(delta_seconds, 0.0) / 86400.0
	temperature += 0.08 * days
	salinity += 0.015 * days
	ph -= 0.010 * days
	nitrate += 0.22 * days
	phosphate += 0.003 * days
	alkalinity -= 0.030 * days
	calcium -= 0.40 * days


func apply_equipment_stabilization(equipment_effects_summary: Dictionary, delta_seconds: float) -> void:
	var days: float = max(delta_seconds, 0.0) / 86400.0
	var stability_bonus: float = float(equipment_effects_summary.get("stability_bonus", 0.0))
	var nutrient_export: float = float(equipment_effects_summary.get("nutrient_export", 0.0))
	var bio_filtration: float = float(equipment_effects_summary.get("bio_filtration", 0.0))
	var temperature_control: float = float(equipment_effects_summary.get("temperature_control", 0.0))
	var flow: float = float(equipment_effects_summary.get("flow", 0.0))
	var oxygenation: float = float(equipment_effects_summary.get("oxygenation", 0.0))
	var ph_support: float = min((flow + oxygenation + nutrient_export) * 0.002, 0.04)

	system_stability = 50.0 + stability_bonus
	nitrate -= (nutrient_export * 0.030 + bio_filtration * 0.020) * days
	phosphate -= nutrient_export * 0.0007 * days
	ph += ph_support * days
	alkalinity += min(stability_bonus * 0.001, 0.04) * days
	calcium += min(stability_bonus * 0.010, 0.30) * days
	temperature = _move_toward_float(temperature, TARGET_TEMPERATURE, temperature_control * 0.12 * days)


func calculate_parameter_status() -> Dictionary:
	return {
		"temperature": _range_status(temperature, 24.0, 26.5),
		"salinity": _range_status(salinity, 34.0, 36.0),
		"ph": _range_status(ph, 7.9, 8.4),
		"nitrate": _range_status(nitrate, 0.0, 10.0),
		"phosphate": _range_status(phosphate, 0.0, 0.10),
		"alkalinity": _range_status(alkalinity, 7.0, 10.0),
		"calcium": _range_status(calcium, 380.0, 460.0),
	}


func calculate_water_quality_score() -> float:
	var score: float = 100.0
	score -= _range_penalty(temperature, 24.0, 26.5, 14.0)
	score -= _range_penalty(salinity, 34.0, 36.0, 14.0)
	score -= _range_penalty(ph, 7.9, 8.4, 16.0)
	score -= _range_penalty(nitrate, 0.0, 10.0, 14.0)
	score -= _range_penalty(phosphate, 0.0, 0.10, 14.0)
	score -= _range_penalty(alkalinity, 7.0, 10.0, 14.0)
	score -= _range_penalty(calcium, 380.0, 460.0, 14.0)
	score += clamp((system_stability - 50.0) * 0.10, 0.0, 5.0)
	return clamp(score, 0.0, 100.0)


func get_water_status() -> String:
	if water_quality_score >= 85.0:
		return "OK"
	if water_quality_score >= 60.0:
		return "WARNING"
	return "CRITICAL"


func get_debug_state() -> Dictionary:
	return {
		"system": "WaterChemistrySystem",
		"initialized": initialized,
		"temperature": temperature,
		"salinity": salinity,
		"ph": ph,
		"nitrate": nitrate,
		"phosphate": phosphate,
		"alkalinity": alkalinity,
		"calcium": calcium,
		"system_stability": system_stability,
		"water_quality_score": water_quality_score,
		"water_status": water_status,
		"chemistry_tick_count": chemistry_tick_count,
		"last_chemistry_update_time": last_chemistry_update_time,
		"last_parameter_delta_summary": last_parameter_delta_summary,
		"delta_temperature": delta_temperature,
		"delta_salinity": delta_salinity,
		"delta_ph": delta_ph,
		"delta_nitrate": delta_nitrate,
		"delta_phosphate": delta_phosphate,
		"delta_alkalinity": delta_alkalinity,
		"delta_calcium": delta_calcium,
		"delta_water_quality_score": delta_water_quality_score,
		"parameter_status": parameter_status.duplicate(),
	}


func _range_status(value: float, low: float, high: float) -> String:
	if value >= low and value <= high:
		return "OK"
	var warning_low: float = low - abs(high - low) * 0.25
	var warning_high: float = high + abs(high - low) * 0.25
	if value >= warning_low and value <= warning_high:
		return "WARNING"
	return "CRITICAL"


func _range_penalty(value: float, low: float, high: float, max_penalty: float) -> float:
	if value >= low and value <= high:
		return 0.0
	var distance: float = min(abs(value - low), abs(value - high))
	var width: float = max(high - low, 0.001)
	return clamp((distance / width) * max_penalty, 0.0, max_penalty)


func _move_toward_float(value: float, target: float, step: float) -> float:
	if value < target:
		return min(value + step, target)
	return max(value - step, target)


func _clamp_debug_ranges() -> void:
	temperature = clamp(temperature, 18.0, 32.0)
	salinity = clamp(salinity, 30.0, 40.0)
	ph = clamp(ph, 7.4, 8.8)
	nitrate = clamp(nitrate, 0.0, 80.0)
	phosphate = clamp(phosphate, 0.0, 1.0)
	alkalinity = clamp(alkalinity, 5.0, 14.0)
	calcium = clamp(calcium, 300.0, 560.0)


func export_state() -> Dictionary:
	return {
		"temperature": temperature,
		"salinity": salinity,
		"ph": ph,
		"nitrate": nitrate,
		"phosphate": phosphate,
		"alkalinity": alkalinity,
		"calcium": calcium,
		"water_quality_score": water_quality_score,
		"accumulated_simulation_seconds": accumulated_simulation_seconds,
		"chemistry_tick_count": chemistry_tick_count,
	}


func import_state(state: Dictionary) -> void:
	temperature = float(state.get("temperature", TARGET_TEMPERATURE))
	salinity = float(state.get("salinity", TARGET_SALINITY))
	ph = float(state.get("ph", TARGET_PH))
	nitrate = float(state.get("nitrate", TARGET_NITRATE))
	phosphate = float(state.get("phosphate", TARGET_PHOSPHATE))
	alkalinity = float(state.get("alkalinity", TARGET_ALKALINITY))
	calcium = float(state.get("calcium", TARGET_CALCIUM))
	water_quality_score = float(state.get("water_quality_score", 100.0))
	accumulated_simulation_seconds = float(state.get("accumulated_simulation_seconds", 0.0))
	chemistry_tick_count = int(state.get("chemistry_tick_count", 0))
	_clamp_debug_ranges()
	parameter_status = calculate_parameter_status()
	water_quality_score = calculate_water_quality_score()
	water_status = get_water_status()


func apply_offline_drift(offline_game_hours: float, equipment_effects_summary: Dictionary) -> void:
	var days: float = max(offline_game_hours, 0.0) / 24.0
	nitrate += 0.04 * days
	phosphate += 0.0008 * days
	salinity += 0.005 * days
	ph -= 0.002 * days
	alkalinity -= 0.005 * days
	calcium -= 0.08 * days
	var temperature_control: float = float(equipment_effects_summary.get("temperature_control", 0.0))
	if temperature_control > 0.0:
		temperature = _move_toward_float(temperature, TARGET_TEMPERATURE, temperature_control * 0.06 * days)
	else:
		temperature += 0.02 * days
	_clamp_debug_ranges()
	parameter_status = calculate_parameter_status()
	water_quality_score = calculate_water_quality_score()
	water_status = get_water_status()


func _format_delta_summary(delta_nitrate: float, delta_phosphate: float, delta_ph: float) -> String:
	return "NO3 %+0.3f / PO4 %+0.4f / pH %+0.3f" % [
		delta_nitrate,
		delta_phosphate,
		delta_ph,
	]
