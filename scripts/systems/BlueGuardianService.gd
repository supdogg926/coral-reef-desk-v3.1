class_name BlueGuardianService
extends RefCounted

enum VoyageState { READY, VOYAGING, RESULT_PENDING }
enum LaunchDenyReason { NONE, VOYAGING, INSUFFICIENT_WAVES, PENDING_UNRESOLVED }

signal state_changed()

var _state: VoyageState = VoyageState.READY
var _dock_index: int = 0
var _voyage_end_ts: int = 0
var _pending_species_id: String = ""
var _pending_result_data: Dictionary = {}
var _voyage_sequence: int = 0

var _game_state: RefCounted = null
var _save_system: SaveSystem = null
var _economy_system: EconomySystem = null
var _wall_clock: WallClockService = null
var _seed_mixer: SeedMixer = null
var _card_asset_library: RefCounted = null
var _livestock_system: RefCounted = null
var _rescue_system: RefCounted = null
var _collection_ids: Array[String] = []


func setup(gs: RefCounted) -> void:
	_game_state = gs
	_save_system = gs.save_system
	_economy_system = gs.economy_system
	_wall_clock = gs.wall_clock_service
	_seed_mixer = SeedMixer.new()
	_card_asset_library = _load_card_library()
	_livestock_system = gs.livestock_system
	_rescue_system = gs.rescue_system


func _load_card_library() -> RefCounted:
	var lib_script = load("res://scripts/systems/CardAssetLibrary.gd")
	if lib_script != null:
		return lib_script.new()
	return null


func import_state(bg: Dictionary) -> void:
	_state = _parse_state(bg.get("voyage_state", "READY"))
	_dock_index = int(bg.get("active_dock_index", 0))
	_voyage_end_ts = int(bg.get("voyage_end_ts", 0))
	_pending_species_id = String(bg.get("pending_species_id", ""))
	_pending_result_data = bg.get("pending_result", {}).duplicate(true) if bg.get("pending_result", {}) is Dictionary else {}
	_voyage_sequence = int(bg.get("voyage_sequence", 0))
	_collection_ids = _to_string_array(bg.get("collection_unlocked_species_ids", []))


func export_state() -> Dictionary:
	return {
		"voyage_state": _state_name(),
		"active_dock_index": _dock_index,
		"voyage_end_ts": _voyage_end_ts,
		"pending_species_id": _pending_species_id,
		"pending_result": _pending_result_data.duplicate(true),
		"voyage_sequence": _voyage_sequence,
		"collection_unlocked_species_ids": _collection_ids.duplicate(true),
	}


func _state_name() -> String:
	match _state:
		VoyageState.VOYAGING: return "VOYAGING"
		VoyageState.RESULT_PENDING: return "RESULT_PENDING"
	return "READY"


func _parse_state(s: String) -> VoyageState:
	match s:
		"VOYAGING": return VoyageState.VOYAGING
		"RESULT_PENDING": return VoyageState.RESULT_PENDING
	return VoyageState.READY


# ── Public API ────────────────────────────────────────

func get_state() -> VoyageState:
	return _state


func get_dock_display_name() -> String:
	var names: Array = BlueGuardianConfig.get_dock_display_names()
	var idx := _dock_index % names.size()
	return names[idx]


func get_voyage_end_ts() -> int:
	return _voyage_end_ts


func get_remaining_seconds() -> int:
	if _state != VoyageState.VOYAGING:
		return 0
	var now := _wall_clock.now_unix() if _wall_clock != null else int(Time.get_unix_time_from_system())
	return max(0, _voyage_end_ts - now)


func get_pending_species_id() -> String:
	return _pending_species_id


func get_pending_result_data() -> Dictionary:
	return _pending_result_data.duplicate(true)


func get_collection_ids() -> Array[String]:
	return _collection_ids.duplicate(true)


func ensure_voyage_settled_if_due() -> void:
	if _state != VoyageState.VOYAGING:
		return
	var now := _wall_clock.now_unix() if _wall_clock != null else int(Time.get_unix_time_from_system())
	if now < _voyage_end_ts:
		return
	if not _pending_species_id.is_empty():
		_state = VoyageState.RESULT_PENDING
		state_changed.emit()
		return
	_settle_voyage(now)


