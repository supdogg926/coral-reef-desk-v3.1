class_name M19MainInterfaceHybrid
extends Control
# M19-B 01 Main Interface — Chrome plates + dynamic world + fact controls

var game_state: GameState = null

# Chrome plates (TextureRects from freeze package)
var _chrome_plates: Dictionary = {}
var _tank_world: Control = null
var _sump_world: Control = null

# Tank composition
var _livestock_sprites: Array = []
var _coral_sprites: Array = []
var _rock_sprites: Array = []
var _anemone_sprites: Array = []
var _sump_equipment_sprites: Array = []

# Fact layer controls
var _sidebar_labels: Dictionary = {}
var _gauge_labels: Array[Label] = []
var _knob_controls: Array = []
var _device_buttons: Array = []

var _refresh_timer: float = 0.0

# Scale constants
const TANK_REAL_WIDTH_CM: float = 90.0
const TANK_INNER_PX: float = 990.0
const PX_PER_CM: float = TANK_INNER_PX / TANK_REAL_WIDTH_CM

# TankClip: (20, 18, 1012, 355) from manifest
const TANK_CLIP := Rect2(20, 18, 1012, 355)
const SUMP_CLIP := Rect2(20, 405, 1012, 108)
const SAND_BASELINE_Y: float = 320.0


func setup(gs: GameState) -> void:
	game_state = gs
	_build()


func _build() -> void:
	anchor_left = 0.0; anchor_right = 1.0; anchor_top = 0.0; anchor_bottom = 1.0

	# ── Single full 01 Runtime Master (ZERO seams, NO region crops) ──
	var full_path: String = "res://assets/m19/ui/chrome/01_runtime_empty_master.png"
	if not ResourceLoader.exists(full_path):
		_ensure_full_master(full_path)
	var master_tr := TextureRect.new()
	master_tr.name = "FullRuntimeMaster01"
	master_tr.position = Vector2.ZERO
	master_tr.size = Vector2(1280, 720)
	master_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	master_tr.stretch_mode = TextureRect.STRETCH_KEEP
	master_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(full_path):
		master_tr.texture = ResourceLoader.load(full_path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	add_child(master_tr)

	# ── WorldLayer: Tank	# ── WorldLayer: Tank ──
	_tank_world = Control.new()
	_tank_world.name = "TankWorld"
	_tank_world.position = TANK_CLIP.position
	_tank_world.size = TANK_CLIP.size
	_tank_world.clip_contents = true
	_tank_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tank_world)

	# ── WorldLayer: Sump ──
	_sump_world = Control.new()
	_sump_world.name = "SumpWorld"
	_sump_world.position = SUMP_CLIP.position
	_sump_world.size = SUMP_CLIP.size
	_sump_world.clip_contents = true
	_sump_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sump_world)

	# ── FactLayer: Sidebar ──
	_build_sidebar_facts()

	# ── FactLayer: Gauges ──
	_build_gauge_facts()

	# ── FactLayer: Knobs ──
	_build_knob_facts()

	# ── FactLayer: Device Grid ──
	_build_device_facts()

	# Initial layout
	_refresh_tank_composition()
	_refresh_sump_equipment()

	print("[M19-B] 01 Main Interface built: single full master 1280x720")


