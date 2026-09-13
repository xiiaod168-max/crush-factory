extends SceneTree
var failures: Array[String] = []
var game: Node3D
func _initialize() -> void:
	call_deferred("run")
func click(b: Button) -> void:
	var position: Vector2 = b.get_global_rect().get_center()
	for pressed in [true,false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = position
		e.global_position = position
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
func key(code: Key) -> void:
	for pressed in [true,false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		await process_frame
		if code==KEY_SPACE: print("SPACE pressed=",pressed," state=",game.press.state)
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.4).timeout
	await click(game.item_buttons.cardboard)
	check(game.phase=="LOADED","Mouse hit did not select cardboard")
	await click(game.hud.primary)
	check(game.press.state=="PRESSING","Primary mouse hit did not start press")
	await key(KEY_SPACE)
	check(game.press.state=="PAUSED","Space did not pause")
	await key(KEY_F3)
	check(game.hud.debug.visible,"F3 dispatch failed")
	root.size = Vector2i(1024,576)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://records/m6-review01/input-debug-small.png")
	await key(KEY_F3)
	check(not game.hud.debug.visible,"F3 did not hide debug")
	await key(KEY_R)
	await create_timer(1).timeout
	check(game.phase=="RESULT","R did not return to settlement")
	await key(KEY_C)
	check(game.phase=="COLLECTED","C did not collect")
	var money: int = game.progress.money
	await key(KEY_C)
	check(game.progress.money==money,"Repeated keyboard collect duplicated reward")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://records/m6-review01/input-small.png")
	FileAccess.open("res://records/m6-review01/input-dispatch.json",FileAccess.WRITE).store_string(JSON.stringify({"input":"Godot Input.parse_input_event; not OS SendInput","window":"1024x576","failures":failures},"\t"))
	root.size = Vector2i(1280,720)
	game.progress.level = 4
	game.new_object()
	await create_timer(0.3).timeout
	var last: Button = game.item_buttons.microwave
	var scroll: ScrollContainer = last.get_parent().get_parent()
	scroll.ensure_control_visible(last)
	await create_timer(0.2).timeout
	check(scroll.scroll_vertical>0,"Seven-object catalog did not scroll")
	await click(last)
	check(game.object_id=="microwave" and game.phase=="LOADED","Scrolled microwave mouse hit failed")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://records/m6-review01/input-microwave.png")
	FileAccess.open("res://records/m6-review01/input-dispatch.json",FileAccess.WRITE).store_string(JSON.stringify({"input":"Godot Input.parse_input_event; not OS SendInput","window":"1280x720 and 1024x576","scrolled_object":"microwave","failures":failures},"\t"))
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS engine mouse/key dispatch and small window" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
