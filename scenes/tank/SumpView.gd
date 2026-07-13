extends Control
# M19 01 Sump View — glass chambers with equipment


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var outer := Rect2(Vector2(8, 4), size - Vector2(16, 8))
	var glass := outer.grow(-6)

	# ── Outer frame ──
	draw_rect(outer, Color(0.10, 0.09, 0.08), true)
	draw_rect(outer, Color(0.40, 0.45, 0.42), false, 2.0)

	# ── Glass tank body (continuous, not separate boxes) ──
	draw_rect(glass, Color(0.04, 0.14, 0.20, 0.7), true)
	draw_rect(glass, Color(0.55, 0.72, 0.78, 0.8), false, 1.5)
	# Glass reflection line
	draw_line(Vector2(glass.position.x + 6, glass.position.y + 6), Vector2(glass.position.x + 6, glass.end.y - 6), Color(0.30, 0.50, 0.56, 0.3), 3.0)

	# ── Chamber dividers (baffles) ──
	var chambers := [
		{"name": "回水泵", "ratio": 0.13, "equip": "pump"},
		{"name": "蛋分", "ratio": 0.18, "equip": "skimmer"},
		{"name": "藻缸", "ratio": 0.14, "equip": "refugium"},
		{"name": "活石", "ratio": 0.12, "equip": "liverock"},
		{"name": "滤材", "ratio": 0.12, "equip": "media"},
		{"name": "设备仓", "ratio": 0.15, "equip": "equipment"},
		{"name": "滤袋/滤棉", "ratio": 0.16, "equip": "sock"},
	]
	var cx := glass.position.x
	for i in range(chambers.size()):
		var ch: Dictionary = chambers[i]
		var cw := glass.size.x * float(ch["ratio"])
		if i == chambers.size() - 1:
			cw = glass.end.x - cx
		var chamber := Rect2(Vector2(cx, glass.position.y), Vector2(cw, glass.size.y))
		_draw_chamber(chamber, ch["name"], ch["equip"], font, i)
		# Baffle
		if i < chambers.size() - 1:
			var bx := chamber.end.x
			draw_line(Vector2(bx, chamber.position.y + 4), Vector2(bx, chamber.end.y - 4), Color(0.45, 0.65, 0.70), 1.5)
		cx += cw

	# ── Flow direction arrow ──
	var flow_y := glass.end.y - 8.0
	draw_line(Vector2(glass.position.x + 20, flow_y), Vector2(glass.end.x - 20, flow_y), Color(0.35, 0.58, 0.65, 0.6), 1.5)
	draw_string(font, Vector2(glass.position.x + 28, flow_y - 4), "水流 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.72, 0.76))

	# ── Pipes (black, between chambers) ──
	for i in range(chambers.size() - 1):
		var px := glass.position.x
		for j in range(i + 1):
			px += glass.size.x * float(chambers[j]["ratio"])
		draw_rect(Rect2(px - 12, glass.position.y - 8, 24, 8), Color(0.08, 0.10, 0.10), true)


func _draw_chamber(rect: Rect2, title: String, equip_type: String, font: Font, index: int) -> void:
	var inset := rect.grow(-4)
	var alpha := 0.10 + float(index % 2) * 0.06

	# Chamber fill
	draw_rect(inset, Color(0.06, 0.16, 0.22, alpha), true)
	draw_rect(inset, Color(0.35, 0.52, 0.58, 0.5), false, 1.0)

	# Label
	draw_string(font, inset.position + Vector2(4, 14), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.78, 0.88, 0.90))

	# Equipment icon
	var center := inset.position + inset.size * 0.5
	match equip_type:
		"pump": _draw_return_pump(center + Vector2(0, 6))
		"skimmer": _draw_skimmer(center + Vector2(0, 4))
		"refugium": _draw_refugium(inset)
		"liverock": _draw_live_rock(inset)
		"media": _draw_bio_media(inset)
		"equipment": _draw_equipment_cell(inset)
		"sock": _draw_filter_socks(inset)


func _draw_return_pump(pos: Vector2) -> void:
	var pr := Rect2(pos - Vector2(20, 14), Vector2(40, 28))
	draw_rect(pr, Color(0.14, 0.16, 0.18), true)
	draw_rect(pr, Color(0.55, 0.62, 0.65), false, 2.0)
	draw_circle(pos, 8.0, Color(0.22, 0.58, 0.72))
	draw_circle(pos, 4.0, Color(0.12, 0.20, 0.24))
	# Pipe out
	draw_line(pos + Vector2(20, 0), pos + Vector2(36, -8), Color(0.10, 0.12, 0.12), 4.0)


func _draw_skimmer(pos: Vector2) -> void:
	# Cup (top)
	draw_rect(Rect2(pos + Vector2(-18, -30), Vector2(36, 18)), Color(0.35, 0.38, 0.40), true)
	draw_rect(Rect2(pos + Vector2(-18, -30), Vector2(36, 18)), Color(0.50, 0.52, 0.55), false, 1.0)
	# Body
	draw_rect(Rect2(pos + Vector2(-14, -12), Vector2(28, 38)), Color(0.55, 0.58, 0.62), true)
	draw_rect(Rect2(pos + Vector2(-14, -12), Vector2(28, 38)), Color(0.65, 0.68, 0.72), false, 1.5)
	# Bubbles
	for i in range(5):
		var bx := pos.x - 8 + float(i) * 4.0
		var by := pos.y - 18 + float(i % 3) * 5.0
		draw_circle(Vector2(bx, by), 1.5 + float(i % 3), Color(0.95, 0.98, 1.0, 0.6))
	# Neck
	draw_line(pos + Vector2(0, -12), pos + Vector2(0, -30), Color(0.40, 0.43, 0.45), 4.0)


