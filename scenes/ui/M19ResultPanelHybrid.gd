class_name M19ResultPanelHybrid
extends PanelContainer
# M19 HYBRID_RASTER_UI Phase 1 — 04 Result Page
# PlateLayer: chrome shell from master
# FactLayer: dynamic text, images, buttons overlaid

var _service: BlueGuardianService = null

# PlateLayer
var _chrome_plate: TextureRect = null
var _chrome_loaded: bool = false

# FactLayer controls
var _title_label: Label = null
var _close_btn: Button = null
var _species_image: TextureRect = null
var _species_name: Label = null
var _badge_label: Label = null
var _field_discovery: Label = null
var _field_region: Label = null
var _field_category: Label = null
var _field_record: Label = null
var _field_retention: Label = null
var _field_reward: Label = null
var _keep_btn: Button = null
var _release_btn: Button = null
var _reward_subtext: Label = null

# Shell constants
const SHELL_S := Vector2(760, 520)
const SHELL_POS := Vector2(260, 100)
const SLOT_A := Vector2(300, 300)

# Chrome plate path
const CHROME_PATH := "res://assets/m19/ui/chrome/shell_04_result_empty.png"
const FALLBACK_PATH := "res://assets/m19/ui/chrome/shell_04_result_empty.png"

# Colors (will use M19SharedTheme once chrome plates arrive)
const TEXT_PRIMARY := Color(0.82, 0.90, 0.92)
const TEXT_MUTED := Color(0.50, 0.58, 0.60)
const TEXT_ACCENT := Color(0.52, 0.80, 0.92)
const TEXT_GOLD := Color(0.96, 0.78, 0.42)
const TEXT_GREEN := Color(0.52, 0.88, 0.58)


func setup(service: BlueGuardianService) -> void:
	_service = service
	if _service != null:
		_service.state_changed.connect(_on_state_changed)
	_build()


func _build() -> void:
	# Position at manifest: 260,100 within 1280x720
	anchor_left = 0.0; anchor_right = 0.0; anchor_top = 0.0; anchor_bottom = 0.0
	offset_left = 260; offset_top = 100
	offset_right = 260 + SHELL_S.x; offset_bottom = 100 + SHELL_S.y
	mouse_filter = Control.MOUSE_FILTER_STOP

	# PlateLayer
	_chrome_plate = TextureRect.new()
	_chrome_plate.name = "ResultShellPlate"
	_chrome_plate.size = SHELL_S
	_chrome_plate.position = Vector2.ZERO
	_chrome_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chrome_plate.stretch_mode = TextureRect.STRETCH_KEEP
	_chrome_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chrome_plate)
	_load_chrome_plate()

	# FactLayer: all positions from M19_RUNTIME_MASTER_FREEZE_01 dynamic_slot_manifest.json page 04
	var fl = Control.new()
	fl.name = "FactLayer"
	fl.size = SHELL_S
	fl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(fl)

	# title (42,25,570,48)
	_title_label = _make_label("救助结果", 20, TEXT_ACCENT)
	_title_label.position = Vector2(42, 25)
	_title_label.size = Vector2(570, 48)
	fl.add_child(_title_label)

	# close_icon (682,24,52,52)
	_close_btn = Button.new()
	_close_btn.position = Vector2(682, 24)
	_close_btn.size = Vector2(52, 52)
	_close_btn.flat = true
	_close_btn.pressed.connect(_on_close)
	fl.add_child(_close_btn)

	# species_image (42,100,320,300)
	_species_image = TextureRect.new()
	_species_image.name = "SpeciesMainImage"
	_species_image.position = Vector2(42, 100)
	_species_image.size = Vector2(320, 300)
	_species_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_species_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fl.add_child(_species_image)

	# species_name (54,405,220,38)
	_species_name = _make_label("", 18, TEXT_PRIMARY)
	_species_name.position = Vector2(54, 405)
	_species_name.size = Vector2(220, 38)
	_species_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.add_child(_species_name)

	# discovery_badge (280,406,90,34)
	_badge_label = _make_label("", 13, TEXT_GOLD)
	_badge_label.position = Vector2(280, 406)
	_badge_label.size = Vector2(90, 34)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.add_child(_badge_label)

	# Row definitions from manifest
	var field_rows = [
		["discovery_type",   395, 105, 325, 44, "发现类型"],
		["source_region",    395, 157, 325, 44, "来源区域"],
		["ecology_category", 395, 209, 325, 44, "生态类别"],
		["rescue_record",    395, 261, 325, 44, "救助记述"],
		["retention_effect", 395, 313, 325, 44, "留缸效果"],
		["release_reward",   395, 365, 325, 44, "放归回响"],
	]

	var field_labels = {}
	var field_values = {}
	for row in field_rows:
		var sid: String = row[0]
		var rx: int = row[1]; var ry: int = row[2]
		var rw: int = row[3]; var rh: int = row[4]
		var label_text: String = row[5]

		var lbl = _make_label(label_text, 12, TEXT_MUTED)
		lbl.position = Vector2(rx, ry)
		lbl.size = Vector2(rw, 16)
		fl.add_child(lbl)

		var val = _make_label("—", 14, TEXT_PRIMARY)
		val.position = Vector2(rx, ry + 18)
		val.size = Vector2(rw, rh - 18)
		fl.add_child(val)

		field_labels[sid] = lbl
		field_values[sid] = val

	_field_discovery = field_values.get("discovery_type")
	_field_region = field_values.get("source_region")
	_field_category = field_values.get("ecology_category")
	_field_record = field_values.get("rescue_record")
	_field_retention = field_values.get("retention_effect")
	_field_reward = field_values.get("release_reward")

	# keep_button (56,451,285,54)
	_keep_btn = _make_button("留在海缸", false)
	_keep_btn.position = Vector2(56, 451)
	_keep_btn.size = Vector2(285, 54)
	_keep_btn.pressed.connect(_on_keep)
	fl.add_child(_keep_btn)

	# release_button (419,451,285,54)
	_release_btn = _make_button("放归", true)
	_release_btn.position = Vector2(419, 451)
	_release_btn.size = Vector2(285, 54)
	_release_btn.pressed.connect(_on_release)
	fl.add_child(_release_btn)

	# reward subtext below release button
	_reward_subtext = _make_label("", 11, TEXT_GOLD)
	_reward_subtext.position = Vector2(419, 451 + 54 + 4)
	_reward_subtext.size = Vector2(285, 14)
	_reward_subtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.add_child(_reward_subtext)

	print("[M19 Gate-B] 04 panel built from M19_RUNTIME_MASTER_FREEZE_01 — 13 slots")


