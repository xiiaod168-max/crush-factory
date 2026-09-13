extends Node3D
## A continuous cylindrical shell. Plastic ring folds differ from cardboard panels.
const HEIGHT: float = 1.45
const RADIUS: float = 0.48
const SIDES: int = 64
const RINGS: int = 40
var compression: float = 0.0
var displayed: float = -1.0
var visual: MeshInstance3D
var collider: CollisionShape3D
var collider_height: float = HEIGHT
var collider_updates: int = 0
var sync_elapsed: float = 0.0
var force_sync: bool = false
var shell_material: StandardMaterial3D
var silver: StandardMaterial3D
var flecks: Array[Dictionary] = []

func _ready() -> void:
	visual = MeshInstance3D.new()
	add_child(visual)
	shell_material = StandardMaterial3D.new()
	shell_material.albedo_texture = load("res://assets/can-label.png")
	shell_material.metallic = 0.55
	shell_material.roughness = 0.29
	shell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	silver = StandardMaterial3D.new()
	silver.albedo_color = Color("b4c1c8")
	silver.metallic = 0.85
	silver.roughness = 0.25
	silver.cull_mode = BaseMaterial3D.CULL_DISABLED
	silver.albedo_texture = load("res://assets/can-lid.png")
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	collider = CollisionShape3D.new()
	collider.shape = CylinderShape3D.new()
	body.add_child(collider)
	sync_collider()
	rebuild()

func set_compression(value: float, immediate: bool = false) -> void:
	compression = clampf(value,0.0,0.9)
	if immediate and absf(collider_height-HEIGHT*(1.0-compression))>0.001: force_sync = true

func _physics_process(dt: float) -> void:
	sync_elapsed += dt
	if force_sync or (sync_elapsed>=0.1 and absf(collider_height-HEIGHT*(1.0-compression))>=HEIGHT*0.02):
		sync_collider()
		sync_elapsed = 0
		force_sync = false

func sync_collider() -> void:
	collider_height = HEIGHT*(1.0-compression)
	collider.shape.height = collider_height
	collider.shape.radius = RADIUS+0.10*compression
	collider.position.y = collider_height*0.5
	collider_updates += 1

func _process(_dt: float) -> void:
	if absf(displayed-compression)>0.0001: rebuild()

func wall_point(theta: float, v: float, c: float) -> Vector3:
	var h: float = HEIGHT*(1.0-c)
	var dent: float = smoothstep(0.0,0.095,c)
	var a: float = smoothstep(0.115,0.30,c)
	var b: float = smoothstep(0.395,0.58,c)
	var d: float = smoothstep(0.665,0.84,c)
	var dense: float = smoothstep(0.78,0.90,c)
	var angle: float = theta + (0.17*a*sin(v*PI)+0.12*b*sin(v*TAU))
	var radius: float = RADIUS
	# Necked ends retain their rolled rims throughout compression.
	radius -= 0.033*(1.0-smoothstep(0.0,0.06,v)+smoothstep(0.92,1.0,v))
	radius -= 0.17*dent*exp(-pow((v-0.72)/0.14,2))*pow(maxf(0.0,cos(theta-1.15)),6)
	var centers: Array[float] = [0.68+0.075*sin(theta-0.3),0.40+0.065*cos(theta+0.8),0.18+0.035*sin(theta*2.0)]
	var amplitudes: Array[float] = [a,b,d]
	for k in range(3):
		var offset: float = v-centers[k]
		var lobe: float = 0.60+0.40*cos(theta-0.6-k*2.1)
		# Outward ridge flanked by inward valleys, oblique around the circumference.
		radius += amplitudes[k]*(0.14+0.08*lobe)*cos(offset*29.0)*exp(-pow(offset/0.17,2))
		radius -= amplitudes[k]*0.17*pow(maxf(0,cos(theta-1.7-k*2.0)),4)*exp(-pow((offset-0.055)/0.10,2))
	radius += dense*0.025*sin(theta*7.0+v*24.0)*sin(v*PI)
	# Disjoint axial bands retain positive thickness, avoiding coplanar folded triangles.
	var axial: float = v-0.24*a*clampf((v-0.52)/0.32,0,1)-0.22*b*clampf((v-0.25)/0.27,0,1)-0.20*d*clampf(v/0.25,0,1)
	axial /= 1.0-0.24*a-0.22*b-0.20*d
	var tilt: float = (0.065*a+0.035*b)*(0.5+0.5*cos(theta-0.3))*v
	var y: float = axial*(h-minf(h*0.25,tilt))
	y += dense*h*0.04*sin(theta*5.0+v*21.0)*axial*(1.0-axial)
	var shift_x: float = 0.14*a*sin(v*PI)-0.10*b*sin(v*TAU)+0.035*d*v
	var shift_z: float = -0.08*a*sin(v*PI)+0.09*b*sin(v*2.5)
	return Vector3(cos(angle)*radius+shift_x,clampf(y,0,h),sin(angle)*radius+shift_z)

