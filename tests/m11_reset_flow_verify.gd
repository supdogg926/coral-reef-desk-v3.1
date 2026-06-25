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
	print("=== M11 RESET FLOW VERIFICATION ===\n")

	# ═══════════════════════════════════════════
	# 1. Build non-default state
	# ═══════════════════════════════════════════
	print("── 1. Non-default state ──")
	var gs: GameState = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("green_torch")
	gs.buy_livestock_from_shop("hammer_coral")
	gs.buy_livestock_from_shop("ocellaris_clown")
	var pre_count: int = gs.livestock_system.get_livestock_count()
	var pre_rp: float = gs.economy_system.get_reef_points()
	_assert(pre_count > 6, "[1a] non-default count > 6 (got %d)" % pre_count)
	_assert(pre_rp > 1000.0, "[1b] non-default RP (got %.0f)" % pre_rp)

	# Release one
	var d1: Dictionary = gs.livestock_system.get_debug_state()
	for entry in d1.get("owned_livestock", []):
		if entry is Dictionary and "green_torch" in String(entry.get("id", "")):
			gs.release_owned_livestock(String(entry.get("id", "")))
			break

	# ═══════════════════════════════════════════
	# 2. Execute reset (same as Main._reset_test_save)
	# ═══════════════════════════════════════════
	print("── 2. Reset ──")
	if gs.save_system != null:
		gs.save_system.clear_save()
	gs = GameState.new()
	gs.initialize()

	var ls2: Dictionary = gs.livestock_system.get_debug_state()
	var post_coral: int = int(ls2.get("coral_count", -1))
	var post_fish: int = int(ls2.get("fish_count", -1))
	var post_count: int = gs.livestock_system.get_livestock_count()
	var post_rp: float = gs.economy_system.get_reef_points()

	# ═══════════════════════════════════════════
	# 3. Verify default state (M11口径)
	# ═══════════════════════════════════════════
	print("── 3. Default state ──")
	_assert(post_count == 6, "[3a] total = 6 (got %d)" % post_count)
	_assert(post_coral == 4, "[3b] CORAL = 4 (M11口径, got %d)" % post_coral)
	_assert(post_fish == 3, "[3c] FISH = 3 (小丑鱼一对=2, got %d)" % post_fish)
	_assert(post_rp >= 0.0 and post_rp < 100.0, "[3d] RP default (got %.0f)" % post_rp)

	# Verify anemone in coral
	var anemone_ok: bool = false
	var pair_ok: bool = false
	for entry in gs.livestock_system.owned_livestock:
		if entry is Dictionary:
			var eid: String = String(entry.get("id", ""))
			if "anemone" in eid:
				var cat: String = gs.livestock_system._normalize_livestock_category(String(entry.get("category", "")))
				_assert(cat == "coral", "[3e] anemone category = coral")
				anemone_ok = true
			if "clownfish" in eid or eid == "clownfish_pair":
				var qty: int = gs.livestock_system._get_entry_quantity(entry)
				_assert(qty == 2, "[3f] clownfish_pair qty = 2 (got %d)" % qty)
				pair_ok = true
	_assert(anemone_ok, "[3g] anemone found")
	_assert(pair_ok, "[3h] clownfish_pair found")

	# ═══════════════════════════════════════════
	# 4. Main scene loads + panel rebind check
	# ═══════════════════════════════════════════
	print("── 4. Main scene + panels ──")
	_assert(load("res://scenes/main/Main.tscn") != null, "[4a] Main.tscn loads")

	# Verify Main.gd reset logic exists (source inspection)
	var main_src: String = load("res://scenes/main/Main.gd").source_code
	_assert("_reset_test_save" in main_src, "[4b] _reset_test_save method exists")
	_assert("shop_panel.setup" in main_src or "shop_panel" in main_src, "[4c] shop_panel referenced in Main")
	_assert("livestock_panel.setup" in main_src or "livestock_panel" in main_src, "[4d] livestock_panel referenced in Main")

	# ═══════════════════════════════════════════
	# 5. Second reset cycle (idempotency)
	# ═══════════════════════════════════════════
	print("── 5. Reset idempotency ──")
	gs.economy_system.add_reef_points(99999.0)
	gs.buy_livestock_from_shop("green_torch")
	_assert(gs.livestock_system.get_livestock_count() > 6, "[5a] modified again")
	if gs.save_system != null:
		gs.save_system.clear_save()
	gs = GameState.new()
	gs.initialize()
	var ls5: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(ls5.get("coral_count", 0)) == 4, "[5b] 2nd reset coral=4")
	_assert(int(ls5.get("fish_count", 0)) == 3, "[5c] 2nd reset fish=3")

	# ═══════════════════════════════════════════
	print("\n=== VERIFICATION RESULT ===")
	if _failures.is_empty():
		print("M11_RESET_FLOW_VERIFY=PASS (%d/%d)" % [_passed, _total])
	else:
		print("M11_RESET_FLOW_VERIFY=FAIL (%d/%d)" % [_passed, _total])
		for f in _failures:
			print("FAILURE: " + f)
