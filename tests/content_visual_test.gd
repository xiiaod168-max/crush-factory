extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.progress.level = 4
	var directory: String = OS.get_environment("CRUSH_RECORD_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	for id in ["bottle","crate","pc","microwave"]:
		game.phase = "SELECT"
		assert(game.choose(id))
		var body = game.press.target
		var max_c: float = game.press.solver.profile.max_compression
		for index in range(4):
			var c: float = [0.0,0.23,0.55,max_c][index]
			game.press.solver.compression = c
			game.press.underside = game.press.TABLE+game.press.solver.height()+0.02
			body.set_compression(c,true)
			body.rebuild()
			var bounds: AABB = body.visual.mesh.get_aabb()
			assert(bounds.position.y>=-0.001 and bounds.end.y<=body.height()+0.003)
			assert(bounds.size.x<2.65 and bounds.size.z<2.0)
			await create_timer(0.15).timeout
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(directory.path_join(id+"-stage-"+str(index)+".png"))
		game.press.underside = game.press.HOME
		game.press.state = "READY"
	print("PASS content geometry: four strategies, four stages, plate and machine bounds")
	game.quit_game()
