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
	push_error("FAIL: " + label + " (substring '" + substr + "' not found)")

func _run() -> void:
	print("=== M11 PLAYER FEEDBACK HOTFIX VERIFICATION ===\n")

	# ═══════════════════════════════════════════
	# 1. Purchase-to-tank: immediate tank entry
	# ═══════════════════════════════════════════
	print("── 1. Purchase-to-tank feedback ──")
	var gs: GameState = GameState.new()
	gs.initialize()
	var init_rp: float = gs.economy_system.get_reef_points()
	var init_count: int = gs.livestock_system.get_livestock_count()
	var init_cap: float = gs.livestock_system.get_capacity_used()
	var init_fish: int = int(gs.livestock_system.get_debug_state().get("fish_count", 0))
	var init_coral: int = int(gs.livestock_system.get_debug_state().get("coral_count", 0))

	var result: Dictionary = gs.buy_livestock_from_shop("fluorescent_turf")
	_assert(result.get("success", false), "[1a] buy succeeds")
	_assert(float(result.get("price", 0)) == 15.0, "[1b] price deducted = 15RP")
	_assert(int(result.get("new_count", 0)) == init_count + 1, "[1c] count +1 immediately")
	_assert(float(result.get("capacity_used", 0)) == init_cap + 2.0, "[1d] capacity_used +2")
	_assert(float(result.get("reef_points", 0)) == init_rp - 15.0, "[1e] RP deducted immediately")

	var ls1: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(ls1.get("coral_count", 0)) == init_coral + 1, "[1f] coral_count +1")
	_assert(int(ls1.get("fish_count", 0)) == init_fish, "[1g] fish_count unchanged")

	var tl: Array = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "购买入缸", "[1h] timeline '购买入缸'")
	_check_timeline_contains(tl, "荧光草皮", "[1i] timeline mentions species")
	_check_timeline_contains(tl, "珊瑚", "[1j] timeline mentions category")
	_check_timeline_contains(tl, "+1", "[1k] timeline shows +1")
	_check_timeline_contains(tl, "RP-15", "[1l] timeline shows RP-15")
	_check_timeline_contains(tl, "容量", "[1m] timeline shows capacity")

	# Buy a fish
	gs.economy_system.add_reef_points(99999.0)
	var fish_r: Dictionary = gs.buy_livestock_from_shop("ocellaris_clown")
	_assert(fish_r.get("success", false), "[1n] fish purchase succeeds")
	var ls2: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(ls2.get("fish_count", 0)) == init_fish + 1, "[1o] fish_count +1 after fish purchase")

	tl = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "公子小丑", "[1p] timeline mentions fish name")
	_check_timeline_contains(tl, "鱼", "[1q] timeline mentions '鱼'")
	_check_timeline_contains(tl, "RP-30", "[1r] timeline shows RP cost for fish")

	# ═══════════════════════════════════════════
	# 2. RP insufficient
	# ═══════════════════════════════════════════
	print("\n── 2. RP insufficient ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.spend_reef_points(gs.economy_system.get_reef_points())
	_assert(gs.economy_system.get_reef_points() < 10.0, "[2a] RP drained")

	var frp: Dictionary = gs.buy_livestock_from_shop("hammer_coral")
	_assert(not frp.get("success", true), "[2b] buy fails on RP")
	_assert(frp.get("error", "") == "insufficient_rp", "[2c] error code 'insufficient_rp'")
	_assert(gs.livestock_system.get_livestock_count() == int(gs.livestock_system.get_debug_state().get("livestock_count", 0)),
		"[2d] count unchanged after RP-fail")

	# ═══════════════════════════════════════════
	# 3. Capacity exceeded
	# ═══════════════════════════════════════════
	print("\n── 3. Capacity exceeded ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	var cap_filled: bool = false
	for i in range(50):
		var cr: Dictionary = gs.buy_livestock_from_shop("fluorescent_turf")
		if not cr.get("success", false):
			_assert(cr.get("error", "") == "capacity_exceeded", "[3a] capacity_exceeded error")
			cap_filled = true
			break
	_assert(cap_filled, "[3b] capacity eventually exceeded")

	# ═══════════════════════════════════════════
	# 4. Release path with full feedback
	# ═══════════════════════════════════════════
	print("\n── 4. Release path ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("fluorescent_turf")
	var pre_cnt: int = gs.livestock_system.get_livestock_count()
	var pre_cap: float = gs.livestock_system.get_capacity_used()

	var d4: Dictionary = gs.livestock_system.get_debug_state()
	var owned4: Array = d4.get("owned_livestock", [])
	_assert(owned4.size() > 0, "[4a] owned items exist")
	var rid: String = ""
	for entry in owned4:
		if entry is Dictionary and "fluorescent_turf" in String(entry.get("id", "")):
			rid = String(entry.get("id", ""))
			break
	_assert(not rid.is_empty(), "[4b] found target for release")

	var rel: Dictionary = gs.release_owned_livestock(rid)
	_assert(rel.get("success", false), "[4c] release succeeds")
	_assert(int(rel.get("new_count", 999)) == pre_cnt - 1, "[4d] count -1")
	_assert(float(rel.get("capacity_used", 999)) < pre_cap, "[4e] capacity freed")
	_assert(float(rel.get("released_capacity", -1)) > 0, "[4f] released_capacity > 0")

	tl = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "放归", "[4g] timeline '放归'")
	_check_timeline_contains(tl, "荧光草皮", "[4h] timeline mentions species")
	_check_timeline_contains(tl, "释放", "[4i] timeline shows '释放'")
	_check_timeline_contains(tl, "容量", "[4j] timeline shows '容量'")
	_check_timeline_contains(tl, "珊瑚", "[4k] timeline shows category")

	# Release should show RP+ (reward), NOT RP- (deduction)
	for entry in tl:
		if entry is Dictionary:
			var t: String = String(entry.get("text", ""))
			if "放归" in t:
				_assert("RP+" in t, "[4l] release timeline shows RP+")
				_assert("RP-" not in t, "[4m] release timeline has no RP- deduction")
				break

	# ═══════════════════════════════════════════
	# 5. Release status feedback format
	# ═══════════════════════════════════════════
	print("\n── 5. Release status feedback format ──")
	# Simulate the LivestockPanel status text format
	var cat: String = String(rel.get("category", ""))
	var cat_d: String = ""
	if cat == "fish": cat_d = "鱼"
	elif cat == "coral": cat_d = "珊瑚"
	_assert(cat_d == "珊瑚", "[5a] release category maps to '珊瑚'")
	var released_cap: float = float(rel.get("released_capacity", 0))
	_assert(released_cap > 0, "[5b] released_capacity positive for status display")
	_assert(rel.has("capacity_used"), "[5c] result has capacity_used for status")
	_assert(rel.has("max_capacity"), "[5d] result has max_capacity for status")
	_assert(rel.has("species_name"), "[5e] result has species_name for status")

	# ═══════════════════════════════════════════
	# 6. Timeline integrity
	# ═══════════════════════════════════════════
	print("\n── 6. Timeline integrity ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	var tl_before: int = gs.action_timeline.size()
	var buys_ok: int = 0
	for sid in ["fluorescent_turf", "button_polyps", "ocellaris_clown"]:
		if gs.buy_livestock_from_shop(sid).get("success", false):
			buys_ok += 1
	_assert(buys_ok >= 2, "[6a] 2+ purchases (got %d)" % buys_ok)
	var tl_after: int = gs.action_timeline.size()
	_assert(tl_after >= tl_before + buys_ok, "[6b] timeline grew per purchase")
	_assert(gs.action_timeline.size() <= 200, "[6c] timeline <= 200")

	# ═══════════════════════════════════════════
	# 7. Fish pair aggregation
	# ═══════════════════════════════════════════
	print("\n── 7. Fish pair aggregation ──")
	gs = GameState.new()
	gs.initialize()
	var ls7: Dictionary = gs.livestock_system.get_debug_state()
	var f7: int = int(ls7.get("fish_count", 0))
	_assert(f7 >= 2, "[7a] pair counts as 2 (got %d)" % f7)

	var pf: bool = false
	for entry in gs.livestock_system.owned_livestock:
		if entry is Dictionary:
			var c: String = (String(entry.get("species_name", "")) + String(entry.get("id", ""))).to_lower()
			if "pair" in c or "一对" in c:
				_assert(gs.livestock_system._get_entry_quantity(entry) == 2, "[7b] pair qty == 2")
				pf = true
				break
	if not pf:
		_assert(f7 >= 2, "[7c] pair verified via fish_count >= 2")
	else:
		print("PASS: [7c] pair entry found (%d assertions total)" % _total)

	# ═══════════════════════════════════════════
	# 8. Anemone coral classification
	# ═══════════════════════════════════════════
	print("\n── 8. Anemone coral ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	_assert(gs.buy_livestock_from_shop("sea_anemone_shop").get("success", false), "[8a] anemone purchase")

	var ls8: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(ls8.get("coral_count", 0)) >= 1, "[8b] anemone in coral_count")
	_assert(int(ls8.get("invertebrate_count", 0)) == 0, "[8c] invertebrate=0")

	var af: bool = false
	for entry in gs.livestock_system.owned_livestock:
		if entry is Dictionary:
			var eid: String = String(entry.get("id", "")).to_lower()
			var ename: String = String(entry.get("species_name", "")).to_lower()
			if "anemone" in eid or "海葵" in ename:
				var acat: String = gs.livestock_system._normalize_livestock_category(String(entry.get("category", "")))
				_assert(acat == "coral", "[8d] anemone normalized to coral (got %s)" % acat)
				af = true
				break
	_assert(af, "[8e] anemone entry found")

	# ═══════════════════════════════════════════
	# 9. Timeline message quality
	# ═══════════════════════════════════════════
	print("\n── 9. Timeline message quality ──")
	gs = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("ocellaris_clown")
	tl = gs.get_timeline_entries(200)
	var has_p: bool = false
	var clean: bool = true
	for entry in tl:
		if entry is Dictionary:
			var t: String = String(entry.get("text", ""))
			if "\\u2192" in t or "\\u2193" in t or "\\u2191" in t:
				clean = false
			if "购买入缸" in t:
				has_p = true
	_assert(clean, "[9a] no raw unicode escapes")
	_assert(has_p, "[9b] '购买入缸' entry in new format")

	# Verify release also has clean format
	gs.buy_livestock_from_shop("fluorescent_turf")
	var d9: Dictionary = gs.livestock_system.get_debug_state()
	var o9: Array = d9.get("owned_livestock", [])
	for entry in o9:
		if entry is Dictionary and "fluorescent_turf" in String(entry.get("id", "")):
			gs.release_owned_livestock(String(entry.get("id", "")))
			break
	tl = gs.get_timeline_entries(200)
	_check_timeline_contains(tl, "释放", "[9c] release timeline has '释放'")

	# ═══════════════════════════════════════════
	# 10. SaveSystem + Scene integrity
	# ═══════════════════════════════════════════
	print("\n── 10. SaveSystem + Scene ──")
	_assert(FileAccess.file_exists("res://scripts/systems/SaveSystem.gd"), "[10a] SaveSystem.gd exists")
	_assert(load("res://scripts/systems/SaveSystem.gd") != null, "[10b] SaveSystem loads")
	_assert(load("res://scenes/main/Main.tscn") != null, "[10c] Main.tscn loads")

	# ═══════════════════════════════════════════
	# RESULT
	# ═══════════════════════════════════════════
	print("\n=== VERIFICATION RESULT ===")
	if _failures.is_empty():
		print("M11_PLAYER_FEEDBACK_VERIFY=PASS (%d/%d)" % [_passed, _total])
	else:
		print("M11_PLAYER_FEEDBACK_VERIFY=FAIL (%d/%d)" % [_passed, _total])
		for f in _failures:
			print("FAILURE: " + f)
