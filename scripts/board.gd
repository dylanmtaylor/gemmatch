extends Node2D

# --- Constants ---
const GRID_SIZE := 8
const CELL_SIZE := 64
const GEM_RADIUS := 26
const GRID_OFFSET := Vector2(44, 100)
const SWAP_TIME := 0.18
const FALL_TIME := 0.15
const REMOVE_TIME := 0.25
const HINT_DELAY := 4.0
const LEVEL_THRESHOLD := 2000

# Gem types 0-6 = normal, special types stored separately
const GEM_COLORS: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW,
	Color.PURPLE, Color.ORANGE, Color.CYAN
]
# Gem shape identifiers for drawing
enum GemShape { CIRCLE, DIAMOND, SQUARE, TRIANGLE, HEXAGON, STAR_SHAPE, PENTAGON }
const GEM_SHAPES: Array[GemShape] = [
	GemShape.CIRCLE, GemShape.DIAMOND, GemShape.SQUARE, GemShape.TRIANGLE,
	GemShape.HEXAGON, GemShape.STAR_SHAPE, GemShape.PENTAGON
]

# Special gem types
enum Special { NONE, FLAME, STAR, HYPERCUBE }

# Combo text
const COMBO_TEXTS: Array[String] = ["Good!", "Great!", "Excellent!", "Amazing!", "Incredible!", "UNBELIEVABLE!"]

# --- State ---
var grid: Array = []              # grid[col][row] = gem color int, -1 = empty
var specials: Array = []          # specials[col][row] = Special enum
var selected := Vector2i(-1, -1)
var score := 0
var chain := 0
var level := 1
var level_progress := 0
var animating := false
var no_moves := false

# Drag state
var dragging := false
var drag_from := Vector2i(-1, -1)

# Keyboard cursor
var cursor := Vector2i(3, 3)

# Hint
var hint_timer := 0.0
var hint_cells: Array[Vector2i] = []
var hint_alpha := 0.0

# Animation state
var gem_offsets: Dictionary = {}
var gem_scales: Dictionary = {}
var shake_amount := 0.0
var score_popups: Array = []
var particles: Array = []         # [{pos, vel, color, life, max_life}]
var select_pulse := 0.0
var combo_text := ""
var combo_life := 0.0
var bg_hue_shift := 0.0
var demo_mode := false
var demo_timer := 0.0
var demo_target := Vector2i(-1, -1)
const DEMO_MOVE_DELAY := 0.25

@onready var score_label: Label = $"../ScoreLabel"
@onready var level_label: Label = $"../LevelLabel"
@onready var message_label: Label = $"../MessageLabel"
@onready var sfx: Node = $"../SFX"

# --- Init ---
func _ready() -> void:
	demo_mode = HighScores.start_demo
	HighScores.start_demo = false
	_init_grid()
	_update_ui()

func _init_grid() -> void:
	grid.clear()
	specials.clear()
	for col in GRID_SIZE:
		var column: Array[int] = []
		var scol: Array[int] = []
		for row in GRID_SIZE:
			column.append(randi_range(0, GEM_COLORS.size() - 1))
			scol.append(Special.NONE)
		grid.append(column)
		specials.append(scol)
	_eliminate_initial_matches()

func _eliminate_initial_matches() -> void:
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			while _has_match_at(col, row):
				grid[col][row] = randi_range(0, GEM_COLORS.size() - 1)

func _has_match_at(col: int, row: int) -> bool:
	var t: int = grid[col][row]
	if col >= 2 and grid[col-1][row] == t and grid[col-2][row] == t:
		return true
	if row >= 2 and grid[col][row-1] == t and grid[col][row-2] == t:
		return true
	return false

# --- Process ---
func _process(delta: float) -> void:
	select_pulse += delta * 5.0
	shake_amount = move_toward(shake_amount, 0.0, delta * 40.0)
	bg_hue_shift += delta * 0.02

	# Hint timer
	if not animating and not no_moves:
		hint_timer += delta
		if hint_timer >= HINT_DELAY and hint_cells.is_empty():
			_find_hint()
		if not hint_cells.is_empty():
			hint_alpha = 0.5 + sin(select_pulse * 1.5) * 0.4

	# Score popups
	var alive_p: Array = []
	for p in score_popups:
		p.life -= delta
		p.pos.y -= delta * 60.0
		if p.life > 0:
			alive_p.append(p)
	score_popups = alive_p

	# Particles
	var alive_parts: Array = []
	for pt in particles:
		pt.life -= delta
		pt.pos += pt.vel * delta
		pt.vel.y += 300.0 * delta  # gravity
		if pt.life > 0:
			alive_parts.append(pt)
	particles = alive_parts

	# Combo text
	if combo_life > 0:
		combo_life -= delta

	# Demo auto-play
	if demo_mode and not animating and not no_moves:
		demo_timer += delta
		if demo_timer >= DEMO_MOVE_DELAY:
			demo_timer = 0.0
			if selected == Vector2i(-1, -1):
				_demo_select()
			else:
				_demo_swap()

	queue_redraw()

