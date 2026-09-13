extends "res://scripts/crush_solver.gd"
const THRESHOLDS = [0.1, 0.43]
func _init() -> void:
	profile.initial_height = 1.25
	profile.max_compression = 0.82
func load_at(c: float) -> float:
	if c<0.10: return 12+38*smoothstep(0,0.10,c)
	if c<0.43: return 7+30*smoothstep(0.25,0.43,c)
	return 10+46*smoothstep(0.55,0.82,c)
func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	var before: float = compression
	var result: Dictionary = super.step(displacement,contacting,pressure,depth)
	result.event = false
	for threshold in THRESHOLDS:
		if before<threshold and compression>=threshold: result.event = true
	permanent_damage = maxf(permanent_damage,compression-minf(compression*0.25,0.065))
	elastic_deformation = compression-permanent_damage
	return result
var permanent_damage: float = 0
var elastic_deformation: float = 0
func recover(dt: float, clearance: float) -> void:
	compression = maxf(permanent_damage+elastic_deformation*exp(-dt*2.5),clampf(1-clearance/profile.initial_height,0,profile.max_compression))
	elastic_deformation = maxf(0,compression-permanent_damage)
	resistance = 0
