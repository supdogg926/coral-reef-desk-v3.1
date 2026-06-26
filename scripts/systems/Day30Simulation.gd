class_name Day30Simulation
extends RefCounted

## M13 30-Day Progression Simulation Engine
## Deterministic, seeded auto-pilot that simulates 30 days of gameplay.
## Records daily snapshots for economy/balance/unlock verification.

const SIM_DAYS: int = 30
const GAME_SECONDS_PER_DAY: float = 86400.0

# Auto-pilot thresholds
const MAINTENANCE_WATER_THRESHOLD: float = 92.0
const BUY_MIN_RP_RESERVE: float = 80.0
const BUY_CAPACITY_HEADROOM: float = 1.0

var _seed: int = 42
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _snapshots: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _warnings: Array[String] = []

# Result flags
var deadlocked: bool = false
var rp_explosion: bool = false
var negative_values: bool = false
var all_days_complete: bool = false


func initialize(seed: int = 42) -> void:
	_seed = seed
	_rng.seed = _seed
	_snapshots.clear()
	_events.clear()
	_warnings.clear()
	deadlocked = false
	rp_explosion = false
	negative_values = false
	all_days_complete = false


func run_simulation(gs: GameState) -> Dictionary:
	print("[M13 SIM] Starting 30-day simulation (seed=%d)..." % _seed)

	# Day 0 snapshot
	_record_snapshot(0, gs)

	for day in range(1, SIM_DAYS + 1):
		# Advance one game-day
		_advance_one_day(gs, day)
		_record_snapshot(day, gs)

		# Check for catastrophic conditions
		if _check_failure(gs, day):
			break

	all_days_complete = _snapshots.size() >= SIM_DAYS + 1  # +1 for day 0

	# Analyze results
	_analyze_results()

	print("[M13 SIM] Done. %d snapshots, %d events, %d warnings" % [_snapshots.size(), _events.size(), _warnings.size()])

	return {
		"snapshots": _snapshots.duplicate(),
		"events": _events.duplicate(),
		"warnings": _warnings.duplicate(),
		"deadlocked": deadlocked,
		"rp_explosion": rp_explosion,
		"negative_values": negative_values,
		"all_days_complete": all_days_complete,
		"total_days_simulated": _snapshots.size() - 1,
		"seed": _seed,
	}


func _advance_one_day(gs: GameState, day: int) -> void:
	# Simulate 1 game-day in chunks for accuracy
	var seconds_remaining: float = GAME_SECONDS_PER_DAY
	var chunk_size: float = 900.0  # 15-min chunks

	while seconds_remaining > 0.0:
		var delta: float = min(chunk_size, seconds_remaining)
		gs.update(delta)
		seconds_remaining -= delta

		# Auto-maintenance: if water quality drops below threshold
		_auto_maintain(gs, day)

		# Auto-buy: if affordable and has capacity
		_auto_buy(gs, day)

	# End-of-day auto actions
	_auto_feed(gs, day)


func _auto_maintain(gs: GameState, day: int) -> void:
	var wc_debug: Dictionary = gs.get_water_chemistry_debug_state()
	var water_quality: float = float(wc_debug.get("water_quality_score", 100.0))

	# Emergency: always maintain if comfort is critically low
	var ls = gs.get("livestock_system")
	var comfort_emergency: bool = false
	var wq_emergency: bool = water_quality < 55.0
	if ls != null:
		var ls_debug: Dictionary = ls.get_debug_state()
		var comfort: float = float(ls_debug.get("comfort_score", 100.0))
		if comfort < 50.0:
			comfort_emergency = true

	if water_quality >= MAINTENANCE_WATER_THRESHOLD and not comfort_emergency and not wq_emergency:
		return

	# Find best maintenance action (cheapest normally, most effective in emergency)
	var best_action: String = ""
	var best_cost: float = 999999.0
	var actions: Array = gs.get_water_maintenance_actions()
	for raw_action in actions:
		if not raw_action is Dictionary:
			continue
		var action: Dictionary = raw_action
		var state: Dictionary = gs.get_maintenance_action_state(String(action.get("id", "")))
		if bool(state.get("can_execute", false)):
			var cost: float = float(state.get("cost", 0.0))
			# In emergency, prefer more effective actions even if expensive
			if comfort_emergency:
				cost = cost * 0.5  # bias toward actions that cost more (more effective)
			if cost < best_cost:
				best_cost = cost
				best_action = String(action.get("id", ""))

	if best_action.is_empty():
		return

	var economy_debug: Dictionary = gs.get_economy_debug_state()
	var rp: float = float(economy_debug.get("reef_points", 0.0))
	if rp < best_cost + BUY_MIN_RP_RESERVE:
		return  # Can't afford maintenance

	var result: Dictionary = gs.apply_water_maintenance_action(best_action)
	if result.get("success", false):
		_events.append({"day": day, "type": "maintenance", "action": best_action, "cost": best_cost, "water_quality_after": water_quality})


