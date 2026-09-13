extends Node3D

var press: Node3D
var camera: Camera3D
var status: Label
var phase_label: Label
var readout: Label
var audio: Node
var ram: MeshInstance3D
var camera_shake: float = 0.0
var elapsed: float = 0.0
var angle: float = 0.55
var orbit_distance: float = 8.4
var camera_height: float = 3.8
var focus := Vector3(0, 2.05, 0)
var new_button: Button
var quitting: bool = false
var aluminum: bool = "--aluminum" in OS.get_cmdline_user_args()
var tire: bool = not aluminum and not "--cardboard" in OS.get_cmdline_user_args()

func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.42 if metal > 0.0 else 0.85
	return m

func block(size: Vector3, pos: Vector3, mat: Material, parent: Node = self) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	parent.add_child(n)
	return n

func cylinder(radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	add_child(n)
	return n

func _ready() -> void:
	if aluminum or tire:
		orbit_distance = 6.0
		camera_height = 3.0
		focus = Vector3(0,1.85,0)
	get_tree().auto_accept_quit = false
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("171d23")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9db1c5")
	env.environment.ambient_light_energy = 0.45
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.65
	light.shadow_enabled = true
	add_child(light)
	var yellow := material(Color("927024"), 0.25)
	yellow.roughness = 0.65
	var steel := material(Color("414b51"), 0.8)
	var dark := material(Color("1d262c"), 0.55)
	var chrome := material(Color("aab8bd"), 0.85)
	block(Vector3(18, 0.2, 18), Vector3(0, -0.12, 0), material(Color("31373a")))
	block(Vector3(3.5, 0.35, 2.7), Vector3(0, 0.825, 0), steel)
	for x in [-1.65, 1.65]:
		block(Vector3(0.32, 4.5, 0.5), Vector3(x, 2.25, 0), yellow)
	block(Vector3(3.7, 0.6, 0.8), Vector3(0, 4.2, 0), yellow)
	for x in [-1.4, 1.4]:
		for z in [-0.9, 0.9]:
			block(Vector3(0.25, 0.7, 0.25), Vector3(x, 0.35, z), dark)
			block(Vector3(0.45, 0.07, 0.42), Vector3(x, 0.035, z), steel)
	for x in [-1.27, 1.27]:
		cylinder(0.07, 2.95, Vector3(x, 2.475, -0.6), chrome)
	cylinder(0.30, 0.7, Vector3(0,4.18,0), dark)
	ram = cylinder(0.14, 1.0, Vector3(0,3.4,0),chrome)
	for x in [-1.64,1.64]:
		for y in [1.05,3.75,4.2]:
			var bolt = cylinder(0.055,0.045,Vector3(x,y,0.27),chrome)
			bolt.rotation_degrees.x = 90
	# Restrained garage backdrop; the press remains the focus.
	block(Vector3(14,6,0.2),Vector3(0,2.9,-4.2),material(Color("252f35")))
	block(Vector3(4.3,3.8,0.12),Vector3(-3.8,1.9,-4.0),dark)
	for y in range(12):
		block(Vector3(4.3,0.025,0.035),Vector3(-3.8,0.3+y*0.28,-3.91),steel)
	for x in [-6,-2,2,6]:
		block(Vector3(0.07,5.5,0.12),Vector3(x,2.6,-4),steel)
	var glow := material(Color("ffe0a6"))
	glow.emission_enabled = true
	glow.emission = Color("ffe0a6")
	block(Vector3(1.5,0.035,0.25),Vector3(0,3.86,-0.36),glow)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1,3.4,2.0)
	fill.light_color = Color("ffe6bd")
	fill.light_energy = 1.4
	fill.omni_range = 7
	add_child(fill)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2.0,3.0,-2)
	rim.light_color = Color("9ec5df")
	rim.light_energy = 1.8
	rim.omni_range = 6
	add_child(rim)
	var stripes := ShaderMaterial.new()
	stripes.shader = Shader.new()
	stripes.shader.code = "shader_type spatial; void fragment(){float s=step(0.5,fract(UV.x*12.0+UV.y*0.65)); ALBEDO=mix(vec3(0.035),vec3(0.64,0.40,0.055),s); ROUGHNESS=0.62;}"
	block(Vector3(3.48,0.14,0.015),Vector3(0,0.84,1.358),stripes)
	var badge := Label3D.new()
	badge.text = "CRUSH FACTORY     /     H-01"
	badge.font_size = 42
	badge.pixel_size = 0.0018
	badge.position = Vector3(0,4.2,0.411)
	badge.modulate = Color("1c2328")
	add_child(badge)
	press = preload("res://scripts/press_controller.gd").new()
	add_child(press)
	press.plate = block(Vector3(2.65, 0.28, 2.1), Vector3(0, 3.29, 0), steel)
	block(Vector3(2.62,0.08,0.02),Vector3(0,0,1.06),stripes,press.plate)
	var target = preload("res://scripts/aluminum_can.gd").new() if aluminum else preload("res://scripts/cardboard.gd").new()
	if tire:
		target.free()
		target = preload("res://scripts/tire.gd").new()
		press.solver_script = preload("res://scripts/rubber_solver.gd")
		press.solver = press.solver_script.new()
	if aluminum:
		press.solver_script = preload("res://scripts/aluminum_solver.gd")
		press.solver = press.solver_script.new()
	target.position.y = 1.0
	add_child(target)
	press.target = target
	audio = preload("res://scripts/press_audio.gd").new()
	audio.metal = aluminum
	audio.rubber = tire
	add_child(audio)
	press.buckled.connect(on_buckle)
	camera = Camera3D.new()
	camera.fov = 43
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var header := Label.new()
	header.text = "CRUSH FACTORY"
	header.position = Vector2(36,28)
	header.add_theme_font_size_override("font_size",26)
	canvas.add_child(header)
	var sub := Label.new()
	sub.text = "M2 REVIEW 01  /  ALUMINUM" if aluminum else "M1 REVIEW 02  /  CORRUGATED PAPER"
	if tire: sub.text = "M3 REVIEW 01  /  RUBBER TIRE"
	sub.position = Vector2(37,65)
	sub.add_theme_color_override("font_color",Color("bcae8f"))
	sub.add_theme_font_size_override("font_size",12)
	canvas.add_child(sub)
	status = Label.new()
	status.position = Vector2(36,133)
	status.add_theme_font_size_override("font_size",15)
	canvas.add_child(status)
	phase_label = Label.new()
	phase_label.position = Vector2(36,160)
	phase_label.add_theme_font_size_override("font_size",21)
	phase_label.add_theme_color_override("font_color",Color("e9c879"))
	canvas.add_child(phase_label)
	readout = Label.new()
	readout.position = Vector2(1040,34)
	readout.add_theme_font_size_override("font_size",15)
	canvas.add_child(readout)
	var row := HBoxContainer.new()
	row.position = Vector2(36,618)
	row.add_theme_constant_override("separation",12)
	canvas.add_child(row)
	for entry in [["PRESS / PAUSE",toggle_press],["RETURN",press.retract],["NEW CAN" if aluminum else "NEW CARTON",press.reset]]:
		var b := Button.new()
		b.text = entry[0]
		if tire and b.text=="NEW CARTON": b.text = "NEW TIRE"
		b.custom_minimum_size = Vector2(155,42)
		b.focus_mode = Control.FOCUS_NONE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.075,0.095,0.11,0.94)
		style.border_color = Color("7c7157")
		style.set_border_width_all(1)
		style.content_margin_left = 16
		style.content_margin_right = 16
		b.add_theme_stylebox_override("normal",style)
		b.pressed.connect(entry[1])
		row.add_child(b)
		new_button = b
	var help := Label.new()
	help.text = "SPACE press / pause   R return   N new carton   1 front   2 side   RMB orbit   Wheel zoom   WASD move   M mute"
	if aluminum: help.text = help.text.replace("new carton","new can")
	if tire: help.text = help.text.replace("new carton","new tire")
	help.position = Vector2(36,678)
	help.add_theme_font_size_override("font_size",12)
	help.add_theme_color_override("font_color",Color("a8b2b7"))
	canvas.add_child(help)
	update_camera()
	if "--demo" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args() or "--probe" in OS.get_cmdline_user_args():
		var runner = preload("res://scripts/demo_runner.gd").new()
		if tire:
			runner.free()
			runner = preload("res://scripts/tire_demo_runner.gd").new()
		runner.game = self
		add_child(runner)