# --- Drawing ---
func _cell_pos(col: int, row: int) -> Vector2:
	return GRID_OFFSET + Vector2(col, row) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5

func _draw_background() -> void:
	var hue: float = fmod(float(level - 1) * 0.13 + bg_hue_shift, 1.0)
	var base := Color.from_hsv(hue, 0.3, 0.18)
	draw_rect(Rect2(Vector2.ZERO, Vector2(600, 730)), base)
	var pattern: int = (level - 1) % 5
	var t: float = bg_hue_shift * 50.0  # use accumulated time
	var accent := Color.from_hsv(hue, 0.5, 0.35)
	match pattern:
		0:  # Floating circles
			for i in 30:
				var x: float = fmod(i * 47.3 + t * (0.3 + fmod(i * 0.17, 0.4)), 700.0) - 50.0
				var y: float = fmod(i * 31.7 + t * (0.2 + fmod(i * 0.13, 0.3)), 830.0) - 50.0
				var r: float = 15.0 + fmod(i * 7.3, 25.0)
				draw_circle(Vector2(x, y), r, Color(accent.r, accent.g, accent.b, 0.15 + fmod(i * 0.01, 0.1)))
		1:  # Diagonal lines
			for i in 20:
				var offset: float = fmod(i * 60.0 - t * 20.0, 1400.0) - 400.0
				draw_line(Vector2(offset, 0), Vector2(offset + 730, 730), Color(accent.r, accent.g, accent.b, 0.12), 2.0)
		2:  # Diamonds
			for i in 25:
				var cx: float = fmod(i * 53.0 + t * 0.25, 700.0) - 50.0
				var cy: float = fmod(i * 41.0 + t * 0.15, 830.0) - 50.0
				var s: float = 12.0 + fmod(i * 9.1, 20.0)
				var pts := PackedVector2Array([Vector2(cx, cy - s), Vector2(cx + s, cy), Vector2(cx, cy + s), Vector2(cx - s, cy)])
				draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.14))
		3:  # Horizontal waves
			for j in 8:
				var pts := PackedVector2Array()
				var by: float = j * 100.0 + fmod(t * 15.0, 100.0) - 50.0
				for x in range(0, 620, 20):
					pts.append(Vector2(x, by + sin(float(x) * 0.02 + t * 0.5 + j) * 30.0))
				for k in range(pts.size() - 1):
					draw_line(pts[k], pts[k + 1], Color(accent.r, accent.g, accent.b, 0.12), 2.0)
		4:  # Hexagon grid
			var hex_r := 30.0
			for gx in range(-1, 12):
				for gy in range(-1, 14):
					var cx: float = gx * hex_r * 1.75 + fmod(t * 8.0, hex_r * 1.75)
					var cy: float = gy * hex_r * 1.5 + (hex_r * 0.75 if gx % 2 == 1 else 0.0)
					var hp := PackedVector2Array()
					for k in 6:
						var a: float = TAU / 6.0 * k
						hp.append(Vector2(cx + cos(a) * hex_r, cy + sin(a) * hex_r))
					for k in 6:
						draw_line(hp[k], hp[(k + 1) % 6], Color(accent.r, accent.g, accent.b, 0.1), 1.0)

