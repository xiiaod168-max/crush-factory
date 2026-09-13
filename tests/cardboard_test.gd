extends SceneTree
func _initialize() -> void:
	var script = load("res://scripts/cardboard.gd")
	if script == null:
		printerr("FAIL: cardboard local deformation not implemented")
		quit(1)
		return
	var box = script.new()
	var rest: Vector3 = box.wall_point(0, 0.35, 0.5, 0.0)
	var bent: Vector3 = box.wall_point(0, 0.35, 0.5, 0.6)
	assert(absf(rest.z - bent.z) > 0.025, "Wall must fold laterally, not merely scale")
	for face in range(4):
		for c in [0.0,0.12,0.44,0.9]:
			for j in range(17):
				var edge: Vector3 = box.wall_point(face,1.0,j/16.0,c)
				var next_edge: Vector3 = box.wall_point((face+1)%4,0.0,j/16.0,c)
				assert(edge.distance_to(next_edge)<0.0001,"Adjacent folded walls must remain connected")
		for v in range(21):
			var p: Vector3 = box.wall_point(face, 0.4, v / 20.0, 0.9)
			assert(p.y >= -0.001 and p.y <= 0.146, "No plate/table penetration")
			assert(p.is_finite(), "Finite geometry")
	box.free()
	print("PASS cardboard: local folding, shared edges, envelope and finite coordinates")
	quit()
