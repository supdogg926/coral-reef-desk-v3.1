class_name SaveSystem
extends RefCounted

var initialized: bool = false
var save_version: int = 1
var save_slot: String = "default"
var last_save_unix_time: int = 0


func initialize() -> void:
	initialized = true


func get_debug_state() -> Dictionary:
	return {
		"system": "SaveSystem",
		"initialized": initialized,
		"save_version": save_version,
		"save_slot": save_slot,
		"last_save_unix_time": last_save_unix_time,
	}