func _draw_gem_shape(center: Vector2, r: float, shape: GemShape, color: Color, bright: Color, dark: Color) -> void:
	match shape:
		GemShape.CIRCLE:
			draw_circle(center, r, dark)
			draw_circle(center, r * 0.85, color)
			draw_circle(center, r * 0.5, bright)
		GemShape.DIAMOND:
			var pts := PackedVector2Array([
				center + Vector2(0, -r), center + Vector2(r, 0),
				center + Vector2(0, r), center + Vector2(-r, 0)])
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array([
				center + Vector2(0, -r*0.5), center + Vector2(r*0.5, 0),
				center + Vector2(0, r*0.5), center + Vector2(-r*0.5, 0)])
			draw_colored_polygon(inner, bright)
		GemShape.SQUARE:
			var half := r * 0.75
			draw_rect(Rect2(center - Vector2(half, half), Vector2(half*2, half*2)), color)
			draw_rect(Rect2(center - Vector2(half*0.5, half*0.5), Vector2(half, half)), bright)
		GemShape.TRIANGLE:
			var pts := PackedVector2Array([
				center + Vector2(0, -r), center + Vector2(r * 0.87, r * 0.5),
				center + Vector2(-r * 0.87, r * 0.5)])
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array([
				center + Vector2(0, -r*0.5), center + Vector2(r*0.43, r*0.25),
				center + Vector2(-r*0.43, r*0.25)])
			draw_colored_polygon(inner, bright)
		GemShape.HEXAGON:
			var pts := PackedVector2Array()
			for i in 6:
				var angle: float = TAU / 6.0 * i - PI / 6.0
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array()
			for i in 6:
				var angle: float = TAU / 6.0 * i - PI / 6.0
				inner.append(center + Vector2(cos(angle), sin(angle)) * r * 0.55)
			draw_colored_polygon(inner, bright)
		GemShape.STAR_SHAPE:
			var pts := PackedVector2Array()
			for i in 10:
				var angle: float = TAU / 10.0 * i - PI / 2.0
				var rad: float = r if i % 2 == 0 else r * 0.5
				pts.append(center + Vector2(cos(angle), sin(angle)) * rad)
			draw_colored_polygon(pts, color)
		GemShape.PENTAGON:
			var pts := PackedVector2Array()
			for i in 5:
				var angle: float = TAU / 5.0 * i - PI / 2.0
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(pts, color)
			var inner := PackedVector2Array()
			for i in 5:
				var angle: float = TAU / 5.0 * i - PI / 2.0
				inner.append(center + Vector2(cos(angle), sin(angle)) * r * 0.55)
			draw_colored_polygon(inner, bright)
	# Specular highlight on all shapes
	draw_circle(center + Vector2(-r * 0.2, -r * 0.25), r * 0.18, Color(1, 1, 1, 0.4))

func _draw_special_overlay(center: Vector2, r: float, spec: int) -> void:
	match spec:
		Special.FLAME:
			# Flame ring
			for i in 3:
				var rad: float = r + 2.0 + i * 2.0
				draw_arc(center, rad, 0, TAU, 16, Color(1, 0.5, 0, 0.5 - i * 0.15), 2.0)
		Special.STAR:
			# Star sparkle
			for i in 4:
				var angle: float = select_pulse + i * PI / 2.0
				var tip := center + Vector2(cos(angle), sin(angle)) * (r + 6)
				draw_line(center, tip, Color(1, 1, 1, 0.7), 2.0)
		Special.HYPERCUBE:
			# Rainbow outline
			for i in 12:
				var a1: float = TAU / 12.0 * i
				var a2: float = TAU / 12.0 * (i + 1)
				var c := Color.from_hsv(fmod(bg_hue_shift + float(i) / 12.0, 1.0), 1, 1)
				draw_arc(center, r + 3, a1, a2, 4, c, 3.0)

