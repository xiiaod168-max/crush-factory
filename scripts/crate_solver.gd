extends "res://scripts/crush_solver.gd"
const THRESHOLDS = [0.13, 0.4]
func _init() -> void:
	profile.initial_height = 1.5
	profile.max_compression = 0.8
func load_at(c: float) -> float:
	if c<0.13: return 62+56*smoothstep(0,0.13,c)
	if c<0.40: return 30+92*smoothstep(0.22,0.40,c)
	return 34+76*smoothstep(0.54,0.80,c)
func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	var before: float = compression
	var result: Dictionary = super.step(displacement,contacting,pressure,depth)
	result.event = false
	for threshold in THRESHOLDS:
		if before<threshold and compression>=threshold: result.event = true
	return result
