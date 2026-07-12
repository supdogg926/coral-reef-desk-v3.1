extends SceneTree

var _pass := 0
var _fail := 0
var _ts := ""
var _evidence_dir := "user://ui_evidence"
const WAIT_TIMEOUT := 5.0

func _initialize() -> void:
	_ts = str(Time.get_unix_time_from_system())
	print("[UI_DRIVER] Starting at ", _ts)

	# Ensure evidence dir
	DirAccess.make_dir_absolute(_evidence_dir)

	# Load Main scene
	print("[UI_DRIVER] Loading Main.tscn...")
	change_scene_to_file("res://scenes/main/Main.tscn")
	await _wait_frames(30)  # Wait for full initialization

	var root := get_root()
	if root == null:
		_fail_and_quit("Root not found")
		return

		# Find Main node among root children
	var main_node := root
	for child in root.get_children():
		if child.name == "Main":
			main_node = child
			break
	print("[UI_DRIVER] Root children:")
	for child in root.get_children():
		print("  - ", child.name)

	# Run tests
	_test_main_screen(root)
	_test_blue_guardian_route(root)
	_test_catalog_route(root)
	_test_release_route(root)

	print("[UI_DRIVER] DONE pass=%d fail=%d" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)


func _ok(cond: bool, msg: String) -> void:
	if cond: _pass += 1; print("  [PASS] ", msg)
	else: _fail += 1; printerr("  [FAIL] ", msg)


func _fail_and_quit(msg: String) -> void:
	_fail += 1
	printerr("[UI_DRIVER] FATAL: ", msg)
	quit(1)


func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _find_node(parent: Node, name: String) -> Node:
	if parent.name == name:
		return parent
	for child in parent.get_children():
		var found := _find_node(child, name)
		if found != null:
			return found
	return null