func _draw() -> void:
	var shake_off := Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))

	# Full-screen animated background — pattern changes each level
	_draw_background()

	# Grid background
	var bg_color := Color.from_hsv(fmod(bg_hue_shift, 1.0), 0.15, 0.12)
	draw_rect(Rect2(GRID_OFFSET + shake_off, Vector2.ONE * CELL_SIZE * GRID_SIZE), bg_color)

	# Checkerboard
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			if (col + row) % 2 == 0:
				draw_rect(Rect2(GRID_OFFSET + Vector2(col, row) * CELL_SIZE + shake_off, Vector2.ONE * CELL_SIZE), Color(1, 1, 1, 0.03))

	# Level progress bar
	var bar_y := GRID_OFFSET.y + GRID_SIZE * CELL_SIZE + 8
	var bar_w: float = CELL_SIZE * GRID_SIZE
	var progress: float = clampf(float(level_progress) / LEVEL_THRESHOLD, 0.0, 1.0)
	draw_rect(Rect2(GRID_OFFSET.x + shake_off.x, bar_y + shake_off.y, bar_w, 12), Color(0.2, 0.2, 0.3))
	if progress > 0:
		draw_rect(Rect2(GRID_OFFSET.x + shake_off.x, bar_y + shake_off.y, bar_w * progress, 12), Color(0.3, 0.8, 1.0))

	# Hint highlight
	if not hint_cells.is_empty():
		for hc in hint_cells:
			var hp := GRID_OFFSET + Vector2(hc) * CELL_SIZE + shake_off
			draw_rect(Rect2(hp, Vector2.ONE * CELL_SIZE), Color(1, 1, 1, hint_alpha * 0.25))

	# Gems
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			var key := Vector2i(col, row)
			if grid[col][row] < 0:
				continue
			var center: Vector2 = _cell_pos(col, row) + shake_off + gem_offsets.get(key, Vector2.ZERO)
			var s: float = gem_scales.get(key, 1.0)
			var r: float = GEM_RADIUS * s
			if r <= 0.5:
				continue
			var gem_type: int = grid[col][row]
			var base_color: Color = GEM_COLORS[gem_type]
			var bright: Color = base_color.lightened(0.25)
			var dark: Color = base_color.darkened(0.2)
			_draw_gem_shape(center, r, GEM_SHAPES[gem_type], base_color, bright, dark)
			if specials[col][row] != Special.NONE:
				_draw_special_overlay(center, r, specials[col][row])

	# Selection highlight
	if selected != Vector2i(-1, -1):
		var sel_off: Vector2 = gem_offsets.get(selected, Vector2.ZERO)
		var sel_center := _cell_pos(selected.x, selected.y) + shake_off + sel_off
		var pulse: float = 1.0 + sin(select_pulse) * 0.12
		draw_arc(sel_center, CELL_SIZE * 0.5 * pulse, 0, TAU, 32, Color(1, 1, 1, 0.5 + sin(select_pulse) * 0.3), 3.0)

	# Keyboard cursor
	if not demo_mode:
		var cur_pos := GRID_OFFSET + Vector2(cursor) * CELL_SIZE + shake_off
		var ca: float = 0.3 + sin(select_pulse * 1.5) * 0.15
		draw_rect(Rect2(cur_pos, Vector2.ONE * CELL_SIZE), Color(1, 1, 1, ca), false, 2.0)

	# Particles
	for pt in particles:
		var alpha: float = clampf(pt.life / pt.max_life, 0.0, 1.0)
		var pr: float = 3.0 * alpha
		draw_circle(pt.pos + shake_off, pr, Color(pt.color.r, pt.color.g, pt.color.b, alpha))

	# Score popups
	var font := ThemeDB.fallback_font
	for p in score_popups:
		var alpha: float = clampf(p.life / 0.5, 0.0, 1.0)
		draw_string(font, p.pos + shake_off, p.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 0.3, alpha))

	# Combo text
	if combo_life > 0:
		var ca: float = clampf(combo_life / 0.5, 0.0, 1.0)
		var cy: float = GRID_OFFSET.y - 30 - (1.0 - ca) * 20
		draw_string(font, Vector2(GRID_OFFSET.x + 150, cy), combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(1, 0.8, 0.2, ca))

	# Demo watermark
	if demo_mode:
		var da: float = 0.15 + sin(select_pulse * 0.5) * 0.12
		draw_string(font, Vector2(GRID_OFFSET.x, GRID_OFFSET.y + GRID_SIZE * CELL_SIZE * 0.5 + 20), "DEMO", HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE * GRID_SIZE, 64, Color(1, 1, 1, da))

# --- Input (click + drag) ---
func _input(event: InputEvent) -> void:
	if demo_mode:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	if animating:
		return
	if no_moves:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
			_restart()
		return

	# Keyboard input
	if event is InputEventKey and event.pressed:
		var dir := Vector2i.ZERO
		match event.keycode:
			KEY_UP, KEY_W: dir = Vector2i(0, -1)
			KEY_DOWN, KEY_S: dir = Vector2i(0, 1)
			KEY_LEFT, KEY_A: dir = Vector2i(-1, 0)
			KEY_RIGHT, KEY_D: dir = Vector2i(1, 0)
			KEY_ENTER, KEY_SPACE:
				if selected == Vector2i(-1, -1):
					selected = cursor
					sfx.play(sfx.select_sound)
					_reset_hint()
				elif selected == cursor:
					selected = Vector2i(-1, -1)
				return
			KEY_ESCAPE:
				selected = Vector2i(-1, -1)
				return
		if dir != Vector2i.ZERO:
			if selected != Vector2i(-1, -1):
				# Swap selected gem in direction
				var target := selected + dir
				if target.x >= 0 and target.x < GRID_SIZE and target.y >= 0 and target.y < GRID_SIZE:
					sfx.play(sfx.swap_sound)
					_do_swap(selected, target)
				return
			cursor.x = clampi(cursor.x + dir.x, 0, GRID_SIZE - 1)
			cursor.y = clampi(cursor.y + dir.y, 0, GRID_SIZE - 1)
			_reset_hint()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _pos_to_cell(event.position)
		if event.pressed:
			if cell.x >= 0:
				cursor = cell
				dragging = true
				drag_from = cell
				if selected == Vector2i(-1, -1):
					selected = cell
					sfx.play(sfx.select_sound)
					_reset_hint()
				elif _is_adjacent(selected, cell):
					sfx.play(sfx.swap_sound)
					_do_swap(selected, cell)
				else:
					selected = cell
					sfx.play(sfx.select_sound)
					_reset_hint()
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging and drag_from.x >= 0:
		var cell := _pos_to_cell(event.position)
		if cell.x >= 0 and cell != drag_from and _is_adjacent(drag_from, cell):
			dragging = false
			selected = Vector2i(-1, -1)
			sfx.play(sfx.swap_sound)
			_do_swap(drag_from, cell)

