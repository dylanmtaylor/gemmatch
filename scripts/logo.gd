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

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var total_w := 0.0
	for i in TITLE.length():
		total_w += font.get_string_size(TITLE[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
	var x: float = (600.0 - total_w) * 0.5
	var base_y: float = 52.0
	for i in TITLE.length():
		var ch: String = TITLE[i]
		var c: Color = COLORS[i % COLORS.size()]
		var bounce: float = sin(time * 3.0 + i * 0.7) * 4.0
		var pos := Vector2(x, base_y + bounce)
		# Shadow
		draw_string(font, pos + Vector2(2, 2), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(0, 0, 0, 0.5))
		# Bright outline
		for off in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
			draw_string(font, pos + off, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, c.darkened(0.3))
		# Main letter
		draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, c.lightened(0.2))
		# Specular dot
		draw_circle(pos + Vector2(4, -10), 3.0, Color(1, 1, 1, 0.3 + sin(time * 4.0 + i) * 0.2))
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
