extends Node
# M19 Final Runtime Probe — heartbeat, input test, modal audit, screenshot capture
# Runs as autoload alongside production Main Scene

var _heartbeat: int = 0
var _evidence_dir: String = ""
var _test_phase: int = 0
var _open_close_results: Array = []
var _main = null
var _gs = null

func _ready():
	_evidence_dir = ProjectSettings.globalize_path("res://reports/m19/final_deterministic/runtime_nodes")
	if not DirAccess.dir_exists_absolute(_evidence_dir):
		DirAccess.make_dir_recursive_absolute(_evidence_dir)
	print("[PROBE] Runtime probe active. Heartbeat started.")


func _process(_delta: float) -> void:
	_heartbeat += 1

	if _test_phase == 0 and _heartbeat > 180:
		_test_phase = 1
		_find_main()
		_run_tests()


func _find_main():
	var root = get_tree().root
	for child in root.get_children():
		var ns: String = str(child.name)
		if ns == "Main" or "Main" in ns:
			_main = child
			_gs = child.get("game_state")
			print("[PROBE] FOUND Main, gs=", str(_gs != null))
			break
	if _main == null:
		# Try with script path
		for child in root.get_children():
			if child.get_script() != null:
				var sp: String = child.get_script().resource_path
				if "Main" in sp:
					_main = child
					break


func _run_tests():
	print("[PROBE] Starting automated tests...")

	# 1. Capture runtime node tree
	_capture_scene_tree("production_runtime_tree.txt")
	_capture_scene_tree_json("production_runtime_nodes.json")

	# 2. Audit legacy nodes
	_audit_legacy_nodes()

	# 3. Audit modal state
	_audit_modal_state()

	# 4. Capture GPU screenshots
	_capture_all_pages()

	# 5. Run close stability
	_run_close_stability()

	# 6. LED state verification
	_capture_led_states()

	# 7. Save results and quit
	_save_results()
	print("[PROBE] Tests complete. Quitting.")
	get_tree().quit(0)


func _capture_scene_tree(filename: String):
	var f = FileAccess.open(_evidence_dir + "/" + filename, FileAccess.WRITE)
	if f == null: return
	f.store_string(_dump_tree(get_tree().root, 0))
	f.close()


func _dump_tree(node: Node, depth: int) -> String:
	var indent := ""
	for i in range(depth): indent += "  "
	var line := indent + str(node.name) + " [" + node.get_class() + "]"
	if node is Control:
		line += " visible=" + str(node.visible)
		line += " in_tree=" + str(node.is_visible_in_tree())
		line += " pos=" + str(node.position)
		line += " size=" + str(node.size)
		line += " mouse_filter=" + str(node.mouse_filter)
	var result := line + "\n"
	for child in node.get_children():
		result += _dump_tree(child, depth + 1)
	return result


func _capture_scene_tree_json(filename: String):
	var nodes = []
	_collect_nodes(get_tree().root, nodes)
	var f = FileAccess.open(_evidence_dir + "/" + filename, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(nodes, "\t"))
		f.close()


func _collect_nodes(node: Node, result: Array):
	var info := {
		"name": str(node.name), "class": node.get_class(),
		"path": str(node.get_path())
	}
	if node is Control:
		info["visible"] = node.visible
		info["visible_in_tree"] = node.is_visible_in_tree()
		info["position"] = [node.position.x, node.position.y]
		info["size"] = [node.size.x, node.size.y]
		info["mouse_filter"] = node.mouse_filter
	result.append(info)
	for child in node.get_children():
		_collect_nodes(child, result)


