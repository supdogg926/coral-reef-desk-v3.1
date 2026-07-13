extends Control
# M19 01 Main Tank View — programmatic rendering per visual contract


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	var tank := Rect2(Vector2(8, 4), sz - Vector2(16, 10))
	var water := Rect2(tank.position + Vector2(14, 42), tank.size - Vector2(28, 54))
	var sand := Rect2(water.position + Vector2(0, water.size.y - 30), Vector2(water.size.x, 30))
	var overflow_w := 58.0
	var overflow := Rect2(Vector2(water.end.x - overflow_w, water.position.y), Vector2(overflow_w, water.size.y))
	var font := get_theme_default_font()

	# ── Tank frame ──
	draw_rect(tank, Color(0.06, 0.09, 0.11), true)
	draw_rect(tank, Color(0.55, 0.68, 0.74), false, 2.5)
	# Inner bezel
	draw_rect(tank.grow(-4), Color(0.04, 0.06, 0.08), false, 1.0)

	# ── Water body ──
	draw_rect(water, Color(0.04, 0.22, 0.36), true)
	# Water surface highlight
	draw_rect(Rect2(water.position, Vector2(water.size.x, 14)), Color(0.18, 0.52, 0.68, 0.7), true)
	draw_line(water.position + Vector2(0, 14), water.position + Vector2(water.size.x, 14), Color(0.35, 0.68, 0.82, 0.5), 1.5)
	# Subtle light rays
	for i in range(3):
		var rx := water.position.x + water.size.x * (0.2 + float(i) * 0.25)
		draw_line(Vector2(rx, water.position.y), Vector2(rx - 30, water.end.y - 20), Color(0.25, 0.55, 0.72, 0.08), 40.0)

	# ── White sand bed ──
	draw_rect(sand, Color(0.72, 0.68, 0.58), true)
	# Sand grain texture
	for i in range(30):
		var gx := sand.position.x + (hash(str(i) + "gx") % int(sand.size.x))
		var gy := sand.position.y + 4.0 + (hash(str(i) + "gy") % int(sand.size.y - 6))
		draw_circle(Vector2(gx, gy), 1.2, Color(0.82, 0.78, 0.68, 0.6))

	# ── Live rock aquascape (asymmetric, left-heavy) ──
	var rock_origin := sand.position + Vector2(water.size.x * 0.35, 10)
	# Main rock mass - irregular polygon
	var rock_points := PackedVector2Array([
		rock_origin + Vector2(-90, 5),
		rock_origin + Vector2(-70, -50),
		rock_origin + Vector2(-30, -78),
		rock_origin + Vector2(15, -62),
		rock_origin + Vector2(50, -35),
		rock_origin + Vector2(65, 5),
	])
	draw_colored_polygon(rock_points, Color(0.25, 0.23, 0.19))
	# Rock highlight edges
	for i in range(rock_points.size() - 1):
		draw_line(rock_points[i], rock_points[i + 1], Color(0.40, 0.38, 0.32), 2.0)
	# Secondary rock (right side, smaller)
	var rock2_origin := sand.position + Vector2(water.size.x * 0.72, 12)
	draw_circle(rock2_origin + Vector2(0, -15), 28.0, Color(0.28, 0.26, 0.22))
	draw_circle(rock2_origin + Vector2(-20, -8), 22.0, Color(0.22, 0.20, 0.17))
	draw_circle(rock2_origin + Vector2(18, -5), 18.0, Color(0.30, 0.28, 0.23))

	# ── Central anemone (red/pink, main focal point) ──
	var anemone_pos := rock_origin + Vector2(-25, -75)
	draw_circle(anemone_pos, 18.0, Color(0.88, 0.25, 0.28))
	# Tentacles
	for i in range(18):
		var angle := float(i) * PI * 2.0 / 18.0
		var tip := anemone_pos + Vector2(cos(angle) * 28.0, sin(angle) * 28.0)
		draw_line(anemone_pos + Vector2(cos(angle) * 12.0, sin(angle) * 12.0), tip, Color(0.95, 0.45, 0.40), 2.5)
		draw_circle(tip, 3.5, Color(0.90, 0.55, 0.60, 0.8))
	# Anemone mouth
	draw_circle(anemone_pos, 5.0, Color(0.40, 0.10, 0.15))
	draw_circle(anemone_pos, 3.0, Color(0.20, 0.05, 0.08))

	# ── Clownfish pair near anemone ──
	_draw_clownfish(anemone_pos + Vector2(22, -8), false)   # right-facing
	_draw_clownfish(anemone_pos + Vector2(-30, 5), true)    # left-facing

	# ── Corals on rocks ──
	_draw_torch_coral(rock_origin + Vector2(-50, -70))
	_draw_gsp(rock_origin + Vector2(20, -40))
	_draw_xenia(rock_origin + Vector2(-60, -55))

	# ── Additional reef fish ──
	_draw_tang(water.position + Vector2(water.size.x * 0.50, water.size.y * 0.52), Color(0.90, 0.78, 0.10))
	_draw_firefish(water.position + Vector2(water.size.x * 0.82, water.size.y * 0.70))
	_draw_small_fish(water.position + Vector2(water.size.x * 0.60, water.size.y * 0.30), Color(0.30, 0.50, 0.90))
	_draw_small_fish(water.position + Vector2(water.size.x * 0.25, water.size.y * 0.55), Color(0.90, 0.30, 0.50))

	# ── Side overflow / filter box (right, black) ──
	draw_rect(overflow, Color(0.04, 0.06, 0.08), true)
	draw_rect(overflow, Color(0.25, 0.35, 0.40), false, 1.5)
	# Inlet grille (top)
	for i in range(4):
		var gy := overflow.position.y + 8.0 + float(i) * 10.0
		draw_line(Vector2(overflow.position.x + 5, gy), Vector2(overflow.position.x + overflow.size.x - 5, gy), Color(0.20, 0.30, 0.34), 1.5)
	# Outlet grille (bottom)
	for i in range(4):
		var by := overflow.position.y + overflow.size.y - 38.0 + float(i) * 10.0
		draw_line(Vector2(overflow.position.x + 5, by), Vector2(overflow.position.x + overflow.size.x - 5, by), Color(0.20, 0.30, 0.34), 1.5)

	# ── Single outlet nozzle ──
	var nozzle_y := overflow.position.y + 18.0
	draw_line(Vector2(overflow.position.x - 6, nozzle_y), Vector2(overflow.position.x - 60, nozzle_y - 8), Color(0.60, 0.72, 0.76), 5.0)
	draw_circle(Vector2(overflow.position.x - 60, nozzle_y - 8), 6.0, Color(0.65, 0.76, 0.80))
	# Flow lines from outlet
	draw_line(Vector2(overflow.position.x - 66, nozzle_y - 8), Vector2(overflow.position.x - 90, nozzle_y - 20), Color(0.28, 0.60, 0.78, 0.5), 2.0)

	# ── Wave maker pump (replaces second outlet) ──
	var wave_pos := Vector2(overflow.position.x - 10, overflow.position.y + overflow.size.y - 42)
	draw_circle(wave_pos, 10.0, Color(0.15, 0.18, 0.20), true)
	draw_circle(wave_pos, 10.0, Color(0.45, 0.55, 0.58), false, 1.5)
	draw_circle(wave_pos, 5.0, Color(0.30, 0.35, 0.38))
	# Wave flow arrows
	draw_line(wave_pos + Vector2(-12, 0), wave_pos + Vector2(-30, -5), Color(0.28, 0.62, 0.80, 0.6), 2.5)
	draw_line(wave_pos + Vector2(-12, 0), wave_pos + Vector2(-30, 5), Color(0.28, 0.62, 0.80, 0.4), 2.0)

	# ── System info in overflow box area (hacker-style cyan) ──
	var info_x := overflow.position.x + 6
	var info_y := overflow.position.y + 52
	var info_color := Color(0.50, 0.80, 0.88)
	# Time/Day/Temp/Waves integrated into side box
	draw_string(font, Vector2(info_x, info_y), "ReefIdleV3", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, info_color)
	draw_string(font, Vector2(info_x, info_y + 14), "M19-T2 · UI Candidate", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.55, 0.85, 0.90, 0.7))
	draw_string(font, Vector2(info_x, info_y + 28), "Day 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, info_color)
	draw_string(font, Vector2(info_x, info_y + 42), "26.2°C", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, info_color)
	draw_string(font, Vector2(info_x, info_y + 56), "浪花 0", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.90, 0.75, 0.30))

	# ── Build ID watermark ──
	var bid := Vector2(tank.position.x + tank.size.x - 12, tank.position.y + tank.size.y - 8)
	draw_string(font, bid, "M19-T2 · unified-ui-runtime-candidate", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, Color(0.45, 0.55, 0.58))
	draw_string(font, tank.position + Vector2(16, 20), "ReefIdleV3 · M19 Blue Guardian", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.82, 0.92, 0.94))


