class_name EconomySystem
extends RefCounted

var initialized: bool = false
var reef_points: float = 0.0
var total_reef_points_earned: float = 0.0
var reef_value: float = 0.0
var income_rate_per_game_hour: float = 0.0
var delta_reef_points: float = 0.0
var last_economy_tick_at: float = 0.0
const OFFLINE_WAVE_CAP_SECONDS: float = 28800.0
const BASE_WAVE_RATE_PER_SECOND: float = 0.01


func initialize() -> void:
	reef_points = 0.0
	total_reef_points_earned = 0.0
	reef_value = 0.0
	income_rate_per_game_hour = 0.0
	delta_reef_points = 0.0
	initialized = true


func update_income(delta_seconds: float, income_rate: float) -> void:
	income_rate_per_game_hour = max(income_rate, 0.0)
	var earned: float = income_rate_per_game_hour * max(delta_seconds, 0.0) / 3600.0
	delta_reef_points = earned
	add_reef_points(earned)


func add_reef_points(amount: float) -> void:
	var safe_amount: float = max(amount, 0.0)
	reef_points += safe_amount
	total_reef_points_earned += safe_amount


func spend_reef_points(amount: float) -> bool:
	var safe_amount: float = max(amount, 0.0)
	if reef_points < safe_amount:
		return false
	reef_points -= safe_amount
	return true


func get_reef_points() -> float:
	return reef_points


func get_waves_balance() -> float:
	return reef_points


func add_waves(amount: float, reason: String = "") -> void:
	add_reef_points(amount)


func spend_waves(amount: float, reason: String = "") -> bool:
	return spend_reef_points(amount)


func calculate_base_trickle(now_unix: float, management_multiplier: float) -> float:
	if last_economy_tick_at <= 0.0:
		last_economy_tick_at = now_unix
		return 0.0
	var elapsed: float = clamp(now_unix - last_economy_tick_at, 0.0, OFFLINE_WAVE_CAP_SECONDS)
	if elapsed <= 0.0: return 0.0
	var capped_mult: float = clamp(management_multiplier, 0.1, 3.0)
	var gain: float = floor(elapsed * BASE_WAVE_RATE_PER_SECOND * capped_mult)
	last_economy_tick_at = now_unix
	return gain


func tick_base_trickle(now_unix: float, management_multiplier: float) -> float:
	var gain: float = calculate_base_trickle(now_unix, management_multiplier)
	if gain > 0.0:
		add_waves(gain, "base_trickle")
	return gain


func export_state() -> Dictionary:
	return {
		"reef_points": reef_points,
		"total_reef_points_earned": total_reef_points_earned,
		"reef_value": reef_value,
		"income_rate_per_game_hour": income_rate_per_game_hour,
	}


func import_state(state: Dictionary) -> void:
	reef_points = float(state.get("reef_points", 0.0))
	total_reef_points_earned = float(state.get("total_reef_points_earned", 0.0))
	reef_value = float(state.get("reef_value", 0.0))
	income_rate_per_game_hour = float(state.get("income_rate_per_game_hour", 0.0))
	delta_reef_points = 0.0


func apply_offline_income(amount: float) -> void:
	add_reef_points(max(amount, 0.0))


func get_debug_state() -> Dictionary:
	return {
		"system": "EconomySystem",
		"initialized": initialized,
		"reef_points": reef_points,
		"total_reef_points_earned": total_reef_points_earned,
		"reef_value": reef_value,
		"income_rate_per_game_hour": income_rate_per_game_hour,
		"delta_reef_points": delta_reef_points,
	}
