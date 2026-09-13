extends "res://scripts/crush_solver.gd"
const THRESHOLDS = [0.19, 0.48, 0.67]
func _init() -> void:
	profile.initial_height = 1.7
	profile.max_compression = 0.82
func load_at(c: float) -> float:
	if c<0.19: return 48+68*smoothstep(0,0.19,c)
	if c<0.48: return 42+85*smoothstep(0.28,0.48,c)
	if c<0.67: return 46+82*smoothstep(0.55,0.67,c)
	return 42+80*smoothstep(0.72,0.82,c)
func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	var before: float = compression
	var result: Dictionary = super.step(displacement,contacting,pressure,depth)
	result.event = false
	for threshold in THRESHOLDS:
		if before<threshold and compression>=threshold: result.event = true
	return result
