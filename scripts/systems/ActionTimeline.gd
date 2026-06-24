class_name ActionTimeline
extends RefCounted

const MAX_ENTRIES: int = 40
const DISPLAY_COUNT: int = 4

var entries: Array[Dictionary] = []

# Anti-spam state — only log system events on state change
var _last_water_status: String = ""
var _last_comfort_tier: String = ""
var _last_revenue_tier: String = ""
var _last_filter_tier: String = ""
var _last_flow_zero: bool = false
var _last_no3_unsafe: bool = false
var _last_po4_unsafe: bool = false
var _neglect_logged: bool = false


func add_player_action(text: String) -> void:
	_append({"text": text})


func add_system_event(text: String) -> void:
	_append({"text": text})


func get_recent(count: int = DISPLAY_COUNT) -> Array[Dictionary]:
	var start: int = max(entries.size() - count, 0)
	var result: Array[Dictionary] = []
	for i in range(start, entries.size()):
		result.append(entries[i])
	return result


func get_all() -> Array[Dictionary]:
	return entries.duplicate()


func _append(entry: Dictionary) -> void:
	entries.append(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()


func reset_neglect() -> void:
	_neglect_logged = false


func should_log_water_status(status: String) -> bool:
	if status != _last_water_status:
		_last_water_status = status
		return true
	return false


func should_log_comfort_tier(tier: String) -> bool:
	if tier != _last_comfort_tier:
		_last_comfort_tier = tier
		return true
	return false


func should_log_revenue_tier(tier: String) -> bool:
	if tier != _last_revenue_tier:
		_last_revenue_tier = tier
		return true
	return false


func should_log_filter_tier(tier: String) -> bool:
	if tier != _last_filter_tier:
		_last_filter_tier = tier
		return true
	return false


func should_log_flow_zero(is_zero: bool) -> bool:
	if is_zero != _last_flow_zero:
		_last_flow_zero = is_zero
		return true
	return false


func should_log_no3_unsafe(unsafe: bool) -> bool:
	if unsafe != _last_no3_unsafe:
		_last_no3_unsafe = unsafe
		return true
	return false


func should_log_po4_unsafe(unsafe: bool) -> bool:
	if unsafe != _last_po4_unsafe:
		_last_po4_unsafe = unsafe
		return true
	return false


func should_log_neglect() -> bool:
	if not _neglect_logged:
		_neglect_logged = true
		return true
	return false
