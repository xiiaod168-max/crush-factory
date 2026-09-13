extends "res://scripts/content_body.gd"
## Separate front door rotates into the cavity before shell layers stack around it.
func _init() -> void:
	initial_height = 1.22
	width = 2.28
	depth = 1.40
	material("c1beb3",0.62,0.33)
	material("202c30",0.35,0.38)
	material("748d87",0.5,0.35)
	material("d6bf77",0.65,0.25)
func wall(x: float,v: float,z: float) -> Vector3:
	var first: float = smoothstep(0.16,0.36,compression)
	var second: float = smoothstep(0.43,0.70,compression)
	x += 0.11*first*sin(v*PI)*signf(x)+0.09*second*sin(v*17)
	z += 0.11*first*sin(v*8+x)+0.08*second*sin(v*19+x*2)
	return Vector3(x,clampf(v*height()-0.035*first*(1+x/1.2)*sin(v*PI),0,height()),z)
func build_geometry() -> void:
	var h: float = height()
	var hinge: float = smoothstep(0.12,0.37,compression)
	var collapse: float = smoothstep(0.42,0.72,compression)
	for side in [-1,1]:
		for j in range(18):
			quad(wall(side*1.1,j/18.0,-0.65),wall(side*1.1,j/18.0,0.65),wall(side*1.1,(j+1)/18.0,0.65),wall(side*1.1,(j+1)/18.0,-0.65),0)
	for j in range(18):
		quad(wall(-1.1,j/18.0,-0.65),wall(1.1,j/18.0,-0.65),wall(1.1,(j+1)/18.0,-0.65),wall(-1.1,(j+1)/18.0,-0.65),0)
	box(Vector3(0,0.045,0),Vector3(2.2,0.08,1.3),0)
	box(Vector3(0.04*collapse,h-0.035,0),Vector3(2.2,0.055,1.3),0,Vector3(0.018*hinge,0.03*collapse,0))
	# Door rotates around its lower edge. Upper edge sinks into the oven cavity.
	var a: float = hinge*0.72+collapse*0.66
	var door_h: float = minf(0.97,(h-0.07)/maxf(0.16,cos(a)))
	var center := Vector3(-0.20+0.09*collapse,0.045+cos(a)*door_h*0.5,0.70-sin(a)*door_h*0.5)
	var rot := Vector3(-a,collapse*0.10,hinge*0.035)
	box(center,Vector3(1.65,door_h,0.085),1,rot)
	var basis := Basis.from_euler(rot)
	box(center+basis*Vector3(-0.10,0,0.049),Vector3(1.19,door_h*0.66,0.012),2,rot)
	box(center+basis*Vector3(0.66,0,0.12),Vector3(0.06,door_h*0.65,0.10),3,rot)
	# Fine dark window grille remains attached to the independent door.
	for i in range(7):
		box(center+basis*Vector3(-0.62+i*0.17,0,0.061),Vector3(0.015,door_h*0.61,0.008),1,rot)
	box(Vector3(0.88,h*0.50,0.64-0.12*collapse),Vector3(0.34,h*0.89,0.08),0,Vector3(0,0,collapse*0.18))
	box(Vector3(0.88,h*0.76,0.692-0.12*collapse),Vector3(0.26,h*0.12,0.015),1)
	for i in range(4):
		box(Vector3(0.88,h*(0.21+i*0.11),0.70-0.12*collapse),Vector3(0.16,0.028,0.018),3)
