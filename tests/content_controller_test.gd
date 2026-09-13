extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.progress.level = 4
	# Thousands of physics steps run in one frame here; audio is tested in real-time EXE cycles.
	game.audio.muted = true
	game.audio.shutdown()
	var p = game.press
	p.set_physics_process(false)
	var events := {"count":0}
	p.buckled.connect(func(): events.count += 1)
	for id in ["bottle","crate","pc","microwave"]:
		game.phase = "SELECT"
		assert(game.choose(id))
		events.count = 0
		await physics_frame
		p.start()
		p._physics_process(1.0/60)
		assert(p.solver.compression==0)
		var paused: bool = false
		for i in range(3000):
			var previous: float = p.underside
			p._physics_process(1.0/60)
			assert(p.underside<=previous+0.00001)
			assert(p.underside>=p.TABLE+p.solver.height()-0.001)
			if p.solver.compression>0.25 and not paused:
				paused = true
				p.stop()
				var saved: float = p.solver.compression
				for j in range(30): p._physics_process(1.0/60)
				assert(p.solver.compression==saved)
				p.start()
			if p.state=="COMPACTED": break
		assert(p.state=="COMPACTED" and events.count==p.solver.THRESHOLDS.size())
		var peak: float = p.solver.compression
		p.retract()
		for i in range(600): p._physics_process(1.0/60)
		assert(p.state=="READY")
		assert(p.solver.compression>0.7*peak if id=="bottle" else p.solver.compression==peak)
		p.reset()
		assert(p.solver.compression==0)
		p.start()
		for i in range(140): p._physics_process(1.0/60)
		var partial: float = p.solver.compression
		p.retract()
		for i in range(600): p._physics_process(1.0/60)
		assert(p.state=="READY" and p.solver.compression<=partial+0.00001)
	print("PASS four new controllers: contact, pause/resume, bounded motion, exact events, unload, reset, early return")
	game.audio.shutdown()
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	quit()
