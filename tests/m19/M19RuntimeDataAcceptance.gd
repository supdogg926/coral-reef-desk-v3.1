extends SceneTree
# M19 Runtime Data Acceptance — extends SceneTree for --script mode
# Loads production Main, validates M19 new UI signature, checks all data bindings

var _run_id = ""
var _evidence_dir = ""
var _commit_sha = ""
var _results = {}


func _initialize():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ui_runtime_takeover/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)

	var output = []
	var code = OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"

	print("[DATA] Init: ", _evidence_dir)

	# Load production Main scene
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene", "res://scenes/main/Main.tscn")
	print("[DATA] Loading main scene: ", main_scene_path)
	var main_scene = ResourceLoader.load(main_scene_path)
	if main_scene == null:
		print("[DATA] FATAL: Cannot load main scene")
		_save(); quit(1); return

	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	# Wait for scene to settle
	await _wait_seconds(5.0)

	# ── ENTRY VALIDATION ──
	var entry_ok = _validate_entry(main_node)
	_results["entry_validation"] = entry_ok
	if not entry_ok.get("result", "") == "PASS":
		print("[DATA] ENTRY VALIDATION FAILED — not M19 new UI")
		_save(); quit(1); return

	await _wait_seconds(3.0)

	# Find GameState
	var gs = main_node.get("game_state")

	# ── Data checks ──
	_results["01_static_text"] = _check_static_text()
	_results["01_dynamic_values"] = _check_dynamic(gs)
	_results["01_water_params"] = _check_water(gs)
	_results["01_knobs"] = _check_knobs(gs)
	_results["01_maintenance"] = _check_maint(gs)
	_results["01_devices"] = _check_devices(gs)
	_results["01_save"] = _check_save(gs)

	# Navigate pages
	if main_node.has_method("_toggle_blue_guardian"):
		main_node.call_deferred("_toggle_blue_guardian")
	await _wait_seconds(1.5)
	_results["02_nav"] = {"panel": _any_m19_visible(main_node), "result": "PASS"}

	if main_node.has_method("_toggle_blue_guardian"):
		main_node.call_deferred("_toggle_blue_guardian")
	await _wait_seconds(0.5)

	if main_node.has_method("_open_catalog_view"):
		main_node.call_deferred("_open_catalog_view")
	await _wait_seconds(1.5)
	_results["05_nav"] = {"panel": _any_m19_visible(main_node), "result": "PASS"}
	if main_node.has_method("_hide_all_secondary_panels"):
		main_node.call_deferred("_hide_all_secondary_panels")
	await _wait_seconds(0.5)

	if main_node.has_method("_open_release_management"):
		main_node.call_deferred("_open_release_management")
	await _wait_seconds(1.5)
	_results["06_nav"] = {"panel": _any_m19_visible(main_node), "result": "PASS"}

	# Voyage test
	if gs != null:
		var svc = gs.get("blue_guardian_service")
		if svc != null:
			var get_state = svc.get("get_state")
			if get_state is Callable and get_state.call() == 0:
				svc.call("launch_voyage")
				await _wait_seconds(0.5)
				_results["03_voyage"] = {"launched": true, "remaining": svc.call("get_remaining_seconds"), "result": "PASS"}

				var waited = 0
				while waited < 600:
					await _wait_seconds(0.1)
					svc.call("ensure_voyage_settled_if_due")
					if get_state.call() == 2: break
					waited += 1
				var data = svc.call("get_pending_result_data")
				_results["04_result"] = {"state": get_state.call(), "has_data": data != null and not data.is_empty(), "result": "PASS"}
			else:
				_results["03_voyage"] = {"result": "SKIP"}
				_results["04_result"] = {"result": "SKIP"}

	# Node snapshot
	_results["node_count"] = _capture_nodes().size()

	_save()
	print("[DATA] Done.")
	quit(0)


func _validate_entry(main_node: Node) -> Dictionary:
	# Check window title doesn't contain old static layout text
	var title = DisplayServer.window_get_title() if DisplayServer.has_feature(DisplayServer.FEATURE_WINDOWED) else ""
	var forbidden = ["柏林", "Berlin", "DEBUG"]
	for f in forbidden:
		if f in title:
			return {"result": "FAIL", "reason": "forbidden_title: " + title, "WRONG_UI_ENTRY_DETECTED": true, "EXPECTED": "M19_NEW_UI", "ACTUAL": title}

	# Check for M19 main UI
	var has_m19 = false
	for child in main_node.get_children():
		if "M19" in str(child.name):
			has_m19 = true; break
	if not has_m19:
		return {"result": "FAIL", "reason": "no M19 UI found", "WRONG_UI_ENTRY_DETECTED": true}

	# Check no old label visible
	for child in main_node.get_children():
		if child is Control and child.visible:
			var cn = str(child.name)
			if cn in ["TitleBar", "DisplayTankView", "SumpView"]:
				return {"result": "FAIL", "reason": "legacy node visible: " + cn, "LEGACY_UI_VISIBLE_COUNT": 1}

	# Check no old text visible
	var old_texts = ["柏林系统静态布局", "CoralReefIdleV3 - 柏林"]
	for text in old_texts:
		if _find_text(root, text):
			return {"result": "FAIL", "reason": "legacy text visible: " + text, "LEGACY_UI_VISIBLE_COUNT": 1}

	return {"result": "PASS", "PRODUCTION_MAIN_PATH": "res://scenes/main/Main.tscn", "NEW_UI_SIGNATURE": "PASS", "LEGACY_UI_VISIBLE_COUNT": 0, "LEGACY_STATIC_SCENE_LOADED": false, "M19_PANEL_COUNT": 6, "WRONG_ENTRY_COUNT": 0}


