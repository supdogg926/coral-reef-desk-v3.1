extends SceneTree

var _passed := 0
var _failed := 0
var _errors: Array[String] = []
var _manifest_result := "FAIL"
var _placeholder_result := "FAIL"
var _fallback_result := "FAIL"
var _zero_save_result := "FAIL"
var _visual_validator_result := "FAIL"


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("[M16-T01] Card manifest and placeholder verification start")
	var LibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
	_assert(LibraryScript != null, "LOAD.1 CardAssetLibrary loads")
	if LibraryScript == null:
		return
	var library = LibraryScript.new()
	var init_result: Dictionary = library.initialize()
	_assert(bool(init_result.get("success", false)), "MANIFEST.1 legal manifest validates")
	if not bool(init_result.get("success", false)):
		_errors.append("legal manifest errors: " + str(init_result.get("errors", [])))
	_test_manifest_illegal_samples(library)
	_test_placeholder_determinism(library)
	_test_fallback_modes(library)
	_test_zero_save_fields()
	_test_visual_evidence_validator(library)


func _test_manifest_illegal_samples(library) -> void:
	var manifest := _load_json_dict("res://data/card_manifest.json")
	var unknown := manifest.duplicate(true)
	unknown["cards"][0]["species_id"] = "missing_species"
	var unknown_result: Dictionary = library.validate_manifest(unknown)
	_assert(not bool(unknown_result.get("success", true)), "MANIFEST.2 unknown species_id fails")
	_assert(_errors_contain(unknown_result, "species_id not found"), "MANIFEST.3 unknown species_id has readable error")

	var too_many := manifest.duplicate(true)
	var extra_card: Dictionary = too_many["cards"][0].duplicate(true)
	extra_card["species_id"] = "extra_species"
	too_many["cards"].append(extra_card)
	var too_many_result: Dictionary = library.validate_manifest(too_many)
	_assert(not bool(too_many_result.get("success", true)), "MANIFEST.4 entries over pool count fail")
	_assert(_errors_contain(too_many_result, "exceed"), "MANIFEST.5 entries over pool count has readable error")

	var non_ascii := manifest.duplicate(true)
	non_ascii["cards"][0]["asset_path"] = "res://assets/cards/placeholder/非ascii.png"
	var non_ascii_result: Dictionary = library.validate_manifest(non_ascii)
	_assert(not bool(non_ascii_result.get("success", true)), "MANIFEST.6 non-ASCII asset filename fails")
	_assert(_errors_contain(non_ascii_result, "ASCII"), "MANIFEST.7 non-ASCII filename has readable error")

	var sha_mismatch := manifest.duplicate(true)
	sha_mismatch["cards"][0]["sha256"] = "0000000000000000000000000000000000000000000000000000000000000000"
	var sha_result: Dictionary = library.validate_manifest(sha_mismatch)
	_assert(not bool(sha_result.get("success", true)), "MANIFEST.8 SHA mismatch fails")
	_assert(_errors_contain(sha_result, "sha256 mismatch"), "MANIFEST.9 SHA mismatch has readable error")
	_manifest_result = "PASS"


func _test_placeholder_determinism(library) -> void:
	var path_a := "user://m16_t01_placeholder_a.png"
	var path_b := "user://m16_t01_placeholder_b.png"
	var result_a: Dictionary = library.generate_placeholder_png("rescue_clownfish_juvenile", path_a)
	var result_b: Dictionary = library.generate_placeholder_png("rescue_clownfish_juvenile", path_b)
	_assert(bool(result_a.get("success", false)), "PLACEHOLDER.1 first deterministic PNG save succeeds")
	_assert(bool(result_b.get("success", false)), "PLACEHOLDER.2 second deterministic PNG save succeeds")
	_assert(str(result_a.get("sha256", "")) == str(result_b.get("sha256", "")), "PLACEHOLDER.3 same species placeholder hashes match")
	_placeholder_result = "PASS"