func _settle_voyage(now: int) -> void:
	var save_seed: int = _get_save_seed()
	var seed: int = _seed_mixer.voyage_seed(save_seed, _voyage_sequence)
	var species_id: String = _draw_species(seed)
	_pending_species_id = species_id
	_pending_result_data = _build_result_data(species_id)
	if not _collection_ids.has(species_id):
		_collection_ids.append(species_id)
	_state = VoyageState.RESULT_PENDING
	_sync_to_game_state()
	if _save_system != null:
		_do_commit()
	state_changed.emit()


func _draw_species(seed: int) -> String:
	var pool: Array = BlueGuardianConfig.get_active_species_pool()
	if pool.is_empty():
		return ""
	var rng: int = _seeded_randi(seed)
	var is_surprise: bool = (rng % 100) < BlueGuardianConfig.SURPRISE_WEIGHT
	var idx: int
	if is_surprise:
		idx = (rng >> 4) % pool.size()
	else:
		idx = (rng >> 8) % pool.size()
	return pool[idx]


func _seeded_randi(seed: int) -> int:
	var x: int = seed
	x = (x * 1103515245 + 12345) & 0x7FFFFFFF
	x = (x * 1103515245 + 12345) & 0x7FFFFFFF
	return x


func _build_result_data(species_id: String) -> Dictionary:
	if species_id.is_empty():
		return {}
	var info := {"species_id": species_id}
	var data_registry: Variant = _get_data_registry()
	if data_registry != null:
		var species_info: Variant = data_registry.call("get_species_by_id", species_id)
		if species_info is Dictionary and not species_info.is_empty():
			info["display_name"] = species_info.get("name_cn", species_id)
			info["description"] = species_info.get("desc", "")
			info["type"] = species_info.get("type", "")
	if not info.has("display_name"):
		info["display_name"] = species_id
	if not info.has("description"):
		info["description"] = "救助生物"
	if not info.has("type"):
		info["type"] = "fish"
	return info


func _get_data_registry():
	if _game_state != null and _game_state.has_method("_get_data_registry"):
		return _game_state.call("_get_data_registry")
	var node: Variant = Engine.get_main_loop()
	if node != null and node.has_method("get_node_or_null"):
		return node.get_node_or_null("/root/DataRegistry")
	return null


# ── Launch ────────────────────────────────────────────

func get_launch_deny_reason() -> LaunchDenyReason:
	if _state == VoyageState.RESULT_PENDING and not _pending_species_id.is_empty():
		return LaunchDenyReason.PENDING_UNRESOLVED
	if _state == VoyageState.VOYAGING:
		return LaunchDenyReason.VOYAGING
	var balance: float = _economy_system.get_waves_balance() if _economy_system != null else 0.0
	if balance < BlueGuardianConfig.WAVE_COST:
		return LaunchDenyReason.INSUFFICIENT_WAVES
	return LaunchDenyReason.NONE


