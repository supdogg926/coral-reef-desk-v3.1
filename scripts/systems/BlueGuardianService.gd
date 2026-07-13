class_name BlueGuardianService
extends RefCounted

enum VoyageState { READY, VOYAGING, RESULT_PENDING }
enum LaunchDenyReason { NONE, VOYAGING, INSUFFICIENT_WAVES, PENDING_UNRESOLVED }

signal state_changed()

var clock = null
var economy = null
var game_state_ref = null
var livestock_gw = null
var rescue_gw = null
var seed_mixer = null
var card_lib = null
var data_registry = null

var _state: VoyageState = VoyageState.READY
var _dock_index: int = 0
var _voyage_end_ts: int = 0
var _pending_species_id: String = ""
var _pending_result_data: Dictionary = {}
var _voyage_sequence: int = 0
var _collection_ids: Array[String] = []
var _persistent_seed: int = 0
var _test_commit_result: bool = true


func configure(p_clock, p_economy, p_game_state, p_livestock_gw, p_rescue_gw) -> void:
	clock = p_clock
	economy = p_economy
	game_state_ref = p_game_state
	livestock_gw = p_livestock_gw
	rescue_gw = p_rescue_gw
	seed_mixer = SeedMixer.new()
	var s = load("res://scripts/systems/CardAssetLibrary.gd")
	if s != null: card_lib = s.new()


func import_state(bg: Dictionary) -> void:
	_state = _parse_state(str(bg.get("voyage_state", "READY")))
	_dock_index = int(bg.get("active_dock_index", 0))
	_voyage_end_ts = int(bg.get("voyage_end_ts", 0))
	_pending_species_id = str(bg.get("pending_species_id", ""))
	_pending_result_data = bg.get("pending_result", {}).duplicate(true) if bg.get("pending_result", {}) is Dictionary else {}
	_voyage_sequence = int(bg.get("voyage_sequence", 0))
	_collection_ids = _str_array(bg.get("collection_unlocked_species_ids", []))
	_persistent_seed = int(bg.get("save_seed", 0))


func export_state() -> Dictionary:
	return {"voyage_state": _state_name(), "active_dock_index": _dock_index,
		"voyage_end_ts": _voyage_end_ts, "pending_species_id": _pending_species_id,
		"pending_result": _pending_result_data.duplicate(true),
		"voyage_sequence": _voyage_sequence,
		"collection_unlocked_species_ids": _collection_ids.duplicate(true),
		"save_seed": _persistent_seed}


func _state_name() -> String:
	match _state:
		VoyageState.VOYAGING: return "VOYAGING"
		VoyageState.RESULT_PENDING: return "RESULT_PENDING"
		_: return "READY"


func _parse_state(s: String) -> VoyageState:
	match s:
		"VOYAGING": return VoyageState.VOYAGING
		"RESULT_PENDING": return VoyageState.RESULT_PENDING
		_: return VoyageState.READY


func _str_array(raw) -> Array[String]:
	var r: Array[String] = []
	if raw is Array: for item in raw: r.append(str(item))
	return r


func get_state() -> VoyageState: return _state
func get_voyage_end_ts() -> int: return _voyage_end_ts
func get_pending_species_id() -> String: return _pending_species_id
func get_pending_result_data() -> Dictionary: return _pending_result_data.duplicate(true)
func get_collection_ids() -> Array[String]: return _collection_ids.duplicate(true)
func get_voyage_sequence() -> int: return _voyage_sequence


func get_remaining_seconds() -> int:
	if _state != VoyageState.VOYAGING: return 0
	var now: int = clock.now_unix() if clock != null else 0
	return max(0, _voyage_end_ts - now)


func get_dock_display_name() -> String:
	var names := ["近岸救助点", "礁缘救助点"]
	return names[_dock_index % names.size()]


func ensure_voyage_settled_if_due() -> void:
	if _state != VoyageState.VOYAGING: return
	var now: int = clock.now_unix() if clock != null else 0
	if now < _voyage_end_ts: return
	if not _pending_species_id.is_empty():
		_state = VoyageState.RESULT_PENDING
		state_changed.emit()
		return
	var seed: int = seed_mixer.voyage_seed(_persistent_seed, _voyage_sequence)
	var species_id: String = _draw_species(seed)
	_pending_species_id = species_id
	_pending_result_data = _build_result(species_id)
	if not _collection_ids.has(species_id):
		_collection_ids.append(species_id)
	_state = VoyageState.RESULT_PENDING
	if game_state_ref != null and game_state_ref.has_method("commit_current_state"):
		game_state_ref.commit_current_state()
	state_changed.emit()


func _draw_species(seed: int) -> String:
	var pool: Array = BlueGuardianConfig.get_active_species_pool()
	if pool.is_empty(): return ""
	var rng: int = _seeded_randi(seed)
	var is_surprise: bool = (rng % 100) < BlueGuardianConfig.SURPRISE_WEIGHT
	var idx: int
	if is_surprise: idx = (rng >> 4) % pool.size()
	else: idx = (rng >> 8) % pool.size()
	return str(pool[idx])


func _seeded_randi(seed: int) -> int:
	var x: int = seed
	x = (x * 1103515245 + 12345) & 0x7FFFFFFF
	x = (x * 1103515245 + 12345) & 0x7FFFFFFF
	return x


