extends RefCounted
## Authored quasistatic resistance, not a rigid-body force integrator.
var profile = preload("res://scripts/material_profile.gd").new()
var compression: float = 0.0
var resistance: float = 0.0
const BUCKLE_AT: float = 0.16

func load_at(c: float) -> float:
	if c < BUCKLE_AT:
		return 20.0 + 58.0 * smoothstep(0.0,BUCKLE_AT,c)
	if c < 0.30:
		return 18.0 + 20.0 * smoothstep(BUCKLE_AT,0.30,c)
	return 32.0 + 50.0 * pow(clampf((c-0.30)/0.60,0.0,1.0),2.2)

func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	if not contacting:
		resistance = 0.0
		return {"travel": maxf(displacement, 0.0), "event": false}
	resistance = load_at(compression)
	var capacity: float = clampf((pressure - resistance) / 80.0, 0.0, 1.0)
	var accepted: float = minf(maxf(displacement, 0.0) * capacity, (profile.max_compression - compression) * profile.initial_height)
	if depth < -0.001:
		accepted = 0.0
	var previous: float = compression
	compression = clampf(compression + accepted / profile.initial_height, 0.0, profile.max_compression)
	var buckled: bool = previous < BUCKLE_AT and compression >= BUCKLE_AT
	resistance = load_at(compression)
	return {"travel": accepted, "event": buckled}

func height() -> float:
	return profile.initial_height * (1.0 - compression)
