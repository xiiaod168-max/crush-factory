extends Control
var object_id: String = "tire"
var item: String = "tire"
func _draw() -> void:
	if object_id!="tire":
		var center := size*0.5
		var dimensions := Vector2(130,76) if object_id=="microwave" else Vector2(100,85)
		draw_rect(Rect2(center-dimensions*0.5,dimensions),Color("d6b762"),false,4)
		if object_id=="crate":
			for i in range(3): draw_line(center+Vector2(-48,-25+i*25),center+Vector2(48,-25+i*25),Color("d6b762"),5)
		else: draw_rect(Rect2(center+Vector2(-50,-27),Vector2(78,52)),Color("d6b762"),false,2)
		return
	var center: Vector2 = size*0.5
	var radius: float = minf(size.x,size.y)*0.43
	if item=="tire":
		draw_circle(center,radius,Color("a6aaa1"))
		draw_circle(center,radius*0.86,Color("303a3e"))
		draw_circle(center,radius*0.52,Color("c3c5b7"))
		draw_circle(center,radius*0.43,Color("121b1f"))
		for i in range(22):
			var v := Vector2.from_angle(i*TAU/22)
			draw_line(center+v*radius*0.88,center+v*radius*0.98,Color("525e61"),3)