func cap_point(theta: float, radial: float, top: bool, c: float) -> Vector3:
	var edge: Vector3 = wall_point(theta,1.0 if top else 0.0,c)
	var center := Vector3(0.035*smoothstep(0.665,0.84,c),HEIGHT*(1.0-c)-minf(0.04,HEIGHT*(1.0-c)*0.15),0) if top else Vector3.ZERO
	var point: Vector3 = center.lerp(edge,radial)
	if top:
		point.y -= 0.012*sin(radial*PI)+0.012*smoothstep(0.4,0.9,c)*sin(theta*3.0)*sin(radial*PI)
	return point

func add_surface(mesh: ArrayMesh, vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, mat: Material) -> void:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(0,indices.size(),3):
		var a: int = indices[i]
		var b: int = indices[i+1]
		var c: int = indices[i+2]
		var n: Vector3 = (vertices[c]-vertices[a]).cross(vertices[b]-vertices[a])
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in range(normals.size()): normals[i] = normals[i].normalized()
	if vertices.size()==(RINGS+1)*(SIDES+1):
		for j in range(RINGS+1):
			var first: int = j*(SIDES+1)
			var last: int = first+SIDES
			var n: Vector3 = (normals[first]+normals[last]).normalized()
			normals[first] = n
			normals[last] = n
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(mesh.get_surface_count()-1,mat)

func rebuild() -> void:
	displayed = compression
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for j in range(RINGS+1):
		for i in range(SIDES+1):
			vertices.append(wall_point(i*TAU/SIDES,j/float(RINGS),compression))
			uvs.append(Vector2(1.0-i/float(SIDES),1.0-j/float(RINGS)))
	for j in range(RINGS):
		for i in range(SIDES):
			var a: int = j*(SIDES+1)+i
			var b: int = a+1
			indices.append_array(PackedInt32Array([a,b,a+SIDES+1,b,b+SIDES+1,a+SIDES+1]))
	add_surface(mesh,vertices,uvs,indices,shell_material)
	vertices = PackedVector3Array()
	uvs = PackedVector2Array()
	indices = PackedInt32Array()
	for top in [false,true]:
		var start: int = vertices.size()
		for j in range(9):
			for i in range(SIDES):
				var theta: float = i*TAU/SIDES
				var point: Vector3 = cap_point(theta,j/8.0,top,compression)
				vertices.append(point)
				uvs.append(Vector2(cos(theta),sin(theta))*j/16.0+Vector2(0.5,0.5))
		for j in range(8):
			for i in range(SIDES):
				var a: int = start+j*SIDES+i
				var b: int = start+j*SIDES+(i+1)%SIDES
				if top: indices.append_array(PackedInt32Array([a,a+SIDES,b,b,a+SIDES,b+SIDES]))
				else: indices.append_array(PackedInt32Array([a,b,a+SIDES,b,b+SIDES,a+SIDES]))
		# Rolled rim, slightly inset so it never protrudes above the press envelope.
		start = vertices.size()
		for j in range(8):
			for i in range(SIDES):
				var theta: float = i*TAU/SIDES
				var ring: Vector3 = wall_point(theta,1.0 if top else 0.0,compression)
				ring += Vector3(cos(theta)*cos(j*TAU/8.0)*0.014,(sin(j*TAU/8.0)-1.0)*0.010 if top else (sin(j*TAU/8.0)+1.0)*0.010,sin(theta)*cos(j*TAU/8.0)*0.014)
				vertices.append(ring)
				uvs.append(Vector2.ZERO)
		for j in range(8):
			for i in range(SIDES):
				var a: int = start+j*SIDES+i
				var b: int = start+j*SIDES+(i+1)%SIDES
				var c: int = start+(j+1)%8*SIDES+i
				var d: int = start+(j+1)%8*SIDES+(i+1)%SIDES
				indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	add_surface(mesh,vertices,uvs,indices,silver)
	visual.mesh = mesh
