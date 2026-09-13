extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/progress.gd")
	assert(script!=null,"Progress model exists")
	var p = script.new()
	p.path = "user://progress-test-"+str(Time.get_ticks_usec())+".json"
	assert(p.money==0 and p.level==1 and not p.unlocked("tire"))
	assert(not p.upgrade(),"Cannot buy unaffordable upgrade")
	assert(p.reward("cardboard",0).total==0,"Unprocessed objects pay nothing")
	assert(p.reward("cardboard",0.85).total>p.reward("cardboard",0.4).total,"Compression increases reward")
	p.money = 40
	assert(p.upgrade() and p.money==0 and p.level==2 and p.unlocked("tire"))
	assert(not p.upgrade(),"Upgrade cannot repeat")
	p.money = 73
	p.muted = true
	assert(p.save())
	var loaded = script.new()
	loaded.path = p.path
	var loaded_ok: bool = loaded.load_save()
	print("LOAD CHECK ",loaded_ok," ",loaded.snapshot()," error=",loaded.error)
	assert(loaded_ok and loaded.money==73 and loaded.level==2 and loaded.muted and loaded.unlocked("tire"))
	assert(not p.snapshot().has("pending_reward"),"No pending crush is persisted")
	print("PASS progress: fresh economy, reward formula, affordability, upgrade, atomic overwrite, save/load settings")
	quit()
