extends SceneTree

const DEFAULT_SCREENSHOT_DIR := "res://reports/m16/screenshots"

var _output_dir := DEFAULT_SCREENSHOT_DIR
var _failed := false
var _saved: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var env_output := OS.get_environment("M16_T03_SCREENSHOT_OUTPUT_DIR")
	if not env_output.is_empty():
		_output_dir = env_output
	DirAccess.make_dir_recursive_absolute(_to_absolute_path(_output_dir))
	get_root().size = Vector2i(960, 540)
	print("[M16-T03] viewport screenshot output dir: ", _output_dir)

	await _capture("m16_t03_01_codex_empty_state_no_silhouette.png", _state_empty(), false)
	await _capture("m16_t03_02_codex_single_rescued_card.png", _state_single(), false)
	await _capture("m16_t03_03_codex_three_rescued_cards.png", _state_three(), false)
	await _capture("m16_t03_04_rescue_count_derived_visible.png", _state_count(), false)
	await _capture("m16_t03_05_codex_card_fallback_placeholder.png", _state_single(), true)

	print("[M16-T03] viewport screenshot generation complete. Saved: ", _saved.size(), " files.")
	quit(1 if _failed or _saved.size() < 5 else 0)


func _capture(filename: String, rescue_state: Dictionary, force_placeholder: bool) -> void:
	for child in get_root().get_children():
		child.queue_free()
	await process_frame

	var panel = _make_panel(rescue_state, force_placeholder)
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(420, 500)
	get_root().add_child(panel)
	panel.show()
	panel.update_display()
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	if image == null:
		printerr("[M16-T03] viewport capture failed: ", filename)
		_failed = true
		return
	if image.get_width() != 960 or image.get_height() != 540:
		image.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var path := _output_dir.path_join(filename)
	var err := image.save_png(_to_absolute_path(path))
	if err == OK:
		_saved.append(filename)
		print("[M16-T03] viewport screenshot saved: ", filename)
	else:
		printerr("[M16-T03] viewport screenshot save failed: ", filename, " err=", err)
		_failed = true


func _make_panel(rescue_state: Dictionary, force_placeholder: bool):
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var PanelScript = load("res://scenes/ui/LivestockPanel.gd")
	var gs = GameStateScript.new()
	gs.initialize()
	gs.rescue_system.import_state({
		"dock_state": {},
		"active_rescue": {},
		"completed_rescues": rescue_state.get("completed_rescues", []),
		"codex_rescue_marks": rescue_state.get("codex_rescue_marks", {}),
		"ecological_reputation": 0,
		"total_release_rp_reward": 0,
		"release_reward_sum_reputation": 0,
		"event_log": [],
		"rng_state": 1,
	})
	var panel = PanelScript.new()
	panel.setup(gs)
	if force_placeholder:
		var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
		var library = LibraryScript.new()
		library.initialize()
		var manifest := _load_json_dict("res://data/card_manifest.json")
		if manifest.has("cards"):
			for i in range(manifest["cards"].size()):
				if str(manifest["cards"][i].get("species_id", "")) == "rescue_clownfish_juvenile":
					manifest["cards"][i]["asset_path"] = "res://assets/cards/rescue/missing_asset.png"
		library.set_manifest_for_test(manifest)
		library.set_placeholder_generation_enabled_for_test(true)
		panel.card_library = library
	panel.update_display()
	return panel


func _state_empty() -> Dictionary:
	return {"codex_rescue_marks": {}, "completed_rescues": []}


func _state_single() -> Dictionary:
	return {
		"codex_rescue_marks": {
			"rescue_clownfish_juvenile": {"rescued": true, "last_released_day": 3},
		},
		"completed_rescues": [_completed("rescue_clownfish_juvenile", "迷路小丑鱼", 3)],
	}


func _state_three() -> Dictionary:
	return {
		"codex_rescue_marks": {
			"rescue_clownfish_juvenile": {"rescued": true, "last_released_day": 3},
			"rescue_cleaner_shrimp": {"rescued": true, "last_released_day": 4},
			"rescue_goby": {"rescued": true, "last_released_day": 5},
		},
		"completed_rescues": [
			_completed("rescue_clownfish_juvenile", "迷路小丑鱼", 3),
			_completed("rescue_cleaner_shrimp", "受困清洁虾", 4),
			_completed("rescue_goby", "虚弱虾虎", 5),
		],
	}


func _state_count() -> Dictionary:
	return {
		"codex_rescue_marks": {
			"rescue_goby": {"rescued": true, "last_released_day": 8},
		},
		"completed_rescues": [
			_completed("rescue_goby", "虚弱虾虎", 5),
			_completed("rescue_goby", "虚弱虾虎", 8),
		],
	}


func _completed(species_id: String, species_name: String, day: int) -> Dictionary:
	return {
		"rescue_id": "%s_%d" % [species_id, day],
		"species_id": species_id,
		"species_name": species_name,
		"released_at_day": day,
		"rescue_status": "released",
		"recovery_progress": 100.0,
	}


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _to_absolute_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path
