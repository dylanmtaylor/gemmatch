extends Node

const SAVE_PATH := "user://highscores.json"
const MAX_ENTRIES := 10

var entries: Array = []  # [{score: int, level: int, date: String}]
var start_demo := false  # Set before changing to main scene

func _ready() -> void:
	load_scores()

func load_scores() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		entries = parsed

func save_scores() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(entries))

func add_score(s: int, lvl: int) -> int:
	# Returns rank (0-based), or -1 if not a high score
	var entry := {"score": s, "level": lvl, "date": Time.get_date_string_from_system()}
	entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	var rank: int = entries.find(entry)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	if rank >= MAX_ENTRIES:
		return -1
	save_scores()
	return rank