# ── Drawing helpers ──

func _draw_clownfish(origin: Vector2, flip: bool) -> void:
	var d := -1.0 if flip else 1.0
	# Body
	var body := PackedVector2Array([
		origin + Vector2(-12 * d, 0), origin + Vector2(0, -9),
		origin + Vector2(18 * d, -3), origin + Vector2(22 * d, 3),
		origin + Vector2(0, 9),
	])
	draw_colored_polygon(body, Color(0.95, 0.45, 0.20))
	# White stripes
	draw_line(origin + Vector2(2 * d, -8), origin + Vector2(2 * d, 8), Color.WHITE, 3.0)
	draw_line(origin + Vector2(14 * d, -5), origin + Vector2(14 * d, 6), Color.WHITE, 2.5)
	# Eye
	draw_circle(origin + Vector2(4 * d, -2), 2.0, Color.BLACK)
	draw_circle(origin + Vector2(4 * d, -2), 1.0, Color.WHITE)
	# Tail fin
	var tail := PackedVector2Array([
		origin + Vector2(-12 * d, 0),
		origin + Vector2(-24 * d, -10),
		origin + Vector2(-26 * d, 0),
		origin + Vector2(-24 * d, 10),
	])
	draw_colored_polygon(tail, Color(0.85, 0.35, 0.15))


