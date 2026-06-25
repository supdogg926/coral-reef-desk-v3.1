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
	print("=== M11 UI LAYOUT VERIFICATION ===\n")

	# ═══════════════════════════════════════════
	# 1. Scene loading
	# ═══════════════════════════════════════════
	print("── 1. Scene structure ──")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(main_scene != null, "[1a] Main.tscn loaded")

	# Instantiate to verify nodes exist (no async needed)
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	_assert(main != null, "[1b] Main instantiated")

	var status_panel = main.get_node_or_null("RootMargin/Layout/StatusPanel")
	_assert(status_panel != null, "[1c] StatusPanel node exists")

	var layout = main.get_node_or_null("RootMargin/Layout")
	_assert(layout != null, "[1d] Layout VBox exists")

	# ═══════════════════════════════════════════
	# 2. Script source quality checks
	# ═══════════════════════════════════════════
	print("── 2. Script source checks ──")
	var sp_src: String = load("res://scenes/ui/StatusPanel.gd").source_code
	_assert("\\u2192" not in sp_src, "[2a] StatusPanel: no \\u2192 escapes")
	_assert("\\u2193" not in sp_src, "[2b] StatusPanel: no \\u2193 escapes")

	var sh_src: String = load("res://scenes/ui/ShopPanel.gd").source_code
	_assert("set_process(true)" in sh_src, "[2c] ShopPanel: set_process(true) present")
	_assert("_process" in sh_src, "[2d] ShopPanel: _process defined")
	_assert("_refresh_button_tooltips" in sh_src, "[2e] ShopPanel: refresh function defined")

	var gs_src: String = load("res://scripts/systems/GameState.gd").source_code
	_assert("购买入缸" in gs_src, "[2f] GameState: '购买入缸' in source")
	_assert("RP-" in gs_src, "[2g] GameState: 'RP-' in source")
	_assert("释放" in gs_src, "[2h] GameState: '释放' in source")

	main.queue_free()

	# ═══════════════════════════════════════════
	# 3. Timeline format
	# ═══════════════════════════════════════════
	print("── 3. Timeline format ──")
	var gs: GameState = GameState.new()
	gs.initialize()
	gs.economy_system.add_reef_points(99999.0)

	gs.buy_livestock_from_shop("green_torch")
	var tl: Array = gs.get_timeline_entries(200)
	var last: Variant = tl[tl.size() - 1]
	var lt: String = String(last.get("text", "")) if last is Dictionary else ""
	_assert("购买入缸" in lt, "[3a] purchase: '购买入缸'")
	_assert("RP-" in lt, "[3b] purchase: RP-")
	_assert("容量" in lt, "[3c] purchase: 容量")

	var d3: Dictionary = gs.livestock_system.get_debug_state()
	for entry in d3.get("owned_livestock", []):
		if entry is Dictionary and "green_torch" in String(entry.get("id", "")):
			gs.release_owned_livestock(String(entry.get("id", "")))
			break
	tl = gs.get_timeline_entries(200)
	last = tl[tl.size() - 1]
	lt = String(last.get("text", "")) if last is Dictionary else ""
	_assert("放归" in lt, "[3d] release: '放归'")
	_assert("RP+" in lt, "[3e] release: RP+")
	_assert("释放" in lt, "[3f] release: '释放'")
	_assert("容量" in lt, "[3g] release: 容量")

	# ═══════════════════════════════════════════
	# 4. Default state
	# ═══════════════════════════════════════════
	print("── 4. Default state ──")
	gs = GameState.new()
	gs.initialize()
	var ls4: Dictionary = gs.livestock_system.get_debug_state()
	_assert(int(ls4.get("coral_count", 0)) == 4, "[4a] CORAL=4")
	_assert(int(ls4.get("fish_count", 0)) == 3, "[4b] FISH=3")
	_assert(int(ls4.get("invertebrate_count", 0)) == 0, "[4c] invertebrate=0")
	_assert(gs.livestock_system.get_livestock_count() == 6, "[4d] total=6")

	# ═══════════════════════════════════════════
	# 5. SaveSystem
	# ═══════════════════════════════════════════
	print("── 5. SaveSystem ──")
	_assert(FileAccess.file_exists("res://scripts/systems/SaveSystem.gd"), "[5a] SaveSystem exists")
	_assert(load("res://scripts/systems/SaveSystem.gd") != null, "[5b] SaveSystem loads")

	# ═══════════════════════════════════════════
	print("\n=== VERIFICATION RESULT ===")
	if _failures.is_empty():
		print("M11_UI_LAYOUT_VERIFY=PASS (%d/%d)" % [_passed, _total])
	else:
		print("M11_UI_LAYOUT_VERIFY=FAIL (%d/%d)" % [_passed, _total])
		for f in _failures:
			print("FAILURE: " + f)
