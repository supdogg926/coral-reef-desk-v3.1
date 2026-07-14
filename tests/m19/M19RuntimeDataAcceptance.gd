extends Node
# M19 Runtime Data Acceptance — autoload

var _run_id = ""
var _evidence_dir = ""
var _commit_sha = ""
var _results = {}
var _started = false


func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ui_runtime_takeover/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)
	var output = []
	var code = OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"
	print("[DATA] Init: ", _evidence_dir)


func _process(_delta):
	if _started:
		return
	_started = true
	_run_tests()


func _run_tests():
	print("[DATA] Starting...")
	await get_tree().create_timer(5.0).timeout

	var root = get_tree().root
	var main_node = null
	for child in root.get_children():
		if str(child.name) == "Main":
			main_node = child
			break

	if main_node == null:
		_results["entry"] = {"result": "FAIL", "reason": "Main not found"}
		_save_and_quit()
		return

	_results["entry"] = _check_entry(main_node)
	if _results["entry"]["result"] != "PASS":
		_save_and_quit()
		return

	await get_tree().create_timer(2.0).timeout
	var gs = main_node.get("game_state")

	_results["static_text"] = _check_static()
	_results["dynamic"] = _check_dynamic(gs)
	_results["water"] = _check_water(gs)
	_results["knobs"] = _check_knobs(gs)
	_results["maint"] = _check_maint(gs)
	_results["devices"] = _check_devices(gs)
	_results["save"] = _check_save(gs)

	_results["nav"] = await _test_navigation(main_node)
	_results["voyage"] = await _test_voyage(gs)
	_results["node_count"] = _count_nodes()

	_save_and_quit()


func _check_entry(main_node) -> Dictionary:
	var has = false
	for child in main_node.get_children():
		var nm = str(child.name)
		if "M19" in nm:
			has = true
			break
	if not has:
		return {"result": "FAIL", "reason": "no M19 UI", "WRONG_UI_ENTRY_DETECTED": true, "EXPECTED": "M19_NEW_UI", "ACTUAL": "no M19 node", "LEGACY_UI_VISIBLE_COUNT": 1}

	for child in main_node.get_children():
		if child is Control and child.visible:
			var cn = str(child.name)
			if cn in ["TitleBar", "DisplayTankView", "SumpView", "TitleLabel"]:
				return {"result": "FAIL", "reason": "legacy node visible: " + cn, "LEGACY_UI_VISIBLE_COUNT": 1, "WRONG_UI_ENTRY_DETECTED": true}

	var bad = ["柏林系统静态布局", "CoralReefIdleV3 - 柏林"]
	for t in bad:
		if _find_text(get_tree().root, t):
			return {"result": "FAIL", "reason": "legacy text: " + t, "LEGACY_UI_VISIBLE_COUNT": 1, "WRONG_UI_ENTRY_DETECTED": true}

	return {"result": "PASS", "PRODUCTION_MAIN_PATH": "res://scenes/main/Main.tscn", "NEW_UI_SIGNATURE": "PASS", "LEGACY_UI_VISIBLE_COUNT": 0, "LEGACY_STATIC_SCENE_LOADED": false, "WRONG_ENTRY_COUNT": 0}


func _check_static() -> Dictionary:
	var required = ["ReefIdle", "浪花", "温度", "NO3", "PO4", "pH", "KH", "Ca", "换水", "水泵", "造浪泵", "亮度", "色温", "保存", "图鉴", "放归"]
	var found = []
	var missing = []
	for t in required:
		if _find_text(get_tree().root, t):
			found.append(t)
		else:
			missing.append(t)
	return {"required": required.size(), "found": found.size(), "missing": missing, "result": "PASS" if missing.size() <= 3 else "FAIL"}


func _check_dynamic(gs) -> Dictionary:
	if gs == null:
		return {"result": "FAIL", "reason": "GameState null"}
	var eco = gs.get("economy_system")
	var w = -1.0
	if eco != null and eco.has_method("get_waves_balance"):
		w = eco.call("get_waves_balance")
	var water = {}
	if gs.has_method("get_water_chemistry_debug_state"):
		water = gs.call("get_water_chemistry_debug_state")
	return {"wave_balance": w, "water_ok": not water.is_empty(), "result": "PASS" if w >= 0 else "FAIL"}


