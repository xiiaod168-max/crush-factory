extends "res://scripts/content_body.gd"
## Rigid slats detach at nails, hinge inward and split; they do not behave like cardboard walls.
func _init() -> void:
	initial_height = 1.5
	width = 1.95
	depth = 1.42
	material("a97742")
	material("c79c5c")
	material("423124")
func build_geometry() -> void:
	var c: float = compression
	var joint: float = smoothstep(0.12,0.30,c)
	var fracture: float = smoothstep(0.39,0.63,c)
	var h: float = height()
	for side in range(4):
		var angle: float = side*PI/2
		var outward: Vector3 = Vector3(sin(angle),0,cos(angle))
		var across: Vector3 = Vector3(cos(angle),0,-sin(angle))
		var span: float = 1.9 if side%2==0 else 1.38
		var distance: float = 0.66 if side%2==0 else 0.90
		for row in range(4):
			var v: float = (row+0.5)/4
			var tilt: float = joint*(0.20 if side%2 else -0.32)*(0.6+v)+fracture*(row%2-0.5)*0.35
			for half in range(2):
				var offset: float = (half-0.5)*span*0.5
				var y: float = 0.09+(h-0.18)*v + fracture*(half-0.5)*0.11*(1 if row%2 else -1)
				var center: Vector3 = outward*(distance-joint*0.14*sin(v*PI))+across*offset+Vector3.UP*y
				var rot := Vector3(tilt,angle,fracture*(half-0.5)*0.44*(1 if side%2 else -1))
				box(center,Vector3(span*0.5-0.016,minf(0.27,h*0.26),0.075),row%2,rot)
				# Dark end grain and a recessed nail at each failed connection.
				box(center+outward*0.045+across*(span*0.21),Vector3(0.025,0.025,0.015),2,Vector3(0,angle,0))
	for i in range(4):
		var x: float = 0.83*(1 if i&1 else -1)
		var z: float = 0.59*(1 if i&2 else -1)
		for half in range(2):
			var y: float = h*(0.27+half*0.46)
			box(Vector3(x*(1-0.12*joint),y,z),Vector3(0.13,h*0.5,0.13),2,Vector3(fracture*0.28*(1 if i&2 else -1),0,joint*0.34*(1 if i&1 else -1)))
	for i in range(5):
		var x: float = (i-2)*0.36
		box(Vector3(x,0.055,0),Vector3(0.33,0.10,1.38),0)
		box(Vector3(x+joint*0.07*sin(i),h-0.055,0.06*fracture),Vector3(0.33,0.10,1.38),1,Vector3(joint*0.05*sin(i),fracture*0.12*sin(i*2),fracture*0.08*cos(i)))
