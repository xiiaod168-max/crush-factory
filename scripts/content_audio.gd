extends RefCounted
## Deterministic original event sounds: PET crinkle, wood split, sheet/hinge rattle.
static func synth(kind: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var bytes := PackedByteArray()
	bytes.resize(8820*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 417
	var low: float = 0
	for i in range(8820):
		var t: float = i/22050.0
		var noise: float = rng.randf_range(-1,1)
		low = lerpf(low,noise,0.17)
		var wave: float
		match kind:
			"bottle": wave = noise*0.22*exp(-t*17)*(0.4+0.6*pow(cos(t*140),8))
			"crate": wave = (noise*0.35*exp(-t*45)+low*0.8*exp(-t*13))*(0.65+0.35*cos(t*220))
			"pc": wave = (sin(t*TAU*210)*0.16+sin(t*TAU*537)*0.07+noise*0.10)*exp(-t*15)
			_: wave = (sin(t*TAU*128)*0.23+sin(t*TAU*319)*0.09+low*0.28)*exp(-t*11)
		bytes.encode_s16(i*2,int(clampf(wave,-1,1)*24000))
	stream.data = bytes
	return stream
