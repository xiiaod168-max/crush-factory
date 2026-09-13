extends Node
## Capture includes the complete slow rebound, never just the plate returning.
var game: Node3D
var age: float = 0
var stage: int = 0
var hold: float = 0
var cycle: int = 0
var events: int = 0
var benchmark: bool = false
var directory: String
var side: bool = false
var samples: Array[float] = []
var failures: Array[String] = []
var last_us: int = 0
var middle_shot: bool = false
var rebound_shot: bool = false
var return_age: float = 0
var peak: float = 0
var recoveries: Array[Dictionary] = []

func _ready() -> void:
	benchmark = "--benchmark" in OS.get_cmdline_user_args()
	side = "--side" in OS.get_cmdline_user_args()
	directory = OS.get_environment("CRUSH_RECORD_DIR")
	if directory.is_empty(): directory = "user://records"
	DirAccess.make_dir_recursive_absolute(directory)
	game.angle = 1.0 if side else 0.0
	game.orbit_distance = 5.6
	game.camera_height = 2.5
	game.focus = Vector3(0,1.72,0)
	game.update_camera()
	game.press.buckled.connect(func(): events += 1)

func shot(label: String) -> void:
	if benchmark: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(("side-" if side else "front-")+label+".png"))

func _process(dt: float) -> void:
	age += dt
	var now: int = Time.get_ticks_usec()
	if benchmark and age>2 and last_us>0: samples.append((now-last_us)/1000.0)
	last_us = now
	var p = game.press
	var s = p.solver
	if p.underside<p.TABLE+s.height()-0.002 and failures.is_empty(): failures.append("Plate crossed elastic envelope")
	match stage:
		0:
			if age>1.5:
				shot("before")
				stage = 1
		1:
			if age>3:
				p.start()
				stage = 2
		2:
			if s.compression>0.33 and not middle_shot:
				middle_shot = true
				shot("moderate")
			if p.state=="COMPACTED":
				peak = s.compression
				shot("maximum")
				hold = 0
				stage = 3
		3:
			hold += dt
			if hold>1.2:
				p.retract()
				shot("return-start")
				return_age = age
				stage = 4
		4:
			if age-return_age>1.2 and not rebound_shot:
				rebound_shot = true
				shot("rebounding")
			if p.state=="READY" and s.elastic_deformation<0.003:
				if s.compression<0.18 or s.compression>peak*0.4: failures.append("Invalid residual damage or missing rebound")
				if age-return_age<2: failures.append("Rebound was instantaneous")
				recoveries.append({"peak":peak,"residual":s.compression,"damage":s.permanent_damage,"elastic":s.elastic_deformation,"rebound_seconds":age-return_age})
				shot("after")
				hold = 0
				stage = 5
		5:
			hold += dt
			if hold>(0.3 if benchmark else 3.0):
				cycle += 1
				print("CYCLE ",cycle," rebound complete; ",recoveries.back()," collider_updates=",p.target.collider_updates)
				if benchmark and cycle<10:
					p.reset()
					p.start()
					middle_shot = false
					rebound_shot = false
					stage = 2
				else: finish()
	if age>360:
		failures.append("Cycle timeout")
		finish()

func finish() -> void:
	set_process(false)
	if events!=cycle: failures.append("Expected one damage event per tire")
	if benchmark:
		samples.sort()
		var sum: float = 0
		for v in samples: sum += v
		var result: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"timing":"Time.get_ticks_usec; 2s warmup; no capture","cycles":cycle,"damage_events":events,"recoveries":recoveries,"failures":failures,"average_fps":1000.0*samples.size()/sum,"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back(),"frames":samples.size(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":"1280x720"}
		FileAccess.open(directory.path_join("benchmark-gl_compatibility.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
		print(JSON.stringify(result))
	game.audio.shutdown()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
