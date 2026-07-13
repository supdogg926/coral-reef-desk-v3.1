class_name M19CodexPanel
extends PanelContainer

var _service: BlueGuardianService = null
var _species_list: ItemList = null
var _main_image: TextureRect = null
var _species_name: Label = null
var _badge_label: Label = null
var _category_label: Label = null
var _desc_label: Label = null
var _region_label: Label = null
var _release_count_label: Label = null
var _progress_label: Label = null
var _filter_buttons: Dictionary = {}
var _all_species_ids: Array[String] = []
var _current_filter: String = "全部"
var _selected_id: String = ""

const SHELL := M19SharedTheme.SHELL_L
const CHROME_SHELL := "res://assets/m19/ui/chrome/shell_05_codex_empty.png"
const FILTERS := ["全部", "鱼类", "珊瑚", "其他"]


func setup(service: BlueGuardianService) -> void:
	_service = service
	_all_species_ids = BlueGuardianConfig.get_active_species_pool()
	_build()


func _build() -> void:
	custom_minimum_size = SHELL.size
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -SHELL.size.x / 2.0; offset_top = -SHELL.size.y / 2.0
	offset_right = SHELL.size.x / 2.0; offset_bottom = SHELL.size.y / 2.0

	# Freeze shell plate
	var shell_tr := TextureRect.new()
	shell_tr.name = "Shell05Plate"
	shell_tr.position = Vector2.ZERO
	shell_tr.size = SHELL.size
	shell_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shell_tr.stretch_mode = TextureRect.STRETCH_KEEP
	shell_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CHROME_SHELL):
		shell_tr.texture = ResourceLoader.load(CHROME_SHELL, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	add_child(shell_tr)

	# Hide old visual containers — freeze shell replaces them
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20); margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20); margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	margin.add_child(inner)

	M19SharedTheme.make_title_bar(inner, "生物图鉴", Callable(self, "_on_close"))

	# Filter row
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	inner.add_child(filter_row)
	for f in FILTERS:
		var fb := M19SharedTheme.make_text_button(f)
		fb.pressed.connect(_on_filter.bind(f))
		filter_row.add_child(fb)
		_filter_buttons[f] = fb

	# Three-column content
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(content)

	# Left column: species list
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(220, 0)
	content.add_child(left)

	_species_list = ItemList.new()
	_species_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_species_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_species_list.item_selected.connect(_on_species_selected)
	left.add_child(_species_list)

	# Center: main image
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 8)
	center.custom_minimum_size = Vector2(320, 0)
	content.add_child(center)

	_main_image = M19SharedTheme.make_image_slot(M19SharedTheme.SLOT_A, "CodexMainImage")
	center.add_child(_main_image)

	_species_name = M19SharedTheme.make_label("", M19SharedTheme.FONT_HEADING, M19SharedTheme.TEXT_PRIMARY)
	_species_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_species_name)

	_badge_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_GOLD)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_badge_label)

	# Right: info fields
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)

	var info_grid := GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 12)
	info_grid.add_theme_constant_override("v_separation", 4)
	right.add_child(info_grid)

	info_grid.add_child(M19SharedTheme.make_label("生态类别", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_category_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY)
	info_grid.add_child(_category_label)

	info_grid.add_child(M19SharedTheme.make_label("发现区域", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_region_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY)
	info_grid.add_child(_region_label)

	info_grid.add_child(M19SharedTheme.make_label("累计放归", M19SharedTheme.FONT_SMALL, M19SharedTheme.TEXT_MUTED))
	_release_count_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_PRIMARY)
	info_grid.add_child(_release_count_label)

	# Description
	_desc_label = M19SharedTheme.make_label("", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_MUTED)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_desc_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	# Action bar with progress
	var action := M19SharedTheme.make_action_bar(inner)
	_progress_label = M19SharedTheme.make_label("已发现 0/16", M19SharedTheme.FONT_BODY, M19SharedTheme.TEXT_ACCENT)
	action.add_child(_progress_label)

	var spacer_action := Control.new()
	spacer_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_child(spacer_action)

	var close_btn := M19SharedTheme.make_secondary_button("关闭")
	close_btn.pressed.connect(_on_close)
	action.add_child(close_btn)

	_refresh_list()

	
	# Hide ALL old visual containers — only freeze shell + its children should be visible
	for child in get_children():
		if child is VBoxContainer or child is MarginContainer or child is HBoxContainer:
			if child.name != "FactLayer" and child.name != "HitLayer":
				child.visible = false
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _refresh_list() -> void:
	_species_list.clear()
	if _service == null:
		return
	var discovered: Array = _service.get_collection_ids()

	for sid in _all_species_ids:
		var cat := BlueGuardianConfig.get_species_rarity_tier(sid)
		var type_str := _get_type_string(sid)

		# Apply filter
		if _current_filter == "鱼类" and type_str != "fish":
			continue
		if _current_filter == "珊瑚" and type_str != "coral":
			continue
		if _current_filter == "其他" and (type_str == "fish" or type_str == "coral"):
			continue

		var display := _get_display_name(sid)
		var prefix := "✓ " if discovered.has(sid) else "○ "
		var idx := _species_list.add_item(prefix + display)
		_species_list.set_item_metadata(idx, sid)
		_species_list.set_item_custom_fg_color(idx, M19SharedTheme.TEXT_ACCENT if discovered.has(sid) else M19SharedTheme.TEXT_MUTED)

	var total := _all_species_ids.size()
	_progress_label.text = "已发现 %d/%d" % [discovered.size(), total]


func _on_species_selected(idx: int) -> void:
	var sid: String = _species_list.get_item_metadata(idx)
	_selected_id = sid
	if _service == null:
		return

	var discovered: Array = _service.get_collection_ids()
	var is_discovered := discovered.has(sid)

	_species_name.text = _get_display_name(sid) if is_discovered else "？？？"
	_category_label.text = BlueGuardianConfig.get_species_rarity_tier(sid) if is_discovered else "未知"
	_region_label.text = BlueGuardianConfig.get_species_region(sid)
	_desc_label.text = _get_description(sid) if is_discovered else "尚未发现该物种，继续航行探索吧"

	if is_discovered:
		_badge_label.text = "已发现"
		_badge_label.add_theme_color_override("font_color", M19SharedTheme.TEXT_ACCENT)
		var tex := M19SharedTheme.load_species_texture(sid)
		if tex != null:
			_main_image.texture = tex
		else:
			_main_image.texture = null
		# Count releases from rescue system
		var release_count := 0
		if _service.rescue_gw != null:
			var debug: Dictionary = _service.rescue_gw.get_debug_state()
			for rec in debug.get("completed_rescues", []):
				if rec is Dictionary and str(rec.get("species_id", "")) == sid:
					release_count += 1
		_release_count_label.text = str(release_count) if release_count > 0 else "0"
	else:
		_badge_label.text = "未发现"
		_badge_label.add_theme_color_override("font_color", M19SharedTheme.TEXT_MUTED)
		_main_image.texture = null
		_release_count_label.text = "-"


func _on_filter(filter: String) -> void:
	_current_filter = filter
	_refresh_list()
	# Highlight active filter
	for f in _filter_buttons:
		var btn: Button = _filter_buttons[f]
		btn.add_theme_color_override("font_color", M19SharedTheme.TEXT_ACCENT if f == filter else M19SharedTheme.TEXT_MUTED)


func _get_display_name(sid: String) -> String:
	var reg: Variant = Engine.get_main_loop()
	if reg is SceneTree:
		var root: Window = reg.root
		for child in root.get_children():
			if child is DataRegistry:
				var raw: Dictionary = child.get_species_by_id(sid)
				if raw is Dictionary and not raw.is_empty():
					return str(raw.get("name", raw.get("name_cn", sid)))
	return sid


func _get_description(sid: String) -> String:
	var reg: Variant = Engine.get_main_loop()
	if reg is SceneTree:
		var root: Window = reg.root
		for child in root.get_children():
			if child is DataRegistry:
				var raw: Dictionary = child.get_species_by_id(sid)
				if raw is Dictionary and not raw.is_empty():
					return str(raw.get("desc", raw.get("description", "")))
	return ""


func _get_type_string(sid: String) -> String:
	var region := BlueGuardianConfig.get_species_region(sid)
	# Approximate: use rarity tier as proxy for category display
	var tier := BlueGuardianConfig.get_species_rarity_tier(sid)
	# Check species_type from registry
	var reg: Variant = Engine.get_main_loop()
	if reg is SceneTree:
		var root: Window = reg.root
		for child in root.get_children():
			if child is DataRegistry:
				var raw: Dictionary = child.get_species_by_id(sid)
				if raw is Dictionary and not raw.is_empty():
					var st := str(raw.get("species_type", raw.get("type", "")))
					if st in ["fish", "coral", "shrimp", "crab"]:
						return st
	# Fallback: classify by pool position
	var fish_keywords := ["clownfish", "shrimp", "crab", "tang", "firefish", "gramma", "angel", "seahorse", "dragonet"]
	for kw in fish_keywords:
		if kw in sid:
			return "fish"
	return "coral"


func _on_close() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()
		if _species_list.item_count > 0:
			_species_list.select(0)
			_on_species_selected(0)
