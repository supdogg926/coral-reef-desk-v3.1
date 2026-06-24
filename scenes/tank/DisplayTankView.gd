extends Control


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var size_rect: Vector2 = size
	var tank_rect: Rect2 = Rect2(Vector2(10, 18), size_rect - Vector2(20, 30))
	var water_rect: Rect2 = Rect2(tank_rect.position + Vector2(10, 36), tank_rect.size - Vector2(20, 48))
	var sand_rect: Rect2 = Rect2(water_rect.position + Vector2(0, water_rect.size.y - 34), Vector2(water_rect.size.x, 34))
	var overflow_width: float = 46.0
	var overflow_rect: Rect2 = Rect2(Vector2(water_rect.end.x - overflow_width, water_rect.position.y), Vector2(overflow_width, water_rect.size.y))
	var font: Font = get_theme_default_font()

	draw_rect(tank_rect, Color(0.08, 0.11, 0.13), true)
	draw_rect(tank_rect, Color(0.64, 0.78, 0.86), false, 3.0)
	draw_string(font, tank_rect.position + Vector2(tank_rect.size.x - 312.0, 22.0), "CoralReefIdleV3 · 柏林系统静态布局", HORIZONTAL_ALIGNMENT_RIGHT, 292.0, 12, Color(0.78, 0.84, 0.84))
	draw_rect(water_rect, Color(0.05, 0.28, 0.42), true)
	draw_rect(Rect2(water_rect.position, Vector2(water_rect.size.x, 10)), Color(0.28, 0.63, 0.78), true)
	draw_rect(sand_rect, Color(0.58, 0.49, 0.34), true)

	draw_rect(overflow_rect, Color(0.03, 0.05, 0.06), true)
	draw_rect(overflow_rect, Color(0.3, 0.45, 0.5), false, 2.0)
	for i in range(5):
		var slot_y: float = overflow_rect.position.y + 16.0 + float(i) * 22.0
		draw_line(Vector2(overflow_rect.position.x + 9.0, slot_y), Vector2(overflow_rect.position.x + overflow_rect.size.x - 9.0, slot_y), Color(0.38, 0.65, 0.75), 2.0)

	var rock_base: Vector2 = sand_rect.position + Vector2(water_rect.size.x * 0.45, 8)
	draw_circle(rock_base + Vector2(-70, -18), 34.0, Color(0.29, 0.28, 0.24))
	draw_circle(rock_base + Vector2(-24, -34), 42.0, Color(0.34, 0.33, 0.28))
	draw_circle(rock_base + Vector2(30, -20), 30.0, Color(0.25, 0.25, 0.22))

	_draw_coral(rock_base + Vector2(-80, -66), Color(0.85, 0.38, 0.34))
	_draw_coral(rock_base + Vector2(-18, -86), Color(0.47, 0.83, 0.48))
	_draw_coral(rock_base + Vector2(48, -62), Color(0.84, 0.58, 0.94))

	_draw_fish(water_rect.position + Vector2(water_rect.size.x * 0.63, water_rect.size.y * 0.36), Color(0.95, 0.64, 0.22), false)
	_draw_fish(water_rect.position + Vector2(water_rect.size.x * 0.76, water_rect.size.y * 0.58), Color(0.22, 0.56, 0.92), true)

	var nozzle_start: Vector2 = Vector2(water_rect.position.x + water_rect.size.x - 92.0, water_rect.position.y + 12.0)
	var nozzle_end: Vector2 = nozzle_start + Vector2(70, 0)
	draw_line(nozzle_start, nozzle_end, Color(0.72, 0.82, 0.86), 5.0)
	draw_circle(nozzle_end, 8.0, Color(0.72, 0.82, 0.86))
	draw_line(nozzle_end + Vector2(-8, 12), nozzle_end + Vector2(-34, 36), Color(0.32, 0.74, 0.92), 2.0)


func _draw_coral(origin: Vector2, color: Color) -> void:
	draw_line(origin, origin + Vector2(0, -30), color, 5.0)
	draw_line(origin + Vector2(0, -14), origin + Vector2(-16, -32), color, 4.0)
	draw_line(origin + Vector2(0, -18), origin + Vector2(16, -38), color, 4.0)
	draw_circle(origin + Vector2(0, -34), 7.0, color.lightened(0.25))


func _draw_fish(origin: Vector2, color: Color, flip: bool) -> void:
	var dir: float = -1.0 if flip else 1.0
	var body: PackedVector2Array = PackedVector2Array([
		origin + Vector2(-20.0 * dir, 0),
		origin + Vector2(0, -10),
		origin + Vector2(24.0 * dir, 0),
		origin + Vector2(0, 10),
	])
	var tail: PackedVector2Array = PackedVector2Array([
		origin + Vector2(-20.0 * dir, 0),
		origin + Vector2(-36.0 * dir, -12),
		origin + Vector2(-36.0 * dir, 12),
	])
	draw_colored_polygon(body, color)
	draw_colored_polygon(tail, color.darkened(0.15))
	draw_circle(origin + Vector2(12.0 * dir, -2), 2.5, Color.WHITE)
