class_name WallClockService
extends RefCounted

var _test_override_unix_time: int = 0
var _test_override_active: bool = false


func now_unix() -> int:
	if _test_override_active:
		return _test_override_unix_time
	return int(Time.get_unix_time_from_system())


func set_test_override(unix_time: int) -> void:
	_test_override_unix_time = unix_time
	_test_override_active = true


func advance_test_override(seconds: int) -> void:
	if _test_override_active:
		_test_override_unix_time += seconds


func clear_test_override() -> void:
	_test_override_active = false
	_test_override_unix_time = 0


func has_test_override() -> bool:
	return _test_override_active


func get_debug_state() -> Dictionary:
	return {
		"system": "WallClockService",
		"test_override_active": _test_override_active,
		"test_override_unix_time": _test_override_unix_time if _test_override_active else -1,
	}
