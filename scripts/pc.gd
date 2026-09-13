extends "res://scripts/content_body.gd"
## The open service side exposes a delayed internal-frame collapse after the skin dents.
func _init() -> void:
	initial_height = 1.70
	width = 1.12
	depth = 1.36
	material("414c55",0.7,0.34)
	material("151e24",0.3,0.48)
	material("4d8d71",0.25,0.5)
	material("bac3c4",0.8,0.28)
func shell(x: float,v: float,z: float) -> Vector3:
	var dent: float = smoothstep(0.02,0.19,compression)
	var rack: float = smoothstep(0.18,0.38,compression)
	var stack: float = smoothstep(0.47,0.75,compression)
	x += rack*0.10*sin(v*PI)+stack*0.07*sin(v*15)
	if x<0: x += dent*0.22*pow(sin(v*PI),4)
	z += (0.12*rack*sin(v*10+x*3)+0.09*stack*sin(v*22))*sin(v*PI)
	return Vector3(x,clampf(v*height()-rack*0.03*(x+0.6)*sin(v*PI),0,height()),z)
func build_geometry() -> void:
	var h: float = height()
	var inner: float = smoothstep(0.25,0.70,compression)
	for row in range(24):
		var v: float = row/24.0
		var w: float = (row+1)/24.0
		# Left skin and back remain continuous; the service side is intentionally open.
		quad(shell(-0.55,v,-0.66),shell(-0.55,v,0.66),shell(-0.55,w,0.66),shell(-0.55,w,-0.66),0)
		quad(shell(-0.55,v,-0.66),shell(0.55,v,-0.66),shell(0.55,w,-0.66),shell(-0.55,w,-0.66),0)
		quad(shell(-0.55,v,0.66),shell(-0.28,v,0.66),shell(-0.28,w,0.66),shell(-0.55,w,0.66),1)
	for v in [0.02,0.98]:
		box(Vector3(0,h*v,0),Vector3(1.10,0.045,1.32),0,Vector3(0,inner*0.10,inner*0.025))
	# A green motherboard, silver power supply and three separate drive cages.
	box(Vector3(-0.41,h*0.44,-0.07),Vector3(0.045,h*0.66,0.84),2,Vector3(inner*0.16,0,inner*0.15))
	box(Vector3(0.04,minf(0.22,h*0.24),-0.3),Vector3(0.77,minf(0.35,h*0.36),0.59),3,Vector3(0,inner*0.19,0))
	for i in range(3):
		var v: float = 0.43+i*0.20
		var y: float = minf(initial_height*v,height()*(v-0.12*inner))
		box(Vector3(0.02+inner*(i-1)*0.12,y,0.39),Vector3(0.76,minf(0.18,h*0.20),0.48),3,Vector3(inner*(i-1)*0.22,inner*(i-1)*0.17,inner*(i-1)*0.14))
		box(Vector3(0.02,y,0.645+inner*0.03),Vector3(0.63,0.045,0.025),1)
	for i in range(5):
		box(Vector3(-0.35,h*(0.25+i*0.10),-0.14),Vector3(0.12,0.065,0.30),1,Vector3(0,0,inner*0.5))
	for x in [-0.50,0.50]:
		box(Vector3(x,h*0.48,0.59),Vector3(0.045,h*0.94,0.045),0,Vector3(0,0,inner*0.24*(1 if x>0 else -1)))
	box(Vector3(-0.42,h*0.88,0.70),Vector3(0.09,0.055,0.018),2)
