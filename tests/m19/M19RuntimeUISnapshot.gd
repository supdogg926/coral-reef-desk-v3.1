extends Node
# M19 Runtime UI Snapshot — loads Main.tscn (F5 equivalent), captures all UI nodes
# Usage: Godot_v4.7-stable_win64.exe --headless --script tests/m19/M19RuntimeUISnapshot.gd

var _run_id: String = ""
var _evidence_dir: String = ""
var _main = null
var _commit_sha: String = ""


func _ready():
	# Load production Main scene (equivalent to F5)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	await get_tree().create_timer(3.0).timeout

	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/ui_runtime_takeover/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)

	var output := []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	_commit_sha = output[0].strip_edges() if code == 0 and output.size() > 0 else "unknown"

	print("[UI-SNAPSHOT] Evidence: ", _evidence_dir, " commit=", _commit_sha)

	# Find Main
	var root = get_tree().root
	for child in root.get_children():
		if str(child.name) == "Main":
			_main = child; break
	if _main == null:
		print("[UI-SNAPSHOT] ERROR: Main not found")
		get_tree().quit(1); return

	await get_tree().create_timer(2.0).timeout

	# Capture 01 main page
	var snapshot := {
		"run_id": _run_id, "commit_sha": _commit_sha,
		"generated_at": str(Time.get_datetime_string_from_system()),
		"pages": {}
	}
	snapshot["pages"]["01"] = _capture_page(root, "01_main")
	_take_screenshot("01_main_runtime")

	# Navigate to each page and capture
	var pages := {
		"02": "_toggle_blue_guardian",
		"05": "_open_catalog_view",
		"06": "_open_release_management"
	}
	for pid in pages:
		if _main.has_method(pages[pid]):
			_main.call_deferred(pages[pid])
		await get_tree().create_timer(1.5).timeout
		snapshot["pages"][pid] = _capture_page(root, pid)
		_take_screenshot(pid + "_runtime")
		# Close
		if pid == "02":
			if _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
		else:
			if _main.has_method("_hide_all_secondary_panels"):
				_main.call_deferred("_hide_all_secondary_panels")
		await get_tree().create_timer(0.5).timeout

	# Save snapshot
	var f = FileAccess.open(_evidence_dir + "/runtime_ui_snapshot.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(snapshot, "\t"))
		f.close()

	print("[UI-SNAPSHOT] Done. ", snapshot["pages"].size(), " pages captured.")
	get_tree().quit(0)


func _capture_page(root: Node, label: String) -> Dictionary:
	var nodes := []
	_collect_nodes(root, nodes)
	var empty_count := 0
	for n in nodes:
		if str(n.get("text", "")) == "" and n["class"] in ["Label", "Button"]:
			empty_count += 1
	return {"page": label, "node_count": nodes.size(), "empty_text_count": empty_count, "nodes": nodes}


func _collect_nodes(node: Node, result: Array):
	for child in node.get_children():
		var cls := child.get_class()
		if cls in ["Label", "Button", "RichTextLabel", "ProgressBar"]:
			var info := {"name": str(child.name), "class": cls, "path": str(child.get_path())}
			if child is Label or child is Button or child is RichTextLabel:
				info["text"] = str(child.text)
			if child is Button:
				info["disabled"] = child.disabled
			if child is ProgressBar:
				info["value"] = child.value
				info["max_value"] = child.max_value
			if child is Control:
				var ctrl: Control = child as Control
				var gp: Vector2 = ctrl.global_position
				info["global_rect"] = [gp.x, gp.y, ctrl.size.x, ctrl.size.y]
			result.append(info)
		_collect_nodes(child, result)


func _take_screenshot(label: String):
	var vp = get_viewport()
	if vp == null: return
	var img = vp.get_texture().get_image()
	if img == null: return
	img.save_png(_evidence_dir + "/" + label + ".png")
