extends Node
# M19 W01 Runtime Probe — writes raw runtime facts for ratchet verification
# Reads NOTHING from source strings. Only reports what the running scene tree contains.

var _run_id: String = ""
var _evidence_dir: String = ""
var _start_frame: int = 0
var _capture_done: bool = false


func _ready():
	_run_id = str(Time.get_unix_time_from_system())
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/acceptance/staging/" + _run_id)
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)
	print("[PROBE-W01] Runtime probe active. run_id=", _run_id)
	# Wait 3 seconds for Main scene to fully initialize, then capture
	get_tree().create_timer(3.0).timeout.connect(_capture_all_and_quit)


func _capture_all_and_quit():
	if _capture_done: return
	_capture_done = true
	_capture_all()
	get_tree().quit(0)


func _capture_all():
	var root := get_tree().root
	var data := {
		"run_id": _run_id,
		"commit_sha": _read_git_head(),
		"generated_at": str(Time.get_datetime_string_from_system()),
		"probe_started_at": _start_frame,
		"probe_finished_at": Engine.get_process_frames(),
		"process_id": OS.get_process_id(),
		"frame_count": Engine.get_process_frames(),
		"active_scene_path": _get_active_scene(),
		"project_path": ProjectSettings.globalize_path("res://"),
		"hybrid_instances": _find_hybrid_instances(root),
		"all_visible_controls": _collect_visible_controls(root),
		"all_texture_rects": _collect_texture_rects(root),
		"all_plate_rects": _collect_plate_rects(root),
		"legacy_visible_nodes": _find_legacy_visible(root),
		"stylebox_nodes": _find_stylebox_nodes(root),
		"color_rect_nodes": _find_color_rect_nodes(root),
		"world_nodes_without_texture": _find_world_nodes_without_texture(root),
		"frozen_plate_count": _count_frozen_plates(root),
		"full_master_count": _count_full_master(root)
	}

	var f = FileAccess.open(_evidence_dir + "/probe_output.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
	print("[PROBE-W01] Evidence written: ", _evidence_dir)


func _read_git_head() -> String:
	# Read HEAD from project directory (not res:// which excludes .git)
	var head_path := ProjectSettings.globalize_path("res://.git/HEAD")
	var f = FileAccess.open(head_path, FileAccess.READ)
	if f != null:
		var ref = f.get_as_text().strip_edges()
		f.close()
		if ref.begins_with("ref: "):
			var ref_path = ref.substr(5).strip_edges()
			var rf = FileAccess.open(ProjectSettings.globalize_path("res://.git/" + ref_path), FileAccess.READ)
			if rf != null:
				var sha = rf.get_as_text().strip_edges()
				rf.close()
				return sha
	return "unknown"


func _get_active_scene() -> String:
	var root := get_tree().root
	for child in root.get_children():
		var ns: String = str(child.name)
		if ns == "Main" or "Main" in ns:
			if child is Node and child.scene_file_path != "":
				return child.scene_file_path
			return "Main (no scene_file_path)"
	return "Main not found"


func _find_hybrid_instances(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		var ns: String = str(child.name)
		if "M19MainUI" in ns or "M19MainInterface" in ns or "Hybrid" in ns:
			var info := {"name": ns, "path": str(child.get_path())}
			if child is Control:
				info["visible"] = child.visible
				info["visible_in_tree"] = child.is_visible_in_tree()
				info["position"] = [child.position.x, child.position.y]
				info["size"] = [child.size.x, child.size.y]
			result.append(info)
		result.append_array(_find_hybrid_instances(child))
	return result


func _collect_visible_controls(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Control and child.visible:
			var info := {
				"name": str(child.name),
				"class": child.get_class(),
				"path": str(child.get_path()),
				"visible_in_tree": child.is_visible_in_tree(),
				"position": [child.position.x, child.position.y],
				"size": [child.size.x, child.size.y],
				"mouse_filter": child.mouse_filter
			}
			result.append(info)
		result.append_array(_collect_visible_controls(child))
	return result


func _collect_texture_rects(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is TextureRect:
			var tex = child.texture
			var info := {
				"name": str(child.name),
				"path": str(child.get_path()),
				"visible": child.visible,
				"visible_in_tree": child.is_visible_in_tree(),
				"position": [child.position.x, child.position.y],
				"size": [child.size.x, child.size.y],
				"resource_path": tex.resource_path if tex != null else "null",
				"expand_mode": child.expand_mode,
				"stretch_mode": child.stretch_mode
			}
			result.append(info)
		result.append_array(_collect_texture_rects(child))
	return result


func _collect_plate_rects(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is TextureRect:
			var path: String = child.texture.resource_path if child.texture != null else ""
			if "shell_" in path or "runtime_master" in path or "01_runtime" in path:
				result.append({
					"name": str(child.name),
					"resource": path,
					"position": [child.position.x, child.position.y],
					"size": [child.size.x, child.size.y],
					"visible_in_tree": child.is_visible_in_tree()
				})
		result.append_array(_collect_plate_rects(child))
	return result


func _find_legacy_visible(node: Node) -> Array:
	var legacy_names := ["Background", "RootMargin", "DisplayTankView", "SumpView", "StatusPanel", "PipeNetworkView", "TitleBar"]
	var result: Array = []
	for child in node.get_children():
		var ns: String = str(child.name)
		for ln in legacy_names:
			if ln in ns:
				if child is Control and child.is_visible_in_tree():
					result.append({"name": ns, "path": str(child.get_path()), "visible": child.visible, "visible_in_tree": true})
		result.append_array(_find_legacy_visible(child))
	return result


func _find_stylebox_nodes(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		var ns: String = str(child.name)
		if child.has_method("add_theme_stylebox_override"):
			result.append({"name": ns, "path": str(child.get_path()), "class": child.get_class()})
		result.append_array(_find_stylebox_nodes(child))
	return result


func _find_color_rect_nodes(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is ColorRect:
			result.append({
				"name": str(child.name), "path": str(child.get_path()),
				"visible": child.visible, "color": [child.color.r, child.color.g, child.color.b, child.color.a],
				"position": [child.position.x, child.position.y], "size": [child.size.x, child.size.y]
			})
		result.append_array(_find_color_rect_nodes(child))
	return result


func _find_world_nodes_without_texture(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		var ns: String = str(child.name)
		if ("Tank" in ns or "Sump" in ns or "World" in ns) and child is Control:
			for gc in child.get_children():
				if gc is ColorRect:
					result.append({"parent": ns, "name": str(gc.name), "is_placeholder": true, "color": [gc.color.r, gc.color.g, gc.color.b]})
		result.append_array(_find_world_nodes_without_texture(child))
	return result


func _count_frozen_plates(node: Node) -> int:
	var count: int = 0
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			var path: String = child.texture.resource_path
			if "shell_" in path or "runtime_master" in path:
				count += 1
		count += _count_frozen_plates(child)
	return count


func _count_full_master(node: Node) -> int:
	var count: int = 0
	for child in node.get_children():
		if child is TextureRect and child.texture != null:
			var path: String = child.texture.resource_path
			if "01_runtime_empty_master" in path:
				count += 1
		count += _count_full_master(child)
	return count
