class_name UnlockSystem
extends RefCounted

const UNLOCK_MILESTONES_PATH: String = "res://data/unlocks/unlock_milestones_seed.json"

var initialized: bool = false
var milestones: Array[Dictionary] = []
var unlocked_states: Dictionary = {}
var current_stage: String = "初级玩家"
var next_unlock_target: String = "解锁中级设备预览"
var unlock_progress: float = 0.0
var unlocked_preview_items: Array[String] = []
var locked_preview_items: Array[String] = []
var load_errors: Array[String] = []


func initialize() -> void:
	_load_milestones()
	unlocked_states.clear()
	unlocked_states["tier1_running"] = true
	unlocked_states["tier2_equipment_preview"] = false
	unlocked_states["tier2_sump_space_preview"] = false
	unlocked_states["tier3_advanced_system_preview"] = false
	_update_preview_lists()
	initialized = load_errors.is_empty()


func update_unlocks(economy_state: Dictionary) -> void:
	var total_earned: float = float(economy_state.get("total_reef_points_earned", 0.0))
	unlocked_states["tier1_running"] = true
	unlocked_states["tier2_equipment_preview"] = total_earned >= 500.0
	unlocked_states["tier2_sump_space_preview"] = total_earned >= 1500.0
	unlocked_states["tier3_advanced_system_preview"] = false

	if bool(unlocked_states.get("tier2_equipment_preview", false)) or bool(unlocked_states.get("tier2_sump_space_preview", false)):
		current_stage = "中级玩家预备"
	else:
		current_stage = "初级玩家"
	_update_target(total_earned)
	_update_preview_lists()


func get_current_stage() -> String:
	return current_stage


func get_next_unlock_target() -> String:
	return next_unlock_target


func get_unlock_progress() -> float:
	return unlock_progress


func is_unlocked(unlock_id: String) -> bool:
	return bool(unlocked_states.get(unlock_id, false))


func get_unlocked_preview_items() -> Array[String]:
	return unlocked_preview_items.duplicate()


func get_locked_preview_items() -> Array[String]:
	return locked_preview_items.duplicate()


func export_state() -> Dictionary:
	return {
		"current_stage": current_stage,
		"unlocked_states": unlocked_states.duplicate(),
	}


func import_state(state: Dictionary) -> void:
	current_stage = String(state.get("current_stage", "初级玩家"))
	var raw_states: Variant = state.get("unlocked_states", {})
	if raw_states is Dictionary:
		unlocked_states = raw_states.duplicate()
	else:
		unlocked_states.clear()
		unlocked_states["tier1_running"] = true
		unlocked_states["tier2_equipment_preview"] = false
		unlocked_states["tier2_sump_space_preview"] = false
		unlocked_states["tier3_advanced_system_preview"] = false
	_update_preview_lists()


func recalculate_from_reef_points(total_earned: float) -> void:
	unlocked_states["tier1_running"] = true
	unlocked_states["tier2_equipment_preview"] = total_earned >= 500.0
	unlocked_states["tier2_sump_space_preview"] = total_earned >= 1500.0
	unlocked_states["tier3_advanced_system_preview"] = false
	if bool(unlocked_states.get("tier2_equipment_preview", false)) or bool(unlocked_states.get("tier2_sump_space_preview", false)):
		current_stage = "中级玩家预备"
	else:
		current_stage = "初级玩家"
	_update_target(total_earned)
	_update_preview_lists()


func get_debug_state() -> Dictionary:
	return {
		"system": "UnlockSystem",
		"initialized": initialized,
		"current_stage": current_stage,
		"next_unlock_target": next_unlock_target,
		"unlock_progress": unlock_progress,
		"unlocked_states": unlocked_states.duplicate(),
		"unlocked_preview_items": unlocked_preview_items.duplicate(),
		"locked_preview_items": locked_preview_items.duplicate(),
		"tier3_status": "高级系统：未解锁",
		"load_errors": load_errors.duplicate(),
	}


func _update_target(total_earned: float) -> void:
	if not bool(unlocked_states.get("tier2_equipment_preview", false)):
		next_unlock_target = "解锁中级设备预览"
		unlock_progress = clamp(total_earned / 500.0, 0.0, 1.0)
		return
	if not bool(unlocked_states.get("tier2_sump_space_preview", false)):
		next_unlock_target = "解锁中级底缸空间预览"
		unlock_progress = clamp((total_earned - 500.0) / 1000.0, 0.0, 1.0)
		return
	next_unlock_target = "高级系统预告（未解锁）"
	unlock_progress = clamp(total_earned / 5000.0, 0.0, 1.0)


func _update_preview_lists() -> void:
	unlocked_preview_items.clear()
	locked_preview_items.clear()
	for milestone in milestones:
		var unlock_id: String = String(milestone.get("unlock_id", ""))
		var raw_items: Variant = milestone.get("preview_items", [])
		var items: Array = []
		if raw_items is Array:
			items = raw_items
		for item in items:
			var item_name: String = String(item)
			if item_name.is_empty():
				continue
			if is_unlocked(unlock_id):
				unlocked_preview_items.append(item_name)
			else:
				locked_preview_items.append(item_name)


func _load_milestones() -> void:
	milestones.clear()
	load_errors.clear()
	var parsed: Variant = _load_json(UNLOCK_MILESTONES_PATH)
	if not parsed is Array:
		load_errors.append("Unlock milestones data is not an array")
		return
	var records: Array = parsed
	for item in records:
		if item is Dictionary:
			milestones.append(item)


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		load_errors.append("Missing unlock milestones data file: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot open unlock milestones data file: " + path)
		return []
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		load_errors.append("Cannot parse unlock milestones data file: " + path)
		return []
	return parsed