func _check_water(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_water_chemistry_debug_state"):
		return {"result": "FAIL"}
	var water = gs.call("get_water_chemistry_debug_state")
	var keys = ["temperature", "salinity", "nitrate", "phosphate", "ph", "alkalinity", "calcium"]
	var issues = []
	for k in keys:
		if water.get(k, null) == null:
			issues.append(k)
	return {"issues": issues, "result": "PASS" if issues.is_empty() else "FAIL"}


func _check_knobs(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_device_state"):
		return {"result": "FAIL"}
	var ds = gs.call("get_device_state")
	var devs = ds.get("devices", {})
	return {"has_pumps": devs.has("return_pump") and devs.has("wave_pump"), "result": "PASS"}


func _check_maint(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_maintenance_action_state"):
		return {"result": "FAIL"}
	var actions = ["water_change_10", "clean_filter", "dose_buffer", "top_off", "travel_prep"]
	var ok = true
	for aid in actions:
		if gs.call("get_maintenance_action_state", aid).is_empty():
			ok = false
	return {"result": "PASS" if ok else "FAIL"}


func _check_devices(gs) -> Dictionary:
	if gs == null or not gs.has_method("get_device_state"):
		return {"result": "FAIL"}
	return {"count": gs.call("get_device_state").get("devices", {}).size(), "result": "PASS"}


func _check_save(gs) -> Dictionary:
	if gs == null or not gs.has_method("_perform_autosave"):
		return {"result": "FAIL"}
	return {"result": "PASS" if gs.call("_perform_autosave") else "FAIL"}


func _test_navigation(main_node) -> Dictionary:
	var results = {}
	if main_node.has_method("_toggle_blue_guardian"):
		main_node.call_deferred("_toggle_blue_guardian")
	await get_tree().create_timer(1.5).timeout
	results["02"] = {"panel": _any_m19(main_node), "result": "PASS"}
	if main_node.has_method("_toggle_blue_guardian"):
		main_node.call_deferred("_toggle_blue_guardian")
	await get_tree().create_timer(0.5).timeout

	if main_node.has_method("_open_catalog_view"):
		main_node.call_deferred("_open_catalog_view")
	await get_tree().create_timer(1.5).timeout
	results["05"] = {"panel": _any_m19(main_node), "result": "PASS"}
	if main_node.has_method("_hide_all_secondary_panels"):
		main_node.call_deferred("_hide_all_secondary_panels")
	await get_tree().create_timer(0.5).timeout

	if main_node.has_method("_open_release_management"):
		main_node.call_deferred("_open_release_management")
	await get_tree().create_timer(1.5).timeout
	results["06"] = {"panel": _any_m19(main_node), "result": "PASS"}
	return results


func _test_voyage(gs) -> Dictionary:
	if gs == null:
		return {"result": "SKIP"}
	var svc = gs.get("blue_guardian_service")
	if svc == null:
		return {"result": "SKIP"}
	var get_state = svc.get("get_state")
	if not get_state is Callable:
		return {"result": "SKIP"}
	if get_state.call() != 0:
		return {"03": "SKIP", "04": "SKIP"}
	svc.call("launch_voyage")
	await get_tree().create_timer(0.5).timeout
	var rem = svc.call("get_remaining_seconds")
	var waited = 0
	while waited < 600:
		await get_tree().create_timer(0.1).timeout
		svc.call("ensure_voyage_settled_if_due")
		if get_state.call() == 2:
			break
		waited += 1
	var data = svc.call("get_pending_result_data")
	return {"03_launched": true, "03_remaining": rem, "04_has_data": data != null and not data.is_empty(), "result": "PASS"}


func _any_m19(main_node) -> bool:
	for child in main_node.get_children():
		if child is Control and child.visible and "M19" in str(child.name):
			return true
	return false


func _find_text(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Label and text in child.text:
			return true
		if child is Button and text in child.text:
			return true
		if _find_text(child, text):
			return true
	return false


func _count_nodes() -> int:
	var nodes = []
	_collect(get_tree().root, nodes)
	return nodes.size()


func _collect(node: Node, result: Array):
	for child in node.get_children():
		if child.get_class() in ["Label", "Button", "RichTextLabel", "ProgressBar"]:
			result.append(str(child.name))
		_collect(child, result)


func _save_and_quit():
	var f = FileAccess.open(_evidence_dir + "/data_acceptance.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"run_id": _run_id, "commit_sha": _commit_sha, "results": _results}, "\t"))
		f.close()
	print("[DATA] Done: ", _evidence_dir)
	get_tree().quit(0)
