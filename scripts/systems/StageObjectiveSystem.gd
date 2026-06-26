class_name StageObjectiveSystem
extends RefCounted

## M12 Stage Objective System — new player guidance layer
## Tracks 6 sequential objectives that guide the player through the core loop.

enum ObjectiveState { LOCKED, ACTIVE, COMPLETED }

const OBJECTIVES: Array[Dictionary] = [
	{
		"id": "buy_first_creature",
		"title": "购买第一只生物",
		"description": "打开商店，选择一只生物带回家。",
		"hint": "点击底部「商店」按钮进入生物商店",
		"category": "discovery",
	},
	{
		"id": "observe_comfort",
		"title": "观察舒适度变化",
		"description": "购买生物后，观察「核心状态」中舒适度的变化。",
		"hint": "舒适度会受生物负载和水质影响",
		"category": "observation",
	},
	{
		"id": "enable_device",
		"title": "开启关键设备",
		"description": "确保水泵和主灯处于开启状态。",
		"hint": "点击底部设备按钮切换 ON/OFF",
		"category": "action",
	},
	{
		"id": "perform_maintenance",
		"title": "执行水质维护",
		"description": "选择一项维护操作（换水/清滤/补水），改善水质。",
		"hint": "维护需要消耗 RP，冷却结束后可再次执行",
		"category": "action",
	},
	{
		"id": "restore_water_quality",
		"title": "恢复水质安全",
		"description": "通过维护和设备管理，将水质评分恢复到正常范围。",
		"hint": "水质评分 ≥ 80 即为安全",
		"category": "recovery",
	},
	{
		"id": "accumulate_rp",
		"title": "积累 Reef Points",
		"description": "累计获得 200 RP，建立稳定的收益循环。",
		"hint": "保持水质和舒适度以维持收益倍率",
		"category": "progression",
	},
]

var _state: Dictionary = {}        # id -> ObjectiveState enum value
var _completion_order: Array[String] = []
var _rp_at_start: float = 0.0
var _rp_target: float = 200.0
var _comfort_observed_triggered: bool = false
var _initial_comfort: float = -1.0

signal objective_completed(objective_id: String, title: String)
signal all_objectives_completed()


func initialize() -> void:
	_state.clear()
	_completion_order.clear()
	_rp_at_start = 0.0
	_comfort_observed_triggered = false
	_initial_comfort = -1.0
	for i in range(OBJECTIVES.size()):
		var obj: Dictionary = OBJECTIVES[i]
		var obj_id: String = String(obj.get("id", ""))
		if i == 0:
			_state[obj_id] = ObjectiveState.ACTIVE
		else:
			_state[obj_id] = ObjectiveState.LOCKED


func set_initial_rp(rp: float) -> void:
	_rp_at_start = rp


func set_initial_comfort(comfort: float) -> void:
	_initial_comfort = comfort


## Called every frame by GameState to check completion conditions.
func check_progress(context: Dictionary) -> void:
	var livestock_count: int = int(context.get("livestock_count", 0))
	var comfort_score: float = float(context.get("comfort_score", 100.0))
	var devices_running: bool = bool(context.get("devices_running", true))
	var maintenance_count: int = int(context.get("maintenance_count", 0))
	var water_quality: float = float(context.get("water_quality_score", 100.0))
	var total_rp_earned: float = float(context.get("total_rp_earned", 0.0))
	var current_rp: float = float(context.get("current_rp", 0.0))

	# Objective 1: Buy first creature
	_check_complete("buy_first_creature", livestock_count >= 1)

	# Objective 2: Observe comfort change (triggered after purchase, comfort differs from initial)
	if _state.get("observe_comfort", ObjectiveState.LOCKED) == ObjectiveState.ACTIVE:
		if _initial_comfort < 0.0:
			_initial_comfort = comfort_score
		if not _comfort_observed_triggered and livestock_count >= 1 and abs(comfort_score - _initial_comfort) > 0.5:
			_comfort_observed_triggered = true
		if _comfort_observed_triggered:
			_check_complete("observe_comfort", true)

	# Objective 3: Enable key devices
	_check_complete("enable_device", devices_running)

	# Objective 4: Perform maintenance
	_check_complete("perform_maintenance", maintenance_count >= 1)

	# Objective 5: Restore water quality
	_check_complete("restore_water_quality", water_quality >= 80.0)

	# Objective 6: Accumulate RP
	var rp_progress: float = max(total_rp_earned - _rp_at_start, 0.0)
	_check_complete("accumulate_rp", rp_progress >= _rp_target)


