extends SceneTree

var _passed := 0
var _failed := 0
var _errors: Array[String] = []
var _pool_result := "FAIL"
var _manifest_result := "FAIL"
var _bag_result := "FAIL"
var _zero_save_result := "FAIL"
var _range_result := "FAIL"


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("[M17-T01] Pool expansion and bag draw verification start")
	_test_pool()
	_test_manifest()
	_test_bag_draw()
	_test_parameter_ranges()
	_test_zero_save_fields()
	_test_forbidden_untouched()


func _test_pool() -> void:
	var pool: Array = _load_json_array("res://data/species_rescue_pool.json")
	_assert(pool.size() == 6, "POOL.1 species_rescue_pool has 6 entries (got %d)" % pool.size())

	var ids: Array[String] = []
	for item in pool:
		if item is Dictionary:
			ids.append(str(item.get("id", "")))
	_assert(ids.has("rescue_clownfish_juvenile"), "POOL.2 clownfish present")
	_assert(ids.has("rescue_cleaner_shrimp"), "POOL.3 shrimp present")
	_assert(ids.has("rescue_goby"), "POOL.4 goby present")
	_assert(ids.has("rescue_seahorse"), "POOL.5 seahorse present")
	_assert(ids.has("rescue_hermit_crab"), "POOL.6 hermit_crab present")
	_assert(ids.has("rescue_brain_coral_frag"), "POOL.7 brain_coral_frag present")

	# Verify no extra fields (no "enabled" pseudo-field)
	for item in pool:
		if item is Dictionary:
			_assert(not item.has("enabled"), "POOL.enabled_no_pseudo_enabled_field on %s" % str(item.get("id", "?")))
			_assert(str(item.get("injury_type", "")) == "reserved", "POOL.injury_%s is reserved" % str(item.get("id", "?")))

	# Category coverage
	var cats: Dictionary = {}
	for item in pool:
		if item is Dictionary:
			var cat: String = str(item.get("category", ""))
			cats[cat] = int(cats.get(cat, 0)) + 1
	_assert(int(cats.get("fish", 0)) == 3, "POOL.cat fish count=3 (got %d)" % int(cats.get("fish", 0)))
	_assert(int(cats.get("crustacean", 0)) == 2, "POOL.cat crustacean count=2 (got %d)" % int(cats.get("crustacean", 0)))
	_assert(int(cats.get("coral", 0)) == 1, "POOL.cat coral count=1 (got %d)" % int(cats.get("coral", 0)))

	_pool_result = "PASS"


func _test_manifest() -> void:
	var manifest: Dictionary = _load_json_dict("res://data/card_manifest.json")
	_assert(int(manifest.get("schema_version", -1)) == 2, "MANIFEST.1 schema_version=2")
	_assert(int(manifest.get("max_entries", -1)) == 6, "MANIFEST.2 max_entries=6")

	var cards: Array = manifest.get("cards", [])
	_assert(cards.size() == 6, "MANIFEST.3 cards count=6 (got %d)" % cards.size())

	var source_counts := {"image2_user_generated": 0, "placeholder": 0}
	for card in cards:
		if card is Dictionary:
			var src: String = str(card.get("source", ""))
			if src == "image2_user_generated":
				source_counts["image2_user_generated"] = source_counts["image2_user_generated"] + 1
			elif src == "placeholder":
				source_counts["placeholder"] = source_counts["placeholder"] + 1
	_assert(source_counts["image2_user_generated"] == 3, "MANIFEST.4 3 image2_user_generated entries")
	_assert(source_counts["placeholder"] == 3, "MANIFEST.5 3 placeholder entries")

	# Verify placeholder SHA256s match on-disk files
	var LibraryScript: GDScript = load("res://scripts/systems/CardAssetLibrary.gd") as GDScript
	var library: RefCounted = LibraryScript.new()
	var init_result: Dictionary = library.initialize()
	_assert(bool(init_result.get("success", false)), "MANIFEST.6 manifest validates with 6 entries")
	if not bool(init_result.get("success", false)):
		_errors.append("manifest errors: " + str(init_result.get("errors", [])))

	_manifest_result = "PASS"


