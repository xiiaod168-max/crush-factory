extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var p = game.press
	p.set_physics_process(false)
	p.start()
	p._physics_process(1.0 / 60)
	assert(p.solver.compression == 0.0, "Must not crush before contact")
	var y: float = p.underside
	p.stop()
	for i in range(60): p._physics_process(1.0 / 60)
	assert(p.underside == y, "Stop holds position")
	p.pressure = 0.1
	p.start()
	for i in range(400): p._physics_process(1.0 / 60)
	assert(p.solver.compression == 0.0, "Weak machine must stall")
	p.pressure = 100
	p.speed = 80.0
	var before_fast: float = p.underside
	p._physics_process(1.0 / 60)
	assert(before_fast - p.underside <= 0.0201, "Overspeed is displacement limited")
	assert(p.underside >= 1.0 + p.solver.height() - 0.001, "Fast stroke cannot penetrate solver envelope")
	var partial: float = p.solver.compression
	p.stop()
	for i in range(20): p._physics_process(1.0 / 60)
	assert(p.solver.compression == partial,"Pause retains partial folds")
	p.retract()
	for i in range(25): p._physics_process(1.0 / 60)
	assert(p.solver.compression == partial,"Early return retains partial folds")
	p.start()
	p.speed = 0.34
	for i in range(1500): p._physics_process(1.0 / 60)
	assert(p.state == "COMPACTED", "Complete compression")
	var c: float = p.solver.compression
	p.retract()
	for i in range(400): p._physics_process(1.0 / 60)
	assert(is_equal_approx(p.underside, p.HOME), "Returns home")
	assert(p.solver.compression == c, "Return preserves damage")
	p.reset()
	assert(p.solver.compression == 0, "New object only at home")
	var counter: Dictionary = {"events":0}
	p.buckled.connect(func(): counter.events += 1)
	p.start()
	var resisting_speed: float = 0.0
	var burst_speed: float = 0.0
	var held_frames: int = 0
	for i in range(2000):
		var old_c: float = p.solver.compression
		var old_y: float = p.underside
		p._physics_process(1.0/60.0)
		var travel: float = old_y-p.underside
		if old_c>0.14 and old_c<0.155: resisting_speed = maxf(resisting_speed,travel*60.0)
		if old_c>0.165 and old_c<0.24: burst_speed = maxf(burst_speed,travel*60.0)
		if p.structural_hold>0 and is_zero_approx(travel): held_frames += 1
	assert(counter.events==1,"Only one synchronized buckle event per cycle")
	assert(held_frames>=3 and held_frames<=8,"Very short bounded hit stop")
	assert(resisting_speed>0 and burst_speed>resisting_speed*3.0,"Visible slowdown then fast local collapse")
	print("PASS feel: resisting=",resisting_speed," burst=",burst_speed," held_frames=",held_frames)
	print("PASS controller: no-contact, stop, weak pressure, high-speed, complete, return, reset")
	game.audio.shutdown()
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	quit()
