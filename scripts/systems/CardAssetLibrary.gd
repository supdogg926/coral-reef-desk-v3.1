extends RefCounted
class_name CardAssetLibrary

const DEFAULT_MANIFEST_PATH := "res://data/card_manifest.json"
const DEFAULT_SCHEMA_PATH := "res://data/schemas/card_manifest_schema.json"
const DEFAULT_SPECIES_POOL_PATH := "res://data/species_rescue_pool.json"
const PLACEHOLDER_WIDTH := 320
const PLACEHOLDER_HEIGHT := 200
const ALLOWED_SOURCE_T01 := "placeholder"

var manifest_path := DEFAULT_MANIFEST_PATH
var schema_path := DEFAULT_SCHEMA_PATH
var species_pool_path := DEFAULT_SPECIES_POOL_PATH

var _manifest: Dictionary = {}
var _species_by_id: Dictionary = {}
var _placeholder_generation_enabled := true


func initialize(
		p_manifest_path: String = DEFAULT_MANIFEST_PATH,
		p_species_pool_path: String = DEFAULT_SPECIES_POOL_PATH,
		p_schema_path: String = DEFAULT_SCHEMA_PATH
) -> Dictionary:
	manifest_path = p_manifest_path
	species_pool_path = p_species_pool_path
	schema_path = p_schema_path
	_species_by_id = _load_species_pool(species_pool_path)
	_manifest = _load_json_file(manifest_path)
	return validate_manifest(_manifest)


func get_card_texture(species_id: String) -> Dictionary:
	if _species_by_id.is_empty():
		_species_by_id = _load_species_pool(species_pool_path)
	if _manifest.is_empty():
		_manifest = _load_json_file(manifest_path)

	var card := _find_card(species_id)
	if not card.is_empty():
		var texture := _load_texture_from_path(str(card.get("asset_path", "")))
		if texture != null:
			return {
				"success": true,
				"status": "asset",
				"species_id": species_id,
				"asset_path": str(card.get("asset_path", "")),
				"texture": texture
			}

	if _placeholder_generation_enabled:
		var placeholder := create_placeholder_texture(species_id)
		if placeholder != null:
			return {
				"success": true,
				"status": "placeholder",
				"species_id": species_id,
				"asset_path": "",
				"texture": placeholder
			}

	return {
		"success": true,
		"status": "text_only",
		"species_id": species_id,
		"asset_path": "",
		"texture": null
	}


func validate_manifest(manifest: Dictionary = {}) -> Dictionary:
	var target := manifest
	if target.is_empty():
		target = _load_json_file(manifest_path)
	var errors: Array[String] = []
	var schema := _load_json_file(schema_path)
	if schema.is_empty():
		errors.append("card manifest schema is missing or invalid")
	if _species_by_id.is_empty():
		_species_by_id = _load_species_pool(species_pool_path)
	if _species_by_id.is_empty():
		errors.append("species_rescue_pool is empty or invalid")

	if int(target.get("schema_version", -1)) != 1:
		errors.append("schema_version must be 1")
	var species_count := _species_by_id.size()
	var max_entries := int(target.get("max_entries", -1))
	if max_entries != species_count:
		errors.append("max_entries must equal species_rescue_pool count: expected %d, got %d" % [species_count, max_entries])

	var cards_value = target.get("cards", null)
	if not (cards_value is Array):
		errors.append("cards must be an array")
		return _validation_result(errors)

	var cards: Array = cards_value
	if cards.size() > species_count:
		errors.append("card entries exceed species_rescue_pool count: %d > %d" % [cards.size(), species_count])
	if cards.size() != species_count:
		errors.append("cards must contain exactly one entry per rescue species: expected %d, got %d" % [species_count, cards.size()])

	var seen := {}
	for index in range(cards.size()):
		var card_value = cards[index]
		if not (card_value is Dictionary):
			errors.append("card entry %d must be an object" % index)
			continue
		var card: Dictionary = card_value
		var species_id := str(card.get("species_id", ""))
		var asset_path := str(card.get("asset_path", ""))
		var sha256 := str(card.get("sha256", ""))
		var source := str(card.get("source", ""))

		if species_id == "":
			errors.append("card entry %d species_id is required" % index)
		elif not _species_by_id.has(species_id):
			errors.append("species_id not found in species_rescue_pool: %s" % species_id)
		elif seen.has(species_id):
			errors.append("duplicate species_id in card manifest: %s" % species_id)
		seen[species_id] = true

		if source != ALLOWED_SOURCE_T01:
			errors.append("source must be placeholder in M16-T01: %s" % source)
		if not asset_path.begins_with("res://"):
			errors.append("asset_path must be a res:// path for %s" % species_id)
		if not _is_ascii(asset_path.get_file()):
			errors.append("asset filename must be ASCII for %s: %s" % [species_id, asset_path.get_file()])
		if sha256.length() != 64:
			errors.append("sha256 must be 64 lowercase hex chars for %s" % species_id)
		elif not FileAccess.file_exists(asset_path):
			errors.append("asset file is missing for %s: %s" % [species_id, asset_path])
		else:
			var actual_sha := compute_file_sha256(asset_path)
			if actual_sha != sha256:
				errors.append("sha256 mismatch for %s: expected %s, got %s" % [species_id, sha256, actual_sha])

	for species_id in _species_by_id.keys():
		if not seen.has(species_id):
			errors.append("missing card manifest entry for species_id: %s" % species_id)

	return _validation_result(errors)


