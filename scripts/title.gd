extends Node2D

var time := 0.0
var idle_timer := 0.0
const IDLE_TIMEOUT := 15.0

const TITLE := "GemMatch"
const COLORS: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW,
	Color.PURPLE, Color.ORANGE, Color.CYAN, Color.RED
]

enum Screen { MENU, HOW_TO_PLAY, HIGH_SCORES }
var current_screen: int = Screen.MENU
var fade := 1.0  # 0=black, 1=visible
var fading_to: int = -1  # target screen during fade, -1 = not fading
var fade_speed := 3.0

# Menu items
const MENU_ITEMS: Array[String] = ["New Game", "How to Play", "High Scores", "Demo Mode", "Quit"]
var menu_hover := 0

# How to Play scroll
const GEM_NAMES: Array[String] = ["Circle", "Diamond", "Square", "Triangle", "Hexagon", "Star", "Pentagon"]
const SPECIAL_INFO: Array[Dictionary] = [
	{"name": "Flame Gem", "desc": "Match 4 in a row. Explodes 3x3 area.", "color": Color(1, 0.5, 0)},
	{"name": "Star Gem", "desc": "Match 5 in a row. Clears all of one color.", "color": Color(1, 1, 0.3)},
	{"name": "Hypercube", "desc": "Match L or T shape. Swap to clear a color.", "color": Color(0.8, 0.5, 1)},
]

# Gem drawing (duplicated subset from board for self-contained drawing)
enum GemShape { CIRCLE, DIAMOND, SQUARE, TRIANGLE, HEXAGON, STAR_SHAPE, PENTAGON }

func _process(delta: float) -> void:
	time += delta
	idle_timer += delta

	# Fade logic
	if fading_to >= 0:
		fade -= delta * fade_speed
		if fade <= 0.0:
			fade = 0.0
			current_screen = fading_to
			fading_to = -1
	elif fade < 1.0:
		fade = minf(fade + delta * fade_speed, 1.0)

	# Demo mode after idle
	if idle_timer >= IDLE_TIMEOUT and fading_to < 0:
		_start_demo()

	queue_redraw()

func _reset_idle() -> void:
	idle_timer = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		_reset_idle()

	if fading_to >= 0:
		return

	# Keyboard input
	if event is InputEventKey and event.pressed:
		if current_screen == Screen.MENU:
			match event.keycode:
				KEY_UP, KEY_W:
					menu_hover = posmod(menu_hover - 1, MENU_ITEMS.size())
				KEY_DOWN, KEY_S:
					menu_hover = posmod(menu_hover + 1, MENU_ITEMS.size())
				KEY_ENTER, KEY_SPACE:
					_activate_menu_item(menu_hover)
		else:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_fade_to(Screen.MENU)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_screen == Screen.MENU:
			_activate_menu_item(menu_hover)
		else:
			_fade_to(Screen.MENU)

	if event is InputEventMouseMotion and current_screen == Screen.MENU:
		var my: float = event.position.y
		var mx: float = event.position.x
		for i in MENU_ITEMS.size():
			var iy: float = 370.0 + i * 50.0
			if mx > 150 and mx < 450 and my > iy - 25 and my < iy + 10:
				menu_hover = i

func _activate_menu_item(idx: int) -> void:
	match idx:
		0: get_tree().change_scene_to_file("res://scenes/main.tscn")
		1: _fade_to(Screen.HOW_TO_PLAY)
		2: _fade_to(Screen.HIGH_SCORES)
		3: _start_demo()
		4: get_tree().quit()

func _fade_to(screen: int) -> void:
	fading_to = screen

func _start_demo() -> void:
	HighScores.start_demo = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
	# Background
	var bg_hue: float = fmod(time * 0.02, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(600, 730)), Color.from_hsv(bg_hue, 0.15, 0.12))

	# Floating gems (background decoration)
	for i in 150:
		var speed: float = 10 + fmod(i * 13.7, 30.0)
		var gx: float = fmod(i * 53.0 + time * speed, 700.0) - 50.0
		var gy: float = fmod(i * 37.0 + time * (8 + fmod(i * 7.3, 20.0)), 830.0) - 50.0
		var c: Color = COLORS[i % COLORS.size()]
		var sz: float = 8 + fmod(i * 11.3, 16.0)
		var alpha: float = 0.08 + fmod(i * 3.7, 0.12)
		var rot: float = time * (0.5 + fmod(i * 0.3, 1.5))
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

	# Draw current screen with fade
	match current_screen:
		Screen.MENU:
			_draw_menu()
		Screen.HOW_TO_PLAY:
			_draw_how_to_play()
		Screen.HIGH_SCORES:
			_draw_high_scores()

	# Fade overlay
	if fade < 1.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(600, 730)), Color(0, 0, 0, 1.0 - fade))

