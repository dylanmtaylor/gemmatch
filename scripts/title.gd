extends Node2D

var time := 0.0
const TITLE := "GemMatch"
const COLORS: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW,
	Color.PURPLE, Color.ORANGE, Color.CYAN, Color.RED
]

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
	# Background
	var bg_hue: float = fmod(time * 0.02, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(600, 730)), Color.from_hsv(bg_hue, 0.15, 0.12))

	# Decorative floating gems
	for i in 200:
		var speed: float = 10 + fmod(i * 13.7, 30.0)
		var gx: float = fmod(i * 53.0 + time * speed, 700.0) - 50.0
		var gy: float = fmod(i * 37.0 + time * (8 + fmod(i * 7.3, 20.0)), 830.0) - 50.0
		var c: Color = COLORS[i % COLORS.size()]
		var sz: float = 8 + fmod(i * 11.3, 16.0)
		var alpha: float = 0.08 + fmod(i * 3.7, 0.12)
		var rot: float = time * (0.5 + fmod(i * 0.3, 1.5))
		# Draw as rotating shapes
		if i % 3 == 0:
			draw_circle(Vector2(gx, gy), sz, Color(c.r, c.g, c.b, alpha))
		elif i % 3 == 1:
			var pts := PackedVector2Array()
			for j in 4:
				var a: float = rot + TAU / 4.0 * j
				pts.append(Vector2(gx + cos(a) * sz, gy + sin(a) * sz))
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, alpha))
		else:
			var pts := PackedVector2Array()
			for j in 6:
				var a: float = rot + TAU / 6.0 * j
				pts.append(Vector2(gx + cos(a) * sz, gy + sin(a) * sz))
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, alpha))

	var font := ThemeDB.fallback_font

	# Large title
	var total_w := 0.0
	for i in TITLE.length():
		total_w += font.get_string_size(TITLE[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var x: float = (600.0 - total_w) * 0.5
	var base_y: float = 300.0
	for i in TITLE.length():
		var ch: String = TITLE[i]
		var c: Color = COLORS[i % COLORS.size()]
		var bounce: float = sin(time * 2.5 + i * 0.6) * 8.0
		var pos := Vector2(x, base_y + bounce)
		# Shadow
		draw_string(font, pos + Vector2(3, 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(0, 0, 0, 0.6))
		# Outline
		for off in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
			draw_string(font, pos + off, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, c.darkened(0.3))
		# Letter
		draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, c.lightened(0.2))
		# Specular
		draw_circle(pos + Vector2(6, -16), 4.0, Color(1, 1, 1, 0.3 + sin(time * 3.0 + i) * 0.2))
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x

	# "Click to Play" with pulse
	var pulse: float = 0.4 + sin(time * 2.0) * 0.4
	draw_string(font, Vector2(210, 420), "Click to Play", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(1, 1, 1, pulse))
