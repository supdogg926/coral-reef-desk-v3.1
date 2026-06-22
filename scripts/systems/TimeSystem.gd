class_name TimeSystem
extends RefCounted

var initialized: bool = false
var elapsed_seconds: float = 0.0
var last_delta_seconds: float = 0.0
var offline_seconds_cap: float = 28800.0
var tick_seconds: float = 1.0
var debug_time_scale: float = 600.0


func initialize() -> void:
	initialized = true


func update_time(delta_seconds: float) -> float:
	last_delta_seconds = max(delta_seconds, 0.0) * debug_time_scale
	elapsed_seconds += last_delta_seconds
	return last_delta_seconds


func get_elapsed_seconds() -> float:
	return elapsed_seconds


func get_elapsed_game_minutes() -> int:
	return int(floor(elapsed_seconds / 60.0))


func get_elapsed_game_time_text() -> String:
	var total_minutes: int = get_elapsed_game_minutes()
	var day_index: int = int(floor(float(total_minutes) / 1440.0)) + 1
	var minutes_in_day: int = total_minutes % 1440
	var hour: int = int(floor(float(minutes_in_day) / 60.0))
	var minute: int = minutes_in_day % 60
	return "Day %d %02d:%02d" % [day_index, hour, minute]


func get_elapsed_days_debug() -> float:
	return elapsed_seconds / 86400.0


func get_debug_state() -> Dictionary:
	return {
		"system": "TimeSystem",
		"initialized": initialized,
		"elapsed_seconds": elapsed_seconds,
		"elapsed_game_minutes": get_elapsed_game_minutes(),
		"elapsed_game_time_text": get_elapsed_game_time_text(),
		"elapsed_days_debug": get_elapsed_days_debug(),
		"last_delta_seconds": last_delta_seconds,
		"debug_time_scale": debug_time_scale,
		"offline_seconds_cap": offline_seconds_cap,
		"tick_seconds": tick_seconds,
	}
