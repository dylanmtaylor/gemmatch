extends AudioStreamPlayer

# Procedural background music — chill chiptune loop
const SAMPLE_RATE := 22050
const BPM := 95.0
const BEAT := 60.0 / BPM
const BAR := BEAT * 4.0
const LOOP_BARS := 8
const VOLUME := 0.18

# Pentatonic scale notes (Hz) across 2 octaves for melody
const PENTA: Array[float] = [
	261.6, 293.7, 329.6, 392.0, 440.0,
	523.3, 587.3, 659.3, 784.0, 880.0
]
# Bass notes
const BASS: Array[float] = [130.8, 146.8, 164.8, 196.0, 220.0]

# Chord progressions (indices into BASS)
const PROG: Array[int] = [0, 3, 4, 2, 0, 3, 2, 4]

func _ready() -> void:
	var duration: float = BAR * LOOP_BARS
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	# Pre-generate a melody sequence (seeded for consistency)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var melody_notes: Array[int] = []
	for i in 64:
		melody_notes.append(rng.randi_range(0, PENTA.size() - 1))

	for i in samples:
		var t: float = float(i) / SAMPLE_RATE
		var bar_idx: int = int(t / BAR) % LOOP_BARS
		var beat_in_bar: float = fmod(t, BAR)
		var beat_idx: int = int(beat_in_bar / BEAT)
		var eighth_idx: int = int(beat_in_bar / (BEAT * 0.5))

		# Bass — root note of chord, square wave
		var bass_freq: float = BASS[PROG[bar_idx]]
		var bass: float = (1.0 if fmod(t * bass_freq, 1.0) < 0.5 else -1.0) * 0.3
		# Bass envelope — hit on beats 0 and 2
		var bass_env: float = 0.0
		if beat_idx == 0 or beat_idx == 2:
			var bt: float = fmod(beat_in_bar, BEAT * 2.0)
			bass_env = maxf(0.0, 1.0 - bt / (BEAT * 1.5))
		bass *= bass_env

		# Melody — triangle wave on eighth notes
		var mel_idx: int = (bar_idx * 8 + eighth_idx) % melody_notes.size()
		var mel_freq: float = PENTA[melody_notes[mel_idx]]
		var mel_phase: float = fmod(t * mel_freq, 1.0)
		var mel: float = (4.0 * absf(mel_phase - 0.5) - 1.0) * 0.25
		# Melody envelope
		var mel_t: float = fmod(beat_in_bar, BEAT * 0.5)
		var mel_env: float = maxf(0.0, 1.0 - mel_t / (BEAT * 0.45))
		mel *= mel_env

		# Pad — soft sine chord (root + fifth)
		var pad_freq: float = BASS[PROG[bar_idx]]
		var pad: float = sin(t * pad_freq * TAU) * 0.08
		pad += sin(t * pad_freq * 1.5 * TAU) * 0.05

		var mix: float = (bass + mel + pad) * VOLUME
		var sample_val: int = clampi(int(mix * 32767), -32768, 32767)
		data.encode_s16(i * 2, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples
	stream.data = data
	self.stream = stream
	volume_db = -6.0
	play()
