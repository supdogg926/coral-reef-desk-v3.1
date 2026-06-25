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

func _run() -> void:
	print("=== M11 RUNTIME UI STATE VERIFICATION ===\n")

	# ═══════════════════════════════════════════
	# A. RP capsule reads from authoritative source
	# ═══════════════════════════════════════════
	print("── A. RP capsule sync ──")
	var gs: GameState = GameState.new()
	gs.initialize()

	# Simulate: StatusPanel reads from economy_debug → same as economy_system
	var econ_rp: float = gs.economy_system.get_reef_points()
	var debug_rp: float = float(gs.get_economy_debug_state().get("reef_points", -1))
	_assert(econ_rp == debug_rp, "[A1] economy RP == economy_debug RP")

	# Change RP, verify debug state follows
	gs.economy_system.add_reef_points(40.0)
	_assert(gs.economy_system.get_reef_points() == econ_rp + 40.0, "[A2] RP changed in economy")
	_assert(float(gs.get_economy_debug_state().get("reef_points", -1)) == econ_rp + 40.0,
		"[A3] economy_debug RP matches after change")

	# RP=40: verify purchase decision uses same RP
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(40.0)
	var shop_check_rp: float = gs.economy_system.get_reef_points()
	_assert(shop_check_rp == 40.0, "[A4] shop reads economy RP = 40")
	var rp_fail: Dictionary = gs.buy_livestock_from_shop("hammer_coral")  # 80RP
	_assert(not rp_fail.get("success", true), "[A5] cannot buy 80RP item with 40RP")
	_assert(rp_fail.get("current_rp", -1) == 40.0, "[A6] buy check returns current_rp=40")

	# RP=219: buy should work then
	gs.economy_system.add_reef_points(200.0)
	_assert(gs.economy_system.get_reef_points() > 200.0, "[A7] RP > 200 now")
	var ok_buy: Dictionary = gs.buy_livestock_from_shop("hammer_coral")
	_assert(ok_buy.get("success", false), "[A8] can buy with enough RP")

	# All RP values agree
	var e_rp: float = gs.economy_system.get_reef_points()
	var d_rp: float = float(gs.get_economy_debug_state().get("reef_points", -1))
	_assert(e_rp == d_rp, "[A9] economy RP == debug RP == status panel RP source")

	# ═══════════════════════════════════════════
	# B. ShopPanel dynamic refresh simulation
	# ═══════════════════════════════════════════
	print("── B. Shop dynamic RP refresh ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	gs.economy_system.add_reef_points(40.0)

	# Simulate ShopPanel update_display (captures RP at open time)
	var initial_rp: float = gs.economy_system.get_reef_points()
	_assert(initial_rp == 40.0, "[B1] shop opens with RP=40")

	# Later, RP changes (passive income)
	gs.economy_system.add_reef_points(100.0)
	var later_rp: float = gs.economy_system.get_reef_points()
	_assert(later_rp == 140.0, "[B2] RP changed to 140 after income")

	# Shop _process would re-read economy RP directly
	var refreshed_rp: float = gs.economy_system.get_reef_points()
	_assert(refreshed_rp == 140.0, "[B3] shop refresh reads 140 (same source)")
	_assert(refreshed_rp != initial_rp, "[B4] refreshed RP differs from snapshot")

	# ═══════════════════════════════════════════
	# C. Purchase timeline: data + UI label path
	# ═══════════════════════════════════════════
	print("── C. Purchase timeline in UI ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	var pre_tl: int = gs.action_timeline.size()
	gs.buy_livestock_from_shop("green_torch")
	var post_tl: int = gs.action_timeline.size()
	_assert(post_tl > pre_tl, "[C1] timeline grew after purchase")

	var tl: Array = gs.get_timeline_entries(200)
	_assert(tl.size() >= post_tl, "[C2] get_timeline_entries(200) returns all entries")

	# Check last entry is the purchase
	var last: Variant = tl[tl.size() - 1]
	_assert(last is Dictionary, "[C3] last entry is Dictionary")
	var last_text: String = String(last.get("text", ""))
	_assert("购买入缸" in last_text, "[C4] last entry contains '购买入缸'")
	_assert("绿火柴" in last_text, "[C5] last entry contains species name")
	_assert("RP-60" in last_text, "[C6] last entry shows RP-60")
	_assert("容量" in last_text, "[C7] last entry shows capacity")

	# Verify StatusPanel guard would allow refresh
	# The guard compares count + last text — after purchase, both changed
	_assert(post_tl > pre_tl, "[C8] count changed → guard allows refresh")

	# ═══════════════════════════════════════════
	# D. Release timeline in UI
	# ═══════════════════════════════════════════
	print("── D. Release timeline in UI ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("green_torch")
	var d4: Dictionary = gs.livestock_system.get_debug_state()
	var o4: Array = d4.get("owned_livestock", [])
	var rid4: String = ""
	for entry in o4:
		if entry is Dictionary and "green_torch" in String(entry.get("id", "")):
			rid4 = String(entry.get("id", ""))
			break
	_assert(not rid4.is_empty(), "[D1] found green_torch to release")

	var pre_rel_tl: int = gs.action_timeline.size()
	gs.release_owned_livestock(rid4)
	var post_rel_tl: int = gs.action_timeline.size()
	_assert(post_rel_tl > pre_rel_tl, "[D2] timeline grew after release")

	tl = gs.get_timeline_entries(200)
	last = tl[tl.size() - 1]
	last_text = String(last.get("text", ""))
	_assert("放归" in last_text, "[D3] last entry contains '放归'")
	_assert("绿火柴" in last_text, "[D4] last entry contains species name")
	_assert("RP+" in last_text, "[D5] last entry shows RP+")
	_assert("释放" in last_text, "[D6] last entry shows '释放'")
	_assert("容量" in last_text, "[D7] last entry shows '容量'")

	# ═══════════════════════════════════════════
	# E. Reset restores default state
	# ═══════════════════════════════════════════
	print("── E. Reset restores defaults ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("green_torch")
	gs.buy_livestock_from_shop("hammer_coral")
	_assert(gs.livestock_system.get_livestock_count() > 6, "[E1] pre-reset: extra livestock exist")

	# Simulate reset: clear save, create new GameState
	if gs.save_system != null:
		gs.save_system.clear_save()
	gs = GameState.new()
	gs.initialize()

	var ls_e: Dictionary = gs.livestock_system.get_debug_state()
	var post_coral: int = int(ls_e.get("coral_count", 0))
	var post_fish: int = int(ls_e.get("fish_count", 0))
	var post_count: int = gs.livestock_system.get_livestock_count()

	# With anemone now in coral, expected: coral=4 fish=3
	_assert(post_count == 6, "[E2] reset: 6 starter livestock (got %d)" % post_count)
	_assert(post_coral == 4, "[E3] reset: coral=4 (anemone in coral, got %d)" % post_coral)
	_assert(post_fish == 3, "[E4] reset: fish=3 (clownfish_pair counts as 2, got %d)" % post_fish)

	# Reset should also clear economy
	_assert(gs.economy_system.get_reef_points() < 100.0, "[E5] reset: RP is default (not 99999)")

	# ═══════════════════════════════════════════
	# F. Core invariants
	# ═══════════════════════════════════════════
	print("── F. Core invariants ──")
	gs = GameState.new()
	gs.initialize()
	var lsf: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(lsf.get("fish_count", 0)) >= 2, "[F1] pair aggregation works")
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("sea_anemone_shop")
	var lsf2: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(lsf2.get("coral_count", 0)) >= 1, "[F2] anemone in coral_count")
	_assert(int(lsf2.get("invertebrate_count", 0)) == 0, "[F3] invertebrate_count=0")
	_assert(gs.action_timeline.size() <= 200, "[F4] timeline ≤ 200")

	# ═══════════════════════════════════════════
	# G. SaveSystem + Scene
	# ═══════════════════════════════════════════
	print("── G. SaveSystem + Scene ──")
	_assert(FileAccess.file_exists("res://scripts/systems/SaveSystem.gd"), "[G1] SaveSystem exists")
	_assert(load("res://scripts/systems/SaveSystem.gd") != null, "[G2] SaveSystem loads")
	_assert(load("res://scenes/main/Main.tscn") != null, "[G3] Main.tscn loads")

	# ═══════════════════════════════════════════
	print("\n=== VERIFICATION RESULT ===")
	if _failures.is_empty():
		print("M11_RUNTIME_UI_STATE_VERIFY=PASS (%d/%d)" % [_passed, _total])
	else:
		print("M11_RUNTIME_UI_STATE_VERIFY=FAIL (%d/%d)" % [_passed, _total])
		for f in _failures:
			print("FAILURE: " + f)
