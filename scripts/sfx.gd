extends Node

const SAMPLE_RATE := 22050

func _make_stream(duration: float, freq_start: float, freq_end: float, vol: float = 0.5, noise_mix: float = 0.0) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t: float = float(i) / SAMPLE_RATE
		var p: float = float(i) / samples
		var freq: float = lerp(freq_start, freq_end, p)
		var envelope: float = (1.0 - p) * vol
		var wave: float = sin(t * freq * TAU) * (1.0 - noise_mix)
		wave += (randf() * 2.0 - 1.0) * noise_mix
		var sample_val: int = clampi(int(wave * envelope * 32767), -32768, 32767)
		data.encode_s16(i * 2, sample_val)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

var swap_sound: AudioStreamWAV
var match_sounds: Array[AudioStreamWAV] = []
var drop_sound: AudioStreamWAV
var bad_swap_sound: AudioStreamWAV
var select_sound: AudioStreamWAV
var explode_sound: AudioStreamWAV
var star_sound: AudioStreamWAV
var level_up_sound: AudioStreamWAV

func _ready() -> void:
	select_sound = _make_stream(0.05, 800, 900, 0.3)
	swap_sound = _make_stream(0.1, 400, 600, 0.4)
	bad_swap_sound = _make_stream(0.15, 300, 150, 0.4, 0.3)
	drop_sound = _make_stream(0.08, 200, 100, 0.3)
	explode_sound = _make_stream(0.25, 150, 50, 0.6, 0.5)
	star_sound = _make_stream(0.4, 400, 1600, 0.5, 0.1)
	level_up_sound = _make_stream(0.5, 300, 1200, 0.6)
	for i in 8:
		match_sounds.append(_make_stream(0.12, 600 + i * 150, 900 + i * 200, 0.5))

func play(stream: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
