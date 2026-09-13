extends Node3D
## Original small workshop dressing. No physics bodies or per-frame mesh rebuilds.
var game: Node3D
var lamp: StandardMaterial3D
var pulse: float = 0
func tube(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 10
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = (a+b)*0.5
	var up: Vector3 = (b-a).normalized()
	var right: Vector3 = up.cross(Vector3.FORWARD).normalized()
	if right.length()<0.1: right = Vector3.RIGHT
	node.basis = Basis(right,up,right.cross(up).normalized())
	add_child(node)
func sign_text(text: String, pos: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = size
	label.pixel_size = 0.0025
	label.modulate = color
	label.outline_size = 0
	add_child(label)
func _ready() -> void:
	var concrete = game.material(Color("aeb4b2"))
	concrete.albedo_texture = preload("res://assets/workshop-concrete.png")
	concrete.uv1_triplanar = true
	concrete.uv1_scale = Vector3.ONE*0.55
	var wall = game.material(Color("89969d"))
	wall.albedo_texture = preload("res://assets/workshop-wall.png")
	wall.uv1_triplanar = true
	wall.uv1_scale = Vector3.ONE*0.6
	var paint = game.material(Color.WHITE,0.3)
	paint.albedo_texture = preload("res://assets/workshop-paint.png")
	paint.roughness = 0.68
	for child in game.get_children():
		if child is WorldEnvironment:
			child.environment.ambient_light_energy = 0.24
			child.environment.background_color = Color("10181d")
		if child is DirectionalLight3D:
			child.light_energy = 0.7
			child.light_color = Color("dde7eb")
		if child is OmniLight3D:
			child.light_energy = 2.0 if child.position.z>0 else 1.6
			child.omni_range = 5.5
		if child is MeshInstance3D and child.mesh is BoxMesh:
			if child.mesh.size.x>17: child.material_override = concrete
			elif child.position.z< -4.1: child.material_override = wall
			elif child.mesh.size.y>4 or child.mesh.size==Vector3(3.7,0.6,0.8): child.material_override = paint
	var pipe = game.material(Color("48565b"),0.65)
	var black = game.material(Color("131b1e"),0.15)
	var yellow = game.material(Color("b38d2f"),0.2)
	for x in [-2.8,-2.58]:
		tube(Vector3(x,0.2,-3.7),Vector3(x,4.5,-3.7),0.055,pipe)
		tube(Vector3(x,4.5,-3.7),Vector3(2.6,4.5,-3.7),0.055,pipe)
		for y in [0.8,2.5,4.1]: game.block(Vector3(0.36,0.06,0.14),Vector3(x,y,-3.73),black,self)
	game.block(Vector3(1.0,1.45,0.35),Vector3(2.65,1.1,-2.6),black,self)
	game.block(Vector3(0.85,0.6,0.025),Vector3(2.65,1.45,-2.4),pipe,self)
	sign_text("HYDRAULIC\nPOWER UNIT",Vector3(2.65,1.44,-2.37),28,Color("dddac8"))
	var points: Array[Vector3] = [Vector3(0,4.45,-0.2),Vector3(0.8,4.65,-0.4),Vector3(1.8,4.45,-0.6),Vector3(2.15,3.9,-1),Vector3(2.2,2.4,-1.6),Vector3(2.65,1.8,-2.6)]
	for i in range(points.size()-1): tube(points[i],points[i+1],0.038,black)
	game.block(Vector3(1.32,0.9,0.04),Vector3(2.65,3.25,-3.83),yellow,self)
	sign_text("CAUTION\nHIGH PRESSURE\nKEEP HANDS CLEAR",Vector3(2.65,3.25,-3.79),36,Color("151c1e"))
	for x in [-2.15,2.15]: game.block(Vector3(0.07,0.009,3.6),Vector3(x,0.002,0.1),yellow,self)
	game.block(Vector3(4.3,0.009,0.07),Vector3(0,0.002,1.9),yellow,self)
	var oil = game.material(Color.WHITE)
	oil.albedo_texture = preload("res://assets/workshop-oil.png")
	oil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	oil.roughness = 0.3
	for pos in [Vector3(1.6,0.008,0.65),Vector3(-0.9,0.008,1.5)]:
		var spot := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(1.5,1.5)
		spot.mesh = mesh
		spot.material_override = oil
		spot.position = pos
		add_child(spot)
	lamp = game.material(Color("a5c58e"))
	lamp.emission_enabled = true
	lamp.emission = Color("a5c58e")
	game.block(Vector3(0.18,0.07,0.04),Vector3(1.65,3.48,0.28),lamp,self)
	game.block(Vector3(0.28,0.32,0.1),Vector3(1.65,3.4,0.24),black,self)
	sign_text("H-01",Vector3(-1.65,2.95,0.26),30,Color("242b28"))
func _process(dt: float) -> void:
	pulse = maxf(0,pulse-dt)
	if lamp:
		lamp.albedo_color = Color("26372a")
		lamp.emission = Color("e3b84b") if pulse>0 else Color("a5c58e")
		lamp.emission_energy_multiplier = 0.3+0.8*pulse