func toggle_press() -> void:
	press.stop() if press.state == "PRESSING" else press.start()

func on_buckle() -> void:
	camera_shake = 0.019 if aluminum else 0.027
	if tire: camera_shake = 0.012
	audio.crack()
	if not aluminum and not tire: press.target.emit_paper_bits()

func update_camera() -> void:
	camera.position = Vector3(sin(angle) * orbit_distance, camera_height, cos(angle) * orbit_distance)
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: toggle_press()
			KEY_R: press.retract()
			KEY_N: press.reset()
			KEY_1: angle = 0.0; focus = Vector3(0,2.05,0)
			KEY_2: angle = 1.0; focus = Vector3(0,2.05,0)
			KEY_M: audio.muted = not audio.muted
			KEY_MINUS: press.pressure = maxf(5,press.pressure-10)
			KEY_EQUAL: press.pressure = minf(100,press.pressure+10)
			KEY_ESCAPE: quit_game()
		update_camera()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		angle -= event.relative.x * 0.006
		camera_height = clampf(camera_height + event.relative.y * 0.01,2.0,5.5)
		update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: orbit_distance = maxf(4.5,orbit_distance-0.3)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: orbit_distance = minf(11,orbit_distance+0.3)
		update_camera()

func _process(dt: float) -> void:
	elapsed += dt
	if Input.is_physical_key_pressed(KEY_A): angle -= dt * 0.55
	if Input.is_physical_key_pressed(KEY_D): angle += dt * 0.55
	if Input.is_physical_key_pressed(KEY_W): orbit_distance = maxf(4.5,orbit_distance-dt*2)
	if Input.is_physical_key_pressed(KEY_S): orbit_distance = minf(11,orbit_distance+dt*2)
	update_camera()
	camera_shake = move_toward(camera_shake,0,dt*0.3)
	camera.position += Vector3(sin(elapsed*83),cos(elapsed*71),0)*camera_shake
	var ram_length: float = maxf(0.15,3.88-(press.underside+0.28))
	ram.scale.y = ram_length
	ram.position.y = 3.88-ram_length*0.5
	status.text = "H-01  /  " + press.state
	var c: float = press.solver.compression
	var phase: String = "Awaiting pressure"
	if press.state == "PRESSING":
		if c < 0.001: phase = "Approaching" if not press.captured else "Contact / resistance"
		elif c < 0.16: phase = "Structure resisting"
		elif c < 0.30: phase = "Primary wall buckling"
		elif c < 0.56: phase = "Adjacent walls folding"
		else: phase = "Densifying the folds"
		if aluminum and c>0.001:
			if c<0.065: phase = "Metal resisting / local dent"
			elif c<0.12: phase = "Shell approaching yield"
			elif c<0.30: phase = "First eccentric buckle"
			elif c<0.40: phase = "Next ring resisting"
			elif c<0.58: phase = "Second ring buckling"
			elif c<0.67: phase = "Lower shell resisting"
			elif c<0.84: phase = "Third buckle / stacking"
			else: phase = "Densifying metal folds"
	elif c > 0.89: phase = "Permanent / compacted"
	elif c > 0: phase = "Permanent creases retained"
	if tire:
		if press.state=="PRESSING":
			phase = "Approaching" if c<0.001 else ("Elastic resistance" if c<0.48 else "High load / sidewall damage")
		elif press.state=="COMPACTED": phase = "Stored elastic strain"
		elif press.state=="PAUSED": phase = "Elastic load / paused"
		elif press.solver.elastic_deformation>0.004: phase = "Rebounding / unloading"
		elif press.solver.permanent_damage>0.005: phase = "Recovered / residual damage"
		else: phase = "Relaxed rubber"
	phase_label.text = phase
	readout.text = "PRESSURE   %03d / 100\nLOAD             %02d\nHEIGHT         %.0f mm\nREDUCTION    %.0f%%" % [press.pressure,press.solver.resistance,press.solver.height()*1000,c*100]
	new_button.disabled = absf(press.underside-press.HOME)>0.005
	audio.set_load(press.state,press.solver.resistance/100.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	if quitting: return
	quitting = true
	set_process(false)
	audio.shutdown()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