func _pos_to_cell(pos: Vector2) -> Vector2i:
	var local: Vector2 = pos - GRID_OFFSET
	var col: int = int(local.x / CELL_SIZE)
	var row: int = int(local.y / CELL_SIZE)
	if col < 0 or col >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, row)

func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1

func _reset_hint() -> void:
	hint_timer = 0.0
	hint_cells.clear()

func _find_hint() -> void:
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			for dir: Vector2i in [Vector2i(1,0), Vector2i(0,1)]:
				var nc: int = col + dir.x
				var nr: int = row + dir.y
				if nc < GRID_SIZE and nr < GRID_SIZE:
					_swap_grid(Vector2i(col, row), Vector2i(nc, nr))
					var m := _find_matches()
					_swap_grid(Vector2i(col, row), Vector2i(nc, nr))
					if not m.is_empty():
						hint_cells = [Vector2i(col, row), Vector2i(nc, nr)]
						return

# --- Swap & Match Logic ---
func _do_swap(a: Vector2i, b: Vector2i) -> void:
	_reset_hint()
	animating = true
	chain = 0

	# Hypercube special: if either is hypercube, destroy all of the other's color
	if specials[a.x][a.y] == Special.HYPERCUBE or specials[b.x][b.y] == Special.HYPERCUBE:
		var hc_pos: Vector2i = a if specials[a.x][a.y] == Special.HYPERCUBE else b
		var other_pos: Vector2i = b if hc_pos == a else a
		var target_color: int = grid[other_pos.x][other_pos.y]
		await _animate_swap(a, b)
		selected = Vector2i(-1, -1)
		sfx.play(sfx.star_sound)
		var to_remove: Array[Vector2i] = [hc_pos]
		for col in GRID_SIZE:
			for row in GRID_SIZE:
				if grid[col][row] == target_color:
					to_remove.append(Vector2i(col, row))
		_spawn_particles_for(to_remove)
		shake_amount = 15.0
		var pts: int = to_remove.size() * 20
		score += pts
		level_progress += pts
		_add_popup(to_remove, pts)
		await _animate_remove(to_remove)
		for c in to_remove:
			grid[c.x][c.y] = -1
			specials[c.x][c.y] = Special.NONE
		await _animate_gravity()
		await _cascade()
		_finish_move()
		return

	_swap_grid(a, b)
	_swap_specials(a, b)
	await _animate_swap(a, b)
	selected = Vector2i(-1, -1)
	var matches := _find_matches()
	if matches.is_empty():
		_swap_grid(a, b)
		_swap_specials(a, b)
		sfx.play(sfx.bad_swap_sound)
		await _animate_swap(a, b)
		animating = false
		return
	await _process_matches_with_specials(a, b, matches)
	_finish_move()

func _swap_grid(a: Vector2i, b: Vector2i) -> void:
	var tmp: int = grid[a.x][a.y]
	grid[a.x][a.y] = grid[b.x][b.y]
	grid[b.x][b.y] = tmp

func _swap_specials(a: Vector2i, b: Vector2i) -> void:
	var tmp: int = specials[a.x][a.y]
	specials[a.x][a.y] = specials[b.x][b.y]
	specials[b.x][b.y] = tmp