func _draw_title(base_y: float) -> void:
	var font := ThemeDB.fallback_font
	var total_w := 0.0
	for i in TITLE.length():
		total_w += font.get_string_size(TITLE[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var x: float = (600.0 - total_w) * 0.5
	for i in TITLE.length():
		var ch: String = TITLE[i]
		var c: Color = COLORS[i % COLORS.size()]
		var bounce: float = sin(time * 2.5 + i * 0.6) * 8.0
		var pos := Vector2(x, base_y + bounce)
		draw_string(font, pos + Vector2(3, 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(0, 0, 0, 0.6))
		for off in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
			draw_string(font, pos + off, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, c.darkened(0.3))
		draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, c.lightened(0.2))
		draw_circle(pos + Vector2(6, -16), 4.0, Color(1, 1, 1, 0.3 + sin(time * 3.0 + i) * 0.2))
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x

func _draw_menu() -> void:
	_draw_title(260.0)
	var font := ThemeDB.fallback_font
	for i in MENU_ITEMS.size():
		var y: float = 370.0 + i * 50.0
		var c := Color(1, 1, 1, 0.7)
		if menu_hover == i:
			c = Color(1, 0.9, 0.3, 1.0)
			var arrow_x: float = 300.0 - font.get_string_size(MENU_ITEMS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x * 0.5 - 20.0
			draw_string(font, Vector2(arrow_x, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, c)
		draw_string(font, Vector2(0, y), MENU_ITEMS[i], HORIZONTAL_ALIGNMENT_CENTER, 600, 26, c)

func _draw_how_to_play() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 60), "How to Play", HORIZONTAL_ALIGNMENT_CENTER, 600, 36, Color(1, 0.9, 0.3))

	# Controls
	draw_string(font, Vector2(0, 110), "Click, drag, or use arrow keys to swap gems", HORIZONTAL_ALIGNMENT_CENTER, 600, 18, Color(0.8, 0.8, 0.8))
	draw_string(font, Vector2(0, 135), "Match 3+ in a row or column to clear", HORIZONTAL_ALIGNMENT_CENTER, 600, 18, Color(0.8, 0.8, 0.8))

	# Gem types
	draw_string(font, Vector2(0, 185), "Gem Types", HORIZONTAL_ALIGNMENT_CENTER, 600, 24, Color(0.6, 0.9, 1))
	var gem_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.CYAN]
	var shapes: Array[GemShape] = [GemShape.CIRCLE, GemShape.DIAMOND, GemShape.SQUARE, GemShape.TRIANGLE, GemShape.HEXAGON, GemShape.STAR_SHAPE, GemShape.PENTAGON]
	for i in 7:
		var gx: float = 52.0 + i * 74.0
		var gy: float = 230.0
		var c: Color = gem_colors[i]
		_draw_gem(Vector2(gx, gy), 22.0, shapes[i], c)
		draw_string(font, Vector2(gx - 37, gy + 38), GEM_NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, 74, 12, Color(0.7, 0.7, 0.7))

	# Special gems
	draw_string(font, Vector2(0, 310), "Special Gems", HORIZONTAL_ALIGNMENT_CENTER, 600, 24, Color(0.6, 0.9, 1))
	for i in SPECIAL_INFO.size():
		var info: Dictionary = SPECIAL_INFO[i]
		var sy: float = 360.0 + i * 100.0
		# Draw example gem with overlay
		var gem_center := Vector2(80, sy)
		var gem_idx: int = i % gem_colors.size()
		_draw_gem(gem_center, 24.0, shapes[gem_idx], gem_colors[gem_idx])
		_draw_special_overlay(gem_center, 24.0, i + 1)  # 1=FLAME, 2=STAR, 3=HYPERCUBE
		draw_string(font, Vector2(120, sy - 8), info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, info.color)
		draw_string(font, Vector2(120, sy + 18), info.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.75, 0.75))

	# Back hint
	var pulse: float = 0.4 + sin(time * 2.0) * 0.3
	draw_string(font, Vector2(0, 690), "Press Escape or click to go back", HORIZONTAL_ALIGNMENT_CENTER, 600, 18, Color(1, 1, 1, pulse))

