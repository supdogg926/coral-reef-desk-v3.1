extends Node
# M19 W01 Page Driver — captures each of 5 pages independently from production Main Scene
# Reads PAGE_ID from env: 02, 03, 04, 05, or 06
# All evidence from real runtime state. No hardcoded values.

var _page_id: String = ""
var _evidence_dir: String = ""
var _main = null
var _captured: bool = false
var _commit_sha: String = ""
var _active_scene_path: String = ""


func _ready():
	_page_id = OS.get_environment("M19_PAGE_ID")
	if _page_id == "" or _page_id.length() < 2:
		print("[PAGE-DRIVER] FATAL: M19_PAGE_ID not set")
		get_tree().quit(1)
		return

	var run_id := OS.get_environment("M19_RUN_ID")
	if run_id == "": run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/acceptance/staging/" + run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)

	# Resolve commit SHA from git
	var output := []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"

	# Read active scene from project settings
	_active_scene_path = ProjectSettings.get_setting("application/run/main_scene", "res://scenes/main/Main.tscn")

	print("[PAGE-DRIVER] Page ", _page_id, " evidence=", _evidence_dir)
	print("[PAGE-DRIVER] Commit=", _commit_sha)

	await get_tree().create_timer(3.0).timeout

	var root = get_tree().root
	for child in root.get_children():
		if str(child.name) == "Main":
			_main = child; break

	if _main == null:
		_save_fail("Main not found"); get_tree().quit(1); return

	await get_tree().create_timer(1.0).timeout

	# Open the target page through production entry (public Main methods only)
	match _page_id:
		"02","03":
			if _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
		"04":
			_open_04()
		"05":
			if _main.has_method("_open_catalog_view"):
				_main.call_deferred("_open_catalog_view")
		"06":
			if _main.has_method("_open_release_management"):
				_main.call_deferred("_open_release_management")

	await get_tree().create_timer(1.5).timeout
	_capture_page()
	get_tree().quit(0)


func _open_04():
	# Production path: voyage must complete → Main._process auto-shows result panel
	var gs = _main.get("game_state")
	if gs == null: return
	var svc = gs.get("blue_guardian_service")
	if svc == null: return

	# Launch voyage if in READY state (production path)
	if svc.get_state() == BlueGuardianService.VoyageState.READY:
		svc.launch_voyage()

	# Wait for voyage to settle
	var max_wait := 300
	var waited := 0
	while waited < max_wait:
		await get_tree().create_timer(0.1).timeout
		svc.ensure_voyage_settled_if_due()
		if svc.get_state() == BlueGuardianService.VoyageState.RESULT_PENDING:
			break
		waited += 1


func _capture_page():
	var run_id := OS.get_environment("M19_RUN_ID")
	if run_id == "": run_id = "unknown"

	var plate_info := {}
	var shell_names := {"02":"shell_02_ready_empty","03":"shell_03_voyaging_empty","04":"shell_04_result_empty","05":"shell_05_codex_empty","06":"shell_06_release_empty"}
	var target_shell := shell_names.get(_page_id, "")

	var root = get_tree().root
	_collect_plate_info(root, target_shell, plate_info)

	var other_visible := 0
	for pid in shell_names:
		if pid == _page_id: continue
		other_visible += _count_visible_shell(root, shell_names[pid])

	var vp = get_viewport()
	if vp != null:
		var img = vp.get_texture().get_image()
		if img != null:
			img.save_png(_evidence_dir + "/page_" + _page_id + "_runtime.png")

	var shell_sha := ""
	var rp: String = plate_info.get("resource_path", "")
	if rp != "":
		var sf = FileAccess.open(rp, FileAccess.READ)
		if sf != null:
			shell_sha = sf.get_sha256()
			sf.close()

	var evidence := {
		"run_id": run_id,
		"commit_sha": _commit_sha,
		"generated_at": str(Time.get_datetime_string_from_system()),
		"source_command": "M19W01PageDriver with M19_PAGE_ID=" + _page_id,
		"active_scene_path": _active_scene_path,
		"page_id": _page_id,
		"plate_resource_path": plate_info.get("resource_path", ""),
		"plate_sha256": shell_sha,
		"plate_global_rect": plate_info.get("global_rect", []),
		"plate_visible_in_tree": plate_info.get("visible_in_tree", false),
		"other_plate_visible_count": other_visible,
		"screenshot_path": "page_" + _page_id + "_runtime.png"
	}

	var f = FileAccess.open(_evidence_dir + "/page_" + _page_id + "_evidence.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(evidence, "\t"))
		f.close()

	print("[PAGE-DRIVER] Page ", _page_id, " captured. Plate visible=", plate_info.get("visible_in_tree", false), " rect=", plate_info.get("global_rect", []))


func _collect_plate_info(node: Node, target_shell: String, result: Dictionary):
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			var rp2: String = child.texture.resource_path
			if target_shell in rp2:
				result["resource_path"] = rp2
				result["visible_in_tree"] = child.is_visible_in_tree() if child is Control else false
				if child is Control:
					var gp := child.global_position
					result["global_rect"] = [gp.x, gp.y, child.size.x, child.size.y]
				result["visible"] = child.visible if child is Control else false
		_collect_plate_info(child, target_shell, result)


func _count_visible_shell(node: Node, shell_name: String) -> int:
	var count: int = 0
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			if shell_name in child.texture.resource_path:
				if child.is_visible_in_tree(): count += 1
		count += _count_visible_shell(child, shell_name)
	return count


func _save_fail(reason: String):
	var f = FileAccess.open(_evidence_dir + "/page_driver_error.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("FAIL " + _page_id + ": " + reason)
		f.close()
