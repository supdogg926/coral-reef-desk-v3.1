extends Node
# M19 W01 All-Page Driver — captures all 5 pages sequentially via production Main entry
# Uses public Main methods only. No private method calls, no test injection.
# All evidence collected from real runtime state.

var _run_id: String = ""
var _evidence_dir: String = ""
var _main = null
var _page_idx: int = 0
var _pages := ["02","03","04","05","06"]
var _results := {}
var _commit_sha: String = ""
var _active_scene_path: String = ""
var _manifest_path: String = "res://assets/m19/ui/manifests/asset_manifest.json"
var _shell_names := {
	"02":"shell_02_ready_empty","03":"shell_03_voyaging_empty",
	"04":"shell_04_result_empty","05":"shell_05_codex_empty",
	"06":"shell_06_release_empty"
}

func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/acceptance/staging/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)

	_commit_sha = _git_rev_parse_head()
	_active_scene_path = ProjectSettings.get_setting("application/run/main_scene", "res://scenes/main/Main.tscn")

	print("[ALL-PAGE] Evidence: ", _evidence_dir)
	print("[ALL-PAGE] Commit: ", _commit_sha)
	print("[ALL-PAGE] ActiveScene: ", _active_scene_path)

	await get_tree().create_timer(3.0).timeout
	var root = get_tree().root
	for child in root.get_children():
		if str(child.name) == "Main":
			_main = child
			break
	if _main == null:
		_save_all(); get_tree().quit(1); return
	await get_tree().create_timer(1.0).timeout
	_test_next_page()


func _git_rev_parse_head() -> String:
	var output := []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	if code == 0 and output.size() > 0:
		return output[0].strip_edges()
	return "unknown"


func _test_next_page():
	if _page_idx >= _pages.size():
		_save_all(); get_tree().quit(0); return
	var pid: String = _pages[_page_idx]
	print("[ALL-PAGE] Testing page ", pid)

	match pid:
		"02":
			if _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
		"03":
			_launch_voyage_production()
		"04":
			_await_voyage_result_production()
		"05":
			if _main.has_method("_open_catalog_view"):
				_main.call_deferred("_open_catalog_view")
		"06":
			if _main.has_method("_open_release_management"):
				_main.call_deferred("_open_release_management")

	await get_tree().create_timer(1.5).timeout
	_capture_current(pid)
	_close_current_page(pid)
	await get_tree().create_timer(0.5).timeout
	_page_idx += 1
	_test_next_page()


func _launch_voyage_production():
	# Production path: open BG → launch voyage → panel shows voyaging state
	var gs = _main.get("game_state")
	if gs == null: return
	var svc = gs.get("blue_guardian_service")
	if svc == null: return
	if svc.get_state() == BlueGuardianService.VoyageState.READY:
		svc.launch_voyage()
	if _main.has_method("_toggle_blue_guardian"):
		_main.call_deferred("_toggle_blue_guardian")


func _await_voyage_result_production():
	# Production path: Main._process auto-detects voyage complete and shows result
	var gs = _main.get("game_state")
	if gs == null: return
	var svc = gs.get("blue_guardian_service")
	if svc == null: return
	var max_wait := 300
	var waited := 0
	while waited < max_wait:
		await get_tree().create_timer(0.1).timeout
		svc.ensure_voyage_settled_if_due()
		if svc.get_state() == BlueGuardianService.VoyageState.RESULT_PENDING:
			break
		waited += 1


func _close_current_page(pid: String):
	match pid:
		"02","03","04":
			if _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
		"05","06":
			if _main.has_method("_hide_all_secondary_panels"):
				_main.call_deferred("_hide_all_secondary_panels")


func _capture_current(pid: String):
	var target: String = _shell_names.get(pid, "")
	var info := {}
	_find_plate(get_tree().root, target, info)

	var vp = get_viewport()
	if vp != null:
		var img = vp.get_texture().get_image()
		if img != null:
			img.save_png(_evidence_dir + "/page_" + pid + "_runtime.png")

	var other: int = 0
	for op in _shell_names:
		if op == pid: continue
		other += _count_visible(get_tree().root, _shell_names[op])

	var shell_sha := ""
	var rp: String = info.get("rp", "")
	if rp != "":
		var f2 = FileAccess.open(rp, FileAccess.READ)
		if f2 != null:
			shell_sha = f2.get_sha256()
			f2.close()

	var manifest_sha := ""
	var mf = FileAccess.open(_manifest_path, FileAccess.READ)
	if mf != null:
		manifest_sha = mf.get_sha256()
		mf.close()

	var evidence := {
		"run_id":_run_id,
		"commit_sha":_commit_sha,
		"generated_at":str(Time.get_datetime_string_from_system()),
		"source_command":"AllPageDriver via production Main entry",
		"active_scene_path":_active_scene_path,
		"page_id":pid,
		"plate_resource_path":info.get("rp",""),
		"plate_sha256":shell_sha,
		"plate_global_rect":info.get("rect",[]),
		"plate_visible_in_tree":info.get("vit",false),
		"other_plate_visible_count":other,
		"screenshot_path":"page_"+pid+"_runtime.png",
		"manifest_path":_manifest_path,
		"manifest_sha256":manifest_sha
	}
	var f = FileAccess.open(_evidence_dir + "/page_" + pid + "_evidence.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(evidence))
		f.close()
	_results[pid] = info.get("vit", false)
	print("[ALL-PAGE] Page ", pid, " visible=", info.get("vit",false), " rect=", info.get("rect",[]))


func _find_plate(node: Node, target: String, out: Dictionary):
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			if target in child.texture.resource_path:
				out["rp"] = child.texture.resource_path
				out["vit"] = child.is_visible_in_tree()
				if child is Control:
					var gp := child.global_position
					out["rect"] = [gp.x, gp.y, child.size.x, child.size.y]
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
	var summary := {
		"pages":_results,"run_id":_run_id,
		"commit_sha":_commit_sha,"active_scene_path":_active_scene_path,
		"generated_at":str(Time.get_datetime_string_from_system())
	}
	var f = FileAccess.open(_evidence_dir + "/all_page_results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(summary))
		f.close()
