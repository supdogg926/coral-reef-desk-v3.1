class_name M19SharedTheme
extends RefCounted

# ── Colors ──
const BG_OVERLAY := Color(0.0, 0.0, 0.0, 0.55)
const SHELL_BG := Color(0.06, 0.10, 0.14, 0.95)
const CARD_BG := Color(0.10, 0.14, 0.18, 0.9)
const TEXT_PRIMARY := Color(0.82, 0.90, 0.92)
const TEXT_MUTED := Color(0.50, 0.58, 0.60)
const TEXT_ACCENT := Color(0.52, 0.80, 0.92)
const TEXT_GOLD := Color(0.96, 0.78, 0.42)
const TEXT_GREEN := Color(0.52, 0.88, 0.58)
const TEXT_WARN := Color(0.92, 0.60, 0.42)
const BORDER_COLOR := Color(0.18, 0.24, 0.28)

const BTN_PRIMARY := Color(0.52, 0.80, 0.92)
const BTN_SECONDARY := Color(0.50, 0.58, 0.60)
const BTN_DANGER := Color(0.92, 0.60, 0.42)
const BTN_KEEP := Color(0.52, 0.88, 0.58)

const PROGRESS_BG := Color(0.10, 0.14, 0.18)
const PROGRESS_FILL := Color(0.42, 0.76, 0.88)

# ── Shells ──
const SHELL_S := Rect2(260, 100, 760, 520)
const SHELL_L := Rect2(120, 70, 1040, 580)

const TITLE_BAR_H := 56
const ACTION_BAR_H := 84

# ── Image Slots ──
const SLOT_A := Vector2(300, 300)
const SLOT_B := Vector2(420, 280)
const SLOT_C := Vector2(72, 72)

# ── Font Sizes ──
const FONT_TITLE := 20
const FONT_HEADING := 16
const FONT_BODY := 13
const FONT_SMALL := 11
const FONT_COUNTDOWN := 64
const FONT_LARGE_NUMBER := 18

# ── Helpers ──

static func make_shell_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SHELL_BG
	s.set_corner_radius_all(10)
	s.set_border_width_all(1)
	s.border_color = BORDER_COLOR
	return s


static func make_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(6)
	s.set_border_width_all(1)
	s.border_color = BORDER_COLOR
	return s


static func make_button_style(fg_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(5)
	s.set_border_width_all(1)
	s.border_color = fg_color.darkened(0.3)
	return s


static func make_progress_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PROGRESS_FILL
	s.set_corner_radius_all(3)
	return s


static func make_title_bar(parent: Control, title: String, close_callback: Callable) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, TITLE_BAR_H)
	bar.add_theme_constant_override("separation", 0)
	parent.add_child(bar)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", FONT_TITLE)
	title_lbl.add_theme_color_override("font_color", TEXT_ACCENT)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title_lbl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = BORDER_COLOR
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(sep)

	return bar


static func make_action_bar(parent: Control) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, ACTION_BAR_H)
	bar.add_theme_constant_override("separation", 12)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)
	return bar


static func make_primary_button(text: String) -> Button:
	return _make_button(text, BTN_PRIMARY, true)


static func make_secondary_button(text: String) -> Button:
	return _make_button(text, BTN_SECONDARY, false)


static func make_text_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", FONT_SMALL)
	b.add_theme_color_override("font_color", TEXT_MUTED)
	b.flat = true
	return b


static func _make_button(text: String, fg: Color, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(140 if primary else 110, 40)
	b.add_theme_font_size_override("font_size", FONT_BODY)
	b.add_theme_color_override("font_color", fg)
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(5)
	s.set_border_width_all(1)
	s.border_color = fg.darkened(0.25)
	b.add_theme_stylebox_override("normal", s)
	var hs := StyleBoxFlat.new()
	hs.bg_color = fg.darkened(0.5)
	hs.set_corner_radius_all(5)
	hs.set_border_width_all(1)
	hs.border_color = fg
	b.add_theme_stylebox_override("hover", hs)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.08, 0.10, 0.12)
	ds.set_corner_radius_all(5)
	ds.set_border_width_all(1)
	ds.border_color = Color(0.12, 0.16, 0.18)
	b.add_theme_stylebox_override("disabled", ds)
	b.add_theme_color_override("font_disabled_color", Color(0.3, 0.35, 0.35))
	return b


static func make_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func make_image_slot(size: Vector2, name: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = name
	tr.custom_minimum_size = size
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return tr


static func make_progress_bar() -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 14)
	pb.add_theme_stylebox_override("background", StyleBoxFlat.new())
	var bg := StyleBoxFlat.new()
	bg.bg_color = PROGRESS_BG
	bg.set_corner_radius_all(3)
	pb.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = PROGRESS_FILL
	fg.set_corner_radius_all(3)
	pb.add_theme_stylebox_override("fill", fg)
	pb.show_percentage = false
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return pb


static func make_separator() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_constant_override("separation", 1)
	return s


static func get_species_image_path(species_id: String) -> String:
	var path := "res://assets/m19/species/%s.png" % species_id
	if FileAccess.file_exists(path):
		return path
	return "res://assets/m19/species/_placeholder.png"


static func load_species_texture(species_id: String) -> Texture2D:
	var path := get_species_image_path(species_id)
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
		if res is Texture2D:
			return res
	return null
