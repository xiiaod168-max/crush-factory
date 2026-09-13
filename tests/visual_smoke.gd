extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.add_child(load("res://scenes/main.tscn").instantiate())
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://records/m0-window.png")
	print("PASS window rendering and screenshot")
	quit()
