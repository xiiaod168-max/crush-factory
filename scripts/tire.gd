extends Node3D
## Upright annular rubber body. The hole, tread and sidewalls share the deformation.
const HEIGHT: float = 1.45
const AROUND: int = 144
const SECTION: int = 32
var compression: float = 0.0
var permanent_damage: float = 0.0
var displayed: float = -1
var displayed_damage: float = -1
var visual: MeshInstance3D
var collider: CollisionShape3D
var collider_height: float = HEIGHT
var collider_updates: int = 0
var sync_elapsed: float = 0
var force_sync: bool = false
var rubber: ShaderMaterial

func _ready() -> void:
	visual = MeshInstance3D.new()
	add_child(visual)
	rubber = ShaderMaterial.new()
	rubber.shader = Shader.new()
	rubber.shader.code = """shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float outer = smoothstep(0.25,0.8,cos(UV.y*6.283185));
 float groove = 1.0-smoothstep(0.10,0.19,abs(sin(UV.x*6.283185*36.0 + 2.5*sin(UV.y*6.283185))));
 float channels = pow(abs(sin(UV.y*6.283185*5.0)),24.0)*outer;
 float side_ring = pow(abs(sin(UV.y*6.283185*6.0)),32.0)*(1.0-outer);
 float grain = fract(sin(dot(UV,vec2(7521.3,821.9)))*43758.5453);
 ALBEDO = vec3(0.073,0.081,0.086)*(1.0-0.55*groove*outer-0.3*channels-0.12*side_ring)+grain*0.004;
 ROUGHNESS = 0.78; METALLIC = 0.0;
}"""
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	collider = CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	body.add_child(collider)
	sync_collider()
	rebuild()

func set_compression(value: float, immediate: bool = false) -> void:
	compression = clampf(value,0,0.66)
	if immediate and absf(compression-permanent_damage)<0.003 and absf(collider_height-HEIGHT*(1.0-compression))>0.001: force_sync = true

func _physics_process(dt: float) -> void:
	sync_elapsed += dt
	if force_sync or (sync_elapsed>=0.1 and absf(collider_height-HEIGHT*(1.0-compression))>HEIGHT*0.02):
		sync_collider()
		sync_elapsed = 0
		force_sync = false

func sync_collider() -> void:
	collider_height = HEIGHT*(1.0-compression)
	collider.shape.size = Vector3(HEIGHT*(1+0.68*compression),collider_height,0.55+compression*0.18)
	collider.position.y = collider_height*0.5
	collider_updates += 1

func point(theta: float, phi: float, c: float, damage: float) -> Vector3:
	var radial: float = 0.545+0.18*cos(phi)
	# Shallow cut tread blocks, only on the outer running surface.
	var tread: float = smoothstep(0.35,0.85,cos(phi))
	radial -= 0.012*tread*pow(absf(cos(theta*36.0+1.25*sin(phi))),18)
	var local: float = pow(maxf(0,cos(theta-0.65)),8)
	radial -= 0.20*damage*local*(0.45+0.55*absf(sin(phi)))
	var h: float = HEIGHT*(1.0-c)
	var bulge: float = 1.0+0.72*c+0.12*c*pow(absf(cos(theta)),3)
	var x: float = radial*cos(theta)*bulge+damage*0.20*sin(theta*1.0)
	var y: float = h*0.5+radial*sin(theta)*(1.0-c)
	# Flatten the contact patches while keeping the central hole visibly elliptical.
	y += 0.07*c*sin(theta)*pow(cos(theta),2)
	y -= damage*0.12*local*(0.5+0.5*sin(theta))
	var z: float = 0.255*sin(phi)*(1.0+0.35*c*pow(absf(cos(theta)),2))
	z += 0.055*c*sin(theta*2.0)*sin(phi)+0.18*damage*local*sin(phi)
	return Vector3(x,clampf(y,0,h),z)

func _process(_dt: float) -> void:
	if absf(displayed-compression)>0.0001 or absf(displayed_damage-permanent_damage)>0.0001: rebuild()

func rebuild() -> void:
	displayed = compression
	displayed_damage = permanent_damage
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(AROUND):
		for j in range(SECTION):
			vertices.append(point(i*TAU/AROUND,j*TAU/SECTION,compression,permanent_damage))
			uv.append(Vector2(i/float(AROUND),j/float(SECTION)))
	normals.resize(vertices.size())
	for i in range(AROUND):
		for j in range(SECTION):
			var a: int = i*SECTION+j
			var b: int = (i+1)%AROUND*SECTION+j
			var c: int = (i+1)%AROUND*SECTION+(j+1)%SECTION
			var d: int = i*SECTION+(j+1)%SECTION
			indices.append_array(PackedInt32Array([a,c,b,a,d,c]))
	for i in range(0,indices.size(),3):
		var a: int = indices[i]
		var b: int = indices[i+1]
		var c: int = indices[i+2]
		var n: Vector3 = (vertices[c]-vertices[a]).cross(vertices[b]-vertices[a])
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in range(normals.size()): normals[i] = normals[i].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,rubber)
	visual.mesh = mesh
