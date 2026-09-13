extends SceneTree
func _initialize() -> void:
	var p = load("res://scripts/progress.gd").new()
	assert(p.ITEMS.size()==7)
	assert(p.unlocked("bottle") and not p.unlocked("crate"))
	for level in range(1,5):
		p.level = level
		assert(p.max_pressure()==[80,100,140,180][level-1])
	assert(p.unlocked("microwave"))
	for id in ["bottle","crate","pc","microwave"]:
		var s = load("res://scripts/"+id+"_solver.gd").new()
		s.step(0.01,false,180,0)
		assert(s.compression==0)
		var events: int = 0
		for i in range(5000):
			var before: float = s.compression
			var result: Dictionary = s.step(0.004,true,180,0)
			assert(s.compression>=before and result.travel<=0.0041)
			if result.event: events += 1
		assert(s.compression>s.profile.max_compression-0.002)
		assert(events>=1 and events<=4)
		if id=="bottle":
			var peak: float = s.compression
			for i in range(600): s.recover(1.0/60,3)
			assert(s.compression<peak-0.025 and s.compression>peak*0.7)
		else:
			var weak = load("res://scripts/"+id+"_solver.gd").new()
			for i in range(5000): weak.step(0.004,true,140 if id=="microwave" else 100,0)
			assert(weak.compression<s.compression-0.2)
	print("PASS content catalog, bounded solver travel, staged events, bottle recovery, pressure capacity")
	quit()
