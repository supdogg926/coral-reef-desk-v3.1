extends SceneTree

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
		printerr("[M14-T03] FAIL: ", label)


func _run_tests() -> void:
	print("[M14-T03] Copy/UI verification start")
	var GameStateScript = load("res://scripts/systems/GameState.gd")
	_assert(GameStateScript != null, "LOAD.1 GameState loads")

	if GameStateScript == null:
		return

	var gs = GameStateScript.new()
	gs.initialize()
	gs.economy_system.add_reef_points(20.0)
	gs.reef_points = gs.economy_system.get_reef_points()

	_test_rescue_config()
	_test_ui_copy_text(gs)
	_test_game_state_feedback(gs)
	_test_rescue_ui_structure(gs)
	_test_forbidden_scope()
	_test_save_roundtrip(gs)


func _test_rescue_config() -> void:
	var cfg_path: String = "res://data/rescue_config.json"
	_assert(FileAccess.file_exists(cfg_path), "CFG.1 rescue_config.json exists")
	var file: FileAccess = FileAccess.open(cfg_path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var cfg: Dictionary = JSON.parse_string(text)
	var playable: Dictionary = cfg.get("first_playable", {})
	_assert(playable.has("dock_entry_hint"), "CFG.2 dock_entry_hint present")
	_assert(playable.has("next_arrival_hint"), "CFG.3 next_arrival_hint present")
	_assert(playable.has("release_settlement_hint"), "CFG.4 release_settlement_hint present")
	_assert(float(playable.get("target_recovery_seconds", 0.0)) > 0.0, "CFG.5 target_recovery_seconds > 0")
	_assert(float(playable.get("first_loop_min_seconds", 0.0)) >= 600.0, "CFG.6 first_loop_min >= 600s")
	_assert(float(playable.get("first_loop_max_seconds", 0.0)) <= 900.0, "CFG.7 first_loop_max <= 900s")


func _test_ui_copy_text(gs) -> void:
	var PanelScript = load("res://scenes/ui/RescueDockPanel.gd")
	_assert(PanelScript != null, "COPY.1 RescueDockPanel loads")

	if PanelScript == null:
		return

	var panel = PanelScript.new()
	panel.setup(gs)
	panel.update_display()

	# Title check
	_assert(panel.title_label.text == "海洋救助站", "COPY.2 title is 海洋救助站")

	# Bring back button
	_assert(panel.bring_back_btn.text == "带回照料", "COPY.3 bring_back_btn is 带回照料")

	# Slot label default
	_assert(panel.slot_label.text.find("救助位") >= 0, "COPY.4 slot_label contains 救助位")

	# Fallback feedback
	_assert(panel.feedback_label.text.find("救助站") >= 0, "COPY.5 feedback_label references 救助站")

	# Codex label
	_assert(panel.codex_label.text.find("救助图鉴") >= 0, "COPY.6 codex_label references 救助图鉴")

	# Now trigger candidate and test active states
	gs._ensure_rescue_dock_candidate()
	panel.update_display()
	var state: Dictionary = gs.get_rescue_ui_state()
	if bool(state.get("has_candidate", false)):
		_assert(panel.candidate_label.text.find("待救助") >= 0, "COPY.7 candidate label shows 待救助")

	# Accept rescue and check recovery display
	var accepted: Dictionary = gs.bring_back_current_rescue()
	if bool(accepted.get("success", false)):
		panel.update_display()
		_assert(panel.slot_label.text.find("救助位") >= 0, "COPY.8 active slot shows 救助位")
		_assert(panel.slot_label.text.find("恢复中") >= 0, "COPY.9 active slot shows 恢复中")

	# Check feedback after bring-back
	var fb_summary: String = String(accepted.get("summary", ""))
	_assert(fb_summary.find("照料") >= 0, "COPY.10 bring-back feedback mentions 照料")

	# Simulate full recovery and release
	var elapsed: float = 0.0
	var ready: bool = false
	while elapsed <= 920.0:
		gs._update_rescue_playable(10.0)
		elapsed += 10.0
		state = gs.get_rescue_ui_state()
		if bool(state.get("ready_to_release", false)):
			ready = true
			break

	_assert(ready, "COPY.11 rescue becomes ready within 920s")
	if ready:
		panel.update_display()
		_assert(panel.release_btn.text == "放归大海", "COPY.12 release button shows 放归大海")
		var released: Dictionary = gs.release_ready_rescue()
		panel.update_display()
		var rel_summary: String = String(released.get("summary", ""))
		_assert(rel_summary.find("回归大海") >= 0, "COPY.13 release feedback mentions 回归大海")
		_assert(rel_summary.find("生态声望") >= 0, "COPY.14 release feedback mentions 生态声望")
		_assert(panel.reputation_label.text.find("生态声望") >= 0, "COPY.15 reputation label shows 生态声望")


func _test_game_state_feedback(gs) -> void:
	_assert(gs.rescue_system != null, "GS.1 rescue_system exists")
	var state: Dictionary = gs.get_rescue_ui_state()
	_assert(state.has("status_text"), "GS.2 UI state has status_text")
	_assert(state.has("ecological_reputation"), "GS.3 UI state has ecological_reputation")
	_assert(state.has("completed_rescue_count"), "GS.4 UI state has completed_rescue_count")
	_assert(state.has("codex_rescue_marks"), "GS.5 UI state has codex_rescue_marks")


func _test_rescue_ui_structure(gs) -> void:
	var state: Dictionary = gs.get_rescue_ui_state()
	var required: Array[String] = [
		"status_text", "has_candidate", "has_active", "recovery_progress",
		"ready_to_release", "bring_back_cost_rp", "target_recovery_seconds",
		"next_arrival", "current_day", "ecological_reputation",
		"codex_rescue_marks", "completed_rescue_count", "reef_points"
	]
	var all_present: bool = true
	for key in required:
		if not state.has(key):
			_errors.append("Missing UI state field: " + key)
			all_present = false
	_assert(all_present, "STRUCT.1 all required UI state fields present")

	var st: String = String(state.get("status_text", ""))
	_assert(st in ["待救助", "救助中", "可放归", "等待"], "STRUCT.2 status_text is valid state")


func _test_forbidden_scope() -> void:
	var files_to_check: Array[String] = [
		"res://scenes/ui/RescueDockPanel.gd",
		"res://scenes/ui/StatusPanel.gd",
		"res://scripts/systems/GameState.gd",
		"res://scenes/ui/LivestockPanel.gd",
	]
	var forbidden_words: Array[String] = [
		"海域解锁", "海域系统", "大海图鉴",
		"多救助位", "multi_rescue",
		"伤情分支", "injury_branch",
		"护理操作", "care_action",
		"繁殖", "breeding",
		"卡牌美术", "card_art",
		"复杂动画", "complex_animation",
		"声望商店", "reputation_shop",
		"声望等级", "reputation_level",
	]

	var clean: bool = true
	for fpath in files_to_check:
		if not FileAccess.file_exists(fpath):
			continue
		var file: FileAccess = FileAccess.open(fpath, FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		for kw in forbidden_words:
			if kw in content:
				_errors.append("Forbidden keyword '" + kw + "' found in " + fpath)
				clean = false

	_assert(clean, "FORBID.1 no forbidden keywords in modified files")

	# Check species_master.json not modified
	var sp_diff: Array = []
	var output: Array = []
	var exit_code: int = OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "diff", "--name-only", "v3.2-m14-t02-rescue-first-playable-ui..HEAD", "--", "data/species_master.json"], output)
	if exit_code == 0 and output.size() > 0:
		var joined: String = ""
		for line in output:
			joined += line
		if "species_master.json" in joined:
			_errors.append("species_master.json was modified (FORBIDDEN)")
			clean = false

	_assert(clean, "FORBID.2 species_master.json not modified")


func _test_save_roundtrip(gs) -> void:
	_assert(gs.rescue_system != null, "SAVE.1 rescue_system exists")
	if gs.rescue_system == null:
		return
	var before: Dictionary = gs.rescue_system.export_state()
	gs.rescue_system.import_state(before)
	var after: Dictionary = gs.rescue_system.export_state()
	_assert(
		int(before.get("ecological_reputation", 0)) == int(after.get("ecological_reputation", 0)),
		"SAVE.2 save/load preserves ecological_reputation"
	)
	_assert(
		String(before.get("dock_state", {}).get("current_rescue_id", "")) == String(after.get("dock_state", {}).get("current_rescue_id", "")),
		"SAVE.3 save/load preserves dock current_rescue_id"
	)


func _print_summary() -> void:
	print("")
	print("[M14-T03] Copy/UI verification complete: %d/%d" % [_passed, _passed + _failed])
	if not _errors.is_empty():
		print("[M14-T03] Failures:")
		for e in _errors:
			print("  - " + e)
	var result: String = "PASS" if _failed == 0 else "FAIL"
	print("M14_T03_COPY_UI_VERIFY_RESULT=" + result)