func _draw_refugium(rect: Rect2) -> void:
	# Green algae background
	var inner := rect.grow(-6)
	draw_rect(inner, Color(0.06, 0.22, 0.10, 0.5), true)
	# Algae strands
	for i in range(8):
		var ax := inner.position.x + 4.0 + float(i) * (inner.size.x - 8) / 7.0
		var h := inner.size.y * (0.4 + (hash(str(i) + "ah") % 50) / 100.0)
		draw_line(Vector2(ax, inner.end.y - 4), Vector2(ax - 3, inner.end.y - h), Color(0.20, 0.65, 0.22), 2.0)
		draw_line(Vector2(ax, inner.end.y - 4), Vector2(ax + 3, inner.end.y - h + 8), Color(0.25, 0.70, 0.28), 1.5)


func _draw_live_rock(rect: Rect2) -> void:
	var inner := rect.grow(-6)
	for i in range(5):
		var rx := inner.position.x + inner.size.x * (0.15 + float(i) * 0.14)
		var ry := inner.position.y + inner.size.y * (0.4 + (hash(str(i) + "rr") % 40) / 100.0)
		var rr := 10.0 + (hash(str(i) + "rs") % 10)
		draw_circle(Vector2(rx, ry), rr, Color(0.22, 0.20, 0.17))
		draw_circle(Vector2(rx, ry), rr, Color(0.35, 0.33, 0.28), false, 1.0)


func _draw_bio_media(rect: Rect2) -> void:
	# Square ceramic media blocks (ordered)
	var inner := rect.grow(-6)
	for row in range(3):
		for col in range(5):
			var bx := inner.position.x + 6.0 + float(col) * (inner.size.x - 12) / 4.0
			var by := inner.position.y + 8.0 + float(row) * (inner.size.y - 16) / 2.0
			draw_rect(Rect2(Vector2(bx - 6, by - 6), Vector2(12, 12)), Color(0.75, 0.72, 0.65), true)
			draw_rect(Rect2(Vector2(bx - 6, by - 6), Vector2(12, 12)), Color(0.55, 0.52, 0.45), false, 0.5)
			# Pores
			draw_circle(Vector2(bx, by), 2.0, Color(0.65, 0.62, 0.55))


func _draw_equipment_cell(rect: Rect2) -> void:
	var inner := rect.grow(-6)
	# UV sterilizer (left)
	var uv_rect := Rect2(inner.position + Vector2(4, inner.size.y * 0.3), Vector2(14, inner.size.y * 0.4))
	draw_rect(uv_rect, Color(0.50, 0.52, 0.55), true)
	draw_rect(uv_rect, Color(0.60, 0.62, 0.65), false, 1.0)
	draw_string(get_theme_default_font(), uv_rect.position + Vector2(1, -12), "杀菌灯", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.90, 0.88, 0.85))

	# Heater (right)
	var heater_pos := inner.position + Vector2(inner.size.x - 24, inner.size.y * 0.5)
	draw_line(heater_pos, heater_pos + Vector2(22, -18), Color(0.85, 0.40, 0.25), 4.0)
	draw_circle(heater_pos + Vector2(22, -18), 4.0, Color(0.95, 0.55, 0.30))
	draw_string(get_theme_default_font(), heater_pos + Vector2(-10, -32), "加热棒", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.90, 0.88, 0.85))


func _draw_filter_socks(rect: Rect2) -> void:
	var inner := rect.grow(-6)
	# Two filter socks (right side as per design)
	var sock1 := Rect2(inner.position + Vector2(8, inner.size.y * 0.15), Vector2(28, inner.size.y * 0.7))
	var sock2 := Rect2(inner.position + Vector2(inner.size.x - 36, inner.size.y * 0.15), Vector2(28, inner.size.y * 0.7))

	_draw_single_sock(sock1, "滤袋")
	_draw_single_sock(sock2, "滤棉")
	# Bio filter baffle plate (replaces one sock)
	var baffle := Rect2(inner.position + Vector2(inner.size.x * 0.4, inner.size.y * 0.2), Vector2(inner.size.x * 0.25, inner.size.y * 0.6))
	draw_rect(baffle, Color(0.60, 0.65, 0.68), true)
	draw_rect(baffle, Color(0.70, 0.75, 0.78), false, 1.0)
	# Baffle holes
	for i in range(8):
		var hx := baffle.position.x + baffle.size.x * (0.15 + float(i % 4) * 0.2)
		var hy := baffle.position.y + baffle.size.y * (0.15 + float(i / 4) * 0.35)
		draw_circle(Vector2(hx, hy), 2.0, Color(0.15, 0.18, 0.20))
	draw_string(get_theme_default_font(), baffle.position + Vector2(4, -12), "生化滤棉", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.88, 0.90))


func _draw_single_sock(sock: Rect2, label: String) -> void:
	draw_rect(sock, Color(0.82, 0.84, 0.80), true)
	draw_rect(sock, Color(0.45, 0.48, 0.44), false, 1.5)
	# Ring
	draw_rect(Rect2(sock.position + Vector2(2, 3), Vector2(sock.size.x - 4, 8)), Color(0.35, 0.38, 0.35), true)
	# Label
	draw_string(get_theme_default_font(), sock.position + Vector2(2, sock.size.y + 12), label, HORIZONTAL_ALIGNMENT_CENTER, sock.size.x, 7, Color(0.82, 0.88, 0.90))
