class_name M19MainInterfaceHybrid
extends Control
# M19 01 Main Interface — Chrome plates + dynamic world + fully wired fact controls
# All data bound to real GameState, no hardcoded display values

var game_state: GameState = null

# Chrome plates
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
var _gauge_name_labels: Array[Label] = []
var _gauge_value_labels: Array[Label] = []
var _knob_name_labels: Array[Label] = []
var _knob_value_labels: Array[Label] = []
var _device_buttons: Array[Button] = []
var _maintenance_buttons: Array[Button] = []
var _feeding_buttons: Array[Button] = []
var _nav_buttons: Dictionary = {}

var _refresh_timer: float = 0.0

# Scale constants
const TANK_REAL_WIDTH_CM: float = 90.0
const TANK_INNER_PX: float = 990.0
const PX_PER_CM: float = TANK_INNER_PX / TANK_REAL_WIDTH_CM

const TANK_CLIP := Rect2(20, 18, 1012, 355)
const SUMP_CLIP := Rect2(20, 405, 1012, 108)
const SAND_BASELINE_Y: float = 320.0

# Gauge config: [name, key_in_water_debug, unit, decimals]
const GAUGE_CONFIG := [
	["温度", "temperature", "°C", 1],
	["盐度", "salinity", "ppt", 1],
	["NO3", "nitrate", "", 2],
	["PO4", "phosphate", "", 3],
	["pH", "ph", "", 2],
	["KH", "alkalinity", "", 1],
	["Ca", "calcium", "", 0],
]

# Knob config: [name, device_id, type]
const KNOB_CONFIG := [
	["水泵", "return_pump", "toggle"],
	["造浪泵", "wave_pump", "toggle"],
	["亮度", "main_light", "intensity"],
	["色温", "reserve", "colortemp"],
]

# Maintenance action IDs (match GameState.MAINTENANCE_ACTION_RULES keys)
const MAINTENANCE_ORDER := ["water_change_10", "clean_filter", "dose_buffer", "top_off", "travel_prep"]

# Feeding action IDs (match GameState.FEEDING_ACTION_RULES keys)
const FEEDING_ORDER := ["fish_food", "coral_food"]

# Frozen 8 maintenance key labels (contract order)
const MAINT_8_LABELS := ["换水","清滤","KH","补水","清藻","更换滤材","喂鱼粮","喂珊瑚粮"]

# Frozen 8 device key labels (contract order)
const DEVICE_8_LABELS := ["蛋分","杀菌灯","加热棒","冷水机","KHA","钙反","卷纸机","煮豆机"]

# Backend device mappings for keys that have real implementations
const DEVICE_BACKEND_MAP := {
	"杀菌灯":"uv_sterilizer", "冷水机":"chiller"
}


func setup(gs: GameState) -> void:
	game_state = gs
	_build()


func _build() -> void:
	anchor_left = 0.0; anchor_right = 1.0; anchor_top = 0.0; anchor_bottom = 1.0

	# Single full 01 Runtime Master (ZERO seams, NO region crops)
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

	# WorldLayer: Tank
	_tank_world = Control.new()
	_tank_world.name = "TankWorld"
	_tank_world.position = TANK_CLIP.position
	_tank_world.size = TANK_CLIP.size
	_tank_world.clip_contents = true
	_tank_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tank_world)

	# WorldLayer: Sump
	_sump_world = Control.new()
	_sump_world.name = "SumpWorld"
	_sump_world.position = SUMP_CLIP.position
	_sump_world.size = SUMP_CLIP.size
	_sump_world.clip_contents = true
	_sump_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sump_world)

	# Fact layers
	_build_sidebar_facts()
	_build_gauge_facts()
	_build_knob_facts()
	_build_device_facts()

	_refresh_tank_composition()
	_refresh_sump_equipment()

	# Immediate data refresh
	_update_dynamic_data()

	print("[M19] 01 Main Interface built: full master + wired facts")