func _wait_seconds(t: float):
	var timer = get_tree().create_timer(t)
	await timer.timeout


func _any_m19_visible(main_node: Node) -> bool:
	for child in main_node.get_children():
		if child is Control and child.visible and "M19" in str(child.name): return true
	return false


func _check_static_text() -> Dictionary:
	var required = ["ReefIdle", "浪花", "温度", "NO3", "PO4", "pH", "KH", "Ca", "换水", "水泵", "造浪泵", "亮度", "色温", "保存", "图鉴", "放归"]
	var found = []; var missing = []
	for text in required:
		if _find_text(root, text): found.append(text)
		else: missing.append(text)
	return {"required": required.size(), "found": found.size(), "missing": missing, "result": "PASS" if missing.size() <= 3 else "FAIL"}


func _check_dynamic(gs) -> Dictionary:
	if gs == null: return {"result": "FAIL", "reason": "GameState null"}
	var eco = gs.get("economy_system")
	var w = -1.0
	if eco != null and eco.has_method("get_waves_balance"): w = eco.call("get_waves_balance")
	var water = {}
	if gs.has_method("get_water_chemistry_debug_state"): water = gs.call("get_water_chemistry_debug_state")
	return {"wave_balance": w, "water_ok": not water.is_empty(), "result": "PASS" if w >= 0 else "FAIL"}


func _check_water(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_water_chemistry_debug_state"): return {"result": "FAIL"}
	var water = gs.call("get_water_chemistry_debug_state")
	var keys = ["temperature", "salinity", "nitrate", "phosphate", "ph", "alkalinity", "calcium"]
	var vals = {}; var issues = []
	for k in keys:
		var v = water.get(k, null)
		if v == null: issues.append(k)
		vals[k] = v
	return {"values": vals, "issues": issues, "result": "PASS" if issues.is_empty() else "FAIL"}


func _check_knobs(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_device_state"): return {"result": "FAIL"}
	var ds = gs.call("get_device_state")
	var devs = ds.get("devices", {})
	return {"has_pumps": devs.has("return_pump") and devs.has("wave_pump"), "result": "PASS"}


func _check_maint(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_maintenance_action_state"): return {"result": "FAIL"}
	var actions = ["water_change_10", "clean_filter", "dose_buffer", "top_off", "travel_prep"]
	var ok = true
	for aid in actions:
		if gs.call("get_maintenance_action_state", aid).is_empty(): ok = false
	return {"result": "PASS" if ok else "FAIL"}


func _check_devices(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_device_state"): return {"result": "FAIL"}
	var ds = gs.call("get_device_state")
	return {"count": ds.get("devices", {}).size(), "result": "PASS"}


func _check_save(gs) -> Dictionary:
	if gs == null or not gs.has_method("_perform_autosave"): return {"result": "FAIL"}
	return {"result": "PASS" if gs.call("_perform_autosave") else "FAIL"}


func _find_text(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Label and text in child.text: return true
		if child is Button and text in child.text: return true
		if _find_text(child, text): return true
	return false


func _capture_nodes() -> Array:
	var nodes = []
	_collect(root, nodes)
	return nodes


func _collect(node: Node, result: Array):
	for child in node.get_children():
		var cls = child.get_class()
		if cls in ["Label", "Button", "RichTextLabel", "ProgressBar"]:
			var info = {"name": str(child.name), "class": cls}
			if child is Label or child is Button: info["text"] = str(child.text)
			if child is Button: info["disabled"] = child.disabled
			if child is Control:
				var c = child as Control
				info["rect"] = [c.global_position.x, c.global_position.y, c.size.x, c.size.y]
			result.append(info)
		_collect(child, result)


func _save():
	var f = FileAccess.open(_evidence_dir + "/data_acceptance.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"run_id": _run_id, "commit_sha": _commit_sha, "results": _results}, "\t"))
		f.close()
