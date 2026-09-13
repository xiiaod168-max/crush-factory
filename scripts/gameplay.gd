extends "res://scripts/main.gd"
## Playable loop layered over the accepted press. Material implementations are untouched.
var progress = preload("res://scripts/progress.gd").new()
var phase: String = "SELECT"
var object_id: String = ""
var peak: float = 0
var settlement: Dictionary = {}
var jobs_collected: int = 0
var idle_load_time: float = 0
var last_c: float = 0
var limit_reached: bool = false
var menu: String = "SELECT"
var hud: CanvasLayer
var panel: PanelContainer
var panel_content: VBoxContainer
var action_buttons: Dictionary = {}
var item_buttons: Dictionary = {}
var purchase_button: Button
var notice: String = ""
var notice_time: float = 0
var feedback: Node
var workshop: Node3D

func _init() -> void:
	aluminum = false
	tire = false

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is CanvasLayer: child.hide()
	press.stop()
	press.fast_approach = true
	press.return_speed = 1.65
	feedback = preload("res://scripts/slice_feedback.gd").new()
	add_child(feedback)
	workshop = preload("res://scripts/workshop.gd").new()
	workshop.game = self
	add_child(workshop)
	press.state = "READY"
	press.target.visible = false
	progress.load_save()
	audio.muted = progress.muted
	press.pressure = progress.max_pressure()
	angle = 0.28
	orbit_distance = 8.2
	camera_height = 3.4
	focus = Vector3(0.3,2.12,0)
	update_camera()
	build_ui()
	show_selection()
	if progress.restored: flash("PROGRESS RESTORED  /  Your money and upgrades are ready.",5)
	if not progress.error.is_empty(): notice = progress.error; notice_time = 99999
	if "--gameplay-demo" in OS.get_cmdline_user_args() or "--gameplay-verify" in OS.get_cmdline_user_args() or "--gameplay-resume" in OS.get_cmdline_user_args():
		var runner = preload("res://scripts/content_runner.gd").new()
		runner.game = self
		add_child(runner)

func safe_to_change() -> bool:
	return (hud==null or hud.moment.is_empty()) and phase in ["SELECT","COLLECTED"] and press.state=="READY" and absf(press.underside-press.HOME)<0.005

func choose(id: String) -> bool:
	if not safe_to_change() or not progress.unlocked(id): return false
	press.target.free()
	aluminum = id=="aluminum"
	tire = id=="tire"
	var script = preload("res://scripts/cardboard.gd")
	press.solver_script = preload("res://scripts/crush_solver.gd")
	if aluminum:
		script = preload("res://scripts/aluminum_can.gd")
		press.solver_script = preload("res://scripts/aluminum_solver.gd")
	if tire:
		script = preload("res://scripts/tire.gd")
		press.solver_script = preload("res://scripts/rubber_solver.gd")
	if id in ["bottle","crate","pc","microwave"]:
		script = load("res://scripts/"+id+".gd")
		press.solver_script = load("res://scripts/"+id+"_solver.gd")
	press.target = script.new()
	press.target.position.y = press.TABLE
	add_child(press.target)
	press.reset()
	press.pressure = progress.max_pressure()
	audio.metal = aluminum
	audio.rubber = tire
	audio.paper.stop()
	audio.paper.stream = preload("res://scripts/content_audio.gd").synth(id) if id in ["bottle","crate","pc","microwave"] else audio.synth(0.32,true)
	object_id = id
	peak = 0
	last_c = 0
	idle_load_time = 0
	limit_reached = false
	settlement = {}
	phase = "LOADED"
	menu = ""
	panel.hide()
	return true

func toggle_press() -> void:
	if phase not in ["LOADED","RUNNING"]: return
	phase = "RUNNING"
	if press.state=="PRESSING": press.stop()
	else: press.start(); idle_load_time = 0

func return_press() -> void:
	if phase not in ["LOADED","RUNNING"]: return
	phase = "UNLOADING"
	press.retract()

func collect() -> bool:
	if phase!="RESULT": return false
	var amount: int = settlement.total
	progress.money += amount
	if not progress.save():
		progress.money -= amount
		flash("SAVE FAILED / Reward not collected. Check the save location and retry.",10)
		return false
	phase = "COLLECTED"
	jobs_collected += 1
	flash("+ %d COINS  /  Saved. Choose another free object." % amount,4)
	show_selection()
	hud.reward(amount)
	return true

func buy_upgrade() -> bool:
	if not safe_to_change() or not progress.upgrade(): return false
	press.pressure = progress.max_pressure()
	hud.upgraded()
	return true

func new_object() -> void:
	if safe_to_change(): show_selection()

func toggle_sound() -> void:
	var previous: bool = progress.muted
	progress.muted = not previous
	if not progress.save():
		progress.muted = previous
		flash("Sound setting could not be saved.",5)
	audio.muted = progress.muted

func _process(dt: float) -> void:
	super._process(dt)
	if hud==null: return
	peak = maxf(peak,press.solver.compression) if phase in ["RUNNING","UNLOADING"] else peak
	if phase=="RUNNING" and press.state=="PRESSING" and press.captured:
		if absf(press.solver.compression-last_c)<0.000025: idle_load_time += dt
		else: idle_load_time = 0
		if idle_load_time>1.4:
			press.stop()
			limit_reached = true
	last_c = press.solver.compression
	if phase=="UNLOADING" and press.state=="READY":
		if not press.solver.has_method("recover") or press.solver.elastic_deformation<0.003:
			settlement = progress.reward(object_id,peak)
			settlement.final_height = press.solver.height()
			settlement.final_compression = press.solver.compression
			phase = "RESULT"
			show_result()
	notice_time = maxf(0,notice_time-dt)
	hud.refresh(dt)

func _input(event: InputEvent) -> void:
	# Reserve gameplay keys on both edges so focused buttons cannot also activate
	# on Space release. Enter remains the native button activation key.
	if event is InputEventKey and event.keycode in [KEY_SPACE,KEY_R,KEY_C,KEY_N,KEY_U,KEY_M,KEY_F3,KEY_ESCAPE,KEY_1,KEY_2]:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo: _unhandled_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F3: hud.debug.visible = not hud.debug.visible
			KEY_SPACE: toggle_press()
			KEY_R: return_press()
			KEY_N: new_object()
			KEY_C: collect()
			KEY_U:
				if safe_to_change(): show_upgrade()
			KEY_M: toggle_sound()
			KEY_ESCAPE: quit_game()
			KEY_1: angle = 0; update_camera()
			KEY_2: angle = 1; update_camera()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		angle -= event.relative.x*0.006
		camera_height = clampf(camera_height+event.relative.y*0.01,2,5.5)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: orbit_distance = maxf(4.5,orbit_distance-0.3)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: orbit_distance = minf(11,orbit_distance+0.3)

func flash(text: String, seconds: float) -> void:
	notice = text
	notice_time = seconds

func build_ui() -> void:
	hud = preload("res://scripts/slice_hud.gd").new()
	hud.game = self
	add_child(hud)
func show_selection() -> void:
	hud.show_selection()
func show_result() -> void:
	hud.show_result()
func show_upgrade() -> void:
	hud.show_upgrade()

func on_buckle() -> void:
	if object_id in ["bottle","crate","pc","microwave"]:
		camera_shake = 0.014 if object_id=="bottle" else 0.022
		audio.crack()
	else: super.on_buckle()
