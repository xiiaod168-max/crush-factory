extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func measure(fast: bool) -> Dictionary:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var p = game.press
	p.set_physics_process(false)
	if fast:
		p.set("fast_approach",true)
		p.set("return_speed",1.65)
	p.start()
	var approach: int = 0
	while not p.captured and approach<600:
		p._physics_process(1.0/60)
		approach += 1
	var trajectory: Array[float] = []
	for i in range(2400):
		p._physics_process(1.0/60)
		trajectory.append(p.solver.compression)
		assert(p.underside>=p.TABLE+p.solver.height()-0.002)
		if p.state=="COMPACTED": break
	p.retract()
	var returning: int = 0
	while p.state!="READY" and returning<600:
		p._physics_process(1.0/60)
		returning += 1
	game.queue_free()
	await process_frame
	return {"approach":approach,"return":returning,"trajectory":trajectory}
func run() -> void:
	var baseline: Dictionary = await measure(false)
	var faster: Dictionary = await measure(true)
	var ok: bool = faster.approach<baseline.approach*0.7 and faster.return<baseline.return*0.5
	# Identical contact integration: acceleration must never carry into deformation.
	var difference: float = 0
	for i in range(mini(faster.trajectory.size(),baseline.trajectory.size())):
		difference = maxf(difference,absf(faster.trajectory[i]-baseline.trajectory[i]))
	ok = ok and faster.trajectory.size()==baseline.trajectory.size() and difference<0.00000001
	print("CADENCE baseline=",baseline.approach,"/",baseline.return," fast=",faster.approach,"/",faster.return," contact_max_difference=",difference)
	await create_timer(0.5).timeout
	print("PASS cadence" if ok else "FAIL cadence")
	quit(0 if ok else 1)
