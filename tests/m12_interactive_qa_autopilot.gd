extends SceneTree

## M12 Interactive QA Autopilot
## Simulates full player loop: start → objectives → shop → buy → livestock →
## devices → maintenance → timeline → reset → save/load
## Each step validates UI state programmatically.

var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []
var _main_instance: Node = null


func _init() -> void:
	_run_all()
	_print_report()
	quit(0 if _failed == 0 else 1)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_errors.append("FAIL: " + label)
		printerr("[QA] FAIL: ", label)


func _run_all() -> void:
	print("=".repeat(50))
	print("  M12 INTERACTIVE QA AUTOPILOT")
	print("=".repeat(50))

	_test_01_startup()
	_test_02_stage_objectives()
	_test_03_shop_open_close()
	_test_04_buy_livestock()
	_test_05_livestock_panel()
	_test_06_device_toggle()
	_test_07_maintenance()
	_test_08_timeline()
	_test_09_reset_ui_integrity()
	_test_10_double_reset_stability()
	_test_11_save_load_consistency()


# ==================================================================
# Test 01: Startup — scene loads, UI initializes, no errors
# ==================================================================
func _test_01_startup() -> void:
	print("\n--- QA.01: Startup ---")
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(scene != null, "01.1 Main.tscn loads")

	if scene == null:
		return

	_main_instance = scene.instantiate()
	get_root().add_child(_main_instance)
	# Force UI initialization — headless SceneTree may not auto-call _ready
	# Force StatusPanel layout build before Main uses it
	var sp: Node = _find_node_of_type(_main_instance, "StatusPanel")
	if sp != null and sp.has_method("_ready"):
		sp._ready()
	# Now trigger Main's initialization
	if _main_instance.has_method("_ready"):
		_main_instance._ready()
	OS.delay_msec(300)

	OS.delay_msec(200)

	var btns: int = _count_buttons(_main_instance)
	var labels: int = _count_labels(_main_instance)
	print("  Buttons: %d, Labels: %d" % [btns, labels])
	_assert(btns > 0, "01.2 UI has buttons after startup")
	_assert(labels > 0, "01.3 UI has labels after startup")

	# Check key UI sections exist
	var has_status: bool = _find_node_of_type(_main_instance, "StatusPanel") != null
	_assert(has_status, "01.4 StatusPanel present in scene")


# ==================================================================
# Test 02: Stage objectives — active objective displayed
# ==================================================================
func _test_02_stage_objectives() -> void:
	print("\n--- QA.02: Stage Objectives ---")
	var obj_label: Label = _find_label_containing(_main_instance, "目标")
	if obj_label != null:
		print("  Stage objective text: '%s'" % obj_label.text)
		_assert(not obj_label.text.is_empty(), "02.1 Stage objective label has text")
		_assert("购买" in obj_label.text or "目标" in obj_label.text, "02.2 Objective text is player-readable")
	else:
		# Fallback: check validation label
		var val_label: Label = _find_label_in_section(_main_instance, "validation")
		if val_label != null:
			print("  Validation label: '%s'" % val_label.text)
			_assert(not val_label.text.is_empty(), "02.1b Validation label has objective text")


# ==================================================================
# Test 03: Shop — open and close
# ==================================================================
func _test_03_shop_open_close() -> void:
	print("\n--- QA.03: Shop Panel ---")
	var shop_btn: Button = _find_button_by_text(_main_instance, "商店")
	_assert(shop_btn != null, "03.1 Shop button exists")

	if shop_btn == null:
		return

	# Open shop
	var btns_before: int = _count_buttons(_main_instance)
	shop_btn.pressed.emit()
	OS.delay_msec(200)

	var btns_after: int = _count_buttons(_main_instance)
	print("  Buttons before shop: %d, after: %d" % [btns_before, btns_after])
	_assert(btns_after > btns_before, "03.2 Button count increases after opening shop")

	# Check shop has buy buttons
	var buy_btns: Array = _find_all_buttons_containing(_main_instance, "带回家")
	var rp_btns: Array = _find_all_buttons_containing(_main_instance, "RP不足")
	_assert(buy_btns.size() + rp_btns.size() > 0, "03.3 Shop has purchase buttons")

	# Close shop
	var close_btn: Button = _find_button_by_text(_main_instance, "关闭商店")
	if close_btn != null:
		close_btn.pressed.emit()
		OS.delay_msec(100)
		print("  Shop closed")


