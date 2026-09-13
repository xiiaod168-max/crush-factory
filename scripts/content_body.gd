extends Node3D
## Only mesh emission and low-frequency envelope collision are shared.
var initial_height: float = 1.5
var width: float = 1.6
var depth: float = 1.2
var compression: float = 0
var permanent_damage: float = 0
var displayed: float = -1
var visual: MeshInstance3D
var collider: CollisionShape3D
var collider_height: float = 0
var collider_updates: int = 0
var elapsed: float = 0
var force_sync: bool = false
var flecks: Array[Dictionary] = []
var surfaces: Array[SurfaceTool] = []
var materials: Array[StandardMaterial3D] = []
func material(color: String, metal: float = 0, roughness: float = 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.metallic = metal
	m.roughness = roughness
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials.append(m)
	return m
func _ready() -> void:
	visual = MeshInstance3D.new()
	add_child(visual)
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	collider = CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	body.add_child(collider)
	sync_collider()
	rebuild()
func height() -> float:
	return initial_height*(1-compression)
func set_compression(value: float, immediate: bool = false) -> void:
	compression = value
	force_sync = immediate and absf(collider_height-height())>0.001
func _physics_process(dt: float) -> void:
	elapsed += dt
	if force_sync or (elapsed>=0.1 and absf(collider_height-height())>initial_height*0.02):
		sync_collider()
		elapsed = 0
		force_sync = false
func sync_collider() -> void:
	collider_height = height()
	collider.shape.size = Vector3(width,collider_height,depth)
	collider.position.y = collider_height*0.5
	collider_updates += 1
func _process(_dt: float) -> void:
	if absf(displayed-compression)>0.0001: rebuild()
func rebuild() -> void:
	surfaces.clear()
	for m in materials:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(m)
		surfaces.append(st)
	build_geometry()
	var mesh := ArrayMesh.new()
	for st in surfaces:
		st.generate_normals()
		st.commit(mesh)
	visual.mesh = mesh
	displayed = compression
func build_geometry() -> void:
	pass
func tri(a: Vector3, b: Vector3, c: Vector3, mat: int) -> void:
	for p in [a,b,c]: surfaces[mat].add_vertex(p)
func quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,mat: int) -> void:
	tri(a,b,c,mat)
	tri(a,c,d,mat)
func box(center: Vector3, size: Vector3, mat: int, rotation: Vector3 = Vector3.ZERO) -> void:
	surfaces[mat].set_smooth_group(-1)
	var points: Array[Vector3] = []
	var basis := Basis.from_euler(rotation)
	for k in range(8):
		var p: Vector3 = center+basis*(size*Vector3(1 if k&1 else -1,1 if k&2 else -1,1 if k&4 else -1)*0.5)
		# Every part belongs to a constrained crushing envelope, never a flying rigid body.
		p.y = clampf(p.y,0.002,height()-0.002)
		points.append(p)
	for face in [[0,4,6,2],[1,3,7,5],[0,1,5,4],[2,6,7,3],[0,2,3,1],[4,5,7,6]]:
		quad(points[face[0]],points[face[1]],points[face[2]],points[face[3]],mat)
	surfaces[mat].set_smooth_group(0)
