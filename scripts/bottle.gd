extends "res://scripts/content_body.gd"
## PET pinches across its section; the narrow neck stays identifiable during collapse.
func _init() -> void:
	initial_height = 1.25
	width = 0.78
	depth = 0.68
	material("77bec1",0.12,0.22)
	material("eee6c5",0,0.7)
	material("225f62",0.1,0.4)
func point(t: float,v: float) -> Vector3:
	var c: float = compression
	var pinch: float = smoothstep(0.06,0.32,c)
	var fold: float = smoothstep(0.40,0.66,c)
	var radius: float = 0.34*(1-0.66*smoothstep(0.68,0.87,v))
	radius *= 0.88+0.12*smoothstep(0,0.1,v)
	radius += 0.012*sin(v*100)*sin(PI*v)
	var local: float = pow(maxf(0,cos(t-1.15+(v-0.5)*4)),4)*exp(-pow((v-0.52)/0.26,2))
	radius *= 1-0.84*pinch*local
	var crease: float = absf(sin(v*15+t*1.5))
	radius += (0.045*pinch+0.075*fold)*(crease-0.4)*sin(v*PI)
	var x: float = cos(t)*radius*(1+0.32*pinch*sin(v*PI))
	var z: float = sin(t)*radius*(1-0.53*pinch*sin(v*PI))
	x += 0.13*pinch*sin(v*PI)+0.08*fold*v
	var neck_height: float = minf(0.14,height()*0.45)
	var y: float = v/0.86*(height()-neck_height) if v<0.86 else height()-neck_height+(v-0.86)/0.14*neck_height
	y -= (0.035*pinch+0.028*fold)*sin(v*PI)*pow(maxf(0,cos(t+v*6)),2)
	return Vector3(x,clampf(y,0,height()),z)
func build_geometry() -> void:
	for j in range(32):
		for i in range(40):
			var v: float = j/32.0
			var mat: int = 2 if j>=29 else (1 if j in range(10,18) else 0)
			quad(point(i*TAU/40,v),point((i+1)*TAU/40,v),point((i+1)*TAU/40,(j+1)/32.0),point(i*TAU/40,(j+1)/32.0),mat)
	for i in range(40):
		tri(Vector3(0.08*smoothstep(0.4,0.66,compression),height(),0),point(i*TAU/40,1),point((i+1)*TAU/40,1),2)
		tri(Vector3.ZERO,point((i+1)*TAU/40,0),point(i*TAU/40,0),0)
	# Label ink bars deform with the wall, making the local pinch visible.
	for j in range(3):
		var v: float = 0.36+j*0.055
		quad(point(0.65,v)*Vector3(1.005,1,1.005),point(2.45,v)*Vector3(1.005,1,1.005),point(2.45,v+0.018)*Vector3(1.005,1,1.005),point(0.65,v+0.018)*Vector3(1.005,1,1.005),2)