func _add_chrome_plate(asset_path: String, x: float, y: float, w: float, h: float) -> void:
	var tr = TextureRect.new()
	tr.position = Vector2(x, y)
	tr.size = Vector2(w, h)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(asset_path):
		tr.texture = ResourceLoader.load(asset_path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	add_child(tr)


func _ensure_full_master(path: String) -> void:
	var src: String = "C:/Users/admin/Desktop/M19_RUNTIME_MASTER_FREEZE_01/M19_RUNTIME_MASTER_FREEZE_01/runtime_masters/01_runtime_empty_master.png"
	if FileAccess.file_exists(src):
		DirAccess.make_dir_recursive_absolute("assets/m19/ui/chrome")
		var fs = FileAccess.open(src, FileAccess.READ)
		if fs != null:
			var data = fs.get_buffer(fs.get_length()); fs.close()
			var fd = FileAccess.open("assets/m19/ui/chrome/01_runtime_empty_master.png", FileAccess.WRITE)
			if fd != null: fd.store_buffer(data); fd.close()


func _refresh_tank_composition() -> void:
	if game_state == null: return
	_clear_tank_sprites()

	var livestock = game_state.livestock_system
	if livestock == null: return

	var debug: Dictionary = livestock.get_debug_state()
	var instances: Array = debug.get("owned_livestock", [])

	# Auto-layout: assign slots by instance order
	var rock_slots = [
		Vector2(105, 310), Vector2(220, 300), Vector2(345, 312), Vector2(470, 298),
		Vector2(600, 310), Vector2(725, 298), Vector2(845, 310), Vector2(945, 302),
	]
	var coral_slots = [Vector2(105,260),Vector2(220,248),Vector2(345,252),Vector2(470,246),Vector2(600,250),Vector2(725,245),Vector2(845,250)]
	var anemone_slots = [Vector2(330,276), Vector2(520,274), Vector2(700,276)]

	var rock_idx = 0; var coral_idx = 0; var anemone_idx = 0

	for i in range(instances.size()):
		var entry: Dictionary = instances[i]
		if entry.get("locked", false): continue
		var category: String = str(entry.get("category", "fish"))

		if category == "coral":
			if rock_idx < rock_slots.size():
				_add_rock_sprite(rock_slots[rock_idx])
				rock_idx += 1
			if coral_idx < coral_slots.size():
				_add_coral_sprite(coral_slots[coral_idx])
				coral_idx += 1
		elif category == "crustacean":
			if rock_idx < rock_slots.size():
				_add_rock_sprite(rock_slots[rock_idx])
				rock_idx += 1
		elif category == "fish":
			pass  # Fish use activity zones, not static sprites

	# Always add at least 1 rock + 2 clownfish for new game
	if rock_idx == 0:
		_add_rock_sprite(rock_slots[0])
	if coral_idx == 0:
		pass  # No corals in new game


func _add_rock_sprite(pos: Vector2) -> void:
	pass  # No debug ColorRect — assets not in runtime pipeline


func _add_coral_sprite(pos: Vector2) -> void:
	pass  # No debug ColorRect — assets not in runtime pipeline


func _clear_tank_sprites() -> void:
	for s in _rock_sprites + _coral_sprites + _anemone_sprites:
		if is_instance_valid(s): s.queue_free()
	_rock_sprites.clear(); _coral_sprites.clear(); _anemone_sprites.clear()


# ── Sump Equipment ──

func _refresh_sump_equipment() -> void:
	_clear_sump_sprites()
	# New game: 1 return pump + 1 filter media
	_add_equipment_sprite(Vector2(65, 82), Color(0.15, 0.17, 0.19))
	_add_equipment_sprite(Vector2(733, 82), Color(0.60, 0.58, 0.52))


func _add_equipment_sprite(pos: Vector2, color: Color) -> void:
	pass  # No debug ColorRect — assets not in runtime pipeline


func _clear_sump_sprites() -> void:
	for s in _sump_equipment_sprites:
		if is_instance_valid(s): s.queue_free()
	_sump_equipment_sprites.clear()


# ── Sidebar Facts ──

func _build_sidebar_facts() -> void:
	var labels_data = [
		["project_title",    1072, 24,  184, 26, "ReefIdle V3", 14, Color(0.78,0.90,0.94)],
		["project_subtitle", 1072, 52,  184, 20, "M19 Blue Guardian", 11, Color(0.50,0.80,0.88)],
		["wave_balance",     1072, 136, 184, 24, "浪花 0", 14, Color(0.92,0.78,0.36)],
		["temperature",      1072, 174, 184, 19, "26.2 C", 11, Color(0.50,0.80,0.88)],
		["time_display",     1072, 220, 184, 19, "--:--", 11, Color(0.50,0.80,0.88)],
		["date_display",     1072, 243, 184, 19, "----/--/--", 9, Color(0.45,0.55,0.58)],
	]
	for ld in labels_data:
		var cid: String = ld[0]
		var lbl = Label.new()
		lbl.position = Vector2(ld[1], ld[2])
		lbl.size = Vector2(ld[3], ld[4])
		lbl.text = ld[5]
		lbl.add_theme_font_size_override("font_size", ld[6])
		lbl.add_theme_color_override("font_color", ld[7])
		add_child(lbl)
		_sidebar_labels[cid] = lbl

	# Navigation buttons
	var nav_btns = [["codex_button", 1064,674,64,32,"图鉴"], ["release_button", 1132,674,64,32,"放归"], ["settings_button", 1200,674,64,32,"设置"]]
	for nb in nav_btns:
		var btn = Button.new()
		btn.position = Vector2(nb[1], nb[2]); btn.size = Vector2(nb[3], nb[4])
		btn.text = nb[5]; btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.50,0.80,0.88)); btn.flat = true
		btn.name = nb[0]
		add_child(btn)
		_sidebar_labels[nb[0]] = btn


