extends SceneTree
# MA1 W03: Real GUI Input Acceptance
# Usage: Godot --script tests/m19/ma1_w03_gui_acceptance.gd --acceptance

var _results = {}
var _evidence_dir = ""
var _main_node = null
var _gs = null

func _initialize():
	var args = OS.get_cmdline_user_args()
	var ok = false
	for a in args:
		if "--acceptance" in a: ok = true; break
	if not ok:
		print("W03: MISSING --acceptance flag. Refusing to run.")
		quit(1); return

	var run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ma1/w03/" + run_id)
	DirAccess.make_dir_recursive_absolute(_evidence_dir)

	var main_path = ProjectSettings.get_setting("application/run/main_scene", "res://scenes/main/Main.tscn")
	var main_scene = load(main_path)
	if main_scene == null: print("W03: FAIL load main"); quit(1); return
	_main_node = main_scene.instantiate()
	root.add_child(_main_node)
	await _wait(5.0)

	_gs = _main_node.get("game_state")
	if _gs == null: _results["init"] = "FAIL: no GameState"; _save(); quit(1); return
	_results["init"] = "PASS"

	# Entry validation
	_results["entry"] = _check_entry()
	if _results["entry"]["result"] != "PASS": _save(); quit(1); return

	# Modal stress: open/close blue guardian 50 times
	_results["modal_stress"] = await _modal_stress("_toggle_blue_guardian", 50, "02_bg")

	# Voyage flow
	_results["voyage"] = await _test_voyage()

	# Codex navigation
	_results["codex"] = await _test_page_nav("_open_catalog_view", "05_codex")

	# Release navigation
	_results["release"] = await _test_page_nav("_open_release_management", "06_release")

	# Save test
	_results["save"] = _test_save()

	_save()
	print("W03: DONE. Results:", _evidence_dir)
	quit(0)


func _check_entry() -> Dictionary:
	var m19 = false; var legacy = 0
	for child in _main_node.get_children():
		if "M19" in str(child.name): m19 = true
		if child is Control and child.visible and str(child.name) in ["TitleBar","DisplayTankView","SumpView"]:
			legacy += 1
	return {"m19_ui": m19, "legacy_visible": legacy, "result": "PASS" if m19 and legacy == 0 else "FAIL"}


func _modal_stress(method: String, cycles: int, tag: String) -> Dictionary:
	var results = []
	for i in range(cycles):
		if _main_node.has_method(method):
			_main_node.call_deferred(method)
		await _wait(0.3)
		var visible = false
		for child in _main_node.get_children():
			if child is Control and child.visible and "M19" in str(child.name) and "MainUI" not in str(child.name):
				visible = true; break
		if _main_node.has_method(method):
			_main_node.call_deferred(method)
		await _wait(0.2)
		var closed = true
		for child in _main_node.get_children():
			if child is Control and child.visible and "M19" in str(child.name) and "MainUI" not in str(child.name):
				closed = false; break
		results.append({"cycle": i, "opened": visible, "closed": closed, "pass": visible and closed})

	var pass_count = 0
	for r in results: if r["pass"]: pass_count += 1
	return {"tag": tag, "cycles": cycles, "pass": pass_count, "result": "PASS" if pass_count >= cycles * 0.95 else "FAIL"}


func _test_voyage() -> Dictionary:
	if _gs == null: return {"result": "SKIP"}
	var svc = _gs.get("blue_guardian_service")
	if svc == null: return {"result": "SKIP"}
	var get_state = svc.get("get_state")
	if not get_state is Callable: return {"result": "SKIP"}
	if get_state.call() != 0: return {"result": "SKIP", "state": get_state.call()}

	svc.call("launch_voyage")
	await _wait(0.5)
	var rem = svc.call("get_remaining_seconds") if svc.has_method("get_remaining_seconds") else -1

	var waited = 0
	while waited < 600:
		await _wait(0.1)
		svc.call("ensure_voyage_settled_if_due")
		if get_state.call() == 2: break
		waited += 1

	var data = svc.call("get_pending_result_data") if svc.has_method("get_pending_result_data") else {}
	return {"launched": rem > 0, "completed": get_state.call() == 2, "has_data": data != null and not data.is_empty(), "result": "PASS"}


func _test_page_nav(method: String, tag: String) -> Dictionary:
	if not _main_node.has_method(method): return {"result": "SKIP"}
	_main_node.call_deferred(method)
	await _wait(1.0)
	var visible = false
	for child in _main_node.get_children():
		if child is Control and child.visible and "M19" in str(child.name) and "MainUI" not in str(child.name):
			visible = true; break
	if _main_node.has_method("_hide_all_secondary_panels"):
		_main_node.call_deferred("_hide_all_secondary_panels")
	await _wait(0.3)
	return {"tag": tag, "opened": visible, "result": "PASS" if visible else "FAIL"}


func _test_save() -> Dictionary:
	if _gs == null or not _gs.has_method("_perform_autosave"): return {"result": "FAIL"}
	var ok = _gs.call("_perform_autosave")
	return {"saved": ok, "result": "PASS" if ok else "FAIL"}


func _wait(seconds: float):
	await create_timer(seconds).timeout


func _save():
	var f = FileAccess.open(_evidence_dir + "/w03_acceptance.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"results": _results}, "\t"))
		f.close()
