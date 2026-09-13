extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.press.set_physics_process(false)
	assert(game.press.fast_approach and game.press.return_speed>1)
	assert(not game.hud.debug.visible)
	var key := InputEventKey.new()
	key.keycode = KEY_F3
	key.pressed = true
	game._unhandled_input(key)
	assert(game.hud.debug.visible)
	game._unhandled_input(key)
	assert(not game.hud.debug.visible)
	game.choose("cardboard")
	game._process(0.016)
	assert(game.hud.primary.text=="PRESS")
	game.hud.primary.pressed.emit()
	game._process(0.016)
	assert(game.hud.primary.text=="PAUSE")
	game.limit_reached = true
	game._process(0.016)
	assert(game.hud.primary.text=="RETURN")
	game.hud.primary.pressed.emit()
	game._process(0.016)
	# No movement took place: zero-value settlement is still a valid completed job.
	game.press._physics_process(0.016)
	game._process(0.016)
	assert(game.phase=="RESULT")
	game.settlement.total = 40
	game.progress.error = "Simulated save unavailable"
	assert(not game.collect() and not game.hud.reward_label.visible)
	game.progress.error = ""
	assert(game.collect() and game.hud.reward_label.visible)
	assert(game.hud.display_money<game.progress.money and not game.collect())
	await create_timer(0.8).timeout
	assert(absf(game.hud.display_money-40)<0.01)
	assert(game.buy_upgrade() and game.hud.moment=="UPGRADE")
	assert(not game.safe_to_change() and not game.choose("cardboard") and not game.buy_upgrade())
	game.hud.moment_button.pressed.emit()
	assert(game.hud.moment=="UNLOCK")
	game.hud.moment_button.pressed.emit()
	assert(game.phase=="LOADED" and game.object_id=="tire")
	assert(game.feedback.tones.size()==3)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS slice: primary action hierarchy, debug toggle, failed-save silence, visible reward and count-up, separate upgrade/unlock, try-tire, duplicate guards")
	quit()