func _ensure_full_master(path: String) -> void:
	var src: String = "C:/Users/admin/Desktop/M19_RUNTIME_MASTER_FREEZE_01/M19_RUNTIME_MASTER_FREEZE_01/runtime_masters/01_runtime_empty_master.png"
	if FileAccess.file_exists(src):
		DirAccess.make_dir_recursive_absolute("assets/m19/ui/chrome")
		var fs = FileAccess.open(src, FileAccess.READ)
		if fs != null:
			var data = fs.get_buffer(fs.get_length()); fs.close()
			var fd = FileAccess.open("assets/m19/ui/chrome/01_runtime_empty_master.png", FileAccess.WRITE)
			if fd != null: fd.store_buffer(data); fd.close()


# ═══════════════════════════════════════════
# Sidebar: system info + navigation
# ═══════════════════════════════════════════

func _build_sidebar_facts() -> void:
	var labels_data = [
		["project_title",    1072, 24,  184, 26, "ReefIdle V3", 14, Color(0.78,0.90,0.94)],
		["project_subtitle", 1072, 52,  184, 20, "M19 Blue Guardian", 11, Color(0.50,0.80,0.88)],
		["wave_balance",     1072, 136, 184, 24, "浪花 0", 14, Color(0.92,0.78,0.36)],
		["temperature",      1072, 174, 184, 19, "--.- °C", 11, Color(0.50,0.80,0.88)],
		["salinity_label",   1072, 196, 184, 17, "--.- ppt", 10, Color(0.45,0.55,0.58)],
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

	# Navigation buttons with signals
	var nav_btns = [
		["save_button",   1064, 640, 64, 28, "保存"],
		["observe_button",1132, 640, 64, 28, "观赏"],
		["codex_button",  1064, 674, 64, 32, "图鉴"],
		["release_button", 1132, 674, 64, 32, "放归"],
		["settings_button",1200, 674, 64, 32, "设置"],
	]
	for nb in nav_btns:
		var btn = Button.new()
		btn.position = Vector2(nb[1], nb[2]); btn.size = Vector2(nb[3], nb[4])
		btn.text = nb[5]; btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.50,0.80,0.88)); btn.flat = true
		btn.name = nb[0]
		add_child(btn)
		_nav_buttons[nb[0]] = btn


# ═══════════════════════════════════════════
# Gauge Facts: 7 water parameters
# ═══════════════════════════════════════════

func _build_gauge_facts() -> void:
	_gauge_name_labels.clear()
	_gauge_value_labels.clear()
	for i in range(GAUGE_CONFIG.size()):
		var cfg = GAUGE_CONFIG[i]
		var gx: int = 15 + i * 55

		# Name label
		var name_lbl = Label.new()
		name_lbl.position = Vector2(gx, 532); name_lbl.size = Vector2(48, 14)
		name_lbl.text = cfg[0]
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.50,0.78,0.86))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_lbl)
		_gauge_name_labels.append(name_lbl)

		# Value label
		var val_lbl = Label.new()
		val_lbl.position = Vector2(gx, 546); val_lbl.size = Vector2(48, 16)
		val_lbl.text = "--"
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.82,0.88,0.84))
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(val_lbl)
		_gauge_value_labels.append(val_lbl)


# ═══════════════════════════════════════════
# Knob Facts: 4 controls with values
# ═══════════════════════════════════════════

func _build_knob_facts() -> void:
	_knob_name_labels.clear()
	_knob_value_labels.clear()
	for i in range(KNOB_CONFIG.size()):
		var cfg = KNOB_CONFIG[i]
		var kx: int = 420 + i * 75

		# Name label
		var name_lbl = Label.new()
		name_lbl.position = Vector2(kx, 532); name_lbl.size = Vector2(64, 14)
		name_lbl.text = cfg[0]
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.76,0.82,0.86))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_lbl)
		_knob_name_labels.append(name_lbl)

		# Value label
		var val_lbl = Label.new()
		val_lbl.position = Vector2(kx, 546); val_lbl.size = Vector2(64, 16)
		val_lbl.text = "--"
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.82,0.90,0.86))
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(val_lbl)
		_knob_value_labels.append(val_lbl)

		# Clickable area for all knobs
		var click_area = Button.new()
		click_area.position = Vector2(kx, 532); click_area.size = Vector2(64, 30)
		click_area.flat = true
		click_area.name = "knob_" + cfg[1]
		match cfg[2]:
			"toggle":
				click_area.pressed.connect(_on_knob_toggle.bind(cfg[1]))
			"intensity":
				click_area.pressed.connect(_on_knob_intensity)
			"colortemp":
				click_area.pressed.connect(_on_knob_colortemp)
		add_child(click_area)


