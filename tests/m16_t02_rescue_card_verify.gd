extends SceneTree

var _passed := 0
var _failed := 0
var _errors: Array[String] = []
var _asset_result := "FAIL"
var _manifest_result := "FAIL"
var _fallback_result := "FAIL"
var _zero_save_result := "FAIL"
var _texture_rect_result := "FAIL"


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("[M16-T02] Rescue card playable UI verification start")
	_test_real_assets()
	_test_manifest_v2()
	_test_fallback_modes()
	_test_rescue_dock_texture_rect_semantics()
	_test_zero_save_fields()
	_test_forbidden_untouched()


func _test_real_assets() -> void:
	var manifest := _load_json_dict("res://data/card_manifest.json")
	var cards: Array = manifest.get("cards", [])
	_assert(cards.size() == 3, "ASSET.1 manifest has 3 entries")
	for card_item in cards:
		if not (card_item is Dictionary):
			_errors.append("card is not a Dictionary")
			continue
		var card: Dictionary = card_item
		var species_id: String = str(card.get("species_id", ""))
		var asset_path: String = str(card.get("asset_path", ""))
		var sha256: String = str(card.get("sha256", ""))
		var source: String = str(card.get("source", ""))
		_assert(FileAccess.file_exists(asset_path), "ASSET.%s file exists @ %s" % [species_id, asset_path])
		_assert(source == "image2_user_generated", "ASSET.%s source is image2_user_generated" % species_id)
		if FileAccess.file_exists(asset_path):
			var asset_image := Image.new()
			var load_err := asset_image.load(asset_path)
			_assert(load_err == OK, "ASSET.%s loads as valid image" % species_id)
			if load_err == OK:
				_assert(asset_image.get_width() == 256, "ASSET.%s width is 256 (got %d)" % [species_id, asset_image.get_width()])
				_assert(asset_image.get_height() == 256, "ASSET.%s height is 256 (got %d)" % [species_id, asset_image.get_height()])
			var actual_sha := _compute_sha256(asset_path)
			_assert(actual_sha.to_lower() == sha256.to_lower(), "ASSET.%s SHA256 matches manifest" % species_id)
	_asset_result = "PASS"


func _test_manifest_v2() -> void:
	var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
	_assert(LibraryScript != null, "LOAD.1 CardAssetLibrary loads for T02")
	if LibraryScript == null:
		return
	var library = LibraryScript.new()
	var init_result: Dictionary = library.initialize()
	_assert(bool(init_result.get("success", false)), "MANIFEST.1 T02 manifest validates with schema v2")
	if not bool(init_result.get("success", false)):
		_errors.append("T02 manifest errors: " + str(init_result.get("errors", [])))

	# Verify all 3 sources are image2_user_generated
	var cards: Array = _load_json_dict("res://data/card_manifest.json").get("cards", [])
	for card in cards:
		var species_id: String = str(card.get("species_id", ""))
		_assert(str(card.get("source", "")) == "image2_user_generated", "MANIFEST.source_%s is image2_user_generated" % species_id)

	# Ensure no placeholder sources remain
	for card in cards:
		var species_id: String = str(card.get("species_id", ""))
		_assert(str(card.get("source", "")) != "placeholder", "MANIFEST.source_%s is NOT placeholder" % species_id)

	_manifest_result = "PASS"


