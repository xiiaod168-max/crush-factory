extends SceneTree
func _initialize() -> void:
	var script = load("res://scripts/progress.gd")
	var p = script.new()
	# Real M5 schema remains readable; unlocks are derived from validated pressure level.
	FileAccess.open(p.path,FileAccess.WRITE).store_string(JSON.stringify({"schema":1,"money":83,"pressure_level":2,"unlocked":["cardboard","aluminum","tire"],"settings":{"muted":true}}))
	assert(p.load_save() and p.money==83 and p.level==2 and p.muted)
	assert(p.unlocked("tire") and p.unlocked("bottle") and not p.unlocked("pc"))
	p.money = 370
	assert(p.upgrade() and p.level==3 and p.money==220 and p.max_pressure()==140)
	assert(p.unlocked("crate") and p.unlocked("pc") and not p.unlocked("microwave"))
	assert(p.upgrade() and p.level==4 and p.money==0 and p.max_pressure()==180)
	assert(p.unlocked("microwave") and not p.upgrade())
	var disk = script.new()
	assert(disk.load_save() and disk.level==4 and disk.money==0 and disk.muted)
	assert(disk.snapshot().unlocked.size()==7)
	p.level = 3
	p.money = 220
	p.error = "forced save failure"
	assert(not p.upgrade() and p.level==3 and p.money==220)
	for id in p.ORDER:
		assert(p.reward(id,0).total==0)
		assert(p.reward(id,p.ITEMS[id].max_c).total>p.reward(id,0.20).total)
	print("PASS M5 save migration, four levels, exact debit, unlocks, max-level guard, write-failure rollback, seven rewards")
	quit()
