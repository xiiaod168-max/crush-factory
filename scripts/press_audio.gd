extends Node
## Original synthesized motor and paper transients. Replaceable AudioStream profiles.
var motor: AudioStreamPlayer
var paper: AudioStreamPlayer
var muted: bool = false
var active: bool = false
var metal: bool = false
var rubber: bool = false

func synth(duration: float, impact: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count: int = int(duration * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 419 if impact else 73
	var smooth_noise: float = 0.0
	for i in range(count):
		var t: float = float(i) / stream.mix_rate
		var noise: float = rng.randf_range(-1,1)
		smooth_noise = lerpf(smooth_noise,noise,0.08)
		var signal_value: float
		if impact:
			var envelope: float = exp(-t*20.0) * minf(t*200,1)
			signal_value = (noise*0.38+sin(TAU*95*t)*0.16+smooth_noise*0.14)*envelope
			signal_value += noise*0.20*exp(-pow((t-0.07)/0.014,2))
			if metal:
				signal_value = noise*0.30*exp(-t*75.0)*minf(t*900,1)
				signal_value += (sin(TAU*740*t)+0.5*sin(TAU*1237*t))*0.19*exp(-t*29.0)*minf(t*600,1)
				signal_value += sin(TAU*72*t)*0.24*exp(-t*24.0)*minf(t*300,1)
		else:
			signal_value = sin(TAU*55*t)*0.18+sin(TAU*110*t)*0.07+sin(TAU*220*t)*0.025+smooth_noise*0.14
		if rubber and impact:
			signal_value = (smooth_noise*0.38+sin(TAU*(175*t+15*t*t))*0.18)*exp(-t*12.0)*minf(t*90,1)
		bytes.encode_s16(i*2,int(clampf(signal_value,-0.9,0.9)*32767))
	stream.data = bytes
	if not impact:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func _ready() -> void:
	motor = AudioStreamPlayer.new()
	motor.stream = synth(2.0,false)
	motor.volume_db = -60
	add_child(motor)
	motor.play()
	paper = AudioStreamPlayer.new()
	paper.stream = synth(0.32,true)
	paper.volume_db = -5
	add_child(paper)

func set_load(state: String, load_value: float) -> void:
	active = state == "PRESSING" or state == "RETURNING"
	var desired: float = -15.0+load_value*6.0 if active and not muted else -60.0
	motor.volume_db = move_toward(motor.volume_db,desired,1.5)
	motor.pitch_scale = 0.88+load_value*0.25 if state == "PRESSING" else 1.1
	if rubber and state=="PRESSING": motor.pitch_scale = 0.85+load_value*0.18
	paper.volume_db = -60 if muted else -5

func crack() -> void:
	if not muted:
		paper.play()

func shutdown() -> void:
	motor.stop()
	paper.stop()
	motor.stream = null
	paper.stream = null
