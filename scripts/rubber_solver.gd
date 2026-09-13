extends RefCounted
## Elastic strain unloads; damage is history-dependent and cannot heal.
var profile = preload("res://scripts/material_profile.gd").new()
var compression: float = 0.0
var elastic_deformation: float = 0.0
var permanent_damage: float = 0.0
var resistance: float = 0.0
var damaged: bool = false

func _init() -> void:
	profile.max_compression = 0.66

func load_at(c: float) -> float:
	return 18.0+67.0*pow(clampf(c/0.66,0,1),2.3)

func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	if not contacting:
		resistance = 0.0
		return {"travel":maxf(displacement,0),"event":false}
	resistance = load_at(compression)
	var travel: float = minf(maxf(displacement,0)*clampf((pressure-resistance)/80.0,0,1),(profile.max_compression-compression)*profile.initial_height)
	if depth < -0.001: travel = 0.0
	compression = clampf(compression+travel/profile.initial_height,0,profile.max_compression)
	if pressure>=78.0:
		permanent_damage = maxf(permanent_damage,0.21*smoothstep(0.48,0.66,compression))
	var event: bool = permanent_damage>0.005 and not damaged
	if event: damaged = true
	elastic_deformation = maxf(0,compression-permanent_damage)
	resistance = load_at(compression)
	return {"travel":travel,"event":event}

func recover(dt: float, clearance: float) -> void:
	var relaxation: float = permanent_damage+elastic_deformation*exp(-dt*1.05)
	var next: float = move_toward(compression,relaxation,0.18*dt)
	compression = maxf(next,clampf(1.0-clearance/profile.initial_height,0,profile.max_compression))
	elastic_deformation = maxf(0,compression-permanent_damage)
	resistance = 0

func height() -> float:
	return profile.initial_height*(1.0-compression)
