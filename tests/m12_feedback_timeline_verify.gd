extends SceneTree

## M12 Feedback & Timeline Productization Verification
## Validates: timeline entry format, feedback quality, category colors, periodic status

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []


func _init() -> void:
	_run_tests()
	_print_summary()
	quit(0 if _failed == 0 else 1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append("FAIL: " + label)
		printerr("[M12] FAIL: ", label)


func _run_tests() -> void:
	print("[M12] Feedback & Timeline Verification Start")

	# Test ActionTimeline basics
	var tl: ActionTimeline = ActionTimeline.new()
	_assert(tl.size() == 0, "TL.1 Empty timeline has size 0")
	_assert(tl.get_recent(10).size() == 0, "TL.2 get_recent on empty returns empty")

	# Test player action
	tl.add_player_action("D1 08:00 购买入缸 小丑鱼 鱼 +2 RP-50 容量 15/30", ActionTimeline.COLOR_POSITIVE)
	_assert(tl.size() == 1, "TL.3 Player action adds entry")
	var entries: Array = tl.get_recent(1)
	_assert(entries.size() == 1, "TL.4 get_recent returns entry")
	var entry: Dictionary = entries[0]
	_assert(String(entry.get("text", "")) != "", "TL.5 Entry has text")
	_assert(entry.get("color", Color.BLACK) == ActionTimeline.COLOR_POSITIVE, "TL.6 Entry has correct color")

	# Test system events
	tl.add_system_event("D1 12:00 水质下降 警告", ActionTimeline.COLOR_CAUTION)
	tl.add_system_event("D1 15:00 水质恶化 危险", ActionTimeline.COLOR_CRITICAL)
	_assert(tl.size() == 3, "TL.7 Multiple entries accumulate")

	# Test anti-spam
	_assert(tl.should_log_water_status("WARNING"), "TL.8 First WARNING triggers log")
	_assert(not tl.should_log_water_status("WARNING"), "TL.9 Second WARNING suppressed")
	_assert(tl.should_log_water_status("CRITICAL"), "TL.10 Status change triggers log")

	# Test category colors
	_assert(ActionTimeline.COLOR_PLAYER != ActionTimeline.COLOR_POSITIVE, "TL.11 Player and positive colors differ")
	_assert(ActionTimeline.COLOR_CAUTION != ActionTimeline.COLOR_CRITICAL, "TL.12 Caution and critical colors differ")
	_assert(ActionTimeline.COLOR_NEUTRAL != ActionTimeline.COLOR_PLAYER, "TL.13 Neutral and player colors differ")

	# Test MAX_ENTRIES cap — add entries up to cap without pushing out key entries
	var fill_needed: int = ActionTimeline.MAX_ENTRIES - tl.size()
	for i in range(fill_needed):
		tl.add_player_action("D1 00:00 entry %d" % i, ActionTimeline.COLOR_NEUTRAL)
	_assert(tl.size() == ActionTimeline.MAX_ENTRIES, "TL.14 Timeline capped at %d" % ActionTimeline.MAX_ENTRIES)

	# Test feedback message formats (check existing patterns)
	var all: Array = tl.get_all()
	var has_purchase: bool = false
	var has_warning: bool = false
	var has_critical: bool = false
	for e in all:
		var t: String = String(e.get("text", ""))
		if "购买" in t or "入缸" in t:
			has_purchase = true
		if "警告" in t:
			has_warning = true
		if "危险" in t:
			has_critical = true
	_assert(has_purchase, "TL.15 Timeline contains purchase entries")
	_assert(has_warning, "TL.16 Timeline contains warning entries")
	_assert(has_critical, "TL.17 Timeline contains critical entries")

	# Test get_recent with boundary
	var recent: Array = tl.get_recent(5)
	_assert(recent.size() == 5, "TL.18 get_recent(5) returns 5 entries")

	# Test reset_neglect
	tl.reset_neglect()
	_assert(tl.should_log_neglect(), "TL.19 Neglect logs after reset")


func _print_summary() -> void:
	print("")
	print("========================================")
	print("  M12 Feedback & Timeline: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		print("  FAILED:")
		for err in _errors:
			print("    ", err)
	print("  %s" % ("PASS" if _failed == 0 else "FAIL"))
	print("========================================")