func _build_result(species_id: String) -> Dictionary:
	var info := {"species_id": species_id, "display_name": species_id, "description": "救助生物", "type": "fish"}
	# Resolve data_registry: configured ref or autoload fallback
	var registry = data_registry
	if registry == null:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			for child in main_loop.root.get_children():
				if child is DataRegistry:
					registry = child
					break
	if registry != null:
		var raw: Variant = registry.get_species_by_id(species_id)
		if raw is Dictionary and not raw.is_empty():
			info["display_name"] = str(raw.get("name", raw.get("name_cn", species_id)))
			info["description"] = str(raw.get("desc", raw.get("description", "")))
			info["type"] = str(raw.get("type", raw.get("species_type", raw.get("category", "fish"))))
	return info


func get_launch_deny_reason() -> LaunchDenyReason:
	if _state == VoyageState.RESULT_PENDING and not _pending_species_id.is_empty():
		return LaunchDenyReason.PENDING_UNRESOLVED
	if _state == VoyageState.VOYAGING: return LaunchDenyReason.VOYAGING
	var bal: float = economy.get_waves_balance() if economy != null else 0.0
	if bal < BlueGuardianConfig.WAVE_COST: return LaunchDenyReason.INSUFFICIENT_WAVES
	return LaunchDenyReason.NONE


func launch_voyage() -> Dictionary:
	var deny := get_launch_deny_reason()
	if deny != LaunchDenyReason.NONE: return {"success": false, "deny_reason": deny}
	var snap := _snapshot()
	if economy != null: economy.spend_waves(BlueGuardianConfig.WAVE_COST, "bg_launch")
	_voyage_sequence += 1
	_dock_index = (_dock_index + 1) % 2
	_voyage_end_ts = clock.now_unix() + BlueGuardianConfig.VOYAGE_DURATION_SECONDS
	_state = VoyageState.VOYAGING
	_pending_species_id = ""
	_pending_result_data = {}
	var ok: bool = _commit_call()
	if not ok: _restore(snap); return {"success": false, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


func keep_pending_result() -> Dictionary:
	ensure_voyage_settled_if_due()
	if _state != VoyageState.RESULT_PENDING or _pending_species_id.is_empty():
		return {"success": false, "error": "no_pending"}
	if livestock_gw != null:
		var cap: Dictionary = livestock_gw.get_debug_state()
		if float(cap.get("current_capacity_used", 0.0)) >= float(cap.get("max_capacity", 30.0)):
			return {"success": false, "error": "capacity_full"}
	var snap := _snapshot()
	if livestock_gw != null: livestock_gw.add_livestock_from_rescue(_pending_species_id, _pending_result_data)
	_pending_species_id = ""
	_pending_result_data = {}
	_state = VoyageState.READY
	var ok: bool = _commit_call()
	if not ok: _restore(snap); return {"success": false, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


func release_pending_result() -> Dictionary:
	ensure_voyage_settled_if_due()
	if _state != VoyageState.RESULT_PENDING or _pending_species_id.is_empty():
		return {"success": false, "error": "no_pending"}
	var snap := _snapshot()
	var sid := _pending_species_id
	if rescue_gw != null: rescue_gw.record_release(sid)
	if economy != null: economy.add_waves(15.0, "release_pulse")
	_pending_species_id = ""
	_pending_result_data = {}
	_state = VoyageState.READY
	var ok: bool = _commit_call()
	if not ok: _restore(snap); return {"success": false, "error": "save_failed"}
	state_changed.emit()
	return {"success": true}


func _snapshot() -> Dictionary:
	return {"state": _state, "dock_index": _dock_index, "voyage_end_ts": _voyage_end_ts,
		"pending_species_id": _pending_species_id, "pending_result_data": _pending_result_data.duplicate(true),
		"voyage_sequence": _voyage_sequence, "collection_ids": _collection_ids.duplicate(true)}


func _restore(snap: Dictionary) -> void:
	_state = snap.get("state", VoyageState.READY)
	_dock_index = int(snap.get("dock_index", 0))
	_voyage_end_ts = int(snap.get("voyage_end_ts", 0))
	_pending_species_id = str(snap.get("pending_species_id", ""))
	_pending_result_data = snap.get("pending_result_data", {}).duplicate(true)
	_voyage_sequence = int(snap.get("voyage_sequence", 0))
	_collection_ids = _str_array(snap.get("collection_ids", []))


func _commit_call() -> bool:
	if not _test_commit_result:
		return false
	if game_state_ref != null and game_state_ref.has_method("commit_current_state"):
		return game_state_ref.commit_current_state()
	return true


func _set_test_commit_result(ok: bool) -> void:
	_test_commit_result = ok


func get_debug_state() -> Dictionary:
	return {"state": _state_name(), "dock_index": _dock_index, "dock_display": get_dock_display_name(),
		"voyage_end_ts": _voyage_end_ts, "remaining_seconds": get_remaining_seconds(),
		"pending_species_id": _pending_species_id, "voyage_sequence": _voyage_sequence,
		"collection_size": _collection_ids.size(), "collection_ids": _collection_ids.duplicate(true)}