func _on_knob_toggle(device_id: String) -> void:
	if game_state == null: return
	game_state.toggle_device(device_id)
	_update_dynamic_data()


func _on_knob_intensity() -> void:
	if game_state == null: return
	# Cycle: 100 → 75 → 50 → 25 → 0 → 100
	var current := game_state.light_intensity
	var next_val := 0
	if current >= 100: next_val = 75
	elif current >= 75: next_val = 50
	elif current >= 50: next_val = 25
	elif current >= 25: next_val = 0
	else: next_val = 100
	game_state.light_intensity = next_val
	game_state.set_light_intensity(next_val)
	_update_dynamic_data()


func _on_knob_colortemp() -> void:
	if game_state == null: return
	# Cycle: 6500 → 10000 → 14000 → 20000 → 6500
	var current := game_state.light_color_temp
	var next_val := 6500
	if current >= 20000: next_val = 6500
	elif current >= 14000: next_val = 20000
	elif current >= 10000: next_val = 14000
	elif current >= 6500: next_val = 10000
	else: next_val = 6500
	game_state.light_color_temp = next_val
	game_state.set_light_color_temp(next_val)
	_update_dynamic_data()


# ═══════════════════════════════════════════
# Device + Maintenance + Feeding Buttons
# ═══════════════════════════════════════════

func _build_device_facts() -> void:
	_device_buttons.clear()
	_maintenance_buttons.clear()
	_feeding_buttons.clear()

	# Row 0: Frozen 8 maintenance keys
	for col in range(8):
		var dx: int = 715 + col * 72
		var dy: int = 540
		var label: String = MAINT_8_LABELS[col]
		var action_id := ""
		match col:
			0: action_id = "water_change_10"
			1: action_id = "clean_filter"
			2: action_id = "dose_buffer"
			3: action_id = "top_off"
			4: action_id = "algae_clean"
			5: action_id = "media_replace"
			6: action_id = "fish_food"
			7: action_id = "coral_food"

		var btn = Button.new()
		btn.position = Vector2(dx, dy); btn.size = Vector2(68, 36)
		btn.text = label
		btn.add_theme_font_size_override("font_size", 9)
		btn.add_theme_color_override("font_color", Color(0.50,0.78,0.86))
		btn.flat = true; btn.name = "key_" + label

		# Wire to backend where real action exists
		if action_id in ["water_change_10","clean_filter","dose_buffer","top_off"]:
			btn.pressed.connect(_on_maintenance_pressed.bind(action_id))
		elif action_id in ["fish_food","coral_food"]:
			btn.pressed.connect(_on_feeding_pressed.bind(action_id))
		else:
			# 清藻 and 更换滤材: no backend yet — disable with reason
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.30, 0.32, 0.32))
			btn.tooltip_text = "维护功能开发中"
		add_child(btn)
		_maintenance_buttons.append(btn)

	# Row 1-2: Frozen 8 device keys (4 per row)
	for idx in range(8):
		var row: int = idx / 4
		var col: int = idx % 4
		var dx: int = 715 + col * 72
		var dy: int = 580 + row * 38
		var label: String = DEVICE_8_LABELS[idx]
		var backend_id: String = DEVICE_BACKEND_MAP.get(label, "")

		var btn = Button.new()
		btn.position = Vector2(dx, dy); btn.size = Vector2(68, 34)
		btn.text = label
		btn.add_theme_font_size_override("font_size", 9)
		btn.flat = true; btn.name = "dev_" + label

		if backend_id != "":
			btn.add_theme_color_override("font_color", Color(0.50,0.78,0.86))
			btn.pressed.connect(_on_device_pressed.bind(backend_id))
		else:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.30, 0.32, 0.32))
			btn.tooltip_text = "设备未实现"
		add_child(btn)
		_device_buttons.append(btn)


func _on_maintenance_pressed(action_id: String) -> void:
	if game_state == null: return
	game_state.apply_water_maintenance_action(action_id)
	_update_dynamic_data()


func _on_feeding_pressed(feed_id: String) -> void:
	if game_state == null: return
	game_state.apply_feeding_action(feed_id)
	_update_dynamic_data()


