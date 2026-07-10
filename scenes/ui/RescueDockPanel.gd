class_name RescueDockPanel
extends PanelContainer

signal close_requested

var game_state: GameState = null
var card_library: RefCounted = null
var rescue_card_texture: TextureRect = null
var title_label: Label = null
var reputation_label: Label = null
var dock_status_label: Label = null
var candidate_label: Label = null
var candidate_desc_label: Label = null
var bring_back_btn: Button = null
var slot_label: Label = null
var progress_bar: ProgressBar = null
var progress_label: Label = null
var care_need_label: Label = null
var nutrition_btn: Button = null
var soothe_btn: Button = null
var purify_btn: Button = null
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
	if card_library == null:
		var CardAssetLibraryScript = load("res://scripts/systems/CardAssetLibrary.gd")
		card_library = CardAssetLibraryScript.new()
		card_library.initialize()
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
	var care_need: String = String(state.get("care_need", ""))
	var care_used: bool = bool(state.get("care_used", false))

	if title_label != null:
		title_label.text = "海洋救助站"
	if reputation_label != null:
		reputation_label.text = "生态声望 %d｜累计救助 %d 只｜每次放归都在修复海洋" % [int(state.get("ecological_reputation", 0)), int(state.get("completed_rescue_count", 0))]
	if dock_status_label != null:
		var st: String = String(state.get("status_text", "等待"))
		if st == "待救助":
			dock_status_label.text = "码头来客：有生物等待救助"
		elif st == "救助中":
			dock_status_label.text = "救助位：生物正在恢复中"
		elif st == "可放归":
			dock_status_label.text = "救助位：生物已康复，可以放归"
		else:
			dock_status_label.text = "码头状态：等待下一只需要帮助的生物"

	if has_candidate:
		candidate_label.text = "待救助：%s" % String(candidate.get("species_name", "未知生物"))
		candidate_desc_label.text = "受伤虚弱，需要照料｜带回成本 %.0f RP｜预计 %.0f 分钟内恢复" % [cost, float(state.get("target_recovery_seconds", 720.0)) / 60.0]
	elif has_active:
		candidate_label.text = "救助位工作中"
		candidate_desc_label.text = "当前救助位已占用，请先完成恢复再接收新的救助"
	else:
		candidate_label.text = "暂无待救助生物"
		candidate_desc_label.text = "下一次到达：第%d天（当前第%d天）" % [next_day, current_day]

	if bring_back_btn != null:
		bring_back_btn.disabled = (not has_candidate) or has_active or current_rp < cost
		bring_back_btn.text = "带回照料"
		if current_rp < cost:
			bring_back_btn.tooltip_text = "RP不足，需要 %.0f RP" % cost
		elif has_active:
			bring_back_btn.tooltip_text = "救助位已占用，请先完成当前救助"
		else:
			bring_back_btn.tooltip_text = "将受伤生物带回救助位进行照料恢复"

	if has_active:
		slot_label.text = "救助位：%s｜%s" % [String(active.get("species_name", "未知生物")), "已康复可放归" if ready else "恢复中"]
		progress_bar.value = progress
		progress_label.text = "恢复进度 %.1f%%｜恢复速度 %.2f/ tick｜水质评分 %.0f 舒适度 %.0f" % [
			progress,
			float(active.get("last_recovery_delta", 0.0)),
			float(active.get("last_water_quality_score", 0.0)),
			float(active.get("last_comfort_score", 0.0)),
		]
	else:
		slot_label.text = "救助位：空闲"
		progress_bar.value = 0.0
		progress_label.text = "救助生物不产金币、不可出售、不占用普通容量｜恢复速度与水质舒适度相关"

	if care_need_label != null:
		if has_active:
			care_need_label.text = "护理需求：%s｜每次救助只能护理一次" % _care_need_text(care_need)
		else:
			care_need_label.text = "护理需求：带回救助后显示"
	_update_card_texture(has_candidate, has_active, candidate, active)
	_update_care_buttons(has_active and not ready, care_used)

	if release_btn != null:
		release_btn.disabled = not ready
		release_btn.text = "放归大海" if ready else "等待恢复"

	var feedback: Dictionary = state.get("last_feedback", {}) if state.get("last_feedback", {}) is Dictionary else {}
	if feedback_label != null:
		feedback_label.text = String(feedback.get("summary", "欢迎来到海洋救助站"))
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

	title_label = _make_label("海洋救助站", 16, Color(0.88, 0.96, 0.94))
	root.add_child(title_label)

	reputation_label = _make_label("生态声望 0｜累计救助 0 只", 11, Color(0.72, 0.90, 0.78))
	root.add_child(reputation_label)

	dock_status_label = _make_label("码头状态：等待下一只需要帮助的生物", 10, Color(0.76, 0.84, 0.86))
	root.add_child(dock_status_label)

	rescue_card_texture = TextureRect.new()
	rescue_card_texture.name = "RescueCardTexture"
	rescue_card_texture.custom_minimum_size = Vector2(96, 96)
	rescue_card_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	rescue_card_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(rescue_card_texture)

	candidate_label = _make_label("暂无待救助生物", 12, Color(0.86, 0.90, 0.88))
	root.add_child(candidate_label)

	candidate_desc_label = _make_label("", 10, Color(0.64, 0.76, 0.78))
	candidate_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(candidate_desc_label)

	bring_back_btn = Button.new()
	bring_back_btn.name = "BringBackRescueButton"
	bring_back_btn.text = "带回照料"
	bring_back_btn.custom_minimum_size = Vector2(0, 28)
	bring_back_btn.add_theme_font_size_override("font_size", 11)
	bring_back_btn.pressed.connect(_on_bring_back_pressed)
	root.add_child(bring_back_btn)

	var sep: HSeparator = HSeparator.new()
	root.add_child(sep)

	slot_label = _make_label("救助位：空闲", 12, Color(0.86, 0.92, 0.90))
	root.add_child(slot_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "RescueProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.custom_minimum_size = Vector2(0, 18)
	root.add_child(progress_bar)

	progress_label = _make_label("救助生物不产金币、不可出售、不占用普通容量", 10, Color(0.68, 0.80, 0.82))
	root.add_child(progress_label)

	care_need_label = _make_label("护理需求：带回救助后显示", 10, Color(0.84, 0.86, 0.70))
	care_need_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(care_need_label)

	var care_row: HBoxContainer = HBoxContainer.new()
	care_row.add_theme_constant_override("separation", 4)
	root.add_child(care_row)

	nutrition_btn = _make_care_button("NutritionCareButton", "营养补给", "nutrition")
	care_row.add_child(nutrition_btn)
	soothe_btn = _make_care_button("SootheCareButton", "安抚照料", "soothe")
	care_row.add_child(soothe_btn)
	purify_btn = _make_care_button("PurifyCareButton", "净水护理", "purify")
	care_row.add_child(purify_btn)

	release_btn = Button.new()
	release_btn.name = "ReleaseRescueButton"
	release_btn.text = "等待恢复"
	release_btn.disabled = true
	release_btn.custom_minimum_size = Vector2(0, 28)
	release_btn.add_theme_font_size_override("font_size", 11)
	release_btn.pressed.connect(_on_release_pressed)
	root.add_child(release_btn)

	feedback_label = _make_label("欢迎来到海洋救助站", 10, Color(0.82, 0.88, 0.76))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(feedback_label)

	codex_label = _make_label("救助图鉴：暂无已救助记录", 10, Color(0.72, 0.84, 0.80))
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


func _on_care_pressed(action: String) -> void:
	if game_state == null:
		return
	game_state.apply_rescue_care(action)
	update_display()


func _on_close_pressed() -> void:
	hide()
	close_requested.emit()


func _format_codex_marks(raw_marks: Variant) -> String:
	if not raw_marks is Dictionary:
		return "救助图鉴：暂无已救助记录"
	var marks: Dictionary = raw_marks
	if marks.is_empty():
		return "救助图鉴：暂无已救助记录"
	var parts: PackedStringArray = PackedStringArray()
	for species_id in marks.keys():
		var mark: Variant = marks.get(species_id, {})
		if mark is Dictionary and bool(mark.get("rescued", false)):
			parts.append(String(species_id) + " 已救助")
	if parts.is_empty():
		return "救助图鉴：暂无已救助记录"
	return "救助图鉴（已救助物种）：" + "｜".join(parts)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = false
	return label


func _make_care_button(node_name: String, text: String, action: String) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(0, 26)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 10)
	button.tooltip_text = "本次救助只能选择一次"
	button.pressed.connect(_on_care_pressed.bind(action))
	return button


