extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var p = game.press
	p.set_physics_process(false)
	var events: Dictionary = {"count":0}
	p.buckled.connect(func(): events.count += 1)
	p.start()
	p._physics_process(1.0/60)
	assert(p.solver.compression==0,"No compression before contact")
	for cycle in range(2):
		var slow: float = 100.0
		var fast: float = 0.0
		for step in range(3600):
			var previous: float = p.underside
			var c: float = p.solver.compression
			p._physics_process(1.0/60)
			var travel: float = previous-p.underside
			assert(travel>=-0.00001 and travel<=0.02001,"No reverse jump or overspeed")
			assert(p.underside>=p.TABLE+p.solver.height()-0.0001,"Plate envelope")
			if c>0.10 and c<0.115 and travel>0: slow = minf(slow,travel*60)
			if c>0.13 and c<0.22: fast = maxf(fast,travel*60)
			if step==600:
				p.stop()
				var saved: float = p.solver.compression
				for i in range(20): p._physics_process(1.0/60)
				assert(saved==p.solver.compression,"Pause retains metal")
				p.retract()
				for i in range(30): p._physics_process(1.0/60)
				assert(saved==p.solver.compression,"Early return retains metal")
				p.start()
			if p.state=="COMPACTED": break
		assert(p.state=="COMPACTED" and events.count==3*(cycle+1),"Three events per can")
		assert(fast>slow*4.0,"Metal releases sharply after hard resistance")
		p.retract()
		for i in range(400): p._physics_process(1.0/60)
		assert(p.state=="READY" and p.solver.compression>=0.899,"Return preserves can")
		p.reset()
		assert(p.solver.load_at(0)>50 and p.solver.compression==0,"Reset retains aluminum solver")
		p.start()
	print("PASS aluminum controller: contact, pause, early return, burst, envelope, 3 events, reset repeat")
	game.audio.shutdown()
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	quit()
