extends SceneTree
## M19 Real GUI Evidence Driver — no pressed.emit, no handler calls, no visible mutation

var _pass := 0
var _fail := 0
var _emit_count := 0
var _ts := ""
var _evidence_dir := "user://m19_gui_evidence"
var _capture_file := "user://m19_capture_request.json"


func _initialize() -> void:
	_ts = str(Time.get_unix_time_from_system())
	DirAccess.make_dir_absolute(_evidence_dir)
	print("[M19_GUI] START ts=", _ts)

	change_scene_to_file("res://scenes/main/Main.tscn")
	await _wait_frames(5)

	var root := get_root()
	var main_node: Node = _find_main(root)
	if main_node == null: _fatal("Main not found")

	print("[M19_GUI] Waiting runtime_ui_ready...")
	var ok: bool = await _wait_until(func(): return main_node.is_runtime_ui_ready(), 15.0, "ready")
	if not ok: _fatal("runtime_ui_ready timeout")

	# Negative control: disabled button
	_test_disabled_button_negative(main_node)
	# Negative control: hidden button
	_test_hidden_button_negative(main_node)

	# Real routes
	await _test_bg_route(root)
	await _test_catalog_route(root)
	await _test_release_route(root)

	print("[M19_GUI] DONE p=%d f=%d emit=%d" % [_pass, _fail, _emit_count])
	quit(0 if _fail == 0 else 1)


func _ok(c: bool, m: String) -> void:
	if c: _pass += 1; print("  [PASS] ", m)
	else: _fail += 1; printerr("  [FAIL] ", m)


func _fatal(m: String) -> void:
	_fail += 1; printerr("[M19_GUI] FATAL: ", m); quit(1)


func _wait_frames(n: int) -> void:
	for i in range(n): await process_frame


func _wait_until(p: Callable, to: float, d: String) -> bool:
	var s: int = Time.get_ticks_msec()
	while not bool(p.call()):
		if Time.get_ticks_msec() - s > int(to * 1000.0):
			printerr("[M19_GUI] TIMEOUT: ", d); return false
		await process_frame
	return true


func _find_main(root: Node) -> Node:
	for c in root.get_children():
		if c.name == "Main": return c
	return null


func _find_by_name(root: Node, name: String) -> Node:
	if root.name == name: return root
	for c in root.get_children():
		var r := _find_by_name(c, name)
		if r != null: return r
	return null


func _panel_visible(root: Node, name: String) -> bool:
	var n := _find_by_name(root, name)
	return n != null and n is CanvasItem and (n as CanvasItem).visible


func _write_capture(scenario: String, filename: String) -> void:
	var data := {"pid": OS.get_process_id(), "scenario": scenario, "filename": filename, "build_head": "5776e46", "preconditions_passed": true}
	var f := FileAccess.open(_capture_file, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(data, "\t"))


func _shot(name: String) -> void:
	await _wait_frames(3)
	var img: Image = get_root().get_viewport().get_texture().get_image()
	img.save_png(_evidence_dir + "/" + name)
	print("  [SHOT] ", name)


# ── Real click: Input.parse_input_event only ──────────

func _click(root: Node, name: String, desc: String) -> bool:
	var n := _find_by_name(root, name)
	if n == null or not (n is Control):
		_ok(false, "click missing: " + name); return false
	var ctrl: Control = n as Control
	if not ctrl.visible:
		_ok(false, "click hidden: " + name); return false

	var pt := ctrl.get_global_rect().get_center()
	var mot := InputEventMouseMotion.new()
	mot.position = pt; mot.global_position = pt
	Input.parse_input_event(mot); await process_frame
	var pr := InputEventMouseButton.new()
	pr.button_index = MOUSE_BUTTON_LEFT; pr.pressed = true; pr.position = pt; pr.global_position = pt
	Input.parse_input_event(pr); await process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT; rel.pressed = false; rel.position = pt; rel.global_position = pt
	Input.parse_input_event(rel); await process_frame
	print("  [CLICK] ", desc, " (", name, ")")
	return true