func _load_chrome_plate() -> void:
	if ResourceLoader.exists(CHROME_PATH):
		_chrome_plate.texture = ResourceLoader.load(CHROME_PATH, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
		_chrome_loaded = true
		print("[M19 HYBRID] Chrome plate loaded: ", CHROME_PATH)
	else:
		_chrome_loaded = false
		print("[M19 HYBRID] CHROME PLATE MISSING: ", CHROME_PATH)
		# Use dark placeholder
		_chrome_plate.self_modulate = Color(0.08, 0.12, 0.16, 0.95)


func _refresh() -> void:
	if _service == null:
		return
	_service.ensure_voyage_settled_if_due()
	if _service.get_state() != BlueGuardianService.VoyageState.RESULT_PENDING:
		hide()
		return

	var data = _service.get_pending_result_data()
	var sid: String = _service.get_pending_species_id()

	# Species name
	_species_name.text = data.get("display_name", sid)

	# Image
	var tex = M19SharedTheme.load_species_texture(sid)
	if tex != null:
		_species_image.texture = tex

	# Badge
	var ids: Array = _service.get_collection_ids()
	if not ids.has(sid):
		_badge_label.text = "首次发现"
		_badge_label.add_theme_color_override("font_color", TEXT_GOLD)
	else:
		_badge_label.text = "再次相遇"
		_badge_label.add_theme_color_override("font_color", TEXT_ACCENT)

	# Fields
	_field_discovery.text = _badge_label.text
	_field_region.text = BlueGuardianConfig.get_species_region(sid)
	_field_category.text = BlueGuardianConfig.get_species_rarity_tier(sid)
	_field_record.text = data.get("description", "救助生物")
	_field_retention.text = "留在海缸可获得持续收益"
	var reward = float(BlueGuardianConfig.get_release_pulse(sid))
	_field_reward.text = "%.0f 朵浪花" % reward
	_reward_subtext.text = "获得 %.0f 朵浪花" % reward

	# Capacity check
	var cap_full = false
	if _service.livestock_gw != null:
		var cap: Dictionary = _service.livestock_gw.get_debug_state()
		cap_full = float(cap.get("current_capacity_used", 0.0)) >= float(cap.get("max_capacity", 30.0))
	_keep_btn.disabled = cap_full
	_keep_btn.tooltip_text = "海缸容量不足" if cap_full else ""


func _on_keep() -> void:
	if _service == null: return
	var r = _service.keep_pending_result()
	if r.get("success", false):
		print("[M19 HYBRID] Keep action: PASS")
		_refresh()
	else:
		print("[M19 HYBRID] Keep action: FAIL - ", r.get("error", "unknown"))

func _on_release() -> void:
	if _service == null: return
	var r = _service.release_pending_result()
	if r.get("success", false):
		print("[M19 HYBRID] Release action: PASS")
		_refresh()
	else:
		print("[M19 HYBRID] Release action: FAIL")

func _on_state_changed() -> void: _refresh()
func _on_close() -> void: hide()

func _on_visibility_changed() -> void:
	if visible: _refresh()


# ── Helpers ──

func _make_label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _make_button(text: String, primary: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	var fg = TEXT_ACCENT if primary else TEXT_MUTED
	b.add_theme_color_override("font_color", fg)
	b.flat = false
	# Programmatic state derivation (per §8)
	# Hover: +8% brightness handled by theme override in _ready
	# We use simple flat style with color states
	return b