func set_manifest_for_test(manifest: Dictionary) -> void:
	_manifest = manifest.duplicate(true)


func set_placeholder_generation_enabled_for_test(enabled: bool) -> void:
	_placeholder_generation_enabled = enabled


func create_placeholder_texture(species_id: String) -> Texture2D:
	var image := create_placeholder_image(species_id)
	return ImageTexture.create_from_image(image)


func create_placeholder_image(species_id: String) -> Image:
	var image := Image.create(PLACEHOLDER_WIDTH, PLACEHOLDER_HEIGHT, false, Image.FORMAT_RGBA8)
	var theme := _theme_color_for_species(species_id)
	var accent := Color(minf(theme.r + 0.35, 1.0), minf(theme.g + 0.35, 1.0), minf(theme.b + 0.35, 1.0), 1.0)
	image.fill(theme)
	image.fill_rect(Rect2i(0, 0, PLACEHOLDER_WIDTH, 14), accent)
	image.fill_rect(Rect2i(0, PLACEHOLDER_HEIGHT - 14, PLACEHOLDER_WIDTH, 14), accent)
	image.fill_rect(Rect2i(20, 26, 118, 8), Color(1, 1, 1, 0.78))
	image.fill_rect(Rect2i(118, 48, 86, 52), Color(0.08, 0.11, 0.14, 0.56))
	image.fill_rect(Rect2i(136, 60, 50, 28), accent)
	_draw_ascii_text(image, "RESCUE CARD", Vector2i(20, 44), 2, Color.WHITE)
	var lines := _wrap_species_id(species_id, 25)
	var y := 124
	for line in lines:
		_draw_ascii_text(image, line, Vector2i(20, y), 2, Color.WHITE)
		y += 18
	_draw_ascii_text(image, "PLACEHOLDER", Vector2i(20, 170), 1, Color.WHITE)
	return image


func generate_placeholder_png(species_id: String, output_path: String) -> Dictionary:
	var image := create_placeholder_image(species_id)
	var err := image.save_png(output_path)
	if err != OK:
		return {"success": false, "error": "save_png_failed:%d" % err, "path": output_path}
	return {"success": true, "path": output_path, "sha256": compute_file_sha256(output_path)}