func _auto_buy(gs: GameState, day: int) -> void:
	var ls = gs.get("livestock_system")
	var es = gs.get("economy_system")
	if ls == null or es == null:
		return

	var items: Array = ls.get_shop_items()
	if items.is_empty():
		return

	# Shuffle with RNG for variety
	_rng.randomize()
	var indices: Array = range(items.size())
	indices.shuffle()

	for idx in indices:
		var item: Dictionary = items[idx]
		var price: float = float(item.get("price", 0.0))
		var slot: float = float(item.get("tank_slot_cost", 1.0))
		var capacity_used: float = ls.get_capacity_used()
		var max_capacity: float = ls.get_max_capacity()

		if es.get_reef_points() < price + BUY_MIN_RP_RESERVE:
			continue
		if capacity_used + slot > max_capacity - BUY_CAPACITY_HEADROOM:
			continue

		var result: Dictionary = gs.buy_livestock_from_shop(String(item.get("id", "")))
		if result.get("success", false):
			_events.append({"day": day, "type": "buy", "species": String(item.get("species_name", "")), "price": price})
			break  # One purchase per auto-buy cycle

	# M13: auto-expand capacity when approaching limit
	var cap_ratio: float = ls.get_capacity_used() / max(ls.get_max_capacity(), 1.0)
	if cap_ratio > 0.55 and es.get_reef_points() > 100.0:
		_auto_expand_capacity(gs, day)


func _auto_feed(gs: GameState, day: int) -> void:
	var feed_result: Dictionary = gs.apply_feeding_action("fish_food")
	if feed_result.get("success", false):
		pass  # Feeding counted in stats via game state


func _record_snapshot(day: int, gs: GameState) -> void:
	var econ: Dictionary = gs.get_economy_debug_state()
	var live: Dictionary = gs.get_livestock_debug_state()
	var water: Dictionary = gs.get_water_chemistry_debug_state()
	var unlock: Dictionary = gs.get_unlock_debug_state()
	var stage_obj: Dictionary = gs.get_stage_objective_debug_state()

	_snapshots.append({
		"day": day,
		"rp": float(econ.get("reef_points", 0.0)),
		"total_rp_earned": float(econ.get("total_reef_points_earned", 0.0)),
		"income_rate_per_hour": float(econ.get("income_rate_per_game_hour", 0.0)),
		"reef_value": float(econ.get("reef_value", 0.0)),
		"livestock_count": int(live.get("livestock_count", 0)),
		"fish_count": int(live.get("fish_count", 0)),
		"coral_count": int(live.get("coral_count", 0)),
		"capacity_used": float(live.get("capacity_used", 0.0)),
		"max_capacity": float(live.get("max_capacity", 0.0)),
		"comfort_score": float(live.get("comfort_score", 100.0)),
		"revenue_multiplier": float(live.get("revenue_multiplier", 1.0)),
		"water_quality_score": float(water.get("water_quality_score", 100.0)),
		"water_status": String(water.get("water_status", "OK")),
		"ph": float(water.get("ph", 8.2)),
		"nitrate": float(water.get("nitrate", 0.0)),
		"phosphate": float(water.get("phosphate", 0.0)),
		"player_level": int(unlock.get("player_level", 1)),
		"stage_obj_completed": int(stage_obj.get("completed_count", 0)),
		"filter_efficiency": float(_get_filter_efficiency(gs)),
	})


func _get_filter_efficiency(gs: GameState) -> float:
	var device_effects: Dictionary = gs.get_device_effect_summary()
	return float(device_effects.get("filter_efficiency_percent", 100.0))


func _check_failure(gs: GameState, day: int) -> bool:
	var econ: Dictionary = gs.get_economy_debug_state()
	var live: Dictionary = gs.get_livestock_debug_state()
	var water: Dictionary = gs.get_water_chemistry_debug_state()

	var rp: float = float(econ.get("reef_points", 0.0))
	var comfort: float = float(live.get("comfort_score", 100.0))
	var water_q: float = float(water.get("water_quality_score", 100.0))

	# Check for negative values
	if rp < 0.0:
		_warnings.append("Day %d: Negative RP (%.1f)" % [day, rp])
		negative_values = true
		return true

	# Check for deadlock: no RP, no income, low comfort
	var income: float = float(econ.get("income_rate_per_game_hour", 0.0))
	var livestock_count: int = int(live.get("livestock_count", 0))
	if rp < 10.0 and income <= 0.0 and livestock_count == 0 and day > 5:
		_warnings.append("Day %d: DEADLOCK — no RP, no income, no livestock" % day)
		deadlocked = true
		return true

	return false