func _draw_high_scores() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 60), "High Scores", HORIZONTAL_ALIGNMENT_CENTER, 600, 36, Color(1, 0.9, 0.3))

	var scores: Array = HighScores.entries
	if scores.is_empty():
		draw_string(font, Vector2(0, 350), "No scores yet!", HORIZONTAL_ALIGNMENT_CENTER, 600, 22, Color(0.6, 0.6, 0.6))
	else:
		# Header
		draw_string(font, Vector2(100, 120), "Rank", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.9, 1))
		draw_string(font, Vector2(220, 120), "Score", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.9, 1))
		draw_string(font, Vector2(360, 120), "Level", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.9, 1))
		draw_string(font, Vector2(460, 120), "Date", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.9, 1))
		for i in scores.size():
			var entry: Dictionary = scores[i]
			var y: float = 160.0 + i * 45.0
			var rank_color := Color(1, 0.85, 0.3) if i == 0 else (Color(0.8, 0.8, 0.9) if i == 1 else (Color(0.75, 0.55, 0.3) if i == 2 else Color(0.7, 0.7, 0.7)))
			draw_string(font, Vector2(100, y), "#%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, rank_color)
			draw_string(font, Vector2(220, y), str(entry.get("score", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, rank_color)
			draw_string(font, Vector2(360, y), "Lv %s" % str(entry.get("level", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, rank_color)
			draw_string(font, Vector2(460, y), str(entry.get("date", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))

	var pulse: float = 0.4 + sin(time * 2.0) * 0.3
	draw_string(font, Vector2(0, 690), "Press Escape or click to go back", HORIZONTAL_ALIGNMENT_CENTER, 600, 18, Color(1, 1, 1, pulse))

# --- Gem drawing helpers (self-contained for title screen) ---
func _draw_gem(center: Vector2, r: float, shape: GemShape, color: Color) -> void:
	var bright: Color = color.lightened(0.25)
	match shape:
		GemShape.CIRCLE:
			draw_circle(center, r, color.darkened(0.2))
			draw_circle(center, r * 0.85, color)
			draw_circle(center, r * 0.5, bright)
		GemShape.DIAMOND:
			var pts := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array([center + Vector2(0, -r*0.5), center + Vector2(r*0.5, 0), center + Vector2(0, r*0.5), center + Vector2(-r*0.5, 0)])
			draw_colored_polygon(inner, bright)
		GemShape.SQUARE:
			var h := r * 0.75
			draw_rect(Rect2(center - Vector2(h, h), Vector2(h*2, h*2)), color)
			draw_rect(Rect2(center - Vector2(h*0.5, h*0.5), Vector2(h, h)), bright)
		GemShape.TRIANGLE:
			var pts := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r*0.87, r*0.5), center + Vector2(-r*0.87, r*0.5)])
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array([center + Vector2(0, -r*0.5), center + Vector2(r*0.43, r*0.25), center + Vector2(-r*0.43, r*0.25)])
			draw_colored_polygon(inner, bright)
		GemShape.HEXAGON:
			var pts := PackedVector2Array()
			for i in 6:
				var a: float = TAU / 6.0 * i - PI / 6.0
				pts.append(center + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array()
			for i in 6:
				var a: float = TAU / 6.0 * i - PI / 6.0
				inner.append(center + Vector2(cos(a), sin(a)) * r * 0.55)
			draw_colored_polygon(inner, bright)
		GemShape.STAR_SHAPE:
			var pts := PackedVector2Array()
			for i in 10:
				var a: float = TAU / 10.0 * i - PI / 2.0
				var rad: float = r if i % 2 == 0 else r * 0.5
				pts.append(center + Vector2(cos(a), sin(a)) * rad)
			draw_colored_polygon(pts, color)
		GemShape.PENTAGON:
			var pts := PackedVector2Array()
			for i in 5:
				var a: float = TAU / 5.0 * i - PI / 2.0
				pts.append(center + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array()
			for i in 5:
				var a: float = TAU / 5.0 * i - PI / 2.0
				inner.append(center + Vector2(cos(a), sin(a)) * r * 0.55)
			draw_colored_polygon(inner, bright)
	draw_circle(center + Vector2(-r * 0.2, -r * 0.25), r * 0.18, Color(1, 1, 1, 0.4))

func _draw_special_overlay(center: Vector2, r: float, spec: int) -> void:
	match spec:
		1:  # FLAME
			for i in 3:
				draw_arc(center, r + 2.0 + i * 2.0, 0, TAU, 16, Color(1, 0.5, 0, 0.5 - i * 0.15), 2.0)
		2:  # STAR
			for i in 4:
				var a: float = time * 5.0 + i * PI / 2.0
				draw_line(center, center + Vector2(cos(a), sin(a)) * (r + 6), Color(1, 1, 1, 0.7), 2.0)
		3:  # HYPERCUBE
			for i in 12:
				var a1: float = TAU / 12.0 * i
				var a2: float = TAU / 12.0 * (i + 1)
				var c := Color.from_hsv(fmod(time * 0.3 + float(i) / 12.0, 1.0), 1, 1)
				draw_arc(center, r + 3, a1, a2, 4, c, 3.0)