# ── Gauge Facts ──

func _build_gauge_facts() -> void:
	var gauge_names = ["温度", "盐度", "NO3", "PO4", "pH", "KH", "Ca"]
	for i in range(7):
		var gx: int = 15 + i * 55
		var lbl = Label.new()
		lbl.position = Vector2(gx, 540); lbl.size = Vector2(48, 18)
		lbl.text = gauge_names[i]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.50,0.78,0.86))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)
		_gauge_labels.append(lbl)


# ── Knob Facts ──

func _build_knob_facts() -> void:
	var knob_names = ["水泵", "造浪泵", "亮度", "色温"]
	for i in range(4):
		var kx: int = 420 + i * 75
		var lbl = Label.new()
		lbl.position = Vector2(kx, 542); lbl.size = Vector2(64, 20)
		lbl.text = knob_names[i]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.76,0.82,0.86))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)
		_knob_controls.append(lbl)


# ── Device Button Facts ──

func _build_device_facts() -> void:
	var dev_names = [
		"换水","清滤","KH","补水",
		"清藻","更换滤材","喂鱼粮","喂珊瑚粮",
		"蛋分","杀菌灯","加热棒","冷水机",
		"煮豆机","钙反","卷纸机","KHA"
	]
	for row in range(4):
		for col in range(4):
			var idx = row * 4 + col
			if idx >= dev_names.size(): break
			var dx: int = 715 + col * 85
			var dy: int = 542 + row * 42
			var btn = Button.new()
			btn.position = Vector2(dx, dy); btn.size = Vector2(78, 38)
			btn.text = dev_names[idx]
			btn.add_theme_font_size_override("font_size", 9)
			btn.add_theme_color_override("font_color", Color(0.50,0.78,0.86))
			btn.flat = true; btn.name = "dev_" + dev_names[idx]
			add_child(btn)
			_device_buttons.append(btn)


func _process(delta: float) -> void:
	if game_state == null: return
	_refresh_timer += delta
	if _refresh_timer < 1.0: return
	_refresh_timer = 0.0
	_update_dynamic_data()


func _update_dynamic_data() -> void:
	if game_state.economy_system != null:
		var w: float = game_state.economy_system.get_waves_balance()
		var wl: Label = _sidebar_labels.get("wave_balance")
		if wl != null: wl.text = "浪花 %.0f" % w

	var dt = Time.get_datetime_dict_from_system()
	var tl: Label = _sidebar_labels.get("time_display")
	if tl != null: tl.text = "%02d:%02d" % [dt.hour, dt.minute]
	var dl: Label = _sidebar_labels.get("date_display")
	if dl != null: dl.text = "%d-%02d-%02d" % [dt.year, dt.month, dt.day]
