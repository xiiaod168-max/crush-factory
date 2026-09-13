extends SceneTree
var failures: int = 0

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ",message)

func _initialize() -> void:
	var box = load("res://scripts/cardboard.gd").new()
	var front: Vector3 = box.wall_point(0,0.32,0.6,0.23)
	var right: Vector3 = box.wall_point(1,0.5,0.5,0.23)
	expect(front.z < 0.53,"Front wall must buckle inward first")
	expect(right.x > 0.98,"Right wall must initially bulge outward")
	expect(absf(box.wall_point(0,0.4,0.45,0.23).y-box.wall_point(1,0.5,0.45,0.23).y)>0.06,"Local vertical collapse must differ between walls")
	expect(box.has_method("top_point"),"Lid needs local deformation")
	for face in range(4):
		for i in range(11):
			for j in range(21):
				for c in [0.0,0.12,0.16,0.23,0.44,0.70,0.90]:
					var p: Vector3 = box.wall_point(face,i/10.0,j/20.0,c)
					expect(p.is_finite() and p.y>=0 and p.y<=1.45*(1-c)+0.001,"Wall envelope remains valid at every phase")
					expect(absf(p.x)<=1.325 and absf(p.z)<=1.05,"Folds stay inside plate footprint")
					if c<0.90:
						var next: Vector3 = box.wall_point(face,i/10.0,j/20.0,c+0.001)
						expect(p.distance_to(next)<0.03,"No discontinuous model swap or geometry jump")
	if box.has_method("top_point"):
		for c in [0.23,0.9]:
			var low: float = 2.0
			var high: float = -1.0
			for i in range(9):
				for j in range(9):
					var p: Vector3 = box.top_point(i/8.0,j/8.0,c)
					low = minf(low,p.y)
					high = maxf(high,p.y)
					expect(p.y <= 1.45*(1-c)+0.001 and p.y>=0,"Lid stays in plate envelope")
			expect(high-low>0.018,"Final lid cannot be a horizontal slab")
		var center_low: float = 2.0
		var center_high: float = -1.0
		for i in range(25):
			var height: float = box.top_point(i/24.0,0.5,0.9).y
			center_low = minf(center_low,height)
			center_high = maxf(center_high,height)
		expect(center_high-center_low>0.04,"Compact lid needs visible local relief, not only overall tilt")
	var solver = load("res://scripts/crush_solver.gd").new()
	var events: int = 0
	var event_load: float = 0.0
	var prior_load: float = 0.0
	for i in range(5000):
		var old_load: float = solver.resistance
		var result: Dictionary = solver.step(0.003,true,100,0.0)
		if result.event:
			events += 1
			prior_load = old_load
			event_load = solver.resistance
	expect(events==1,"Primary buckling fires exactly once per carton")
	expect(prior_load-event_load>25,"Buckling must produce an immediate load drop")
	box.free()
	print("Review02 tests: ",failures," failures")
	quit(0 if failures==0 else 1)
