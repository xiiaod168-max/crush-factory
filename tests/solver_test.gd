extends SceneTree

func _initialize() -> void:
	var solver_script = load("res://scripts/crush_solver.gd")
	if solver_script == null:
		printerr("FAIL: CrushSolver is not implemented")
		quit(1)
		return
	var s = solver_script.new()
	var empty = s.step(0.02, false, 100.0, 0.0)
	assert(is_equal_approx(empty.travel, 0.02), "Free travel")
	assert(is_zero_approx(s.compression), "No deformation without contact")
	var weak = s.step(0.02, true, 0.1, 0.01)
	assert(is_zero_approx(weak.travel), "Insufficient pressure stalls")
	for i in range(2000):
		s.step(0.02, true, 100.0, 0.01)
	assert(s.compression > 0.85 and s.compression <= 0.9, "Compact but bounded")
	var retained: float = s.compression
	s.step(0.0, false, 100.0, 0.0)
	assert(is_equal_approx(s.compression, retained), "Permanent unloaded compression")
	print("PASS solver: free travel, contact, pressure stall, bounds, permanence")
	quit()