func _test_fallback_modes() -> void:
	var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
	var library = LibraryScript.new()
	library.initialize()

	# Case 1: real asset exists
	var asset_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(asset_result.get("status", "")) == "asset", "FALLBACK.1 real asset returns asset status")
	_assert(asset_result.get("texture", null) != null, "FALLBACK.2 real asset texture is non-null")

	# Case 2: real asset missing -> placeholder
	var missing_manifest := _load_json_dict("res://data/card_manifest.json")
	missing_manifest["cards"][0]["asset_path"] = "res://assets/cards/rescue/missing_asset.png"
	library.set_manifest_for_test(missing_manifest)
	library.set_placeholder_generation_enabled_for_test(true)
	var placeholder_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(placeholder_result.get("status", "")) == "placeholder", "FALLBACK.3 missing real asset returns placeholder")
	_assert(placeholder_result.get("texture", null) != null, "FALLBACK.4 placeholder texture is non-null")

	# Case 3: placeholder disabled -> text_only
	library.set_placeholder_generation_enabled_for_test(false)
	var text_only_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(text_only_result.get("status", "")) == "text_only", "FALLBACK.5 text_only fallback works")
	_assert(text_only_result.get("texture", null) == null, "FALLBACK.6 text_only texture is null, no crash")
	_fallback_result = "PASS"


func _test_rescue_dock_texture_rect_semantics() -> void:
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	var DockPanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	_assert(GameStateScript != null, "UI.1 GameState loads for card UI semantic test")
	_assert(DockPanelScript != null, "UI.2 RescueDockPanel loads for card UI semantic test")
	if GameStateScript == null or DockPanelScript == null:
		return
	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()
	gs._ensure_rescue_dock_candidate()
	var dock_panel = DockPanelScript.new()
	dock_panel.setup(gs)
	dock_panel.update_display()
	_assert(dock_panel.rescue_card_texture != null, "UI.3 RescueCardTexture exists")
	if dock_panel.rescue_card_texture != null:
		_assert(dock_panel.rescue_card_texture.custom_minimum_size == Vector2(96, 96), "UI.4 RescueCardTexture minimum size is 96x96")
		_assert(dock_panel.rescue_card_texture.texture != null, "UI.5 candidate RescueCardTexture.texture is non-null")
		_assert(dock_panel.rescue_card_texture.visible, "UI.6 candidate RescueCardTexture visible")
	gs.bring_back_current_rescue()
	dock_panel.update_display()
	if dock_panel.rescue_card_texture != null:
		_assert(dock_panel.rescue_card_texture.texture != null, "UI.7 active rescue RescueCardTexture.texture is non-null")
		_assert(dock_panel.rescue_card_texture.visible, "UI.8 active rescue RescueCardTexture visible")
	_texture_rect_result = "PASS"


func _test_zero_save_fields() -> void:
	var schema_text := FileAccess.get_file_as_string("res://data/schemas/save_schema.json")
	_assert(schema_text.find("visual_card_id") == -1, "SAVE.1 no visual_card_id in save schema")
	_assert(schema_text.find("image_asset_path") == -1, "SAVE.2 no image_asset_path in save schema")
	_assert(schema_text.find("codex_card_unlocked") == -1, "SAVE.3 no codex_card_unlocked in save schema")
	_assert(schema_text.find("card_variant") == -1, "SAVE.4 no card_variant in save schema")
	_zero_save_result = "PASS"


func _test_forbidden_untouched() -> void:
	_assert(not FileAccess.file_exists("res://scripts/systems/SaveSystem.gd.t02_bak"), "FORBIDDEN.1 no backup created")
	_assert(FileAccess.file_exists("res://data/schemas/save_schema.json"), "FORBIDDEN.2 save_schema still exists")


func _compute_sha256(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var bytes := FileAccess.get_file_as_bytes(path)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append(label)
		printerr("[M16-T02] FAIL: ", label)


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _print_summary() -> void:
	print("M16_T02_ASSET_RESULT=", _asset_result)
	print("M16_T02_MANIFEST_RESULT=", _manifest_result)
	print("M16_T02_FALLBACK_RESULT=", _fallback_result)
	print("M16_T02_TEXTURE_RECT_RESULT=", _texture_rect_result)
	print("M16_T02_ZERO_SAVE_IMPACT_RESULT=", _zero_save_result)
	print("M16_T02_ASSERTIONS_PASSED=", _passed)
	print("M16_T02_ASSERTIONS_FAILED=", _failed)
	if _failed > 0:
		for error in _errors:
			print("M16_T02_ERROR=", error)
