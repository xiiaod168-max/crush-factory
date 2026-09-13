extends Node
var player: AudioStreamPlayer
var tones: Dictionary = {}
func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	for kind in ["collect","upgrade","unlock"]:
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var duration: float = 0.8 if kind=="upgrade" else 0.42
		var bytes := PackedByteArray()
		bytes.resize(int(duration*22050)*2)
		for i in range(bytes.size()/2):
			var t: float = float(i)/22050.0
			var v: float = sin(TAU*72*t)*exp(-t*13)*0.45
			if kind=="collect": v += sin(TAU*480*t)*exp(-t*24)*0.25
			if kind=="upgrade": v += sin(TAU*(95*t+45*t*t))*exp(-t*4)*0.3
			if kind=="unlock": v += (sin(TAU*360*t)+sin(TAU*540*t))*exp(-t*9)*0.16
			bytes.encode_s16(i*2,int(clampf(v*minf(t*300,1),-0.9,0.9)*32767))
		stream.data = bytes
		tones[kind] = stream
func play(kind: String, muted: bool) -> void:
	if muted: return
	player.stream = tones[kind]
	player.volume_db = -9 if kind=="upgrade" else -12
	player.play()
