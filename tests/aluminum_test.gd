extends SceneTree

func _initialize() -> void:
	var metal_script = load("res://scripts/aluminum_solver.gd")
	var mesh_script = load("res://scripts/aluminum_can.gd")
	assert(metal_script != null and mesh_script != null, "Aluminum implementation must exist")
	var solver = metal_script.new()
	var can = mesh_script.new()
	var paper = load("res://scripts/crush_solver.gd").new()
	assert(solver.load_at(0.04)>paper.load_at(0.04)+20.0,"Metal initially harder than paper")
	assert(solver.step(0.01,false,100,0).event == false and solver.compression==0,"No contact no plasticity")
	solver.step(0.01,true,20,0)
	assert(solver.compression==0,"Insufficient pressure stalls metal")
	var events: int = 0
	for i in range(12000):
		var previous: float = solver.compression
		var result: Dictionary = solver.step(0.004,true,100,0)
		assert(solver.compression>=previous and result.travel<=0.00401)
		if result.event: events += 1
	assert(events==3 and solver.compression>=0.899,"Three plastic instabilities and full compaction")
	var permanent: float = solver.compression
	solver.step(0.01,false,100,0)
	assert(solver.compression==permanent,"Unloading preserves plastic strain")
	for threshold in [0.12,0.40,0.67]:
		assert(solver.load_at(threshold-0.001)-solver.load_at(threshold+0.001)>35,"Abrupt load release")
	for c in [0.0,0.04,0.12,0.20,0.40,0.53,0.67,0.78,0.90]:
		for j in range(41):
			for i in range(65):
				var p: Vector3 = can.wall_point(i*TAU/64.0,j/40.0,c)
				assert(p.is_finite() and p.y>=-0.0001 and p.y<=1.45*(1.0-c)+0.0001,"Finite bounded metal geometry")
				assert(absf(p.x)<1.26 and absf(p.z)<1.0,"Metal remains within press footprint")
				assert(p.distance_to(can.wall_point(i*TAU/64.0,j/40.0,minf(c+0.001,0.9)))<0.035,"Continuous geometry")
				if j<40:
					assert(can.wall_point(i*TAU/64.0,(j+1)/40.0,c).y>p.y,"Folded rings retain positive layer thickness")
			assert(can.wall_point(0,j/40.0,c).distance_to(can.wall_point(TAU,j/40.0,c))<0.0001,"Cylinder seam continuous")
	var dent: Vector3 = can.wall_point(1.15,0.72,0.06)
	assert(Vector2(dent.x,dent.z).length()<0.46,"Local dent before main failure")
	var front: Vector3 = can.wall_point(PI/2,0.68,0.25)
	var back: Vector3 = can.wall_point(PI*1.5,0.68,0.25)
	assert(absf(front.z+back.z)>0.025,"Asymmetric ring buckle")
	print("PASS aluminum: pressure, three events, plasticity, local dent, asymmetry, seam, envelope, continuity")
	can.free()
	quit()