func launch_voyage() -> Dictionary:
	var deny := get_launch_deny_reason()
	if deny != LaunchDenyReason.NONE:
		return {"success": false, "deny_reason": deny}

	var snapshot: Dictionary = _capture_mutable()
	if _economy_system != null:
		_economy_system.spend_waves(BlueGuardianConfig.WAVE_COST, "blue_guardian_launch")
	_voyage_sequence += 1
	_dock_index = (_dock_index + 1) % BlueGuardianConfig.ACTIVE_DOCK_COUNT
	var now := _wall_clock.now_unix() if _wall_clock != null else int(Time.get_unix_time_from_system())
	_voyage_end_ts = now + BlueGuardianConfig.VOYAGE_DURATION_SECONDS
	_state = VoyageState.VOYAGING
	_pending_species_id = ""
	_pending_result_data = {}
	_sync_to_game_state()
	var ok: bool = _do_commit()
	if not ok:
		_restore_mutable(snapshot)
		return {"success": false, "deny_reason": LaunchDenyReason.NONE, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


# ── Keep in Tank ──────────────────────────────────────

func keep_in_tank() -> Dictionary:
	ensure_voyage_settled_if_due()
	if _state != VoyageState.RESULT_PENDING or _pending_species_id.is_empty():
		return {"success": false, "error": "no_pending"}

	if _livestock_system != null:
		var cap_state: Dictionary = _livestock_system.get_debug_state()
		var used: float = float(cap_state.get("current_capacity_used", 0.0))
		var max_cap: float = float(cap_state.get("max_capacity", 30.0))
		if used >= max_cap:
			return {"success": false, "error": "capacity_full"}

	var snapshot: Dictionary = _capture_mutable()
	if _livestock_system != null:
		_livestock_system.add_livestock_from_rescue(_pending_species_id, _pending_result_data)
	_pending_species_id = ""
	_pending_result_data = {}
	_state = VoyageState.READY
	_sync_to_game_state()
	var ok: bool = _do_commit()
	if not ok:
		_restore_mutable(snapshot)
		return {"success": false, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


# ── Release ───────────────────────────────────────────

func release_pending() -> Dictionary:
	ensure_voyage_settled_if_due()
	if _state != VoyageState.RESULT_PENDING or _pending_species_id.is_empty():
		return {"success": false, "error": "no_pending"}

	var snapshot: Dictionary = _capture_mutable()
	var species_id := _pending_species_id
	if _rescue_system != null:
		_rescue_system.record_release(species_id)
	if _economy_system != null:
		_economy_system.add_waves(15.0, "release_pulse")
	_pending_species_id = ""
	_pending_result_data = {}
	_state = VoyageState.READY
	_sync_to_game_state()
	var ok: bool = _do_commit()
	if not ok:
		_restore_mutable(snapshot)
		return {"success": false, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


# ── Internal Helpers ──────────────────────────────────

func _get_save_seed() -> int:
	if _game_state != null:
		var bg: Variant = _game_state.get("blue_guardian_state")
		if bg is Dictionary:
			return int(bg.get("save_seed", 0))
	return 0


func _sync_to_game_state() -> void:
	if _game_state == null:
		return
	if "blue_guardian_state" in _game_state:
		var bg: Dictionary = _game_state.blue_guardian_state.duplicate(true)
		bg["voyage_state"] = _state_name()
		bg["voyage_sequence"] = _voyage_sequence
		bg["voyage_end_ts"] = _voyage_end_ts
		bg["pending_species_id"] = _pending_species_id
		bg["pending_result"] = _pending_result_data.duplicate(true)
		bg["active_dock_index"] = _dock_index
		bg["collection_unlocked_species_ids"] = _collection_ids.duplicate(true)
		_game_state.blue_guardian_state = bg


func _do_commit() -> bool:
	if _game_state != null and _game_state.has_method("commit_current_state"):
		return _game_state.commit_current_state()
	return false


func _capture_mutable() -> Dictionary:
	return {
		"state": _state,
		"voyage_end_ts": _voyage_end_ts,
		"pending_species_id": _pending_species_id,
		"pending_result_data": _pending_result_data.duplicate(true),
		"voyage_sequence": _voyage_sequence,
		"dock_index": _dock_index,
		"collection_ids": _collection_ids.duplicate(true),
	}


func _restore_mutable(snapshot: Dictionary) -> void:
	_state = snapshot.get("state", VoyageState.READY)
	_voyage_end_ts = int(snapshot.get("voyage_end_ts", 0))
	_pending_species_id = String(snapshot.get("pending_species_id", ""))
	_pending_result_data = snapshot.get("pending_result_data", {}).duplicate(true)
	_voyage_sequence = int(snapshot.get("voyage_sequence", 0))
	_dock_index = int(snapshot.get("dock_index", 0))
	_collection_ids = _to_string_array(snapshot.get("collection_ids", []))


func _to_string_array(raw) -> Array[String]:
	var result: Array[String] = []
	if raw is Array:
		for item in raw:
			result.append(String(item))
	return result


func get_debug_state() -> Dictionary:
	return {
		"state": _state_name(),
		"dock_index": _dock_index,
		"dock_display": get_dock_display_name(),
		"voyage_end_ts": _voyage_end_ts,
		"remaining_seconds": get_remaining_seconds(),
		"pending_species_id": _pending_species_id,
		"voyage_sequence": _voyage_sequence,
		"collection_size": _collection_ids.size(),
		"collection_ids": _collection_ids.duplicate(true),
	}
