extends Node
# M19 Runtime UI Snapshot — captures all Label/Button/ProgressBar nodes across 01-06 pages
# Produces reports/m19/ui_runtime_takeover/<run_id>/runtime_ui_snapshot.json

var _run_id: String = ""
var _evidence_dir: String = ""
var _main = null
var _commit_sha: String = ""


func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ui_runtime_takeover/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)

	var output := []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"

	print("[UI-SNAPSHOT] Evidence dir: ", _evidence_dir)

	await get_tree().create_timer(3.0).timeout
	var root = get_tree().root
	for child in root.get_children():
		if str(child.name) == "Main":
			_main = child; break

	if _main == null:
		_save_error("Main not found"); get_tree().quit(1); return

	await get_tree().create_timer(1.0).timeout

	# Capture 01 main page first
	var snapshot := {
		"run_id": _run_id, "commit_sha": _commit_sha,
		"generated_at": str(Time.get_datetime_string_from_system()),
		"pages": {}
	}

	snapshot["pages"]["01"] = _capture_page_nodes(root, "01_main")

	# Capture pages 02-06 by navigating
	var pages := {
		"02": "_toggle_blue_guardian",
		"05": "_open_catalog_view",
		"06": "_open_release_management"
	}

	for pid in pages:
		var method: String = pages[pid]
		if _main.has_method(method):
			_main.call_deferred(method)
		await get_tree().create_timer(1.0).timeout
		snapshot["pages"][pid] = _capture_page_nodes(root, pid)
		# Close
		if pid == "02":
			if _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
		elif pid in ["05", "06"]:
			if _main.has_method("_hide_all_secondary_panels"):
				_main.call_deferred("_hide_all_secondary_panels")
		await get_tree().create_timer(0.5).timeout

	# 03 Voyaging — launch voyage then capture
	var gs = _main.get("game_state")
	if gs != null:
		var svc = gs.get("blue_guardian_service")
		if svc != null and svc.get_state() == BlueGuardianService.VoyageState.READY:
			svc.launch_voyage()
	if _main.has_method("_toggle_blue_guardian"):
		_main.call_deferred("_toggle_blue_guardian")
	await get_tree().create_timer(1.0).timeout
	snapshot["pages"]["03"] = _capture_page_nodes(root, "03_voyaging")
	if _main.has_method("_toggle_blue_guardian"):
		_main.call_deferred("_toggle_blue_guardian")
	await get_tree().create_timer(0.5).timeout

	# 04 Result — wait for voyage to complete
	if gs != null:
		var svc = gs.get("blue_guardian_service")
		if svc != null:
			var waited := 0
			while waited < 300:
				await get_tree().create_timer(0.1).timeout
				svc.ensure_voyage_settled_if_due()
				if svc.get_state() == BlueGuardianService.VoyageState.RESULT_PENDING:
					break
				waited += 1
	await get_tree().create_timer(1.0).timeout
	snapshot["pages"]["04"] = _capture_page_nodes(root, "04_result")

	# Take screenshot of each captured state
	_take_screenshots()

	var f = FileAccess.open(_evidence_dir + "/runtime_ui_snapshot.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(snapshot, "\t"))
		f.close()

	print("[UI-SNAPSHOT] Done. ", snapshot["pages"].size(), " pages captured.")
	get_tree().quit(0)


func _capture_page_nodes(root: Node, page_label: String) -> Dictionary:
	var nodes := []
	_collect_ui_nodes(root, nodes)
	# Count issues
	var empty_count := 0
	var null_count := 0
	for n in nodes:
		if n.get("text", "") == "" and n["class"] in ["Label", "Button"]:
			empty_count += 1
		if str(n.get("text", "")) in ["null", "NaN", "inf", "-inf"]:
			null_count += 1
	return {
		"page": page_label,
		"node_count": nodes.size(),
		"empty_text_count": empty_count,
		"null_value_count": null_count,
		"nodes": nodes
	}


func _collect_ui_nodes(node: Node, result: Array):
	for child in node.get_children():
		var cls := child.get_class()
		if cls in ["Label", "Button", "RichTextLabel", "ProgressBar", "SpinBox", "HSlider", "ItemList"]:
			var info := {
				"name": str(child.name),
				"class": cls,
				"path": str(child.get_path()),
				"visible": child.visible if child is CanvasItem else true,
				"visible_in_tree": child.is_visible_in_tree() if child is CanvasItem else false,
			}
			if child is Label or child is Button or child is RichTextLabel:
				info["text"] = child.text
			if child is Button:
				info["disabled"] = child.disabled
				info["tooltip"] = child.tooltip_text
			if child is ProgressBar:
				info["value"] = child.value
				info["max_value"] = child.max_value
			if child is Control:
				var gp := child.global_position
				info["global_rect"] = [gp.x, gp.y, child.size.x, child.size.y]
			result.append(info)
		_collect_ui_nodes(child, result)


func _take_screenshots():
	var vp = get_viewport()
	if vp == null: return
	var img = vp.get_texture().get_image()
	if img == null: return
	img.save_png(_evidence_dir + "/01_main_runtime.png")


func _save_error(reason: String):
	var f = FileAccess.open(_evidence_dir + "/error.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("ERROR: " + reason)
		f.close()