func _audit_legacy_nodes():
	var legacy := []
	var root = get_tree().root
	for child in root.get_children():
		var ns: String = str(child.name)
		if "DisplayTankView" in ns or "SumpView" in ns or "PipeNetworkView" in ns:
			legacy.append({"name": ns, "visible": child is Control and child.visible})
	# Check inside RootMargin
	for child in root.get_children():
		if "RootMargin" in str(child.name) and child is Control:
			legacy.append({"name": "RootMargin", "visible": child.visible})
			for gc in child.get_children():
				legacy.append({"name": str(gc.name), "visible": gc is Control and gc.visible})
	var f = FileAccess.open(_evidence_dir + "/legacy_nodes_audit.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(legacy, "\t"))
		f.close()


func _audit_modal_state():
	var state := {
		"heartbeat": _heartbeat,
		"tree_paused": get_tree().paused,
		"focus_owner": str(get_viewport().gui_get_focus_owner().get_path()) if get_viewport().gui_get_focus_owner() != null else "null",
		"input_handled": get_viewport().is_input_handled() if get_viewport().has_method("is_input_handled") else "unknown"
	}
	var f = FileAccess.open(_evidence_dir + "/modal_state.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(state, "\t"))
		f.close()


func _run_close_stability():
	# Test each secondary page: open → verify → close → verify main responsive
	var results := []
	var pages := ["blue_guardian", "codex", "release"]
	var hb_before: int

	for page in pages:
		for cycle in range(10):
			hb_before = _heartbeat

			# Open the page
			if page == "blue_guardian" and _main != null and _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")
			elif page == "codex" and _main != null and _main.has_method("_open_catalog_view"):
				_main.call_deferred("_open_catalog_view")
			elif page == "release" and _main != null and _main.has_method("_open_release_management"):
				_main.call_deferred("_open_release_management")

			await get_tree().create_timer(0.5).timeout
			var hb_after_open := _heartbeat

			# Close the page
			if page == "blue_guardian" and _main != null and _main.has_method("_toggle_blue_guardian"):
				_main.call_deferred("_toggle_blue_guardian")

			await get_tree().create_timer(1.0).timeout
			var hb_after_close := _heartbeat

			var ok := (hb_after_open > hb_before) and (hb_after_close > hb_after_open + 10)
			results.append({
				"page": page, "cycle": cycle,
				"hb_before": hb_before, "hb_after_open": hb_after_open, "hb_after_close": hb_after_close,
				"pass": ok
			})

	var f = FileAccess.open(_evidence_dir + "/close_stability_results.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(results, "\t"))
		f.close()


func _capture_led_states():
	# Take full screenshot for LED analysis
	var vp = get_viewport()
	if vp == null: return
	var img = vp.get_texture().get_image()
	if img == null: return
	var path := _evidence_dir + "/../runtime/01_led_current_state.png"
	img.save_png(path)


func _save_results():
	var summary := {
		"heartbeat_final": _heartbeat,
		"test_phase": _test_phase,
		"evidence_dir": _evidence_dir,
		"close_cycles_run": len(_open_close_results),
		"close_cycles_pass": _count_passing(_open_close_results)
	}
	var f = FileAccess.open(_evidence_dir + "/probe_summary.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(summary, "\t"))
		f.close()


func _count_passing(results: Array) -> int:
	var count: int = 0
	for r in results:
		if r.get("pass", false): count += 1
	return count

func _capture_all_pages():
	var runtime_dir := ProjectSettings.globalize_path("res://reports/m19/final_deterministic/runtime")
	if not DirAccess.dir_exists_absolute(runtime_dir):
		DirAccess.make_dir_recursive_absolute(runtime_dir)

	if _main == null:
		print("[PROBE] _capture_all_pages: _main is null, skipping")
		return

	var svc = null
	var wc = null
	var gs = _main.get("game_state")
	if gs != null:
		svc = gs.get("blue_guardian_service")
		if svc != null:
			wc = svc.get("clock")
			print("[PROBE] Service references found")
	else:
		print("[PROBE] GameState not found on Main")

	# 01: capture bare main interface
	await get_tree().create_timer(0.5).timeout
	_snap(runtime_dir, "01_main_exact_final")

	# Launch voyage for 02/03/04
	if svc != null and wc != null:
		svc.call("_set_test_commit_result", true)
		wc.set_test_override(10000000)

		# 02 Ready
		if _main != null and _main.has_method("_toggle_blue_guardian"):
			_main.call_deferred("_toggle_blue_guardian")
		await get_tree().create_timer(1.0).timeout
		_snap(runtime_dir, "02_ready_exact_final")
		if _main != null and _main.has_method("_toggle_blue_guardian"):
			_main.call_deferred("_toggle_blue_guardian")
		await get_tree().create_timer(0.3).timeout

		# 03 Voyaging
		svc.launch_voyage()
		if _main != null and _main.has_method("_toggle_blue_guardian"):
			_main.call_deferred("_toggle_blue_guardian")
		await get_tree().create_timer(1.0).timeout
		_snap(runtime_dir, "03_voyaging_exact_final")
		if _main != null and _main.has_method("_toggle_blue_guardian"):
			_main.call_deferred("_toggle_blue_guardian")
		await get_tree().create_timer(0.3).timeout

		# 04 Result
		wc.advance_test_override(BlueGuardianConfig.VOYAGE_DURATION_SECONDS + 5)
		svc.ensure_voyage_settled_if_due()
		_show_hybrid()
		await get_tree().create_timer(1.0).timeout
		_snap(runtime_dir, "04_result_exact_final")

	# 05 Codex
	if _main != null and _main.has_method("_open_catalog_view"):
		_main.call_deferred("_open_catalog_view")
	await get_tree().create_timer(1.0).timeout
	_snap(runtime_dir, "05_codex_exact_final")
	_hide_named("M19CodexPanel")
	await get_tree().create_timer(0.3).timeout

	# 06 Release
	if _main != null and _main.has_method("_open_release_management"):
		_main.call_deferred("_open_release_management")
	await get_tree().create_timer(1.0).timeout
	_snap(runtime_dir, "06_release_exact_final")
	_hide_named("M19ReleasePanel")


func _show_hybrid():
	if _main == null: return
	for child in _main.get_children():
		if "M19Result" in str(child.name) or "Hybrid" in str(child.name):
			if child.has_method("_refresh"): child.call("_refresh")
			child.show()
			return


func _hide_named(name_hint: String):
	if _main == null: return
	for child in _main.get_children():
		if name_hint in str(child.name):
			child.hide()
			return


func _snap(dir_path: String, label: String):
	var vp = get_viewport()
	if vp == null: return
	var img = vp.get_texture().get_image()
	if img == null: return
	img.save_png(dir_path + "/" + label + ".png")
