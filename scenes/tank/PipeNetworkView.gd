extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -1
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	_draw_drain_indicator(w)
	_draw_return_indicator(w)
	_draw_ato_indicator(w)


func _draw_drain_indicator(w: float) -> void:
	var start: Vector2 = Vector2(w * 0.095, 248.0)
	var end: Vector2 = Vector2(w * 0.145, 360.0)
	_draw_subtle_pipe([start, end], Color(0.16, 0.55, 0.78, 0.28), "下水")


func _draw_return_indicator(w: float) -> void:
	var start: Vector2 = Vector2(w * 0.82, 120.0)
	var end: Vector2 = Vector2(w * 0.89, 120.0)
	_draw_subtle_pipe([start, end], Color(0.26, 0.78, 0.52, 0.25), "回水")


func _draw_ato_indicator(w: float) -> void:
	var start: Vector2 = Vector2(w * 0.89, 515.0)
	var end: Vector2 = Vector2(w * 0.84, 540.0)
	_draw_dashed_pipe(start, end, Color(0.72, 0.78, 0.86, 0.22), "补水")


func _draw_subtle_pipe(points: Array[Vector2], color: Color, label: String) -> void:
	var font: Font = get_theme_default_font()
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.02, 0.03, 0.04, 0.18), 5.0)
		draw_line(points[i], points[i + 1], color, 3.0)

	if points.size() >= 2:
		var from_point: Vector2 = points[points.size() - 2]
		var to_point: Vector2 = points[points.size() - 1]
		_draw_arrow(from_point, to_point, color)
		draw_string(font, to_point + Vector2(6, -6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color.lightened(0.35))


func _draw_dashed_pipe(start: Vector2, end: Vector2, color: Color, label: String) -> void:
	var font: Font = get_theme_default_font()
	var segments: int = 4
	var direction: Vector2 = (end - start) / float(segments)
	for i in range(segments):
		if i % 2 == 0:
			var a: Vector2 = start + direction * float(i)
			var b: Vector2 = start + direction * float(i + 1)
			draw_line(a, b, color, 2.0)
	draw_string(font, end + Vector2(5, -4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color.lightened(0.35))


func _draw_arrow(from_point: Vector2, to_point: Vector2, color: Color) -> void:
	var direction: Vector2 = (to_point - from_point).normalized()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var tip: Vector2 = to_point
	var left: Vector2 = tip - direction * 10.0 + normal * 4.0
	var right: Vector2 = tip - direction * 10.0 - normal * 4.0
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
