extends RefCounted
const ITEMS = {
	"cardboard":{"name":"CARDBOARD BOX","material":"Corrugated paper","base":24,"difficulty":1.0,"bonus":6,"recommended":80,"max_c":0.90,"level":1},
	"aluminum":{"name":"ALUMINUM CAN","material":"Aluminum","base":36,"difficulty":1.4,"bonus":9,"recommended":100,"max_c":0.90,"level":1},
	"tire":{"name":"RUBBER TIRE","material":"Elastic rubber","base":50,"difficulty":1.8,"bonus":12,"recommended":100,"max_c":0.66,"level":2},
	"bottle":{"name":"PLASTIC BOTTLE","material":"PET packaging","base":30,"difficulty":1.0,"bonus":7,"recommended":80,"max_c":0.82,"level":1},
	"crate":{"name":"WOODEN CRATE","material":"Wood / nailed joints","base":72,"difficulty":1.8,"bonus":20,"recommended":140,"max_c":0.80,"level":3},
	"pc":{"name":"PC TOWER","material":"Steel / internal frame","base":88,"difficulty":2.0,"bonus":24,"recommended":140,"max_c":0.82,"level":3},
	"microwave":{"name":"MICROWAVE OVEN","material":"Steel / hinged door","base":108,"difficulty":2.2,"bonus":30,"recommended":180,"max_c":0.76,"level":4}
}
const UPGRADE_COST: int = 40
const PRESSURES = [80.0,100.0,140.0,180.0]
const COSTS = [40,150,220]
const ORDER = ["bottle","cardboard","aluminum","tire","crate","pc","microwave"]
var money: int = 0
var level: int = 1
var muted: bool = false
var path: String = "user://progress.json"
var error: String = ""
var restored: bool = false

func _init() -> void:
	if not OS.get_environment("CRUSH_SAVE_PATH").is_empty(): path = OS.get_environment("CRUSH_SAVE_PATH")

func max_pressure() -> float:
	return PRESSURES[level-1]

func upgrade_cost() -> int:
	return COSTS[level-1] if level<4 else 0

func unlocked_at(at_level: int) -> Array:
	return ORDER.filter(func(id): return ITEMS[id].level==at_level)

func unlocked(id: String) -> bool:
	return ITEMS.has(id) and level>=ITEMS[id].level

func reward(id: String, peak: float) -> Dictionary:
	var item: Dictionary = ITEMS[id]
	var ratio: float = clampf(peak,0,item.max_c)
	var value: int = roundi(item.base*item.difficulty*(0.25+0.75*ratio)) if ratio>=0.005 else 0
	var bonus: int = item.bonus if ratio>=item.max_c*0.85 else 0
	return {"base":item.base,"difficulty":item.difficulty,"ratio":ratio,"value":value,"bonus":bonus,"total":value+bonus}

func snapshot() -> Dictionary:
	return {"schema":1,"money":money,"pressure_level":level,"unlocked":ORDER.filter(func(id): return unlocked(id)),"settings":{"muted":muted}}

func load_save() -> bool:
	if not FileAccess.file_exists(path): return true
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema")!=1:
		error = "Save unreadable. Existing progress has not been overwritten."
		return false
	if typeof(data.get("money")) not in [TYPE_INT,TYPE_FLOAT] or typeof(data.get("pressure_level")) not in [TYPE_INT,TYPE_FLOAT] or not data.get("settings",{}) is Dictionary:
		error = "Save types invalid. Existing progress has not been overwritten."
		return false
	if data.money<0 or data.money>2000000000 or data.money!=floor(data.money) or data.pressure_level!=floor(data.pressure_level) or int(data.pressure_level) not in [1,2,3,4]:
		error = "Save values invalid. Existing progress has not been overwritten."
		return false
	money = int(data.money)
	level = int(data.pressure_level)
	muted = bool(data.get("settings",{}).get("muted",false))
	restored = true
	return true

func save() -> bool:
	if not error.is_empty(): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(snapshot(),"\t"))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func upgrade() -> bool:
	var cost: int = upgrade_cost()
	if level>=4 or money<cost: return false
	money -= cost
	level += 1
	if not save():
		money += cost
		level -= 1
		return false
	return true