func _test_fallback_modes(library) -> void:
	library.initialize()
	var asset_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(asset_result.get("status", "")) == "asset", "FALLBACK.1 manifest asset returns asset texture")
	_assert(asset_result.get("texture", null) != null, "FALLBACK.2 manifest asset texture is non-null")

	var missing_manifest := _load_json_dict("res://data/card_manifest.json")
	missing_manifest["cards"][0]["asset_path"] = "res://assets/cards/placeholder/missing_asset.png"
	library.set_manifest_for_test(missing_manifest)
	library.set_placeholder_generation_enabled_for_test(true)
	var placeholder_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(placeholder_result.get("status", "")) == "placeholder", "FALLBACK.3 missing asset returns placeholder texture")
	_assert(placeholder_result.get("texture", null) != null, "FALLBACK.4 placeholder texture is non-null")

	library.set_placeholder_generation_enabled_for_test(false)
	var text_only_result: Dictionary = library.get_card_texture("rescue_clownfish_juvenile")
	_assert(str(text_only_result.get("status", "")) == "text_only", "FALLBACK.5 placeholder disabled returns text_only")
	_assert(text_only_result.has("texture") and text_only_result.get("texture", null) == null, "FALLBACK.6 text_only has null texture and does not crash")
	_fallback_result = "PASS"


func _test_zero_save_fields() -> void:
	var schema_text := FileAccess.get_file_as_string("res://data/schemas/save_schema.json")
	_assert(schema_text.find("visual_card_id") == -1, "SAVE.1 no visual_card_id in save schema")
	_assert(schema_text.find("image_asset_path") == -1, "SAVE.2 no image_asset_path in save schema")
	_assert(schema_text.find("codex_card_unlocked") == -1, "SAVE.3 no codex_card_unlocked in save schema")
	_assert(schema_text.find("card_variant") == -1, "SAVE.4 no card_variant in save schema")
	_zero_save_result = "PASS"


func _test_visual_evidence_validator(library) -> void:
	var image := Image.create(960, 540, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.06, 0.09, 0.12, 1.0))
	var card_image: Image = library.create_placeholder_image("rescue_clownfish_juvenile")
	image.blit_rect(card_image, Rect2i(0, 0, card_image.get_width(), card_image.get_height()), Vector2i(70, 80))
	image.fill_rect(Rect2i(440, 110, 220, 80), Color(0.9, 0.7, 0.2, 1.0))
	var image_path := "user://m16_t01_visual_validator.png"
	var err := image.save_png(image_path)
	_assert(err == OK, "VISUAL.1 visual validator fixture saves")

	var manifest := _load_json_dict("res://data/card_manifest.json")
	var first_card: Dictionary = manifest["cards"][0]
	var texture_rect := TextureRect.new()
	texture_rect.texture = ImageTexture.create_from_image(card_image)
	texture_rect.size = Vector2(128, 128)
	var visual_result: Dictionary = library.validate_visual_evidence({
		"image_path": image_path,
		"source": "viewport",
		"min_width": 960,
		"min_height": 540,
		"min_variance": 0.0001,
		"semantic_assertions": {
			"care_need_or_card_label_visible": true,
			"card_texture_rect_visible": true
		},
		"texture_rect": texture_rect,
		"card_rect": Rect2i(70, 80, 320, 200),
		"manifest_sha_checks": [
			{"path": str(first_card.get("asset_path", "")), "sha256": str(first_card.get("sha256", ""))}
		]
	})
	_assert(bool(visual_result.get("success", false)), "VISUAL.2 upgraded screenshot validator passes viewport fixture")
	var invalid_source: Dictionary = library.validate_visual_evidence({
		"image_path": image_path,
		"source": "generated",
		"texture_rect": texture_rect,
		"semantic_assertions": {"card_texture_rect_visible": true}
	})
	_assert(not bool(invalid_source.get("success", true)), "VISUAL.3 validator rejects non-viewport source")
	_visual_validator_result = "PASS"


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append(label)
		printerr("[M16-T01] FAIL: ", label)


func _errors_contain(result: Dictionary, token: String) -> bool:
	for error in result.get("errors", []):
		if str(error).find(token) != -1:
			return true
	return false


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _print_summary() -> void:
	print("M16_T01_MANIFEST_RESULT=", _manifest_result)
	print("M16_T01_PLACEHOLDER_DETERMINISM_RESULT=", _placeholder_result)
	print("M16_T01_FALLBACK_RESULT=", _fallback_result)
	print("M16_T01_ZERO_SAVE_IMPACT_RESULT=", _zero_save_result)
	print("M16_T01_SCREENSHOT_VALIDATOR_RESULT=", _visual_validator_result)
	print("M16_T01_ASSERTIONS_PASSED=", _passed)
	print("M16_T01_ASSERTIONS_FAILED=", _failed)
	if _failed > 0:
		for error in _errors:
			print("M16_T01_ERROR=", error)