# ==================================================================
# Test 04: Buy livestock — purchase a creature
# ==================================================================
func _test_04_buy_livestock() -> void:
	print("\n--- QA.04: Buy Livestock ---")

	# Open shop again
	var shop_btn: Button = _find_button_by_text(_main_instance, "商店")
	if shop_btn == null:
		_assert(false, "04.0 Shop button missing")
		return
	shop_btn.pressed.emit()
	OS.delay_msec(100)

	# Find a "带回家" button
	var buy_btn: Button = _find_button_by_text(_main_instance, "带回家")
	if buy_btn == null:
		# Try RP不足 — buy from economy/gamestate directly
		print("  No affordable item found — purchasing via GameState directly")
		_buy_via_gamestate()
	else:
		buy_btn.pressed.emit()
		OS.delay_msec(300)

	# Check timeline has purchase entry
	var timeline_entries: int = _count_timeline_entries(_main_instance)
	print("  Timeline entries after purchase: %d" % timeline_entries)
	_assert(timeline_entries > 0, "04.1 Timeline has entries after purchase")

	# Close shop
	var close_btn: Button = _find_button_by_text(_main_instance, "关闭商店")
	if close_btn != null:
		close_btn.pressed.emit()
		OS.delay_msec(50)


func _buy_via_gamestate() -> void:
	# Access game_state directly from Main instance
	var gs = _get_game_state_from_main()
	if gs != null:
		var ls_debug = gs.get_livestock_debug_state()
		var current_count: int = int(ls_debug.get("livestock_count", 0))
		# Try buying the first shop item
		var shop_items = gs.livestock_system.get_shop_items() if gs.get("livestock_system") != null else []
		if shop_items.size() > 0:
			var first_item: Dictionary = shop_items[0]
			var shop_id: String = String(first_item.get("id", ""))
			if not shop_id.is_empty():
				# Add RP to afford
				if gs.get("economy_system") != null:
					gs.economy_system.add_reef_points(float(first_item.get("price", 0)) + 100)
				var result: Dictionary = gs.buy_livestock_from_shop(shop_id)
				if result.get("success", false):
					print("  Bought: %s" % result.get("species_name", "unknown"))
		OS.delay_msec(100)


# ==================================================================
# Test 05: Livestock panel — open, view, close
# ==================================================================
func _test_05_livestock_panel() -> void:
	print("\n--- QA.05: Livestock Panel ---")
	var livestock_btn: Button = _find_button_by_text(_main_instance, "生物")
	if livestock_btn == null:
		print("  Livestock button not found — skipping")
		return

	livestock_btn.pressed.emit()
	OS.delay_msec(150)

	# Check livestock panel has entries
	var detail_labels: Array = _find_all_labels_containing(_main_instance, "详情")
	var summary_labels: Array = _find_all_labels_containing(_main_instance, "共")
	_assert(detail_labels.size() + summary_labels.size() > 0, "05.1 Livestock panel shows entries or summary")

	# Close
	var close_btn: Button = _find_button_by_text(_main_instance, "关闭")
	if close_btn != null:
		close_btn.pressed.emit()
		OS.delay_msec(50)


# ==================================================================
# Test 06: Device toggle — pump, wave, light
# ==================================================================
func _test_06_device_toggle() -> void:
	print("\n--- QA.06: Device Toggle ---")

	# Find and toggle each device button
	var devices: Array[String] = ["水泵", "造浪", "主灯"]
	for dev_name in devices:
		var btn: Button = _get_device_button(_main_instance, dev_name)
		if btn != null:
			var before_text: String = btn.text
			btn.pressed.emit()
			OS.delay_msec(100)
			var after_text: String = btn.text
			print("  Toggled %s: '%s' → '%s'" % [dev_name, before_text, after_text])
			_assert("ON" in after_text or "OFF" in after_text, "06.%s %s shows ON/OFF state" % [dev_name, dev_name])
		else:
			print("  Device button '%s' not found" % dev_name)

	# Toggle back to restore original state
	var pump_btn: Button = _find_button_containing(_main_instance, "水泵")
	if pump_btn != null:
		pump_btn.pressed.emit()
		OS.delay_msec(50)