func _draw_tang(origin: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		origin + Vector2(-24, 0), origin + Vector2(0, -16),
		origin + Vector2(28, -2), origin + Vector2(24, 10),
		origin + Vector2(0, 16),
	])
	draw_colored_polygon(body, color)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-24, 0), origin + Vector2(-40, -14),
		origin + Vector2(-40, 14),
	]), color.darkened(0.15))
	draw_circle(origin + Vector2(12, -4), 3.0, Color.WHITE)
	draw_circle(origin + Vector2(12, -4), 1.5, Color.BLACK)


func _draw_firefish(origin: Vector2) -> void:
	var body := PackedVector2Array([
		origin + Vector2(-18, 0), origin + Vector2(0, -8),
		origin + Vector2(20, 0), origin + Vector2(24, 4),
		origin + Vector2(0, 8),
	])
	draw_colored_polygon(body, Color(0.95, 0.75, 0.30))
	# Long dorsal fin
	draw_line(origin + Vector2(-4, -7), origin + Vector2(-2, -28), Color(0.95, 0.45, 0.20), 2.0)
	draw_line(origin + Vector2(-2, -28), origin + Vector2(2, -8), Color(0.95, 0.45, 0.20), 1.5)
	draw_circle(origin + Vector2(8, -2), 2.0, Color.BLACK)


func _draw_small_fish(origin: Vector2, color: Color) -> void:
	draw_circle(origin, 6.0, color)
	var tail := PackedVector2Array([origin, origin + Vector2(-12, -6), origin + Vector2(-12, 6)])
	draw_colored_polygon(tail, color.darkened(0.2))
	draw_circle(origin + Vector2(3, -1), 1.5, Color.BLACK)


func _draw_torch_coral(origin: Vector2) -> void:
	# Stalk
	draw_line(origin + Vector2(0, 5), origin + Vector2(0, -20), Color(0.65, 0.58, 0.45), 5.0)
	# Branches
	for i in range(3):
		var bx := float(i - 1) * 14.0
		var tip := origin + Vector2(bx, -28)
		draw_line(origin + Vector2(0, -14), tip, Color(0.60, 0.53, 0.40), 3.5)
		# Polyp head
		draw_circle(tip, 7.0, Color(0.45, 0.85, 0.40))
		draw_circle(tip + Vector2(-2, -2), 3.0, Color(0.60, 0.95, 0.50, 0.7))
	# Skeleton base
	draw_circle(origin, 8.0, Color(0.55, 0.48, 0.38))


func _draw_gsp(origin: Vector2) -> void:
	# Green star polyp mat
	draw_rect(Rect2(origin + Vector2(-18, -14), Vector2(36, 28)), Color(0.30, 0.28, 0.24), true)
	# Polyps
	for i in range(10):
		var px := origin.x - 12 + (hash(str(i) + "px") % 24)
		var py := origin.y - 8 + (hash(str(i) + "py") % 16)
		var ppos := Vector2(float(px), float(py))
		draw_circle(ppos, 2.5, Color(0.25, 0.88, 0.25))
		# Star tentacles
		for j in range(6):
			var a := float(j) * PI * 2.0 / 6.0
			draw_line(ppos, ppos + Vector2(cos(a) * 5.0, sin(a) * 5.0), Color(0.35, 0.92, 0.30, 0.6), 1.0)


func _draw_xenia(origin: Vector2) -> void:
	# Pulsing xenia stalks
	for i in range(4):
		var sx := float(i - 1) * 10.0
		var stalk := origin + Vector2(sx, -5)
		draw_line(stalk, stalk + Vector2(0, -18), Color(0.82, 0.72, 0.78), 3.0)
		var head := stalk + Vector2(0, -18)
		# Feathery polyp
		for j in range(5):
			var a := float(j) * PI * 1.4 / 4.0 - PI * 0.7
			draw_line(head, head + Vector2(cos(a) * 8.0, sin(a) * 7.0), Color(0.90, 0.80, 0.85, 0.7), 1.5)
		draw_circle(head, 3.0, Color(0.95, 0.85, 0.88))
