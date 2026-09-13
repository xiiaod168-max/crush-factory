extends "res://scripts/crush_solver.gd"
## Three shell instabilities; plastic strain never unloads.
const THRESHOLDS = [0.12, 0.40, 0.67]

func load_at(c: float) -> float:
	if c < 0.12: return 55.0+29.0*smoothstep(0.0,0.12,c)
	if c < 0.40: return 16.0+64.0*smoothstep(0.22,0.40,c)
	if c < 0.67: return 20.0+62.0*smoothstep(0.49,0.67,c)
	return 22.0+62.0*smoothstep(0.76,0.90,c)

func step(displacement: float, contacting: bool, pressure: float, depth: float) -> Dictionary:
	var previous: float = compression
	var result: Dictionary = super.step(displacement,contacting,pressure,depth)
	result.event = false
	for threshold in THRESHOLDS:
		if previous < threshold and compression >= threshold: result.event = true
	return result