func _on_device_pressed(device_id: String) -> void:
	if game_state == null: return
	game_state.toggle_device(device_id)
	_update_dynamic_data()


# ═══════════════════════════════════════════
# Tank composition (visual)
# ═══════════════════════════════════════════

func _refresh_tank_composition() -> void:
	if game_state == null: return
	_clear_tank_sprites()

	var livestock = game_state.livestock_system
	if livestock == null: return

	var debug: Dictionary = livestock.get_debug_state()
	var instances: Array = debug.get("owned_livestock", [])

	var rock_slots = [
		Vector2(105, 310), Vector2(220, 300), Vector2(345, 312), Vector2(470, 298),
		Vector2(600, 310), Vector2(725, 298), Vector2(845, 310), Vector2(945, 302),
	]
	var coral_slots = [Vector2(105,260),Vector2(220,248),Vector2(345,252),Vector2(470,246),Vector2(600,250),Vector2(725,245),Vector2(845,250)]
	var rock_idx = 0; var coral_idx = 0

	for i in range(instances.size()):
		var entry: Dictionary = instances[i]
		if entry.get("locked", false): continue
		var category: String = str(entry.get("category", "fish"))
		if category == "coral" or category == "crustacean":
			if rock_idx < rock_slots.size():
				_add_rock_sprite(rock_slots[rock_idx]); rock_idx += 1
			if coral_idx < coral_slots.size():
				_add_coral_sprite(coral_slots[coral_idx]); coral_idx += 1

	if rock_idx == 0:
		_add_rock_sprite(rock_slots[0])


func _add_rock_sprite(pos: Vector2) -> void:
	pass


func _add_coral_sprite(pos: Vector2) -> void:
	pass


func _clear_tank_sprites() -> void:
	for s in _rock_sprites + _coral_sprites + _anemone_sprites:
		if is_instance_valid(s): s.queue_free()
	_rock_sprites.clear(); _coral_sprites.clear(); _anemone_sprites.clear()


func _refresh_sump_equipment() -> void:
	_clear_sump_sprites()
	_add_equipment_sprite(Vector2(65, 82), Color(0.15, 0.17, 0.19))
	_add_equipment_sprite(Vector2(733, 82), Color(0.60, 0.58, 0.52))


func _add_equipment_sprite(pos: Vector2, color: Color) -> void:
	pass


func _clear_sump_sprites() -> void:
	for s in _sump_equipment_sprites:
		if is_instance_valid(s): s.queue_free()
	_sump_equipment_sprites.clear()


# ═══════════════════════════════════════════
# Dynamic data refresh (called every 1s)
# ═══════════════════════════════════════════

func _process(delta: float) -> void:
	if game_state == null: return
	_refresh_timer += delta
	if _refresh_timer < 1.0: return
	_refresh_timer = 0.0
	_update_dynamic_data()


