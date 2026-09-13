extends Node3D
## Four folded walls share corner coordinates. Original UVs travel with the paper.
const HEIGHT: float = 1.45
const HALF_X: float = 0.9
const HALF_Z: float = 0.675
const NU: int = 16
const NV: int = 20
var compression: float = 0.0
var displayed: float = -1.0
var body: StaticBody3D
var collider: CollisionShape3D
var visual: MeshInstance3D
var side_material: StandardMaterial3D
var lid_material: StandardMaterial3D
var sync_elapsed: float = 0.0
var collider_height: float = HEIGHT
var collider_updates: int = 0
var force_sync: bool = false
var flecks: Array[Dictionary] = []

func _ready() -> void:
	visual = MeshInstance3D.new()
	add_child(visual)
	side_material = StandardMaterial3D.new()
	side_material.albedo_texture = load("res://assets/paper.png")
	side_material.roughness = 0.94
	side_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	side_material.vertex_color_use_as_albedo = true
	lid_material = side_material.duplicate()
	lid_material.albedo_texture = load("res://assets/paper-top.png")
	body = StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	collider = CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	body.add_child(collider)
	sync_collider()
	rebuild()
	# Six reusable paper flecks, deliberately not free rigid bodies.
	for i in range(6):
		var fleck := MeshInstance3D.new()
		var chip := BoxMesh.new()
		chip.size = Vector3(0.018+i*0.003,0.002,0.012+i*0.002)
		fleck.mesh = chip
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color("b58b56")
		fleck.material_override = paper
		fleck.visible = false
		add_child(fleck)
		flecks.append({"node":fleck,"velocity":Vector3.ZERO,"life":0.0})

func set_compression(value: float, immediate: bool = false) -> void:
	compression = clampf(value, 0.0, 0.9)
	if immediate and absf(collider_height - HEIGHT * (1.0 - compression)) > 0.001:
		force_sync = true

func _physics_process(dt: float) -> void:
	sync_elapsed += dt
	if force_sync or (sync_elapsed >= 0.1 and absf(collider_height - HEIGHT * (1.0 - compression)) >= HEIGHT * 0.02):
		sync_collider()
		force_sync = false
		sync_elapsed = 0.0

func sync_collider() -> void:
	collider_height = HEIGHT * (1.0 - compression)
	collider.shape.size = Vector3(1.8, collider_height, 1.35)
	collider.position.y = collider_height * 0.5
	collider_updates += 1

func _process(dt: float) -> void:
	if absf(displayed - compression) > 0.0001:
		rebuild()
	for item in flecks:
		if item.life <= 0.0: continue
		item.life -= dt
		item.velocity.y -= dt * 2.8
		item.node.position += item.velocity * dt
		item.node.rotation += Vector3(3,1,2)*dt
		if item.life <= 0.0 or item.node.position.y < 0.012:
			item.node.visible = false
			item.life = 0.0

func emit_paper_bits() -> void:
	for i in range(flecks.size()):
		var item: Dictionary = flecks[i]
		item.node.position = wall_point(0,0.2+i*0.11,0.57,compression)+Vector3(0,0,0.02)
		item.velocity = Vector3(-0.13+i*0.05,0.22+i*0.025,0.18+i*0.02)
		item.life = 1.1
		item.node.visible = true

func hinge(v: float, center: float, width: float) -> float:
	return maxf(0.0,1.0-absf(v-center)/width)

func deform_point(x: float, z: float, v: float, c: float) -> Vector3:
	var h: float = HEIGHT*(1.0-c)
	var primary: float = smoothstep(0.12,0.275,c)
	var secondary: float = smoothstep(0.30,0.56,c)
	var dense: float = smoothstep(0.56,0.90,c)
	var front: float = smoothstep(-0.15,HALF_Z,z)
	var back: float = 1.0-smoothstep(-HALF_Z,0.1,z)
	var right: float = smoothstep(-0.25,HALF_X,x)
	var left: float = 1.0-smoothstep(-HALF_X,0.15,x)
	var dent: float = smoothstep(0.0,0.12,c)
	var diagonal: float = 0.61+0.17*x+0.065*z
	var dx: float = 0.30*right*primary*hinge(v,0.48+0.13*z,0.4)
	dx -= 0.64*right*secondary*hinge(v,0.68-0.20*z,0.24)
	dx += 0.24*left*secondary*hinge(v,0.52+0.2*z,0.35)
	var dz: float = -0.55*front*primary*hinge(v,diagonal,0.36)
	dz -= 0.25*back*secondary*hinge(v,0.45+0.14*x,0.30)
	dz -= 0.035*front*dent*sin(v*PI)
	# A corner sinks first; neighbouring wall hinges activate later.
	dx += 0.12*front*left*primary*v*v
	dz -= 0.10*front*left*primary*v*v
	var crumple: float = dense*0.105*sin(v*17.0+x*4.0-z*3.0)*sin(v*PI)
	dx += x/HALF_X*crumple
	dz += z/HALF_Z*crumple*0.7
	var depression: float = minf(0.25,h*0.55)*primary*front*(0.45+0.55*left)
	depression += dense*0.025*(0.5+0.5*sin(x*7.0+z*5.0))
	depression += dense*minf(0.085,h*0.55)*(0.55*absf(sin(x*6.5+z*3.2))+0.45*absf(sin(z*8.0-x*2.0)))
	depression = minf(depression,h*0.72)
	var local_height: float = h-depression
	var vertical: float = v + primary*sin(v*PI)*(-0.22*front+0.11*right)
	vertical += secondary*0.09*sin(v*TAU+1.5*x-z)*sin(v*PI)
	vertical += dense*0.10*sin(v*15.0+x*3.0+z*4.0)*sin(v*PI)
	return Vector3(clampf(x+dx,-1.26,1.26),clampf(local_height*vertical,0.0,h),clampf(z+dz,-1.0,1.0))

