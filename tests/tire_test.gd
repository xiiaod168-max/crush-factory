extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tire = load("res://scripts/tire.gd").new()
	for c in [0.0,0.21,0.33,0.50,0.66]:
		for d in [0.0,0.21]:
			for i in range(73):
				for j in range(17):
					var t: float = i*TAU/72.0
					var f: float = j*TAU/16.0
					var p: Vector3 = tire.point(t,f,c,d)
					assert(p.is_finite() and p.y>=0 and p.y<=1.45*(1-c)+0.0001,"Tire vertical envelope")
					assert(absf(p.x)<1.26 and absf(p.z)<1.0,"Tire stays under plate")
					assert(p.distance_to(tire.point(t,f,minf(c+0.001,0.66),d))<0.01,"Smooth deformation")
			assert(tire.point(0,1,c,d).distance_to(tire.point(TAU,1,c,d))<0.0001,"Annulus seam")
	var left: Vector3 = tire.point(PI,PI,0.66,0.21)
	var right: Vector3 = tire.point(0,PI,0.66,0.21)
	var top: Vector3 = tire.point(PI/2,PI,0.66,0.21)
	var bottom: Vector3 = tire.point(PI*1.5,PI,0.66,0.21)
	assert(top.y-bottom.y>0.1 and (right.x-left.x)/(top.y-bottom.y)>3,"Hole is open and very elliptical")
	assert(tire.point(0,0,0.66,0).x>tire.point(0,0,0,0).x+0.3,"Strong outward bulge")
	tire.free()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var p = game.press
	p.set_physics_process(false)
	p.start()
	p._physics_process(1.0/60)
	assert(p.solver.compression==0,"No early deformation")
	for i in range(3000):
		p._physics_process(1.0/60)
		assert(p.underside>=1.0+p.solver.height()-0.0001)
		if p.state=="COMPACTED": break
	assert(p.state=="COMPACTED","Tire stops at material compression limit")
	var peak: float = p.solver.compression
	p.stop()
	for i in range(20): p._physics_process(1.0/60)
	assert(p.solver.compression==peak,"Pause holds strain")
	p.retract()
	for i in range(600):
		var old: float = p.solver.compression
		p._physics_process(1.0/60)
		assert(p.underside>=1.0+p.solver.height()-0.0001,"Rebound cannot pass through plate")
		assert(p.solver.compression<=old and old-p.solver.compression<0.005,"No rebound explosion")
	assert(p.state=="READY" and p.solver.compression>0.19 and p.solver.compression<0.22,"Settles with visible damage")
	p.reset()
	assert(p.solver.permanent_damage==0 and p.solver.compression==0,"New tire clears both histories")
	p.start()
	for i in range(240): p._physics_process(1.0/60)
	p.retract()
	for i in range(650): p._physics_process(1.0/60)
	assert(p.solver.compression<0.001,"Early return restores undamaged tire")
	print("PASS tire: geometry, hole, bulge, contact, pause, full recovery path, residual damage, reset, early return")
	game.audio.shutdown()
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
