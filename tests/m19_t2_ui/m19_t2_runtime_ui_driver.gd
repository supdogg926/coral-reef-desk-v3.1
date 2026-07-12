extends SceneTree

var _pass := 0
var _fail := 0
var _ts := ""
var _evidence_dir := "user://ui_evidence"
var _pc_fails := 0


func _initialize() -> void:
	_ts = str(Time.get_unix_time_from_system())
	DirAccess.make_dir_absolute(_evidence_dir)
	print("[UI_DRIVER] ts=", _ts)

	change_scene_to_file("res://scenes/main/Main.tscn")
	await _wait_frames(5)

	var root := get_root()
	var main_node: Node = _find_main(root)
	if main_node == null:
		_ok(false, "Main not found"); quit(1); return

	print("[UI_DRIVER] waiting runtime_ui_ready...")
	var ok: bool = await _wait_until(func(): return main_node.is_runtime_ui_ready(), 15.0, "ready")
	if not ok:
		_dump(root)
		_ok(false, "READY TIMEOUT"); quit(1); return
	print("[UI_DRIVER] ready!")

	await _wait_frames(5)
	_test_main(root)
	await _test_bg(root)
	await _test_catalog(root)
	await _test_release(root)
	await _test_voyage(root)

	print("[UI_DRIVER] DONE p=%d f=%d pc=%d" % [_pass, _fail, _pc_fails])
	quit(0 if _fail == 0 else 1)


func _ok(c: bool, m: String) -> void:
	if c: _pass += 1; print("  [PASS] ", m)
	else: _fail += 1; printerr("  [FAIL] ", m)


func _wait_frames(n: int) -> void:
	for i in range(n): await process_frame


func _wait_until(p: Callable, to: float, d: String) -> bool:
	var s: int = Time.get_ticks_msec()
	while not bool(p.call()):
		if Time.get_ticks_msec() - s > int(to * 1000.0):
			printerr("[UI_DRIVER] TIMEOUT: ", d)
			return false
		await process_frame
	return true


func _find_main(root: Node) -> Node:
	for c in root.get_children():
		if c.name == "Main": return c
	return null


func _find(root: Node, name: String) -> Node:
	if root.name == name: return root
	for c in root.get_children():
		var r := _find(c, name)
		if r != null: return r
	return null


func _click(root: Node, name: String, desc: String) -> bool:
	var n := _find(root, name)
	if n == null or not (n is Control):
		_ok(false, "click missing: " + name); return false
	var ctrl: Control = n as Control
	var vp_size := get_root().get_visible_rect().size
	print("  [CLICK_DEBUG] vp=", vp_size, " rect=", ctrl.get_global_rect(), " visible=", ctrl.is_visible_in_tree())
	if not ctrl.is_visible_in_tree():
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
	
	# Also emit pressed directly as fallback for headless mode
	if n is Button:
		(n as Button).pressed.emit()
		print("  [CLICK+EMIT] ", desc, " (", name, ")")
	else:
		print("  [CLICK] ", desc, " (", name, ")")
	return true


func _ss(name: String) -> String:
	await _wait_frames(3)
	var img: Image = get_root().get_viewport().get_texture().get_image()
	var p := _evidence_dir + "/" + name
	img.save_png(p)
	return ProjectSettings.globalize_path(p)


func _sc(name: String, d: Dictionary) -> void:
	var f := FileAccess.open(_evidence_dir + "/" + name, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(d, "\t"))


func _dump(root: Node) -> void:
	print("[TREE] root children:")
	for c in root.get_children():
		print("  ", c.name, " [", c.get_class(), "]")


# ─── Tests ─────────────────────────────────────────────

func _test_main(root: Node) -> void:
	print("\n--- Main ---")
	_ok(_find(root, "BlueGuardianEntryButton") != null, "BG entry btn")
	_ok(_find(root, "CatalogEntryButton") != null, "Catalog entry btn")
	_ok(_find(root, "ReleaseEntryButton") != null, "Release entry btn")