func _animate_swap(a: Vector2i, b: Vector2i) -> void:
	var pos_a := Vector2(a - b) * CELL_SIZE
	var pos_b := Vector2(b - a) * CELL_SIZE
	gem_offsets[a] = pos_a
	gem_offsets[b] = pos_b
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: Vector2) -> void: gem_offsets[a] = v, pos_a, Vector2.ZERO, SWAP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_method(func(v: Vector2) -> void: gem_offsets[b] = v, pos_b, Vector2.ZERO, SWAP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw.finished
	gem_offsets.erase(a)
	gem_offsets.erase(b)

func _find_matches() -> Array[Vector2i]:
	var matched: Array[Vector2i] = []
	# Horizontal
	for row in GRID_SIZE:
		var run := 1
		for col in range(1, GRID_SIZE):
			if grid[col][row] >= 0 and grid[col][row] == grid[col-1][row]:
				run += 1
			else:
				if run >= 3:
					for k in run:
						var v := Vector2i(col - run + k, row)
						if v not in matched:
							matched.append(v)
				run = 1
		if run >= 3:
			for k in run:
				var v := Vector2i(GRID_SIZE - run + k, row)
				if v not in matched:
					matched.append(v)
	# Vertical
	for col in GRID_SIZE:
		var run := 1
		for row in range(1, GRID_SIZE):
			if grid[col][row] >= 0 and grid[col][row] == grid[col][row-1]:
				run += 1
			else:
				if run >= 3:
					for k in run:
						var v := Vector2i(col, row - run + k)
						if v not in matched:
							matched.append(v)
				run = 1
		if run >= 3:
			for k in run:
				var v := Vector2i(col, GRID_SIZE - run + k)
				if v not in matched:
					matched.append(v)
	return matched

# --- Special Gem Creation & Processing ---
func _detect_special(swap_a: Vector2i, swap_b: Vector2i, matches: Array[Vector2i]) -> Dictionary:
	# Returns {cell: Vector2i, type: Special} or empty
	# Check for match-5 (star gem), match-4 (flame), L/T shape (hypercube)
	# Find runs
	var h_runs: Array = _get_runs_h(matches)
	var v_runs: Array = _get_runs_v(matches)

	# Match-5+ -> Star at swap position
	for r in h_runs:
		if r.size() >= 5:
			var pos: Vector2i = swap_a if swap_a in r else (swap_b if swap_b in r else r[2])
			return {cell = pos, type = Special.STAR}
	for r in v_runs:
		if r.size() >= 5:
			var pos: Vector2i = swap_a if swap_a in r else (swap_b if swap_b in r else r[2])
			return {cell = pos, type = Special.STAR}

	# L/T shape: cell in both a horizontal and vertical run -> Hypercube
	for cell in matches:
		var in_h := false
		var in_v := false
		for r in h_runs:
			if cell in r:
				in_h = true
				break
		for r in v_runs:
			if cell in r:
				in_v = true
				break
		if in_h and in_v:
			return {cell = cell, type = Special.HYPERCUBE}

	# Match-4 -> Flame at swap position
	for r in h_runs:
		if r.size() == 4:
			var pos: Vector2i = swap_a if swap_a in r else (swap_b if swap_b in r else r[1])
			return {cell = pos, type = Special.FLAME}
	for r in v_runs:
		if r.size() == 4:
			var pos: Vector2i = swap_a if swap_a in r else (swap_b if swap_b in r else r[1])
			return {cell = pos, type = Special.FLAME}

	return {}

func _get_runs_h(matches: Array[Vector2i]) -> Array:
	var runs: Array = []
	for row in GRID_SIZE:
		var row_cells: Array[Vector2i] = []
		for m in matches:
			if m.y == row:
				row_cells.append(m)
		row_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
		if row_cells.size() < 3:
			continue
		var run: Array[Vector2i] = [row_cells[0]]
		for i in range(1, row_cells.size()):
			if row_cells[i].x == row_cells[i-1].x + 1:
				run.append(row_cells[i])
			else:
				if run.size() >= 3:
					runs.append(run.duplicate())
				run = [row_cells[i]]
		if run.size() >= 3:
			runs.append(run)
	return runs

func _get_runs_v(matches: Array[Vector2i]) -> Array:
	var runs: Array = []
	for col in GRID_SIZE:
		var col_cells: Array[Vector2i] = []
		for m in matches:
			if m.x == col:
				col_cells.append(m)
		col_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
		if col_cells.size() < 3:
			continue
		var run: Array[Vector2i] = [col_cells[0]]
		for i in range(1, col_cells.size()):
			if col_cells[i].y == col_cells[i-1].y + 1:
				run.append(col_cells[i])
			else:
				if run.size() >= 3:
					runs.append(run.duplicate())
				run = [col_cells[i]]
		if run.size() >= 3:
			runs.append(run)
	return runs

func _process_matches_with_specials(swap_a: Vector2i, swap_b: Vector2i, matches: Array[Vector2i]) -> void:
	chain = 0
	while not matches.is_empty():
		chain += 1
		# Detect special gem creation
		var special_info: Dictionary = _detect_special(swap_a, swap_b, matches)

		# Trigger existing specials in matched cells
		var extra_remove: Array[Vector2i] = []
		for m in matches:
			if specials[m.x][m.y] == Special.FLAME:
				sfx.play(sfx.explode_sound)
				extra_remove.append_array(_get_3x3(m))
			elif specials[m.x][m.y] == Special.STAR:
				sfx.play(sfx.star_sound)
				var color: int = grid[m.x][m.y]
				for col in GRID_SIZE:
					for row in GRID_SIZE:
						if grid[col][row] == color:
							var v := Vector2i(col, row)
							if v not in extra_remove:
								extra_remove.append(v)

		# Merge extra into matches
		for e in extra_remove:
			if e not in matches and e.x >= 0 and e.x < GRID_SIZE and e.y >= 0 and e.y < GRID_SIZE and grid[e.x][e.y] >= 0:
				matches.append(e)

		var pts: int = matches.size() * 10 * chain
		score += pts
		level_progress += pts
		_update_ui()

		# Combo text
		if chain >= 2 and chain - 2 < COMBO_TEXTS.size():
			combo_text = COMBO_TEXTS[chain - 2]
			combo_life = 1.0

		var snd_idx: int = clampi(chain - 1, 0, sfx.match_sounds.size() - 1)
		sfx.play(sfx.match_sounds[snd_idx])
		shake_amount = clampf(chain * 3.0, 3.0, 15.0)

		_spawn_particles_for(matches)
		_add_popup(matches, pts)
		await _animate_remove(matches)

		# Place special gem if earned (before clearing)
		if not special_info.is_empty():
			var sc: Vector2i = special_info.cell
			# Don't clear this cell — it becomes the special
			grid[sc.x][sc.y] = grid[sc.x][sc.y] if grid[sc.x][sc.y] >= 0 else randi_range(0, GEM_COLORS.size() - 1)
			specials[sc.x][sc.y] = special_info.type
			matches.erase(sc)

		for m in matches:
			grid[m.x][m.y] = -1
			specials[m.x][m.y] = Special.NONE

		await _animate_gravity()
		# For cascades, use center of board as swap reference
		swap_a = Vector2i(4, 4)
		swap_b = Vector2i(4, 4)
		matches = _find_matches()

func _cascade() -> void:
	var matches := _find_matches()
	while not matches.is_empty():
		chain += 1
		var pts: int = matches.size() * 10 * chain
		score += pts
		level_progress += pts
		_update_ui()
		if chain >= 2 and chain - 2 < COMBO_TEXTS.size():
			combo_text = COMBO_TEXTS[chain - 2]
			combo_life = 1.0
		var snd_idx: int = clampi(chain - 1, 0, sfx.match_sounds.size() - 1)
		sfx.play(sfx.match_sounds[snd_idx])
		shake_amount = clampf(chain * 3.0, 3.0, 15.0)
		_spawn_particles_for(matches)
		_add_popup(matches, pts)
		await _animate_remove(matches)
		for m in matches:
			grid[m.x][m.y] = -1
			specials[m.x][m.y] = Special.NONE
		await _animate_gravity()
		matches = _find_matches()

func _get_3x3(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var c := Vector2i(center.x + dx, center.y + dy)
			if c.x >= 0 and c.x < GRID_SIZE and c.y >= 0 and c.y < GRID_SIZE:
				cells.append(c)
	return cells

# --- Animation helpers ---
func _animate_remove(cells: Array[Vector2i]) -> void:
	for c in cells:
		gem_scales[c] = 1.0
	var tw := create_tween().set_parallel(true)
	for c in cells:
		tw.tween_method(func(v: float) -> void: gem_scales[c] = v, 1.0, 0.0, REMOVE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await tw.finished
	for c in cells:
		gem_scales.erase(c)

func _animate_gravity() -> void:
	var moves: Array = []
	for col in GRID_SIZE:
		var write := GRID_SIZE - 1
		for row in range(GRID_SIZE - 1, -1, -1):
			if grid[col][row] >= 0:
				if write != row:
					moves.append({col = col, from_row = row, to_row = write})
				write -= 1
		for row in range(write, -1, -1):
			moves.append({col = col, from_row = row - (write + 1), to_row = row})

	# Apply grid changes
	for col in GRID_SIZE:
		var write := GRID_SIZE - 1
		var new_specials: Array[int] = []
		new_specials.resize(GRID_SIZE)
		new_specials.fill(Special.NONE)
		for row in range(GRID_SIZE - 1, -1, -1):
			if grid[col][row] >= 0:
				grid[col][write] = grid[col][row]
				new_specials[write] = specials[col][row]
				if write != row:
					grid[col][row] = -1
					specials[col][row] = Special.NONE
				write -= 1
		for row in range(write, -1, -1):
			grid[col][row] = randi_range(0, GEM_COLORS.size() - 1)
			new_specials[row] = Special.NONE
		for row in GRID_SIZE:
			specials[col][row] = new_specials[row]

	if moves.is_empty():
		return
	var tw := create_tween().set_parallel(true)
	for m in moves:
		var key := Vector2i(m.col, m.to_row)
		var dist: float = (m.from_row - m.to_row) * CELL_SIZE
		var offset_start := Vector2(0, -dist)
		gem_offsets[key] = offset_start
		var fall_time: float = FALL_TIME * sqrt(absf(m.from_row - m.to_row))
		tw.tween_method(func(v: Vector2) -> void: gem_offsets[key] = v, offset_start, Vector2.ZERO, fall_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	sfx.play(sfx.drop_sound)
	await tw.finished
	gem_offsets.clear()

func _spawn_particles_for(cells: Array[Vector2i]) -> void:
	for c in cells:
		if grid[c.x][c.y] < 0:
			continue
		var color: Color = GEM_COLORS[grid[c.x][c.y]]
		var center := _cell_pos(c.x, c.y)
		for i in 6:
			var angle: float = randf() * TAU
			var speed: float = randf_range(80, 200)
			particles.append({
				pos = center,
				vel = Vector2(cos(angle), sin(angle)) * speed,
				color = color,
				life = randf_range(0.3, 0.7),
				max_life = 0.7
			})

func _add_popup(cells: Array[Vector2i], pts: int) -> void:
	var centroid := Vector2.ZERO
	for m in cells:
		centroid += _cell_pos(m.x, m.y)
	centroid /= cells.size()
	score_popups.append({pos = centroid - Vector2(30, 0), text = "+%d" % pts, life = 0.8})

# --- End-of-move ---
func _finish_move() -> void:
	# Level up check
	if level_progress >= LEVEL_THRESHOLD:
		level += 1
		level_progress -= LEVEL_THRESHOLD
		sfx.play(sfx.level_up_sound)
		combo_text = "LEVEL %d!" % level
		combo_life = 1.5
		shake_amount = 10.0
	_update_ui()
	if not _has_valid_moves():
		if demo_mode:
			get_tree().change_scene_to_file("res://scenes/title.tscn")
			return
		no_moves = true
		var rank: int = HighScores.add_score(score, level)
		if rank == 0:
			message_label.text = "NEW HIGH SCORE! Click to restart."
		elif rank > 0:
			message_label.text = "Top %d! Click to restart." % (rank + 1)
		else:
			message_label.text = "No moves! Click to restart."
		message_label.visible = true
	animating = false

func _has_valid_moves() -> bool:
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			for dir: Vector2i in [Vector2i(1,0), Vector2i(0,1)]:
				var nc: int = col + dir.x
				var nr: int = row + dir.y
				if nc < GRID_SIZE and nr < GRID_SIZE:
					_swap_grid(Vector2i(col, row), Vector2i(nc, nr))
					var m := _find_matches()
					_swap_grid(Vector2i(col, row), Vector2i(nc, nr))
					if not m.is_empty():
						return true
	return false

func _restart() -> void:
	no_moves = false
	score = 0
	chain = 0
	level = 1
	level_progress = 0
	message_label.visible = false
	gem_offsets.clear()
	gem_scales.clear()
	score_popups.clear()
	particles.clear()
	combo_life = 0.0
	_init_grid()
	_update_ui()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	level_label.text = "Level %d" % level

func _demo_select() -> void:
	var best_a := Vector2i.ZERO
	var best_b := Vector2i.ZERO
	var best_score := -1
	for col in GRID_SIZE:
		for row in GRID_SIZE:
			for dir: Vector2i in [Vector2i(1,0), Vector2i(0,1)]:
				var nc: int = col + dir.x
				var nr: int = row + dir.y
				if nc >= GRID_SIZE or nr >= GRID_SIZE:
					continue
				var a := Vector2i(col, row)
				var b := Vector2i(nc, nr)
				_swap_grid(a, b)
				var m := _find_matches()
				var s := 0
				if not m.is_empty():
					s = m.size()
					var h := _get_runs_h(m)
					var v := _get_runs_v(m)
					for r in h + v:
						if r.size() >= 5:
							s += 50
						elif r.size() == 4:
							s += 20
					for cell in m:
						var in_h := false
						var in_v := false
						for r in h:
							if cell in r:
								in_h = true
								break
						for r in v:
							if cell in r:
								in_v = true
								break
						if in_h and in_v:
							s += 35
							break
					for cell in m:
						if specials[cell.x][cell.y] != Special.NONE:
							s += 30
				_swap_grid(a, b)
				if s > best_score:
					best_score = s
					best_a = a
					best_b = b
	if best_score > 0:
		selected = best_a
		demo_target = best_b

func _demo_swap() -> void:
	var a := selected
	var b := demo_target
	selected = Vector2i(-1, -1)
	demo_target = Vector2i(-1, -1)
	if a.x >= 0 and b.x >= 0:
		_do_swap(a, b)