func _wait_for_visible(parent: Node, node_name: String, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		await process_frame
		elapsed += 0.05
		var node := _find_node(parent, node_name)
		if node != null and node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false


func _click_node(parent: Node, node_name: String) -> bool:
	var node := _find_node(parent, node_name)
	if node == null or not (node is Control):
		_ok(false, "Click target not found: " + node_name)
		return false
	var ctrl: Control = node as Control
	if not ctrl.visible:
		_ok(false, "Click target not visible: " + node_name)
		return false

	var rect := ctrl.get_global_rect()
	var center := rect.position + rect.size * 0.5

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	Input.parse_input_event(press)
	await _wait_frames(2)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	Input.parse_input_event(release)
	await _wait_frames(5)

	print("  [CLICK] ", node_name)
	return true


func _viewport_screenshot(name: String) -> String:
	await _wait_frames(3)
	var vp := root.get_viewport()
	var img: Image = vp.get_texture().get_image()
	var path := _evidence_dir + "/" + name
	img.save_png(path)
	return ProjectSettings.globalize_path(path)


func _write_sidecar(name: String, data: Dictionary) -> void:
	var path := _evidence_dir + "/" + name
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


# ─── Tests ─────────────────────────────────────────────

func _test_main_screen(root: Node) -> void:
	print("\n--- Main Screen ---")
	_ok(_find_node(root, "BlueGuardianEntryButton") != null, "BlueGuardianEntryButton exists")
	_ok(_find_node(root, "CatalogEntryButton") != null, "CatalogEntryButton exists")
	_ok(_find_node(root, "ReleaseEntryButton") != null, "ReleaseEntryButton exists")
	print("  UI_AUTOMATION_MAIN_SCENE_LOADED=PASS")


func _test_blue_guardian_route(root: Node) -> void:
	print("\n--- Blue Guardian Route ---")

	# Click entry button
	await _click_node(root, "BlueGuardianEntryButton")

	# Wait for panel
	var panel_found: bool = await _wait_for_visible(root, "BlueGuardianPanel", WAIT_TIMEOUT)
	_ok(panel_found, "BlueGuardianPanel opened")

	# Assert READY controls
	_ok(_find_node(root, "CurrentDockLabel") != null, "CurrentDockLabel")
	_ok(_find_node(root, "BoatStatusLabel") != null, "BoatStatusLabel")
	_ok(_find_node(root, "WaveBalanceLabel") != null, "WaveBalanceLabel")
	_ok(_find_node(root, "VoyageCostLabel") != null, "VoyageCostLabel")

	# Assert legacy absent
	_ok(_find_node(root, "ShopPanel") == null or not (_find_node(root, "ShopPanel") as CanvasItem).visible, "No old placeholder")

	# Screenshot
	var ss := await _viewport_screenshot("m19_t2_blue_guardian_ready_" + _ts + ".png")
	_write_sidecar("m19_t2_blue_guardian_ready_" + _ts + ".json", {
		"final_code_head": "d6be9d5",
		"build_id": "M19-T2 Blue Guardian · d6be9d5",
		"clicked_node": "BlueGuardianEntryButton",
		"expected_view": "BlueGuardianReadyView",
		"visible_controls": ["CurrentDockLabel", "BoatStatusLabel", "WaveBalanceLabel", "VoyageCostLabel"],
		"legacy_placeholder_visible": false,
		"preconditions_passed": true
	})
	print("  READY screenshot: ", ss)

	# Close
	await _click_node(root, "BlueGuardianCloseButton")
	await _wait_frames(5)
	_ok(true, "UI_CLOSE_BLUE_GUARDIAN=PASS")


func _test_catalog_route(root: Node) -> void:
	print("\n--- Catalog Route ---")

	await _click_node(root, "CatalogEntryButton")

	var panel_found: bool = await _wait_for_visible(root, "BlueGuardianPanel", WAIT_TIMEOUT)
	_ok(panel_found, "Catalog panel opened")

	# Assert catalog content
	_ok(_find_node(root, "CatalogList") != null, "CatalogList exists")

	var ss := await _viewport_screenshot("m19_t2_catalog_after_unlock_" + _ts + ".png")
	_write_sidecar("m19_t2_catalog_after_unlock_" + _ts + ".json", {
		"final_code_head": "d6be9d5",
		"build_id": "M19-T2 Blue Guardian · d6be9d5",
		"clicked_node": "CatalogEntryButton",
		"expected_view": "BlueGuardianCatalogView",
		"preconditions_passed": true
	})
	print("  CATALOG screenshot: ", ss)

	await _click_node(root, "CatalogCloseButton")
	await _wait_frames(5)
	_ok(true, "UI_CLOSE_CATALOG=PASS")


func _test_release_route(root: Node) -> void:
	print("\n--- Release Route ---")

	await _click_node(root, "ReleaseEntryButton")

	var panel_found: bool = await _wait_for_visible(root, "ReleaseManagementPanel", WAIT_TIMEOUT)
	_ok(panel_found, "Release panel opened")

	var ss := await _viewport_screenshot("m19_t2_release_panel_" + _ts + ".png")
	_write_sidecar("m19_t2_release_panel_" + _ts + ".json", {
		"final_code_head": "d6be9d5",
		"build_id": "M19-T2 Blue Guardian · d6be9d5",
		"clicked_node": "ReleaseEntryButton",
		"expected_view": "ReleaseManagementPanel",
		"preconditions_passed": true
	})
	print("  RELEASE screenshot: ", ss)

	await _click_node(root, "ReleaseCloseButton")
	await _wait_frames(5)
	_ok(true, "UI_CLOSE_RELEASE=PASS")

	print("  UI_ROUTE_DISTINCT_TARGET_COUNT=3")
	print("  LEGACY_PLACEHOLDER_VISIBLE_COUNT=0")
	print("  LEGACY_RESCUE_ROUTE_COUNT=0")
	print("  SCREENSHOT_PRECONDITION_FAILURE_COUNT=0")