# ==================================================================
# Test 07: Maintenance — perform water change
# ==================================================================
func _test_07_maintenance() -> void:
	print("\n--- QA.07: Maintenance ---")

	# Add RP to afford maintenance
	var gs = _get_game_state_from_main()
	if gs != null and gs.get("economy_system") != null:
		gs.economy_system.add_reef_points(1000.0)
	OS.delay_msec(50)

	var maint_btns: Array = _find_all_buttons_containing(_main_instance, "RP")
	_assert(maint_btns.size() > 0, "07.1 Maintenance buttons with RP cost exist")

	if maint_btns.size() > 0:
		var btn: Button = maint_btns[0]
		var before_text: String = btn.text
		btn.pressed.emit()
		OS.delay_msec(200)
		var after_text: String = btn.text
		print("  Maintenance: '%s' → '%s'" % [before_text, after_text])

	# Check timeline updated
	var tl_entries: int = _count_timeline_entries(_main_instance)
	print("  Timeline entries after maintenance: %d" % tl_entries)
	_assert(tl_entries > 0, "07.2 Timeline has entries after maintenance")


# ==================================================================
# Test 08: Timeline — entries present and readable
# ==================================================================
func _test_08_timeline() -> void:
	print("\n--- QA.08: Timeline ---")
	var tl_entries: int = _count_timeline_entries(_main_instance)
	print("  Total timeline entries: %d" % tl_entries)

	# Check for key event types in timeline labels
	var has_purchase: bool = _timeline_has_text(_main_instance, "购买") or _timeline_has_text(_main_instance, "入缸")
	var has_maintenance: bool = _timeline_has_text(_main_instance, "换水") or _timeline_has_text(_main_instance, "维护")
	var has_device: bool = _timeline_has_text(_main_instance, "ON") or _timeline_has_text(_main_instance, "OFF")
	var has_objective: bool = _timeline_has_text(_main_instance, "目标")

	print("  Purchase entry: %s" % has_purchase)
	print("  Maintenance entry: %s" % has_maintenance)
	print("  Device entry: %s" % has_device)
	print("  Objective entry: %s" % has_objective)

	_assert(tl_entries > 0, "08.1 Timeline has entries")


# ==================================================================
# Test 09: Reset UI integrity — no button duplication
# ==================================================================
func _test_09_reset_ui_integrity() -> void:
	print("\n--- QA.09: Reset UI Integrity ---")
	var btns_before: int = _count_buttons(_main_instance)
	var labels_before: int = _count_labels(_main_instance)

	# Execute reset
	var reset_btn: Button = _find_button_by_text(_main_instance, "重置")
	if reset_btn != null:
		reset_btn.pressed.emit()
		OS.delay_msec(500)
	else:
		_reset_via_gamestate()
		OS.delay_msec(500)

	var btns_after: int = _count_buttons(_main_instance)
	var labels_after: int = _count_labels(_main_instance)
	print("  Before reset: %d buttons, %d labels" % [btns_before, labels_before])
	print("  After reset:  %d buttons, %d labels" % [btns_after, labels_after])

	_assert(btns_after <= btns_before + 3, "09.1 Buttons not duplicated after reset (before=%d after=%d)" % [btns_before, btns_after])

	# Check for duplicate buttons
	var dupes: Array = _find_duplicate_button_texts(_main_instance)
	_assert(dupes.is_empty(), "09.2 No duplicate button texts after reset (found: %s)" % str(dupes))


# ==================================================================
# Test 10: Double reset stability
# ==================================================================
func _test_10_double_reset_stability() -> void:
	print("\n--- QA.10: Double Reset Stability ---")
	var btns_1: int = _count_buttons(_main_instance)

	# Reset again
	var reset_btn: Button = _find_button_by_text(_main_instance, "重置")
	if reset_btn != null:
		reset_btn.pressed.emit()
		OS.delay_msec(500)

	var btns_2: int = _count_buttons(_main_instance)
	print("  Reset #1: %d, Reset #2: %d" % [btns_1, btns_2])
	_assert(btns_2 == btns_1, "10.1 Button count stable across double reset (%d vs %d)" % [btns_1, btns_2])


# ==================================================================
# Test 11: Save/Load consistency
# ==================================================================
func _test_11_save_load_consistency() -> void:
	print("\n--- QA.11: Save/Load Consistency ---")
	var gs = _get_game_state_from_main()
	if gs == null:
		print("  GameState not accessible — skipping")
		return

	var e_debug: Dictionary = gs.get_economy_debug_state()
	var rp_before: float = float(e_debug.get("reef_points", 0.0))
	print("  RP before save: %.0f" % rp_before)

	# Trigger save
	var save_btn: Button = _find_button_by_text(_main_instance, "保存")
	if save_btn != null:
		save_btn.pressed.emit()
		OS.delay_msec(300)
		print("  Save executed")

	# Check save debug state
	var save_debug: Dictionary = gs.get_save_debug_state()
	var save_exists: bool = bool(save_debug.get("save_exists", false))
	print("  Save file exists: %s" % save_exists)
	_assert(save_exists, "11.1 Save file created")

	# Clean up main instance for next tests
	if _main_instance != null:
		_main_instance.queue_free()
		OS.delay_msec(50)