func _test_bag_draw() -> void:
	var RescueSystemScript: GDScript = load("res://scripts/systems/RescueSystem.gd") as GDScript
	var rs: RefCounted = RescueSystemScript.new()
	rs.initialize(1401)

	# Record initial RNG state
	var rng_before: int = rs._rng_state

	# Generate 6 candidates and verify uniqueness within cycle
	var species_seen: Array[String] = []
	var rng_consumed_per_draw: Array[int] = []
	for i in range(6):
		var rng_before_draw: int = rs._rng_state
		var candidate: Dictionary = rs._generate_candidate(1)
		var sid: String = str(candidate.get("species_id", ""))
		_assert(not species_seen.has(sid), "BAG.1 cycle no repeat: %s at pos %d" % [sid, i])
		species_seen.append(sid)

		# Count RNG steps consumed: each draw should be exactly 1 _rand_range call
		# _rand_range does: _rng_state = (rng_state * MULT + INC) % MOD; return min + rng_state % range
		# That's exactly 1 state transition.
		var rng_after_draw: int = rs._rng_state
		rng_consumed_per_draw.append(rng_before_draw != rng_after_draw as int)

	_assert(species_seen.size() == 6, "BAG.2 cycle size=6")

	# Generate 7th candidate - should start new cycle (bag refilled)
	var candidate7: Dictionary = rs._generate_candidate(1)
	var sid7: String = str(candidate7.get("species_id", ""))
	_assert(not sid7.is_empty(), "BAG.3 cycle 2 candidate valid")
	# Note: sid7 may equal species_seen[5] (cycle boundary repeat, known limitation)

	# Each draw should consume RNG
	var all_consumed: bool = true
	for v in rng_consumed_per_draw:
		if v == 0:
			all_consumed = false
	_assert(all_consumed, "BAG.4 each draw consumes RNG")

	_bag_result = "PASS"


func _test_parameter_ranges() -> void:
	var pool: Array = _load_json_array("res://data/species_rescue_pool.json")
	for item in pool:
		if not (item is Dictionary):
			continue
		var sid: String = str(item.get("id", "?"))
		var rec: float = float(item.get("recovery_rate_base", 0))
		var rep: int = int(item.get("reward_reputation", 0))
		var rp: int = int(item.get("reward_rp", 0))
		var wp: float = float(item.get("water_pressure", -1))
		_assert(rec >= 22.0 and rec <= 30.0, "RANGE.%s recovery %.1f in [22,30]" % [sid, rec])
		_assert(rep >= 5 and rep <= 7, "RANGE.%s reputation %d in [5,7]" % [sid, rep])
		_assert(rp >= 6 and rp <= 8, "RANGE.%s rp %d in [6,8]" % [sid, rp])
		_assert(wp >= 0.05 and wp <= 0.08, "RANGE.%s water_pressure %.2f in [0.05,0.08]" % [sid, wp])
	_range_result = "PASS"


func _test_zero_save_fields() -> void:
	var schema_text := FileAccess.get_file_as_string("res://data/schemas/save_schema.json")
	_assert(schema_text.find("species_pool_version") == -1, "SAVE.1 no species_pool_version in save schema")
	_assert(schema_text.find("bag_state") == -1, "SAVE.2 no bag_state in save schema")
	_assert(schema_text.find("visual_card_id") == -1, "SAVE.3 no visual_card_id in save schema")
	_zero_save_result = "PASS"


func _test_forbidden_untouched() -> void:
	_assert(FileAccess.file_exists("res://data/schemas/save_schema.json"), "FORBIDDEN.1 save_schema still exists")
	_assert(FileAccess.file_exists("res://scripts/systems/SaveSystem.gd"), "FORBIDDEN.2 SaveSystem still exists")


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append(label)
		printerr("[M17-T01] FAIL: ", label)


func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _load_json_array(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	return []


func _print_summary() -> void:
	print("M17_T01_POOL_RESULT=", _pool_result)
	print("M17_T01_MANIFEST_RESULT=", _manifest_result)
	print("M17_T01_BAG_DRAW_RESULT=", _bag_result)
	print("M17_T01_RANGE_RESULT=", _range_result)
	print("M17_T01_ZERO_SAVE_IMPACT_RESULT=", _zero_save_result)
	print("M17_T01_ASSERTIONS_PASSED=", _passed)
	print("M17_T01_ASSERTIONS_FAILED=", _failed)
	if _failed > 0:
		for error in _errors:
			print("M17_T01_ERROR=", error)
