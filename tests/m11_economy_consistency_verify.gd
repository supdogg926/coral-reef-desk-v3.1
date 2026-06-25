extends SceneTree

var _failures: Array[String] = []
var _total: int = 0
var _passed: int = 0

func _init() -> void:
	_run()
	quit(1 if not _failures.is_empty() else 0)

func _assert(condition: bool, label: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("PASS: " + label)
	else:
		_failures.append(label)
		push_error("FAIL: " + label)

func _check_timeline_contains(entries: Array, substr: String, label: String) -> void:
	_total += 1
	for entry in entries:
		if entry is Dictionary and substr in String(entry.get("text", "")):
			_passed += 1
			print("PASS: " + label + " (found: " + String(entry.get("text", "")) + ")")
			return
	_failures.append(label)
	push_error("FAIL: " + label)

func _run() -> void:
	print("=== M11 ECONOMY CONSISTENCY VERIFICATION ===\n")

	# ═══════════════════════════════════════════
	# A. RP source of truth consistency
	# ═══════════════════════════════════════════
	print("── A. RP source of truth ──")
	var gs: GameState = GameState.new()
	gs.initialize()

	# A1: Status panel RP = economy system RP
	var economy_rp: float = gs.economy_system.get_reef_points()
	var economy_debug_rp: float = float(gs.get_economy_debug_state().get("reef_points", -1))
	_assert(economy_rp == economy_debug_rp, "[A1] economy_system RP == economy_debug RP")

	# A2: Purchase decision uses economy_system RP (same source)
	var before_buy_rp: float = gs.economy_system.get_reef_points()
	var buy_result: Dictionary = gs.buy_livestock_from_shop("fluorescent_turf")
	if buy_result.get("success", false):
		var price: float = float(buy_result.get("price", 0))
		_assert(gs.economy_system.get_reef_points() == before_buy_rp - price,
			"[A2] economy RP decreased by purchase price")
		# Status panel would read same value via economy debug state
		_assert(float(gs.get_economy_debug_state().get("reef_points", -1)) == gs.economy_system.get_reef_points(),
			"[A3] economy_debug RP matches after purchase")

	# A4: RP=1 cannot buy expensive item
	gs = GameState.new()
	gs.initialize()
	# Drain all RP, then set to 1
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(1.0)
	_assert(gs.economy_system.get_reef_points() < 2.0, "[A4] RP set to ~1")
	var expensive: Dictionary = gs.buy_livestock_from_shop("hammer_coral")
	_assert(not expensive.get("success", true), "[A5] cannot buy 80RP item with 1RP")
	_assert(expensive.get("error", "") == "insufficient_rp", "[A6] error is insufficient_rp")

	# A5: RP=40 cannot buy 150RP item (jewel_flower = 150RP)
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(40.0)
	var jewel: Dictionary = gs.buy_livestock_from_shop("jewel_flower")
	_assert(not jewel.get("success", true), "[A7] cannot buy 150RP item with 40RP")

	# A6: RP enough → succeeds with correct deduction
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(200.0)
	_assert(gs.economy_system.get_reef_points() == 200.0, "[A8] RP set to 200")
	var buy2: Dictionary = gs.buy_livestock_from_shop("hammer_coral")
	_assert(buy2.get("success", false), "[A9] purchase succeeds with enough RP")
	_assert(float(buy2.get("price", 0)) == 80.0, "[A10] price deducted = 80")
	_assert(gs.economy_system.get_reef_points() == 120.0, "[A11] RP after purchase = 120")
	_assert(float(gs.get_economy_debug_state().get("reef_points", -1)) == 120.0,
		"[A12] economy_debug RP also = 120")

	# ═══════════════════════════════════════════
	# B. Purchase-to-tank with RP
	# ═══════════════════════════════════════════
	print("── B. Purchase feedback ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(500.0)
	var init_rp: float = gs.economy_system.get_reef_points()
	var init_cnt: int = gs.livestock_system.get_livestock_count()
	var init_cap: float = gs.livestock_system.get_capacity_used()

	var r: Dictionary = gs.buy_livestock_from_shop("green_torch")
	_assert(r.get("success", false), "[B1] purchase succeeds")
	_assert(float(r.get("price", 0)) == 60.0, "[B2] price = 60")
	_assert(gs.livestock_system.get_livestock_count() == init_cnt + 1, "[B3] count +1")
	_assert(gs.livestock_system.get_capacity_used() > init_cap, "[B4] capacity increased")
	_assert(gs.economy_system.get_reef_points() == init_rp - 60.0, "[B5] RP deducted correctly")

	var tl: Array = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "购买入缸", "[B6] timeline '购买入缸'")
	_check_timeline_contains(tl, "绿火柴", "[B7] timeline species name")
	_check_timeline_contains(tl, "RP-60", "[B8] timeline shows RP-60")

	# Verify purchase_price stored on entry
	var ls_b: Dictionary = gs.livestock_system.get_debug_state()
	var ob: Array = ls_b.get("owned_livestock", [])
	var found_pp: bool = false
	for entry in ob:
		if entry is Dictionary and "green_torch" in String(entry.get("id", "")):
			_assert(float(entry.get("purchase_price", -1)) == 60.0, "[B9] purchase_price stored = 60")
			found_pp = true
	_assert(found_pp, "[B10] found purchased entry with purchase_price")

	# ═══════════════════════════════════════════
	# C. Release RP reward
	# ═══════════════════════════════════════════
	print("── C. Release RP reward ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(500.0)

	# Buy then release
	gs.buy_livestock_from_shop("green_torch")
	var pre_rel_rp: float = gs.economy_system.get_reef_points()
	var pre_rel_cnt: int = gs.livestock_system.get_livestock_count()
	var pre_rel_cap: float = gs.livestock_system.get_capacity_used()

	# Find entry
	var dc: Dictionary = gs.livestock_system.get_debug_state()
	var oc: Array = dc.get("owned_livestock", [])
	var release_id: String = ""
	for entry in oc:
		if entry is Dictionary and "green_torch" in String(entry.get("id", "")):
			release_id = String(entry.get("id", ""))
			break
	_assert(not release_id.is_empty(), "[C1] found entry to release")

	var rel: Dictionary = gs.release_owned_livestock(release_id)
	_assert(rel.get("success", false), "[C2] release succeeds")
	_assert(gs.livestock_system.get_livestock_count() == pre_rel_cnt - 1, "[C3] count -1")
	_assert(gs.livestock_system.get_capacity_used() < pre_rel_cap, "[C4] capacity freed")

	# RP should INCREASE (25% of 60 = 15)
	var release_rp: int = int(rel.get("release_rp", -1))
	var post_rel_rp: float = gs.economy_system.get_reef_points()
	_assert(release_rp == 15, "[C5] release RP = 15 (25%% of 60, got %d)" % release_rp)
	_assert(post_rel_rp > pre_rel_rp, "[C6] RP increased after release")
	_assert(post_rel_rp == pre_rel_rp + release_rp, "[C7] RP += release_rp exactly")

	tl = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "放归", "[C8] timeline '放归'")
	_check_timeline_contains(tl, "RP+15", "[C9] timeline shows RP+15")
	_check_timeline_contains(tl, "释放", "[C10] timeline shows '释放'")
	_check_timeline_contains(tl, "容量", "[C11] timeline shows '容量'")

	# Release a starter creature (no purchase_price → min 1 RP)
	# Buy something cheap first to have room
	gs.economy_system.add_reef_points(500.0)
	gs.buy_livestock_from_shop("fluorescent_turf")
	var od: Array = gs.livestock_system.get_debug_state().get("owned_livestock", [])
	var starter_id: String = ""
	for entry in od:
		if entry is Dictionary:
			var eid: String = String(entry.get("id", ""))
			# Find starter items (no timestamp in id, looking for 'anemone' or 'clownfish_pair')
			if eid == "anemone" or eid == "clownfish_pair" or eid == "blue_tang":
				starter_id = eid
				break
	if not starter_id.is_empty():
		var starter_rp: float = gs.economy_system.get_reef_points()
		var srel: Dictionary = gs.release_owned_livestock(starter_id)
		_assert(srel.get("success", false), "[C12] starter release succeeds")
		var s_release_rp: int = int(srel.get("release_rp", -1))
		_assert(s_release_rp >= 1, "[C13] starter release RP >= 1 (got %d)" % s_release_rp)
		_assert(gs.economy_system.get_reef_points() > starter_rp, "[C14] RP increased for starter release")
	else:
		print("SKIP: no starter entry found for C12-C14")

	# ═══════════════════════════════════════════
	# D. Release has NO RP deduction
	# ═══════════════════════════════════════════
	print("── D. Release never deducts RP ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(500.0)
	gs.buy_livestock_from_shop("fluorescent_turf")
	var d_od: Array = gs.livestock_system.get_debug_state().get("owned_livestock", [])
	var d_rid: String = ""
	for entry in d_od:
		if entry is Dictionary and "fluorescent_turf" in String(entry.get("id", "")):
			d_rid = String(entry.get("id", ""))
			break
	if not d_rid.is_empty():
		var d_pre_rp: float = gs.economy_system.get_reef_points()
		gs.release_owned_livestock(d_rid)
		_assert(gs.economy_system.get_reef_points() >= d_pre_rp, "[D1] release never reduces RP")
	else:
		print("SKIP: no entry for D1")

	# ═══════════════════════════════════════════
	# E. Capacity exceeded + RP insufficient still work
	# ═══════════════════════════════════════════
	print("── E. Error paths ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	var fail_rp: Dictionary = gs.buy_livestock_from_shop("hammer_coral")
	_assert(not fail_rp.get("success", true), "[E1] RP insufficient still fails")

	gs.economy_system.add_reef_points(99999.0)
	var cap_filled: bool = false
	for i in range(50):
		var cr: Dictionary = gs.buy_livestock_from_shop("fluorescent_turf")
		if not cr.get("success", false):
			_assert(cr.get("error", "") == "capacity_exceeded", "[E2] capacity_exceeded error still works")
			cap_filled = true
			break
	_assert(cap_filled, "[E3] capacity exceeded eventually")

	# ═══════════════════════════════════════════
	# F. Fish pair + anemone coral + timeline
	# ═══════════════════════════════════════════
	print("── F. Core invariants ──")
	gs = GameState.new()
	gs.initialize()
	var lsf: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(lsf.get("fish_count", 0)) >= 2, "[F1] pair aggregation: fish >= 2")

	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("sea_anemone_shop")
	var lsf2: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(lsf2.get("coral_count", 0)) >= 1, "[F2] anemone in coral_count")
	_assert(int(lsf2.get("invertebrate_count", 0)) == 0, "[F3] invertebrate = 0")

	_assert(gs.action_timeline.size() <= 200, "[F4] timeline <= 200")

	# ═══════════════════════════════════════════
	# G. SaveSystem + Scene
	# ═══════════════════════════════════════════
	print("── G. SaveSystem + Scene ──")
	_assert(FileAccess.file_exists("res://scripts/systems/SaveSystem.gd"), "[G1] SaveSystem.gd exists")
	_assert(load("res://scripts/systems/SaveSystem.gd") != null, "[G2] SaveSystem loads")
	_assert(load("res://scenes/main/Main.tscn") != null, "[G3] Main.tscn loads")

	# ═══════════════════════════════════════════
	print("\n=== VERIFICATION RESULT ===")
	if _failures.is_empty():
		print("M11_ECONOMY_CONSISTENCY_VERIFY=PASS (%d/%d)" % [_passed, _total])
	else:
		print("M11_ECONOMY_CONSISTENCY_VERIFY=FAIL (%d/%d)" % [_passed, _total])
		for f in _failures:
			print("FAILURE: " + f)
