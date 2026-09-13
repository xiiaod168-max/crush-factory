extends Node
## Reproducible showcase using normal game controls; capture timing excluded from benchmarks.
var game: Node3D
var age: float = 0.0
var stage: int = 0
var hold: float = 0.0
var cycle: int = 0
var benchmark: bool = false
var directory: String
var folded_shot: bool = false
var buckling_shot: bool = false
var buckle_count: int = 0
var samples: Array[float] = []
var memory_samples: Array[int] = []
var side: bool = false
var capture_busy: bool = false
var failures: Array[String] = []
var max_cycles: int = 10
var last_frame_us: int = 0
var dent_shot: bool = false
var compacted_shot: bool = false

func _ready() -> void:
	benchmark = "--benchmark" in OS.get_cmdline_user_args() or "--probe" in OS.get_cmdline_user_args()
	max_cycles = 1 if "--probe" in OS.get_cmdline_user_args() else 10
	side = "--side" in OS.get_cmdline_user_args()
	game.angle = 1.0 if side else 0.0
	game.orbit_distance = 6.5
	game.camera_height = 2.9
	game.focus = Vector3(0,1.8,0)
	if game.aluminum:
		game.orbit_distance = 5.4
		game.camera_height = 2.7
		game.focus = Vector3(0,1.75,0)
	game.update_camera()
	game.press.buckled.connect(func(): buckle_count += 1)
	directory = OS.get_environment("CRUSH_RECORD_DIR")
	if directory.is_empty(): directory = "user://records"
	DirAccess.make_dir_recursive_absolute(directory)

func screenshot(label: String) -> void:
	if benchmark or capture_busy: return
	capture_busy = true
	await RenderingServer.frame_post_draw
	var path: String = directory.path_join(("side-" if side else "front-")+label+".png")
	get_viewport().get_texture().get_image().save_png(path)
	capture_busy = false

func _process(dt: float) -> void:
	age += dt
	var now_us: int = Time.get_ticks_usec()
	if benchmark and age > 2.0 and last_frame_us > 0:
		samples.append(float(now_us-last_frame_us)/1000.0)
	last_frame_us = now_us
	var p = game.press
	if p.underside < p.TABLE + p.solver.height() - 0.002:
		if failures.is_empty(): failures.append("Plate crossed solver envelope")
	match stage:
		0:
			if age > 1.5:
				screenshot("before")
				stage = 1
		1:
			if age > 3.0:
				p.start()
				stage = 2
		2:
			if game.aluminum and p.solver.compression>0.05 and not dent_shot:
				dent_shot = true
				screenshot("dent")
			if p.solver.compression > 0.225 and not buckling_shot:
				buckling_shot = true
				screenshot("buckling")
			if p.solver.compression > 0.55 and not folded_shot:
				folded_shot = true
				screenshot("folding")
			if p.state == "COMPACTED":
				if game.aluminum and not compacted_shot:
					compacted_shot = true
					screenshot("compacted")
				stage = 3
				hold = 0
		3:
			hold += dt
			if hold > 1.0:
				p.retract()
				stage = 4
		4:
			if p.state == "READY":
				if p.solver.compression < 0.899: failures.append("Damage lost on return")
				for item in p.target.flecks:
					if item.life > 0: failures.append("Fleck outlived its bounded lifetime")
				screenshot("after")
				stage = 5
				hold = 0
		5:
			hold += dt
			if hold > (0.25 if benchmark else 3.0):
				cycle += 1
				memory_samples.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
				print("CYCLE ",cycle," completed; memory=",memory_samples.back()," collider_updates=",p.target.collider_updates)
				if benchmark and cycle < max_cycles:
					p.reset()
					p.start()
					stage = 2
				else:
					finish()
	if age > 330:
		failures.append("Showcase timeout")
		finish()

func finish() -> void:
	set_process(false)
	if benchmark:
		samples.sort()
		var sum: float = 0.0
		for value in samples: sum += value
		if buckle_count != cycle*(3 if game.aluminum else 1): failures.append("Unexpected number of material buckles")
		var result: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"timing":"Time.get_ticks_usec frame intervals; 2s warmup; no capture","cycles":cycle,"buckle_events":buckle_count,"frames":samples.size(),"average_fps":1000.0/(sum/maxi(1,samples.size())),"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back(),"memory_bytes_per_cycle":memory_samples,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":"1280x720"}
		var file = FileAccess.open(directory.path_join("benchmark-"+RenderingServer.get_current_rendering_method()+".json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t"))
		print(JSON.stringify(result))
	game.audio.shutdown()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