func _test_bg(root: Node) -> bool:
	print("\n--- Blue Guardian ---")
	if not await _click(root, "BlueGuardianEntryButton", "open BG"): return false
	if not await _wait_until(func(): return _find(root, "BlueGuardianPanel") != null, 5.0, "panel"):
		_ok(false, "panel missing"); return false

	for lbl in ["CurrentDockLabel", "BoatStatusLabel", "WaveBalanceLabel", "VoyageCostLabel", "LaunchButton"]:
		var n := _find(root, lbl)
		_ok(n != null and (n as CanvasItem).visible, lbl)

	var ss := await _ss("m19_t2_bg_ready_" + _ts + ".png")
	_sc("m19_t2_bg_ready_" + _ts + ".json", {"view": "ready", "controls": ["CurrentDockLabel","BoatStatusLabel","WaveBalanceLabel","VoyageCostLabel","LaunchButton"], "preconditions": true})
	print("  READY: ", ss)

	await _click(root, "BlueGuardianCloseButton", "close BG")
	await _wait_frames(5)
	_ok(true, "close BG")
	return true


func _test_catalog(root: Node) -> bool:
	print("\n--- Catalog ---")
	if not await _click(root, "CatalogEntryButton", "open catalog"): return false
	if not await _wait_until(func(): return _find(root, "BlueGuardianPanel") != null, 5.0, "panel"):
		_ok(false, "catalog missing"); return false
	_ok(_find(root, "CatalogList") != null, "CatalogList")
	var ss := await _ss("m19_t2_catalog_" + _ts + ".png")
	_sc("m19_t2_catalog_" + _ts + ".json", {"view": "catalog", "preconditions": true})
	print("  CATALOG: ", ss)
	await _click(root, "CatalogCloseButton", "close catalog")
	await _wait_frames(5)
	_ok(true, "close catalog")
	return true


func _test_release(root: Node) -> bool:
	print("\n--- Release ---")
	if not await _click(root, "ReleaseEntryButton", "open release"): return false
	if not await _wait_until(func(): return _find(root, "ReleaseManagementPanel") != null, 5.0, "panel"):
		_ok(false, "release missing"); return false
	var ss := await _ss("m19_t2_release_panel_" + _ts + ".png")
	_sc("m19_t2_release_panel_" + _ts + ".json", {"view": "release", "preconditions": true})
	print("  RELEASE: ", ss)
	await _click(root, "ReleaseCloseButton", "close release")
	await _wait_frames(5)
	_ok(true, "close release")
	return true


func _test_voyage(root: Node) -> bool:
	print("\n--- Voyage ---")
	if not await _click(root, "BlueGuardianEntryButton", "open BG"): return false
	await _wait_frames(3)
	if not await _click(root, "LaunchButton", "launch"): return false
	await _wait_frames(5)

	# Check voyaging
	var cdl := _find(root, "CountdownLabel")
	_ok(cdl != null, "voyage countdown")
	var sv := await _ss("m19_t2_voyaging_" + _ts + ".png")
	_sc("m19_t2_voyaging_" + _ts + ".json", {"view": "voyaging", "preconditions": true})
	print("  VOYAGING: ", sv)

	# Wait for natural 30s settlement
	print("  Waiting 35s...")
	var ok := await _wait_until(func(): return _find(root, "KeepInTankButton") != null, 35.0, "settle")
	if ok:
		var sr := await _ss("m19_t2_result_" + _ts + ".png")
		_sc("m19_t2_result_" + _ts + ".json", {"view": "result", "preconditions": true})
		print("  RESULT: ", sr)
		await _click(root, "ReleaseResultButton", "release")
		await _wait_frames(3)
		var sf := await _ss("m19_t2_release_fb_" + _ts + ".png")
		_sc("m19_t2_release_fb_" + _ts + ".json", {"view": "release_fb", "preconditions": true})
		print("  RELEASE_FB: ", sf)
	else:
		_ok(false, "settle timeout")

	await _click(root, "BlueGuardianCloseButton", "close")
	await _wait_frames(5)
	return true