func _update_card_texture(has_candidate: bool, has_active: bool, candidate: Dictionary, active: Dictionary) -> void:
	if rescue_card_texture == null or card_library == null:
		return
	if has_active:
		var species_id: String = String(active.get("species_id", ""))
		if not species_id.is_empty():
			var result: Dictionary = card_library.get_card_texture(species_id)
			var texture = result.get("texture", null)
			if texture != null:
				rescue_card_texture.texture = texture
				rescue_card_texture.visible = true
				return
		rescue_card_texture.visible = false
	elif has_candidate:
		var species_id: String = String(candidate.get("species_id", ""))
		if not species_id.is_empty():
			var result: Dictionary = card_library.get_card_texture(species_id)
			var texture = result.get("texture", null)
			if texture != null:
				rescue_card_texture.texture = texture
				rescue_card_texture.visible = true
				return
		rescue_card_texture.visible = false
	else:
		rescue_card_texture.visible = false


func _update_care_buttons(can_care: bool, care_used: bool) -> void:
	var disabled: bool = (not can_care) or care_used
	for button in [nutrition_btn, soothe_btn, purify_btn]:
		if button == null:
			continue
		button.disabled = disabled
		button.tooltip_text = "已护理，本次救助不能再次护理" if care_used else "本次救助只能选择一次"


func _care_need_text(need: String) -> String:
	match need:
		"weak":
			return "虚弱，需要营养"
		"stressed":
			return "紧张，需要安抚"
		"minor_injury":
			return "轻微擦伤，需要净水"
		_:
			return "等待判断"