func _check_complete(objective_id: String, condition: bool) -> void:
	var current: int = int(_state.get(objective_id, ObjectiveState.LOCKED))
	if current != ObjectiveState.ACTIVE:
		return
	if not condition:
		return
	_state[objective_id] = ObjectiveState.COMPLETED
	_completion_order.append(objective_id)
	# Unlock next objective
	_unlock_next(objective_id)
	var obj: Dictionary = _get_definition(objective_id)
	var title: String = String(obj.get("title", objective_id))
	objective_completed.emit(objective_id, title)
	if _all_completed():
		all_objectives_completed.emit()


func _unlock_next(completed_id: String) -> void:
	var found: bool = false
	for obj in OBJECTIVES:
		var obj_id: String = String(obj.get("id", ""))
		if found:
			_state[obj_id] = ObjectiveState.ACTIVE
			break
		if obj_id == completed_id:
			found = true


func _all_completed() -> bool:
	for obj in OBJECTIVES:
		var obj_id: String = String(obj.get("id", ""))
		if int(_state.get(obj_id, ObjectiveState.LOCKED)) != ObjectiveState.COMPLETED:
			return false
	return true


func get_active_objective() -> Dictionary:
	for obj in OBJECTIVES:
		var obj_id: String = String(obj.get("id", ""))
		if int(_state.get(obj_id, ObjectiveState.LOCKED)) == ObjectiveState.ACTIVE:
			return obj.duplicate()
	return {}


func get_objective_state(objective_id: String) -> int:
	return int(_state.get(objective_id, ObjectiveState.LOCKED))


func get_completed_count() -> int:
	return _completion_order.size()


func get_total_count() -> int:
	return OBJECTIVES.size()


func get_all_states() -> Dictionary:
	var result: Dictionary = {}
	for obj in OBJECTIVES:
		var obj_id: String = String(obj.get("id", ""))
		result[obj_id] = {
			"title": String(obj.get("title", obj_id)),
			"state": int(_state.get(obj_id, ObjectiveState.LOCKED)),
			"description": String(obj.get("description", "")),
			"hint": String(obj.get("hint", "")),
			"category": String(obj.get("category", "")),
		}
	return result


func get_debug_state() -> Dictionary:
	return {
		"system": "StageObjectiveSystem",
		"completed_count": get_completed_count(),
		"total_count": get_total_count(),
		"all_completed": _all_completed(),
		"active_objective": get_active_objective(),
		"all_states": get_all_states(),
	}


func _get_definition(objective_id: String) -> Dictionary:
	for obj in OBJECTIVES:
		if String(obj.get("id", "")) == objective_id:
			return obj
	return {}


func export_state() -> Dictionary:
	var state_map: Dictionary = {}
	for key in _state.keys():
		state_map[key] = int(_state[key])
	return {
		"state": state_map,
		"completion_order": _completion_order.duplicate(),
		"rp_at_start": _rp_at_start,
		"rp_target": _rp_target,
		"comfort_observed_triggered": _comfort_observed_triggered,
		"initial_comfort": _initial_comfort,
	}


func import_state(data: Dictionary) -> void:
	var raw_state: Variant = data.get("state", {})
	if raw_state is Dictionary:
		for key in raw_state.keys():
			_state[key] = int(raw_state[key])
	var raw_order: Variant = data.get("completion_order", [])
	if raw_order is Array:
		_completion_order.clear()
		for item in raw_order:
			_completion_order.append(String(item))
	_rp_at_start = float(data.get("rp_at_start", 0.0))
	_rp_target = float(data.get("rp_target", 200.0))
	_comfort_observed_triggered = bool(data.get("comfort_observed_triggered", false))
	_initial_comfort = float(data.get("initial_comfort", -1.0))