func _update_dynamic_data() -> void:
	if game_state == null: return

	# ── Sidebar: economy ──
	if game_state.economy_system != null:
		var w: float = game_state.economy_system.get_waves_balance()
		var wl: Label = _sidebar_labels.get("wave_balance")
		if wl != null: wl.text = "浪花 %.0f" % w

	# ── Sidebar: temperature from water chemistry ──
	var water = game_state.get_water_chemistry_debug_state()
	if not water.is_empty():
		var temp: float = float(water.get("temperature", 0.0))
		var tl: Label = _sidebar_labels.get("temperature")
		if tl != null: tl.text = "%.1f °C" % temp
		var sal: float = float(water.get("salinity", 0.0))
		var sl: Label = _sidebar_labels.get("salinity_label")
		if sl != null: sl.text = "%.1f ppt" % sal

	# ── Sidebar: time/date from system ──
	var dt = Time.get_datetime_dict_from_system()
	var time_lbl: Label = _sidebar_labels.get("time_display")
	if time_lbl != null: time_lbl.text = "%02d:%02d" % [dt.hour, dt.minute]
	var date_lbl: Label = _sidebar_labels.get("date_display")
	if date_lbl != null: date_lbl.text = "%d-%02d-%02d" % [dt.year, dt.month, dt.day]

	# ── Gauges: water parameters ──
	for i in range(GAUGE_CONFIG.size()):
		if i >= _gauge_value_labels.size(): break
		var cfg = GAUGE_CONFIG[i]
		var key: String = cfg[1]
		var unit: String = cfg[2]
		var decimals: int = cfg[3]
		var val: float = float(water.get(key, 0.0))
		var val_lbl: Label = _gauge_value_labels[i]
		var format_str := "%." + str(decimals) + "f"
		if unit != "":
			val_lbl.text = format_str % val
		else:
			val_lbl.text = format_str % val

	# ── Knobs: device states ──
	var device_state: Dictionary = game_state.get_device_state()
	var raw_devices: Variant = device_state.get("devices", {})
	var devices: Dictionary = raw_devices if raw_devices is Dictionary else {}
	for i in range(KNOB_CONFIG.size()):
		if i >= _knob_value_labels.size(): break
		var cfg = KNOB_CONFIG[i]
		var dev_id: String = cfg[1]
		var dev_type: String = cfg[2]
		var val_lbl: Label = _knob_value_labels[i]
		if dev_type == "toggle":
			var dev_info: Dictionary = devices.get(dev_id, {}) if devices is Dictionary else {}
			var enabled: bool = bool(dev_info.get("enabled", false))
			val_lbl.text = "ON" if enabled else "OFF"
		elif dev_type == "intensity":
			val_lbl.text = "%d%%" % game_state.light_intensity
		elif dev_type == "colortemp":
			val_lbl.text = "%dK" % game_state.light_color_temp

	# ── Device buttons: on/off state (only for devices with backend) ──
	for i in range(_device_buttons.size()):
		var btn: Button = _device_buttons[i]
		var label: String = DEVICE_8_LABELS[i] if i < DEVICE_8_LABELS.size() else ""
		var backend_id: String = DEVICE_BACKEND_MAP.get(label, "")
		if backend_id == "": continue  # no backend, already disabled
		var dev_info: Dictionary = devices.get(backend_id, {}) if devices is Dictionary else {}
		if dev_info.is_empty():
			btn.disabled = true
			btn.tooltip_text = label + ": 未实现"
		else:
			var enabled: bool = bool(dev_info.get("enabled", false))
			btn.disabled = false
			btn.add_theme_color_override("font_color", Color(0.50,0.88,0.68) if enabled else Color(0.50,0.78,0.86))
			btn.tooltip_text = label + (": ON" if enabled else ": OFF")

	# ── Maintenance buttons: cooldown + cost ──
	for i in range(MAINTENANCE_ORDER.size()):
		if i >= _maintenance_buttons.size(): break
		var action_id: String = MAINTENANCE_ORDER[i]
		var btn: Button = _maintenance_buttons[i]
		var state: Dictionary = game_state.get_maintenance_action_state(action_id)
		var remaining: float = float(state.get("remaining_cooldown", 0.0))
		var reason: String = str(state.get("reason", "ok"))
		if remaining > 0.0:
			btn.disabled = true
			btn.tooltip_text = "冷却中: %ds" % int(ceil(remaining))
			btn.add_theme_color_override("font_color", Color(0.35, 0.38, 0.38))
		elif reason == "insufficient_funds":
			btn.disabled = true
			btn.tooltip_text = "RP不足"
			btn.add_theme_color_override("font_color", Color(0.55, 0.40, 0.35))
		else:
			btn.disabled = false
			btn.tooltip_text = ""
			btn.add_theme_color_override("font_color", Color(0.50,0.78,0.86))

	# ── Feeding buttons: cooldown ──
	for i in range(FEEDING_ORDER.size()):
		if i >= _feeding_buttons.size(): break
		var feed_id: String = FEEDING_ORDER[i]
		var btn: Button = _feeding_buttons[i]
		var state: Dictionary = game_state.get_feeding_action_state(feed_id)
		var remaining: float = float(state.get("remaining_cooldown", 0.0))
		if remaining > 0.0:
			btn.disabled = true
			btn.tooltip_text = "冷却中: %ds" % int(ceil(remaining))
			btn.add_theme_color_override("font_color", Color(0.35, 0.38, 0.38))
		else:
			btn.disabled = false
			btn.tooltip_text = ""
			btn.add_theme_color_override("font_color", Color(0.60,0.88,0.72))