func wall_point(face: int, u: float, v: float, c: float) -> Vector3:
	var perimeter: Vector2
	match face:
		0: perimeter = Vector2(lerpf(-HALF_X, HALF_X, u), HALF_Z)
		1: perimeter = Vector2(HALF_X, lerpf(HALF_Z, -HALF_Z, u))
		2: perimeter = Vector2(lerpf(HALF_X, -HALF_X, u), -HALF_Z)
		_: perimeter = Vector2(-HALF_X, lerpf(-HALF_Z, HALF_Z, u))
	return deform_point(perimeter.x,perimeter.y,v,c)

func top_point(u: float, v: float, c: float) -> Vector3:
	return deform_point(lerpf(-HALF_X,HALF_X,u),lerpf(-HALF_Z,HALF_Z,v),1.0,c)

func add_quad(verts: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv: Vector2, step_uv: Vector2) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	var other_normal: Vector3 = (c-a).cross(d-a).normalized()
	verts.append_array(PackedVector3Array([a,c,b,a,d,c]))
	normals.append_array(PackedVector3Array([normal,normal,normal,other_normal,other_normal,other_normal]))
	uvs.append_array(PackedVector2Array([uv,uv+step_uv,uv+Vector2(step_uv.x,0),uv,uv+Vector2(0,step_uv.y),uv+step_uv]))

func surface(mesh: ArrayMesh, vertices: PackedVector3Array, normals: PackedVector3Array, uv: PackedVector2Array, mat: Material) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var colors := PackedColorArray()
	for i in range(vertices.size()):
		var wear: float = compression*0.07*(0.5+0.5*sin(vertices[i].x*13.0+vertices[i].y*31.0+vertices[i].z*8.0))
		colors.append(Color(1.0-wear,1.0-wear,1.0-wear,1.0))
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(mesh.get_surface_count()-1, mat)

func rebuild() -> void:
	displayed = compression
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	for face in range(4):
		for j in range(NV):
			for i in range(NU):
				var u: float = float(i) / NU
				var v: float = float(j) / NV
				var du: float = 1.0 / NU
				var dv: float = 1.0 / NV
				add_quad(verts,normals,uv,wall_point(face,u,v,compression),wall_point(face,u+du,v,compression),wall_point(face,u+du,v+dv,compression),wall_point(face,u,v+dv,compression),Vector2(u,1.0-v),Vector2(du,-dv))
	surface(mesh,verts,normals,uv,side_material)
	verts = PackedVector3Array()
	normals = PackedVector3Array()
	uv = PackedVector2Array()
	# Two lid flaps overlap slightly after secondary folding, with a small layer offset.
	var overlap: float = 0.065*smoothstep(0.30,0.56,compression)
	for flap in range(2):
		var start_v: float = 0.0 if flap==0 else 0.5-overlap
		var end_v: float = 0.5+overlap if flap==0 else 1.0
		for j in range(6):
			for i in range(12):
				var u: float = i/12.0
				var v: float = lerpf(start_v,end_v,j/6.0)
				var du: float = 1.0/12.0
				var dv: float = (end_v-start_v)/6.0
				var points: Array[Vector3] = [top_point(u,v,compression),top_point(u,v+dv,compression),top_point(u+du,v+dv,compression),top_point(u+du,v,compression)]
				if flap==0:
					for k in range(4):
						var source_u: float = u if k<2 else u+du
						var source_v: float = v if k==0 or k==3 else v+dv
						var edge_fade: float = sin(source_u*PI)*sin(source_v*PI)
						points[k].y = minf(HEIGHT*(1.0-compression),points[k].y+0.008*overlap/0.065*maxf(0.0,edge_fade))
				add_quad(verts,normals,uv,points[0],points[1],points[2],points[3],Vector2(v,u),Vector2(dv,du))
	surface(mesh,verts,normals,uv,lid_material)
	visual.mesh = mesh
