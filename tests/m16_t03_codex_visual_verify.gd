extends SceneTree

var _passed := 0
var _failed := 0
var _errors: Array[String] = []
var _codex_result := "FAIL"
var _fallback_result := "FAIL"
var _zero_save_result := "FAIL"


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("[M16-T03] Codex visual record verification start")
	_test_empty_state()
	_test_three_rescued_cards()
	_test_livestock_panel_fallback()
	_test_zero_save_fields()


func _test_empty_state() -> void:
	var panel = _make_panel({})
	panel.update_display()
	_assert(panel.rescue_codex_cards != null, "CODEX.1 rescue codex card container exists")
	_assert(panel.rescue_codex_cards.get_child_count() == 0, "CODEX.2 empty codex has no silhouette/question cards")
	_assert(panel.rescue_codex_label.text == "救助图鉴：暂无已救助记录", "CODEX.3 empty state keeps existing text")


func _test_three_rescued_cards() -> void:
	var completed := [
		_completed("rescue_clownfish_juvenile", "迷路小丑鱼", 3),
		_completed("rescue_cleaner_shrimp", "受困清洁虾", 4),
		_completed("rescue_goby", "虚弱虾虎", 5),
		_completed("rescue_goby", "虚弱虾虎", 6),
	]
	var panel = _make_panel({
		"codex_rescue_marks": {
			"rescue_clownfish_juvenile": {"rescued": true, "last_released_day": 3},
			"rescue_cleaner_shrimp": {"rescued": true, "last_released_day": 4},
			"rescue_goby": {"rescued": true, "last_released_day": 6},
		},
		"completed_rescues": completed,
	})
	panel.update_display()
	_assert(panel.rescue_codex_cards.get_child_count() == 3, "CODEX.4 three rescued species cards visible")
	var counts := {}
	for card in panel.rescue_codex_cards.get_children():
		_assert(card.name.begins_with("RescueCodexCard_"), "CODEX.5 card node is named by species")
		var texture_rect = card.get_node_or_null("RescueCodexCardTexture")
		_assert(texture_rect != null, "CODEX.6 card TextureRect exists")
		if texture_rect != null:
			_assert(texture_rect.texture != null, "CODEX.7 card texture is non-null")
			_assert(texture_rect.custom_minimum_size.x >= 64.0 and texture_rect.custom_minimum_size.y >= 64.0, "CODEX.8 card render size >=64px")
			_assert(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "CODEX.9 card uses keep-aspect-centered")
		var species_label = card.get_node_or_null("RescueCodexSpeciesName")
		var mark_label = card.get_node_or_null("RescueCodexRescuedMark")
		_assert(species_label != null and String(species_label.text) != "", "CODEX.10 species name visible")
		_assert(mark_label != null and String(mark_label.text).begins_with("已救助 x"), "CODEX.11 rescued mark/count visible")
		counts[card.name.replace("RescueCodexCard_", "")] = String(mark_label.text)
	_assert(counts.get("rescue_goby", "") == "已救助 x2", "CODEX.12 rescue_count derived from completed_rescues")
	_assert(counts.get("rescue_clownfish_juvenile", "") == "已救助 x1", "CODEX.13 clownfish count derived from completed_rescues")
	_codex_result = "PASS"


func _test_livestock_panel_fallback() -> void:
	var panel = _make_panel({
		"codex_rescue_marks": {
			"rescue_clownfish_juvenile": {"rescued": true, "last_released_day": 3},
		},
		"completed_rescues": [_completed("rescue_clownfish_juvenile", "迷路小丑鱼", 3)],
	})
	var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
	var library = LibraryScript.new()
	library.initialize()
	var missing_manifest := _load_json_dict("res://data/card_manifest.json")
	missing_manifest["cards"][0]["asset_path"] = "res://assets/cards/rescue/missing_asset.png"
	library.set_manifest_for_test(missing_manifest)
	library.set_placeholder_generation_enabled_for_test(true)
	panel.card_library = library
	panel.update_display()
	var card = panel.rescue_codex_cards.get_child(0)
	var texture_rect = card.get_node_or_null("RescueCodexCardTexture")
	_assert(texture_rect != null and texture_rect.texture != null, "FALLBACK.1 missing real asset displays placeholder texture")
	library.set_placeholder_generation_enabled_for_test(false)
	panel.update_display()
	card = panel.rescue_codex_cards.get_child(0)
	texture_rect = card.get_node_or_null("RescueCodexCardTexture")
	_assert(texture_rect != null and texture_rect.texture == null, "FALLBACK.2 placeholder disabled uses text_only without crash")
	_fallback_result = "PASS"


func _test_zero_save_fields() -> void:
	var schema_text := FileAccess.get_file_as_string("res://data/schemas/save_schema.json")
	_assert(schema_text.find("codex_card_unlocked") == -1, "SAVE.1 no codex_card_unlocked in save schema")
	_assert(schema_text.find("rescue_count") == -1, "SAVE.2 no rescue_count in save schema")
	_assert(schema_text.find("last_rescued_at") == -1, "SAVE.3 no last_rescued_at in save schema")
	_assert(schema_text.find("visual_card_id") == -1, "SAVE.4 no visual_card_id in save schema")
	_assert(schema_text.find("image_asset_path") == -1, "SAVE.5 no image_asset_path in save schema")
	_assert(schema_text.find("card_variant") == -1, "SAVE.6 no card_variant in save schema")
	_zero_save_result = "PASS"


func _make_panel(rescue_state: Dictionary):
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
	return panel


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


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append(label)
		printerr("[M16-T03] FAIL: ", label)


func _print_summary() -> void:
	print("M16_T03_CODEX_VISUAL_RECORD_RESULT=", _codex_result)
	print("M16_T03_FALLBACK_RESULT=", _fallback_result)
	print("M16_T03_ZERO_SAVE_IMPACT_RESULT=", _zero_save_result)
	print("M16_T03_ASSERTIONS_PASSED=", _passed)
	print("M16_T03_ASSERTIONS_FAILED=", _failed)
	if _failed > 0:
		for error in _errors:
			print("M16_T03_ERROR=", error)
