extends Control


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var outer_rect: Rect2 = Rect2(Vector2(10, 8), size - Vector2(20, 14))
	var title_pos: Vector2 = outer_rect.position + Vector2(16, 21)
	var sump_rect: Rect2 = Rect2(outer_rect.position + Vector2(22, 34), outer_rect.size - Vector2(44, 44))

	draw_rect(outer_rect, Color(0.11, 0.10, 0.09), true)
	draw_rect(outer_rect, Color(0.34, 0.32, 0.28), false, 2.0)
	draw_string(font, title_pos, "底缸", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.86, 0.91, 0.92))
	draw_rect(sump_rect, Color(0.04, 0.11, 0.15), true)
	draw_rect(sump_rect, Color(0.55, 0.72, 0.78), false, 1.6)

	var modules: Array[Dictionary] = [
		{"name": "滤袋区", "sub": "入水过滤", "ratio": 0.10},
		{"name": "滤材区", "sub": "Bio Media", "ratio": 0.16},
		{"name": "藻缸区", "sub": "Refugium", "ratio": 0.15},
		{"name": "活石区", "sub": "Live Rock", "ratio": 0.13},
		{"name": "蛋分区", "sub": "Skimmer", "ratio": 0.16},
		{"name": "设备预留", "sub": "Future Slot", "ratio": 0.16},
		{"name": "ATO 补水仓", "sub": "储水 / 补水", "ratio": 0.14},
	]
	var x: float = sump_rect.position.x
	for i in range(modules.size()):
		var module: Dictionary = modules[i]
		var width: float = sump_rect.size.x * float(module.get("ratio", 0.12))
		if i == modules.size() - 1:
			width = sump_rect.end.x - x
		var chamber: Rect2 = Rect2(Vector2(x, sump_rect.position.y), Vector2(width, sump_rect.size.y))
		_draw_chamber_outline(font, chamber, String(module.get("name", "")), String(module.get("sub", "")), i)
		if i < modules.size() - 1:
			draw_line(Vector2(chamber.end.x, chamber.position.y + 5.0), Vector2(chamber.end.x, chamber.end.y - 5.0), Color(0.50, 0.68, 0.72), 1.4)
		x += width

	var flow_y: float = sump_rect.position.y + sump_rect.size.y - 12.0
	draw_line(Vector2(sump_rect.position.x + 10.0, flow_y), Vector2(sump_rect.end.x - 10.0, flow_y), Color(0.35, 0.55, 0.62, 0.75), 1.2)
	draw_string(font, Vector2(sump_rect.position.x + 12.0, flow_y - 4.0), "水流路径  →", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.62, 0.76, 0.78))


func _draw_chamber_outline(font: Font, rect: Rect2, title: String, subtitle: String, index: int) -> void:
	var inset: Rect2 = rect.grow(-5.0)
	var fill_alpha: float = 0.18 + float(index % 2) * 0.06
	draw_rect(inset, Color(0.08, 0.18, 0.22, fill_alpha), true)
	draw_rect(inset, Color(0.40, 0.60, 0.64, 0.72), false, 1.0)
	draw_string(font, inset.position + Vector2(7, 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.93, 0.92))
	draw_string(font, inset.position + Vector2(7, 34), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.57, 0.70, 0.70))


func _draw_slot_badges(font: Font, sump_rect: Rect2, chamber_width: float) -> void:
	var badge_color: Color = Color(0.12, 0.22, 0.24, 0.88)
	var border_color: Color = Color(0.44, 0.67, 0.70, 0.95)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(8, 7), Vector2(66, 17)), "滤袋｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(78, 7), Vector2(66, 17)), "滤材｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(chamber_width + 10, 7), Vector2(76, 17)), "蛋分｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(chamber_width * 2.0 + 10, 7), Vector2(66, 17)), "藻缸｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(chamber_width * 2.0 + 80, 7), Vector2(66, 17)), "活石｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(chamber_width * 3.0 + 10, 7), Vector2(66, 17)), "回水｜已装", badge_color, border_color)
	_draw_badge(font, Rect2(sump_rect.position + Vector2(chamber_width * 3.0 + 80, 7), Vector2(66, 17)), "加热｜已装", badge_color, border_color)


func _draw_badge(font: Font, rect: Rect2, text: String, fill: Color, border: Color) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 1.0)
	draw_string(font, rect.position + Vector2(5, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.88, 0.95, 0.92))


func _draw_filter_sock(origin: Vector2) -> void:
	var sock_rect: Rect2 = Rect2(origin + Vector2(-13, 0), Vector2(26, 42))
	draw_rect(sock_rect, Color(0.86, 0.88, 0.82), true)
	draw_rect(sock_rect, Color(0.42, 0.45, 0.42), false, 2.0)
	draw_line(sock_rect.position + Vector2(4, 10), sock_rect.position + Vector2(sock_rect.size.x - 4, 10), Color(0.5, 0.52, 0.48), 2.0)


func _draw_skimmer(origin: Vector2) -> void:
	draw_circle(origin + Vector2(0, 24), 16.0, Color(0.58, 0.68, 0.72))
	draw_rect(Rect2(origin + Vector2(-12, -8), Vector2(24, 42)), Color(0.62, 0.74, 0.78), false, 2.0)
	draw_rect(Rect2(origin + Vector2(-16, -25), Vector2(32, 16)), Color(0.42, 0.48, 0.5), true)
	for i in range(4):
		draw_circle(origin + Vector2(-9 + i * 6, 7 + i % 2 * 7), 2.2, Color(0.9, 0.96, 1.0, 0.75))


func _draw_refugium(rect: Rect2) -> void:
	draw_rect(rect, Color(0.08, 0.25, 0.12), true)
	for i in range(5):
		var x: float = rect.position.x + 8.0 + float(i) * 14.0
		draw_line(Vector2(x, rect.position.y + rect.size.y - 5.0), Vector2(x + 6.0, rect.position.y + 8.0), Color(0.28, 0.72, 0.32), 2.0)


func _draw_heater(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(34, -24), Color(0.86, 0.36, 0.22), 4.0)
	draw_circle(origin + Vector2(34, -24), 4.5, Color(0.95, 0.56, 0.36))


func _draw_return_pump(origin: Vector2) -> void:
	var pump_rect: Rect2 = Rect2(origin, Vector2(42, 24))
	draw_rect(pump_rect, Color(0.15, 0.17, 0.18), true)
	draw_rect(pump_rect, Color(0.62, 0.72, 0.74), false, 2.0)
	draw_circle(pump_rect.position + pump_rect.size * 0.5, 7.0, Color(0.24, 0.72, 0.88))