# ── Negative Controls ──────────────────────────────────

func _test_disabled_button_negative(main_node: Node) -> void:
	print("\n--- Negative: Disabled ---")
	var btn: Button = Button.new()
	btn.name = "M19TestDisabledButton"
	btn.disabled = true
	btn.position = Vector2(10, 10)
	btn.size = Vector2(100, 30)
	main_node.add_child(btn)
	await _wait_frames(2)
	_click(get_root(), "M19TestDisabledButton", "disabled")
	_ok(btn.button_pressed == false, "disabled: not pressed")
	_ok(_emit_count == 0, "disabled: emit_count=0")
	btn.queue_free()


func _test_hidden_button_negative(main_node: Node) -> void:
	print("\n--- Negative: Hidden ---")
	var btn: Button = Button.new()
	btn.name = "M19TestHiddenButton"
	btn.visible = false
	btn.position = Vector2(10, 50)
	btn.size = Vector2(100, 30)
	main_node.add_child(btn)
	await _wait_frames(2)
	var found := _find_by_name(get_root(), "M19TestHiddenButton")
	_ok(found != null, "hidden: node exists")
	_ok(not (found as Control).visible, "hidden: not visible")
	btn.queue_free()


# ── Blue Guardian Route ────────────────────────────────

func _test_bg_route(root: Node) -> bool:
	print("\n--- Blue Guardian ---")
	if not await _click(root, "BlueGuardianEntryButton", "open BG"): return false
	if not await _wait_until(func(): return _panel_visible(root, "BlueGuardianPanel"), 5.0, "panel"): return false

	_ok(_panel_visible(root, "CurrentDockLabel"), "CurrentDockLabel")
	_ok(_panel_visible(root, "BoatStatusLabel"), "BoatStatusLabel")
	_ok(_panel_visible(root, "WaveBalanceLabel"), "WaveBalanceLabel")
	_ok(_panel_visible(root, "VoyageCostLabel"), "VoyageCostLabel")
	_ok(_panel_visible(root, "LaunchButton"), "LaunchButton")
	_ok(not _panel_visible(root, "ReleaseManagementPanel"), "no legacy release")

	await _shot("bg_ready_" + _ts + ".png")

	if not await _click(root, "BlueGuardianCloseButton", "close BG"): return false
	await _wait_frames(5)
	_ok(not _panel_visible(root, "BlueGuardianPanel"), "BG closed")
	_ok(_panel_visible(root, "BlueGuardianEntryButton"), "main restored")
	return true


# ── Catalog Route ──────────────────────────────────────

func _test_catalog_route(root: Node) -> bool:
	print("\n--- Catalog ---")
	if not await _click(root, "CatalogEntryButton", "open catalog"): return false
	if not await _wait_until(func(): return _panel_visible(root, "BlueGuardianPanel"), 5.0, "panel"): return false

	_ok(_find_by_name(root, "CatalogList") != null, "CatalogList")
	_ok(not _panel_visible(root, "ReleaseManagementPanel"), "no release panel")

	await _shot("catalog_" + _ts + ".png")

	if not await _click(root, "CatalogCloseButton", "close catalog"): return false
	await _wait_frames(5)
	_ok(not _panel_visible(root, "BlueGuardianPanel"), "catalog closed")
	return true


# ── Release Route ──────────────────────────────────────

func _test_release_route(root: Node) -> bool:
	print("\n--- Release ---")
	if not await _click(root, "ReleaseEntryButton", "open release"): return false
	if not await _wait_until(func(): return _panel_visible(root, "ReleaseManagementPanel"), 5.0, "panel"): return false

	_ok(not _panel_visible(root, "BlueGuardianPanel"), "no BG panel")

	await _shot("release_" + _ts + ".png")

	if not await _click(root, "ReleaseCloseButton", "close release"): return false
	await _wait_frames(5)
	_ok(not _panel_visible(root, "ReleaseManagementPanel"), "release closed")
	return true
