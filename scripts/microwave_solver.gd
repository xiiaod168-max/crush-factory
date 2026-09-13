extends "res://scripts/crush_solver.gd"
const THRESHOLDS = [0.17, 0.44]
func _init() -> void:
	profile.initial_height = 1.22
	profile.max_compression = 0.76
func load_at(c: float) -> float:
	if c<0.17: return 78+83*smoothstep(0,0.17,c)
	if c<0.44: return 56+110*smoothstep(0.27,0.44,c)
	return 66+95*smoothstep(0.53,0.76,c)
func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	var before: float = compression
	var result: Dictionary = super.step(displacement,contacting,pressure,depth)
	result.event = false
	for threshold in THRESHOLDS:
		if before<threshold and compression>=threshold: result.event = true
	return result
