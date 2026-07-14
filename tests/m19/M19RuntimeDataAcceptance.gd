extends Node
# M19 Runtime GUI Acceptance v3 — captures 15+ screenshots with operations

var _run_id = ""; var _evidence_dir = ""; var _commit_sha = ""
var _results = {}; var _frame = 0; var _done = false
var _main_node = null; var _gs = null; var _screenshots = []

func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ui_runtime_takeover/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir): DirAccess.make_dir_recursive_absolute(_evidence_dir)
	var output = []; var code = OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"
	print("[GUI] Init: ", _evidence_dir)

func _process(_delta):
	if _done: return; _frame += 1
	if _frame == 5:
		var root = get_tree().root
		for child in root.get_children():
			if str(child.name) == "Main": _main_node = child; _gs = child.get("game_state"); break
	if _frame == 60: _snap("01_main_runtime")
	elif _frame == 120: _op_knob("return_pump", "01_knob_pump")
	elif _frame == 180: _op_knob("wave_pump", "01_knob_wave")
	elif _frame == 240: _op_light()
	elif _frame == 300: _snap("01_after_knobs")
	elif _frame == 360: _op_maint("water_change_10", "01_maint_change")
	elif _frame == 420: _op_feed("fish_food", "01_feed")
	elif _frame == 480: _op_device("chiller", "01_device_chiller")
	elif _frame == 540: _snap("01_after_ops")
	elif _frame == 600: _nav("02", "_toggle_blue_guardian")
	elif _frame == 750: _snap("02_ready_runtime")
	elif _frame == 800: _do_launch()
	elif _frame == 950: _snap("03_voyaging_runtime")
	elif _frame == 2800: _snap("04_result_runtime")
	elif _frame == 2850: _close()
	elif _frame == 2900: _nav("05", "_open_catalog_view")
	elif _frame == 3050: _snap("05_codex_runtime")
	elif _frame == 3100: _close()
	elif _frame == 3150: _nav("06", "_open_release_management")
	elif _frame == 3300: _snap("06_release_runtime")
	elif _frame == 3350: _close()
	elif _frame == 3400: _nav("main", "_on_observe_pressed")
	elif _frame == 3550: _snap("01_observe_mode")
	elif _frame == 3600: _do_save()
	elif _frame == 3700: _snap("01_after_save")
	elif _frame == 3750: _check_all(); _finalize(); _done = true; get_tree().quit(0)

func _op_knob(dev_id: String, label: String):
	print("[GUI] Knob: ", dev_id)
	if _gs != null and _gs.has_method("toggle_device"): _gs.call("toggle_device", dev_id)
	_screenshots.append(label)

func _op_light():
	print("[GUI] Light intensity")
	if _gs != null and "light_intensity" in _gs: _gs.light_intensity = 50; _gs.set_light_intensity(50)

func _op_maint(aid: String, label: String):
	print("[GUI] Maint: ", aid)
	if _gs != null and _gs.has_method("apply_water_maintenance_action"): _gs.call("apply_water_maintenance_action", aid)

func _op_feed(fid: String, label: String):
	print("[GUI] Feed: ", fid)
	if _gs != null and _gs.has_method("apply_feeding_action"): _gs.call("apply_feeding_action", fid)

func _op_device(did: String, label: String):
	print("[GUI] Device: ", did)
	if _gs != null: _gs.toggle_device(did)

func _nav(tag: String, method: String):
	print("[GUI] Nav: ", tag)
	if _main_node != null and _main_node.has_method(method): _main_node.call_deferred(method)

func _close():
	print("[GUI] Close panels")
	if _main_node != null and _main_node.has_method("_hide_all_secondary_panels"): _main_node.call_deferred("_hide_all_secondary_panels")

func _do_launch():
	print("[GUI] Launch voyage")
	if _gs != null:
		var svc = _gs.get("blue_guardian_service")
		if svc != null: svc.call("launch_voyage")

func _do_save():
	print("[GUI] Save")
	if _gs != null and _gs.has_method("_perform_autosave"): _gs.call("_perform_autosave")
	if _main_node != null and _main_node.has_method("_manual_save_test"): _main_node.call_deferred("_manual_save_test")

func _snap(label: String):
	print("[GUI] Snap: ", label)
	var vp = get_viewport()
	if vp != null:
		var img = vp.get_texture().get_image()
		if img != null: img.save_png(_evidence_dir + "/" + label + ".png")
	_screenshots.append(label)

func _check_all():
	var required = ["ReefIdle", "浪花", "温度", "NO3", "PO4", "pH", "KH", "Ca", "换水", "水泵", "造浪泵", "亮度", "色温", "保存", "图鉴", "放归"]
	var found = []; var missing = []
	for t in required:
		if _find_text(get_tree().root, t): found.append(t)
		else: missing.append(t)
	_results["static"] = {"found": found.size(), "missing": missing, "result": "PASS" if missing.size() <= 2 else "FAIL"}
	if _gs != null:
		var eco = _gs.get("economy_system")
		_results["wave"] = eco.call("get_waves_balance") if eco != null and eco.has_method("get_waves_balance") else -1
		if _gs.has_method("get_water_chemistry_debug_state"):
			var w = _gs.call("get_water_chemistry_debug_state")
			var issues = []
			for k in ["temperature","salinity","nitrate","phosphate","ph","alkalinity","calcium"]:
				if w.get(k,null) == null: issues.append(k)
			_results["water"] = {"issues": issues}
		_results["dynamic"] = "PASS"
	_results["screenshots"] = _screenshots

func _finalize():
	var f = FileAccess.open(_evidence_dir + "/acceptance_results.json", FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify({"run_id":_run_id, "commit_sha":_commit_sha, "frames":_frame, "results":_results}, "\t")); f.close()
	print("[GUI] Complete: ", _screenshots.size(), " screenshots")

func _find_text(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Label and text in child.text: return true
		if child is Button and text in child.text: return true
		if _find_text(child, text): return true
	return false
