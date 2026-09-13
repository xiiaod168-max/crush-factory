extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/rubber_solver.gd")
	assert(script!=null,"Independent rubber solver exists")
	var solver = script.new()
	assert(solver.load_at(0.5)>solver.load_at(0.2)+20,"Progressively harder rubber")
	solver.step(0.02,false,100,0)
	assert(solver.compression==0,"No contact no deformation")
	while solver.compression<0.30: solver.step(0.006,true,65,0)
	assert(solver.permanent_damage==0,"Moderate pressure stays elastic")
	for i in range(600): solver.recover(1.0/60,2.15)
	assert(solver.compression<0.001,"Undamaged tire recovers")
	var events: int = 0
	for i in range(4000):
		var result: Dictionary = solver.step(0.006,true,100,0)
		if result.event: events += 1
	assert(events==1 and solver.compression>0.659,"One damage event at high strain")
	assert(solver.elastic_deformation>0.4 and solver.permanent_damage>0.19,"Separate elasticity and damage")
	var peak: float = solver.compression
	for i in range(600):
		var old: float = solver.compression
		solver.recover(1.0/60,2.15)
		assert(solver.compression<=old and old-solver.compression<0.005,"Bounded monotone rebound")
	assert(solver.compression>0.19 and solver.compression<peak*0.4,"Most strain recovers but visible damage stays")
	var saved: float = solver.permanent_damage
	for i in range(100): solver.step(0.005,true,100,0)
	assert(solver.permanent_damage>=saved,"Repress cannot heal damage")
	var gap: float = solver.height()+0.005
	solver.recover(0.05,gap)
	assert(solver.height()<=gap+0.00001,"Rebound respects plate clearance")
	print("PASS rubber: nonlinear load, low-pressure recovery, high-pressure damage, bounded rebound, no healing, clearance")
	quit()