func compute_file_sha256(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var bytes := FileAccess.get_file_as_bytes(path)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func validate_visual_evidence(options: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var image_path := str(options.get("image_path", ""))
	var source := str(options.get("source", ""))
	var min_width := int(options.get("min_width", 960))
	var min_height := int(options.get("min_height", 540))
	var min_variance := float(options.get("min_variance", 0.0001))

	if source != "viewport":
		errors.append("screenshot source must be viewport")
	var image := Image.new()
	var err := image.load(image_path)
	if err != OK:
		errors.append("image could not be loaded: %s" % image_path)
	else:
		if image.get_width() < min_width or image.get_height() < min_height:
			errors.append("image resolution below threshold: %dx%d" % [image.get_width(), image.get_height()])
		if image.get_width() == 32 and image.get_height() == 32:
			errors.append("image must not be a 32x32 placeholder")
		var full_variance := calculate_image_variance(image)
		if full_variance < min_variance:
			errors.append("image variance is too low: %.8f" % full_variance)

		if options.has("card_rect"):
			var card_rect: Rect2i = options["card_rect"]
			var card_variance := calculate_image_variance(image, card_rect)
			if card_variance < min_variance:
				errors.append("card region variance is too low: %.8f" % card_variance)

	var semantics: Dictionary = options.get("semantic_assertions", {})
	for key in semantics.keys():
		if not bool(semantics[key]):
			errors.append("UI semantic assertion failed: %s" % str(key))

	var texture_rect = options.get("texture_rect", null)
	if texture_rect != null:
		if not texture_rect.get("texture"):
			errors.append("TextureRect.texture must not be null")
		if texture_rect is Control:
			var size: Vector2 = texture_rect.size
			if size.x < 64.0 or size.y < 64.0:
				errors.append("TextureRect rendered size must be at least 64px")

	var sha_checks: Array = options.get("manifest_sha_checks", [])
	for item in sha_checks:
		if not (item is Dictionary):
			errors.append("manifest_sha_checks entries must be objects")
			continue
		var path := str(item.get("path", ""))
		var expected_sha := str(item.get("sha256", ""))
		var actual_sha := compute_file_sha256(path)
		if actual_sha != expected_sha:
			errors.append("manifest SHA mismatch for visual evidence check: %s" % path)

	return _validation_result(errors)


func calculate_image_variance(image: Image, region: Rect2i = Rect2i()) -> float:
	var rect := region
	if rect.size == Vector2i.ZERO:
		rect = Rect2i(0, 0, image.get_width(), image.get_height())
	rect.position.x = clampi(rect.position.x, 0, image.get_width() - 1)
	rect.position.y = clampi(rect.position.y, 0, image.get_height() - 1)
	rect.size.x = clampi(rect.size.x, 1, image.get_width() - rect.position.x)
	rect.size.y = clampi(rect.size.y, 1, image.get_height() - rect.position.y)
	var step_x := maxi(1, rect.size.x / 80)
	var step_y := maxi(1, rect.size.y / 80)
	var values: Array[float] = []
	for y in range(rect.position.y, rect.position.y + rect.size.y, step_y):
		for x in range(rect.position.x, rect.position.x + rect.size.x, step_x):
			var color := image.get_pixel(x, y)
			values.append((color.r + color.g + color.b) / 3.0)
	if values.is_empty():
		return 0.0
	var mean := 0.0
	for value in values:
		mean += value
	mean /= values.size()
	var variance := 0.0
	for value in values:
		var delta := value - mean
		variance += delta * delta
	return variance / values.size()


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _load_species_pool(path: String) -> Dictionary:
	var result := {}
	if not FileAccess.file_exists(path):
		return result
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not (parsed is Array):
		return result
	for item in parsed:
		if item is Dictionary and item.has("id"):
			result[str(item["id"])] = item
	return result


func _find_card(species_id: String) -> Dictionary:
	var cards: Array = _manifest.get("cards", [])
	for card in cards:
		if card is Dictionary and str(card.get("species_id", "")) == species_id:
			return card
	return {}


func _load_texture_from_path(path: String) -> Texture2D:
	if not path.begins_with("res://") or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _validation_result(errors: Array[String]) -> Dictionary:
	return {"success": errors.is_empty(), "errors": errors}


func _is_ascii(value: String) -> bool:
	for index in range(value.length()):
		if value.unicode_at(index) > 127:
			return false
	return true


func _theme_color_for_species(species_id: String) -> Color:
	var hash := 2166136261
	for byte in species_id.to_utf8_buffer():
		hash = int((hash ^ byte) * 16777619) & 0x7fffffff
	var hue := float(hash % 360) / 360.0
	return Color.from_hsv(hue, 0.56, 0.62, 1.0)


func _wrap_species_id(species_id: String, max_chars: int) -> Array[String]:
	var parts := species_id.split("_", false)
	var lines: Array[String] = []
	var current := ""
	for part in parts:
		var candidate := part if current == "" else current + "_" + part
		if candidate.length() > max_chars and current != "":
			lines.append(current)
			current = part
		else:
			current = candidate
	if current != "":
		lines.append(current)
	return lines


func _draw_ascii_text(image: Image, text: String, origin: Vector2i, scale: int, color: Color) -> void:
	var cursor := origin
	for index in range(text.length()):
		var character := text.substr(index, 1).to_lower()
		if character == " ":
			cursor.x += 4 * scale
			continue
		_draw_ascii_char(image, character, cursor, scale, color)
		cursor.x += 6 * scale


func _draw_ascii_char(image: Image, character: String, origin: Vector2i, scale: int, color: Color) -> void:
	var patterns := _font_patterns()
	var pattern: Array = patterns.get(character, patterns.get("?"))
	for row_index in pattern.size():
		var row := str(pattern[row_index])
		for col_index in range(row.length()):
			if row.substr(col_index, 1) == "1":
				image.fill_rect(Rect2i(origin.x + col_index * scale, origin.y + row_index * scale, scale, scale), color)


func _font_patterns() -> Dictionary:
	return {
		"a": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
		"b": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
		"c": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
		"d": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
		"e": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
		"f": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
		"g": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
		"h": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
		"i": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
		"j": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
		"k": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
		"l": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
		"m": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
		"n": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
		"o": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
		"p": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
		"q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
		"r": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
		"s": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
		"t": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
		"u": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
		"v": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
		"w": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
		"x": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
		"y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
		"z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
		"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
		"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
		"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
		"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
		"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
		"5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
		"6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
		"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
		"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
		"9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
		"_": ["00000", "00000", "00000", "00000", "00000", "00000", "11111"],
		"-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
		"?": ["01110", "10001", "00001", "00010", "00100", "00000", "00100"]
	}
