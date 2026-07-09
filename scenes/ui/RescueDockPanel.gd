class_name RescueDockPanel
extends PanelContainer

signal close_requested

var game_state: GameState = null
var title_label: Label = null
var reputation_label: Label = null
var dock_status_label: Label = null
var candidate_label: Label = null
var candidate_desc_label: Label = null
var bring_back_btn: Button = null
var slot_label: Label = null
var progress_bar: ProgressBar = null
var progress_label: Label = null
var release_btn: Button = null
var feedback_label: Label = null
var codex_label: Label = null
var _built: bool = false


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.15, 0.96)
	style.border_color = Color(0.28, 0.56, 0.62)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", style)


func setup(gs: GameState) -> void:
	game_state = gs
	if not _built:
		_build_ui()
		_built = true
	update_display()


func update_display() -> void:
	if not _built or game_state == null:
		return
	var state: Dictionary = game_state.get_rescue_ui_state()
	var has_candidate: bool = bool(state.get("has_candidate", false))
	var has_active: bool = bool(state.get("has_active", false))
	var ready: bool = bool(state.get("ready_to_release", false))
	var candidate: Dictionary = state.get("candidate", {}) if state.get("candidate", {}) is Dictionary else {}
	var active: Dictionary = state.get("active_rescue", {}) if state.get("active_rescue", {}) is Dictionary else {}
	var cost: float = float(state.get("bring_back_cost_rp", 0.0))
	var progress: float = float(state.get("recovery_progress", 0.0))
	var current_rp: float = float(state.get("reef_points", 0.0))
	var next_day: int = int(state.get("next_arrival", 1))
	var current_day: int = int(state.get("current_day", 1))

	if title_label != null:
		title_label.text = "救助码头"
	if reputation_label != null:
		reputation_label.text = "生态声望 %d｜完成救助 %d" % [int(state.get("ecological_reputation", 0)), int(state.get("completed_rescue_count", 0))]
	if dock_status_label != null:
		dock_status_label.text = "入口状态：%s" % String(state.get("status_text", "等待"))

	if has_candidate:
		candidate_label.text = "待救助：%s" % String(candidate.get("species_name", "未知生物"))
		candidate_desc_label.text = "被渔网困住，状态虚弱｜带回成本 %.0f RP｜预计 %.0f 分钟内恢复" % [cost, float(state.get("target_recovery_seconds", 720.0)) / 60.0]
	elif has_active:
		candidate_label.text = "码头等待下一只生物"
		candidate_desc_label.text = "救助位已占用，请先完成当前救助"
	else:
		candidate_label.text = "暂无待救助生物"
		candidate_desc_label.text = "下一次到达：第%d天（当前第%d天）" % [next_day, current_day]

	if bring_back_btn != null:
		bring_back_btn.disabled = (not has_candidate) or has_active or current_rp < cost
		bring_back_btn.text = "带回救助"
		if current_rp < cost:
			bring_back_btn.tooltip_text = "RP不足，需要 %.0f RP" % cost
		elif has_active:
			bring_back_btn.tooltip_text = "救助位已占用"
		else:
			bring_back_btn.tooltip_text = "调用 RescueSystem 接收当前待救助生物"

	if has_active:
		slot_label.text = "唯一救助位：%s｜%s" % [String(active.get("species_name", "未知生物")), "可放归" if ready else "恢复中"]
		progress_bar.value = progress
		progress_label.text = "恢复 %.1f%%｜速度 %.2f/ tick｜水质 %.0f 舒适 %.0f" % [
			progress,
			float(active.get("last_recovery_delta", 0.0)),
			float(active.get("last_water_quality_score", 0.0)),
			float(active.get("last_comfort_score", 0.0)),
		]
	else:
		slot_label.text = "唯一救助位：空"
		progress_bar.value = 0.0
		progress_label.text = "救助生物不产金币，不可出售，不进入普通容量经济"

	if release_btn != null:
		release_btn.disabled = not ready
		release_btn.text = "放归" if ready else "等待恢复"

	var feedback: Dictionary = state.get("last_feedback", {}) if state.get("last_feedback", {}) is Dictionary else {}
	if feedback_label != null:
		feedback_label.text = String(feedback.get("summary", "等待玩家操作"))
	if codex_label != null:
		codex_label.text = _format_codex_marks(state.get("codex_rescue_marks", {}))


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	title_label = _make_label("救助码头", 16, Color(0.88, 0.96, 0.94))
	root.add_child(title_label)

	reputation_label = _make_label("生态声望 0", 11, Color(0.72, 0.90, 0.78))
	root.add_child(reputation_label)

	dock_status_label = _make_label("入口状态：等待", 10, Color(0.76, 0.84, 0.86))
	root.add_child(dock_status_label)

	candidate_label = _make_label("暂无待救助生物", 12, Color(0.86, 0.90, 0.88))
	root.add_child(candidate_label)

	candidate_desc_label = _make_label("", 10, Color(0.64, 0.76, 0.78))
	candidate_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(candidate_desc_label)

	bring_back_btn = Button.new()
	bring_back_btn.name = "BringBackRescueButton"
	bring_back_btn.text = "带回救助"
	bring_back_btn.custom_minimum_size = Vector2(0, 28)
	bring_back_btn.add_theme_font_size_override("font_size", 11)
	bring_back_btn.pressed.connect(_on_bring_back_pressed)
	root.add_child(bring_back_btn)

	var sep: HSeparator = HSeparator.new()
	root.add_child(sep)

	slot_label = _make_label("唯一救助位：空", 12, Color(0.86, 0.92, 0.90))
	root.add_child(slot_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "RescueProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.custom_minimum_size = Vector2(0, 18)
	root.add_child(progress_bar)

	progress_label = _make_label("", 10, Color(0.68, 0.80, 0.82))
	root.add_child(progress_label)

	release_btn = Button.new()
	release_btn.name = "ReleaseRescueButton"
	release_btn.text = "等待恢复"
	release_btn.disabled = true
	release_btn.custom_minimum_size = Vector2(0, 28)
	release_btn.add_theme_font_size_override("font_size", 11)
	release_btn.pressed.connect(_on_release_pressed)
	root.add_child(release_btn)

	feedback_label = _make_label("等待玩家操作", 10, Color(0.82, 0.88, 0.76))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(feedback_label)

	codex_label = _make_label("图鉴救助标记：暂无", 10, Color(0.72, 0.84, 0.80))
	codex_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(codex_label)

	var close_btn: Button = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(0, 26)
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.pressed.connect(_on_close_pressed)
	root.add_child(close_btn)


func _on_bring_back_pressed() -> void:
	if game_state == null:
		return
	game_state.bring_back_current_rescue()
	update_display()


func _on_release_pressed() -> void:
	if game_state == null:
		return
	game_state.release_ready_rescue()
	update_display()


func _on_close_pressed() -> void:
	hide()
	close_requested.emit()


func _format_codex_marks(raw_marks: Variant) -> String:
	if not raw_marks is Dictionary:
		return "图鉴救助标记：暂无"
	var marks: Dictionary = raw_marks
	if marks.is_empty():
		return "图鉴救助标记：暂无"
	var parts: PackedStringArray = PackedStringArray()
	for species_id in marks.keys():
		var mark: Variant = marks.get(species_id, {})
		if mark is Dictionary and bool(mark.get("rescued", false)):
			parts.append(String(species_id) + " 已救助")
	if parts.is_empty():
		return "图鉴救助标记：暂无"
	return "图鉴救助标记：" + "｜".join(parts)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = false
	return label