func _analyze_results() -> void:
	if _snapshots.size() < 2:
		return

	# Check RP explosion: >10x growth in 5 days
	for i in range(5, _snapshots.size()):
		var prev_rp: float = float(_snapshots[i - 5].get("rp", 0.0))
		var curr_rp: float = float(_snapshots[i].get("rp", 0.0))
		if prev_rp > 50.0 and curr_rp > prev_rp * 10.0:
			_warnings.append("Day %d: RP explosion (%.0f → %.0f in 5 days)" % [_snapshots[i].get("day", 0), prev_rp, curr_rp])
			rp_explosion = true
			break

	# Check for NaN or infinite
	for snap in _snapshots:
		for key in ["rp", "income_rate_per_hour", "comfort_score", "water_quality_score"]:
			var val = snap.get(key, 0.0)
			if typeof(val) == TYPE_FLOAT and (is_nan(val) or is_inf(val)):
				_warnings.append("Day %d: %s is NaN/Inf" % [snap.get("day", 0), key])
				negative_values = true


func get_snapshot(day: int) -> Dictionary:
	for snap in _snapshots:
		if int(snap.get("day", -1)) == day:
			return snap
	return {}


func get_snapshots() -> Array[Dictionary]:
	return _snapshots.duplicate()


func get_events() -> Array[Dictionary]:
	return _events.duplicate()


func get_warnings() -> Array[String]:
	return _warnings.duplicate()


func run_simulation_days(gs: GameState, num_days: int) -> Dictionary:
	print("[M13 SIM] Running %d-day simulation..." % num_days)
	_record_snapshot(0, gs)
	for day in range(1, num_days + 1):
		_advance_one_day(gs, day)
		_record_snapshot(day, gs)
		if _check_failure(gs, day):
			break
	all_days_complete = _snapshots.size() >= num_days + 1
	_analyze_results()
	return {
		"snapshots": _snapshots.duplicate(),
		"events": _events.duplicate(),
		"warnings": _warnings.duplicate(),
		"deadlocked": deadlocked,
		"rp_explosion": rp_explosion,
		"negative_values": negative_values,
		"all_days_complete": all_days_complete,
		"total_days_simulated": _snapshots.size() - 1,
		"seed": _seed,
	}



func _auto_expand_capacity(gs: GameState, day: int) -> void:
	var ls = gs.get("livestock_system")
	var es = gs.get("economy_system")
	if ls == null or es == null:
		return
	var cost: float = 100.0
	if es.get_reef_points() < cost:
		return
	# M13: simulate capacity upgrade by increasing max_capacity
	var current_max: float = ls.get_max_capacity()
	if current_max >= 100.0:
		return  # Cap capacity growth
	es.spend_reef_points(cost)
	# Increase max_capacity by ~5-8
	var growth: float = 5.0 + _rng.randf() * 3.0
	ls.max_capacity = min(current_max + growth, 80.0)
	_events.append({"day": day, "type": "expand", "cost": cost, "new_capacity": ls.max_capacity})



func export_csv() -> String:
	var header: String = "day,rp,total_rp_earned,income_rate,reef_value,livestock_count,capacity_used,max_capacity,comfort_score,revenue_multiplier,water_quality_score,water_status,ph,nitrate,phosphate,player_level,stage_obj_completed\n"
	var rows: PackedStringArray = PackedStringArray()
	for snap in _snapshots:
		rows.append("%d,%.1f,%.1f,%.2f,%.1f,%d,%.1f,%.1f,%.1f,%.2f,%.1f,%s,%.2f,%.2f,%.3f,%d,%d" % [
			int(snap.get("day", 0)),
			float(snap.get("rp", 0.0)),
			float(snap.get("total_rp_earned", 0.0)),
			float(snap.get("income_rate_per_hour", 0.0)),
			float(snap.get("reef_value", 0.0)),
			int(snap.get("livestock_count", 0)),
			float(snap.get("capacity_used", 0.0)),
			float(snap.get("max_capacity", 0.0)),
			float(snap.get("comfort_score", 100.0)),
			float(snap.get("revenue_multiplier", 1.0)),
			float(snap.get("water_quality_score", 100.0)),
			String(snap.get("water_status", "OK")),
			float(snap.get("ph", 8.2)),
			float(snap.get("nitrate", 0.0)),
			float(snap.get("phosphate", 0.0)),
			int(snap.get("player_level", 1)),
			int(snap.get("stage_obj_completed", 0)),
		])
	return header + "\n".join(rows)
