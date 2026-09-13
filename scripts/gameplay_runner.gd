extends Node
## Drives real UI actions. Restart verification is a separate executable invocation.
var game: Node3D
var verify: bool = false
var resume: bool = false
var age: float = 0
var last_us: int = 0
var samples: Array[float] = []
var failures: Array[String] = []
var results: Array[Dictionary] = []
var directory: String
var finished: bool = false

func _ready() -> void:
	verify = "--gameplay-verify" in OS.get_cmdline_user_args()
	resume = "--gameplay-resume" in OS.get_cmdline_user_args()
	directory = OS.get_environment("CRUSH_RECORD_DIR")
	if directory.is_empty(): directory = "user://records"
	DirAccess.make_dir_recursive_absolute(directory)
	call_deferred("run")

func _process(dt: float) -> void:
	age += dt
	var now: int = Time.get_ticks_usec()
	if verify and age>2 and last_us>0: samples.append((now-last_us)/1000.0)
	last_us = now
	if age>650 and not finished:
		failures.append("Gameplay timeout")
		finish()

func delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func click(b: Button) -> void:
	check(not b.disabled,"Attempted disabled UI action: "+b.text)
	b.grab_focus()
	await delay(0.05 if verify else 0.45)
	if not b.disabled: b.pressed.emit()

func shot(name: String) -> void:
	if verify: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))

func run() -> void:
	await delay(0.5 if verify else 2)
	if resume:
		var previous = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("gameplay-session.json")))
		check(game.progress.restored,"Save was not loaded")
		check(game.progress.money==int(previous.money) and game.progress.level==2,"Wallet or upgrade lost at restart")
		check(game.progress.unlocked("tire") and game.phase=="SELECT" and game.object_id.is_empty(),"Restart did not restore unlock and Ready scene")
		check(not game.collect(),"Restart duplicated a reward")
		shot("restart-restored")
		await delay(2)
		await click(game.action_buttons.upgrades)
		await delay(2)
		shot("restart-upgrade")
		finish()
		return
	check(game.progress.money==0 and game.progress.level==1,"New game verification requires an isolated fresh save")
	check(not game.choose("tire"),"Tire should start locked")
	shot("new-game")
	check(not game.hud.debug.visible,"Debug HUD should default off")
	var debug_key := InputEventKey.new()
	debug_key.keycode = KEY_F3
	debug_key.pressed = true
	game._unhandled_input(debug_key)
	check(game.hud.debug.visible,"F3 did not open debug HUD")
	game._unhandled_input(debug_key)
	var order: Array[String] = ["cardboard","aluminum"]
	if verify:
		for i in range(4): order.append_array(["cardboard","aluminum","tire"])
		order.append("tire")
	else: order.append("tire")
	for index in range(order.size()):
		if index==2:
			check(game.progress.money>=40,"First box and can cannot fund first upgrade")
			await click(game.action_buttons.upgrades)
			await delay(0.1 if verify else 2)
			shot("upgrade-before")
			var before: int = game.progress.money
			await click(game.purchase_button)
			check(game.progress.level==2 and game.press.pressure==100 and game.progress.money==before-40,"Upgrade did not change actual pressure or cost")
			check(not game.buy_upgrade(),"Upgrade purchased twice")
			check(game.progress.unlocked("tire"),"Tire failed to unlock")
			await delay(0.1 if verify else 3)
			shot("press-upgraded")
			check(game.hud.moment=="UPGRADE","Upgrade moment missing")
			await click(game.hud.moment_button)
			await delay(0.1 if verify else 2.5)
			shot("tire-unlocked")
			check(game.hud.moment=="UNLOCK","Unlock moment missing")
			if verify: game.hud.dismiss_unlock()
			else: await click(game.hud.moment_button)
		var id: String = order[index]
		if game.phase!="LOADED": await click(game.item_buttons[id])
		check(game.phase=="LOADED" and game.object_id==id,"Selection failed")
		check(not game.choose("cardboard"),"Unsettled object could be replaced")
		await delay(0.1 if verify else 1.2)
		await click(game.action_buttons.press)
		var started: float = age
		var captured_peak: bool = false
		while game.press.state!="COMPACTED" and not game.limit_reached and age-started<48:
			if game.peak>0.3 and not captured_peak:
				captured_peak = true
				shot(id+"-crushing")
			check(game.press.underside>=game.press.TABLE+game.press.solver.height()-0.002,"Plate envelope failure")
			await get_tree().process_frame
		check(age-started<48,"Material did not stop or reach a pressure limit")
		shot(id+"-peak")
		await delay(0.1 if verify else 1.2)
		await click(game.hud.primary)
		check(not game.collect() and not game.choose("cardboard"),"Could collect or replace while unloading")
		while game.phase!="RESULT": await get_tree().process_frame
		var bank: int = game.progress.money
		var reward: int = game.settlement.total
		var row: Dictionary = {"object":id,"level":game.progress.level,"pressure":game.press.pressure,"peak":game.peak,"final":game.press.solver.compression,"reward":reward,"compression_seconds":age-started}
		if id=="tire": check(row.final<row.peak*0.4 and row.final>0.18,"Tire rebound regressed")
		shot(id+"-result")
		await delay(0.1 if verify else 3)
		await click(game.action_buttons.collect)
		check(game.progress.money==bank+reward and not game.collect(),"Reward lost or collectible twice")
		game.toggle_press()
		check(game.phase=="COLLECTED","Collected object could be replayed")
		var disk = preload("res://scripts/progress.gd").new()
		check(disk.load_save() and disk.money==game.progress.money,"Collected money not durable")
		await delay(0.05 if verify else 0.28)
		shot(id+"-reward")
		results.append(row)
		print("GAMEPLAY CYCLE ",results.size()," ",row," money=",game.progress.money)
		await delay(0.1 if verify else 1.5)
	if verify:
		var low: float = results[1].peak
		var high: float = results[3].peak
		check(high>low+0.4,"Upgrade did not improve aluminum compression")
	shot("session-complete")
	await delay(0.2 if verify else 2)
	finish()

func finish() -> void:
	if finished: return
	finished = true
	set_process(false)
	var data: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"mode":"resume" if resume else ("verify" if verify else "session"),"pid":OS.get_process_id(),"money":game.progress.money,"level":game.progress.level,"tire_unlocked":game.progress.unlocked("tire"),"phase":game.phase,"object":game.object_id,"settings":game.progress.snapshot().settings,"cycles":results,"failures":failures}
	if verify and not samples.is_empty():
		samples.sort()
		var sum: float = 0
		for v in samples: sum += v
		data.performance = {"average_fps":1000.0*samples.size()/sum,"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back(),"frames":samples.size(),"timing":"Time.get_ticks_usec; 2s warmup; no capture","renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":"1280x720"}
	var name: String = "gameplay-resume.json" if resume else ("gameplay-verify.json" if verify else "gameplay-session.json")
	FileAccess.open(directory.path_join(name),FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	print(JSON.stringify(data))
	game.quit_game()