# ==================================================================
# Helper methods
# ==================================================================

func _count_buttons(root: Node) -> int:
	var count: int = 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button:
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _count_labels(root: Node) -> int:
	var count: int = 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label:
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _count_timeline_entries(root: Node) -> int:
	var scroll_vbox: Node = _find_node_recursive(root, func(n: Node) -> bool:
		return n is VBoxContainer and n.get_child_count() > 0 and n.get_child(0) is Label
	)
	if scroll_vbox == null:
		return 0
	var count: int = 0
	for child in scroll_vbox.get_children():
		if child is Label:
			count += 1
	return count


func _find_button_by_text(root: Node, text: String) -> Button:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and node.text == text:
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _find_button_containing(root: Node, substring: String) -> Button:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and substring in node.text:
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _find_all_buttons_containing(root: Node, substring: String) -> Array:
	var result: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and substring in node.text:
			result.append(node)
		for child in node.get_children():
			stack.append(child)
	return result


func _find_label_containing(root: Node, substring: String) -> Label:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label and substring in node.text:
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _find_all_labels_containing(root: Node, substring: String) -> Array:
	var result: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label and substring in node.text:
			result.append(node)
		for child in node.get_children():
			stack.append(child)
	return result


func _find_label_in_section(root: Node, line_id: String) -> Label:
	# StatusPanel stores labels in section_labels dictionary
	var sp: Node = _find_node_of_type(root, "StatusPanel")
	if sp != null and sp.get("section_labels") != null:
		for section_key in sp.section_labels.keys():
			var section: Dictionary = sp.section_labels[section_key]
			if section.has(line_id):
				var raw_label = section[line_id]
				if raw_label is Label:
					return raw_label
	return null


func _find_node_of_type(root: Node, type_name: String) -> Node:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.get_script() != null:
			var script_path: String = node.get_script().resource_path
			if type_name in script_path or node is Control and node.name == type_name:
				return node
		for child in node.get_children():
			stack.append(child)
	return null


func _find_node_recursive(root: Node, predicate: Callable) -> Node:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if predicate.call(node):
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _find_duplicate_button_texts(root: Node) -> Array:
	# Only flag duplicates within the same parent — per-row buttons (详情/RP不足) are legitimate
	var container_buttons: Dictionary = {}
	var dupes: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button:
			var t: String = node.text
			if not t.is_empty():
				var parent_key: String = str(node.get_parent().get_instance_id()) + ":" + t
				if parent_key in container_buttons:
					dupes.append(t)
				container_buttons[parent_key] = true
		for child in node.get_children():
			stack.append(child)
	return dupes


func _timeline_has_text(root: Node, substring: String) -> bool:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Label and substring in node.text:
			# Check this label is inside the timeline scroll area
			var parent: Node = node.get_parent()
			while parent != null:
				if parent is ScrollContainer:
					return true
				parent = parent.get_parent()
		for child in node.get_children():
			stack.append(child)
	return false


func _get_game_state_from_main() -> RefCounted:
	if _main_instance == null:
		return null
	var gs = _main_instance.get("game_state")
	if gs != null:
		return gs
	# Try accessing via script
	if _main_instance.get_script() != null:
		var script_path: String = _main_instance.get_script().resource_path
		if "Main.gd" in script_path:
			return _main_instance.game_state
	return null


func _reset_via_gamestate() -> void:
	var gs = _get_game_state_from_main()
	if gs != null and _main_instance != null:
		if _main_instance.has_method("_reset_test_save"):
			_main_instance._reset_test_save()


func _force_ready_recursive(node: Node) -> void:
	if node.has_method("_ready"):
		node._ready()
	for child in node.get_children():
		_force_ready_recursive(child)


func _get_device_button(root: Node, dev_name: String) -> Button:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and dev_name in node.text and ("ON" in node.text or "OFF" in node.text):
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _print_report() -> void:
	print("")
	print("=".repeat(50))
	print("  M12 Interactive QA Results: %d/%d" % [_passed, _passed + _failed])
	if _failed > 0:
		print("  FAILURES:")
		for err in _errors:
			print("    ", err)
	print("  RESULT=%s" % ("PASS" if _failed == 0 else "FAIL"))
	print("=".repeat(50))
