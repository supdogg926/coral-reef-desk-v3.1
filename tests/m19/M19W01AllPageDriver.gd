extends Node
# M19 W01 All-Page Driver — captures all 5 pages sequentially in one process

var _run_id: String = ""
var _evidence_dir: String = ""
var _main = null
var _page_idx: int = 0
var _pages := ["02","03","04","05","06"]
var _results := {}

func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/acceptance/staging/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)
	print("[ALL-PAGE] Evidence: ", _evidence_dir)
	await get_tree().create_timer(3.0).timeout
	var root = get_tree().root
	for child in root.get_children():
		if str(child.name) == "Main": _main = child
	if _main == null:
		_save_all(); get_tree().quit(1); return
	await get_tree().create_timer(1.0).timeout
	_test_next_page()

func _test_next_page():
	if _page_idx >= _pages.size():
		_save_all(); get_tree().quit(0); return
	var pid: String = _pages[_page_idx]
	print("[ALL-PAGE] Testing page ", pid)
	match pid:
		"02":
			if _main.has_method("_toggle_blue_guardian"):
				_main._toggle_blue_guardian()
		"03":
			_launch_voyage_then_open()
		"04": _open_04()
		"05":
			if _main.has_method("_open_catalog_view"):
				_main._open_catalog_view()
		"06":
			if _main.has_method("_open_release_management"):
				_main._open_release_management()
	await get_tree().create_timer(1.5).timeout
	_capture_current(pid)
	# Close the page
	match pid:
		"02":
			if _main.has_method("_toggle_blue_guardian"):
				_main._toggle_blue_guardian()
		"03":
			if _main.has_method("_toggle_blue_guardian"):
				_main._toggle_blue_guardian()
		"04": _hide_result_panel()
		"05","06": _hide_named(pid)
	await get_tree().create_timer(0.5).timeout
	_page_idx += 1
	_test_next_page()

func _launch_voyage_then_open():
	var gs = _main.get("game_state")
	if gs == null: return
	var svc = gs.get("blue_guardian_service")
	if svc == null: return
	var wc = svc.get("clock")
	if wc == null: return
	svc.call("_set_test_commit_result", true)
	wc.set_test_override(10000000)
	svc.launch_voyage()
	if _main.has_method("_toggle_blue_guardian"):
		_main._toggle_blue_guardian()

func _open_04():
	var gs = _main.get("game_state")
	if gs == null: return
	var svc = gs.get("blue_guardian_service")
	if svc == null: return
	var wc = svc.get("clock")
	if wc == null: return
	svc.call("_set_test_commit_result", true)
	wc.set_test_override(10000000)
	svc.launch_voyage()
	wc.advance_test_override(BlueGuardianConfig.VOYAGE_DURATION_SECONDS + 5)
	svc.ensure_voyage_settled_if_due()
	for child in _main.get_children():
		if "Hybrid" in str(child.name) or "ResultPanelHybrid" in str(child.name):
			if child.has_method("_refresh"): child._refresh()
			child.show()

func _hide_result_panel():
	for child in _main.get_children():
		if "Hybrid" in str(child.name) or "ResultPanelHybrid" in str(child.name):
			child.hide()

func _hide_named(hint: String):
	for child in _main.get_children():
		if hint in str(child.name): child.hide()

func _capture_current(pid: String):
	var shell_names := {"02":"shell_02_ready_empty","03":"shell_03_voyaging_empty","04":"shell_04_result_empty","05":"shell_05_codex_empty","06":"shell_06_release_empty"}
	var target: String = shell_names.get(pid, "")
	var info := {}
	_find_plate(get_tree().root, target, info)
	
	# Screenshot
	var vp = get_viewport()
	if vp != null:
		var img = vp.get_texture().get_image()
		if img != null:
			img.save_png(_evidence_dir + "/page_" + pid + "_runtime.png")
	
	# Count other visible plates
	var other: int = 0
	for op in shell_names:
		if op == pid: continue
		other += _count_visible(get_tree().root, shell_names[op])
	
	var commit := "unknown"
	var f = FileAccess.open(_evidence_dir + "/page_" + pid + "_evidence.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"run_id":_run_id,"commit_sha":commit,"generated_at":str(Time.get_datetime_string_from_system()),
			"source_command":"AllPageDriver","active_scene_path":"res://scenes/main/Main.tscn",
			"page_id":pid,"plate_resource_path":info.get("rp",""),"plate_visible_in_tree":info.get("vit",false),
			"plate_global_rect":info.get("rect",[]),"other_plate_visible_count":other,"screenshot_path":"page_"+pid+"_runtime.png"
		}))
		f.close()
	_results[pid] = info.get("vit", false)
	print("[ALL-PAGE] Page ", pid, " visible=", info.get("vit",false))

func _find_plate(node: Node, target: String, out: Dictionary):
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			if target in child.texture.resource_path:
				out["rp"] = child.texture.resource_path
				out["vit"] = child.is_visible_in_tree()
				out["rect"] = [child.position.x, child.position.y, child.size.x, child.size.y]
		_find_plate(child, target, out)

func _count_visible(node: Node, target: String) -> int:
	var c: int = 0
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			if target in child.texture.resource_path and child.is_visible_in_tree():
				c += 1
		c += _count_visible(child, target)
	return c

func _save_all():
	var f = FileAccess.open(_evidence_dir + "/all_page_results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"pages":_results,"run_id":_run_id}))
		f.close()
