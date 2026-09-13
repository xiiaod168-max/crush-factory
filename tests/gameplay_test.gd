extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.press.set_physics_process(false)
	assert(game.phase=="SELECT" and not game.collect() and not game.choose("tire"))
	assert(game.choose("cardboard") and not game.choose("aluminum"))
	game.toggle_press()
	game.toggle_press()
	assert(game.press.state=="PAUSED" and not game.collect() and not game.buy_upgrade())
	game.new_object()
	assert(game.phase=="RUNNING")
	game.return_press()
	for i in range(600):
		game.press._physics_process(1.0/60)
		game._process(1.0/60)
	assert(game.phase=="RESULT" and game.settlement.total==0)
	game.progress.error = "Simulated unavailable save"
	assert(not game.collect() and game.phase=="RESULT" and game.progress.money==0)
	game.progress.error = ""
	game.panel_content.get_child(game.panel_content.get_child_count()-1).pressed.emit()
	assert(game.phase=="COLLECTED" and not game.collect())
	game.progress.money = 40
	game.show_upgrade()
	game.purchase_button.pressed.emit()
	assert(game.progress.level==2 and game.progress.money==0 and not game.buy_upgrade())
	game.hud.unlock()
	game.hud.dismiss_unlock()
	game.toggle_sound()
	assert(game.progress.muted)
	assert(game.choose("tire"))
	game.toggle_press()
	game.queue_free()
	await process_frame
	var restored = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	assert(restored.phase=="SELECT" and restored.object_id.is_empty() and not restored.collect())
	assert(restored.progress.level==2 and restored.progress.money==0 and restored.progress.muted)
	restored.queue_free()
	await create_timer(0.5).timeout
	print("PASS gameplay: lifecycle guards, pause, early return, zero reward, failed save rollback, signal-safe panels, single collect, upgrade, settings, abandoned scene reload")
	quit()
