extends CanvasLayer
## Presentation owns controls and animations; money is committed by gameplay first.
const YELLOW := Color("e3b84b")
const WHITE := Color("e7e6dc")
const MUTED := Color("9ca7a8")
var game: Node3D
var wallet: Label
var object_label: Label
var compression: Label
var hint: Label
var debug: Label
var panel: PanelContainer
var content: VBoxContainer
var reward_label: Label
var primary: Button
var secondary: Button
var moment_button: Button
var moment: String = ""
var display_money: float = 0
var reward_tween: Tween
var all_buttons: Dictionary = {}
var last_action: String = ""
func text(value: String, size: int, parent: Node, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label
func style(bg: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = Color("626c67")
	result.set_border_width_all(1)
	result.content_margin_left = 18
	result.content_margin_right = 18
	return result
func button(value: String, action: Callable, parent: Node, strong: bool = false) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(0,48)
	b.add_theme_font_size_override("font_size",17)
	var base: Color = YELLOW if strong else Color("253138")
	b.add_theme_stylebox_override("normal",style(base))
	b.add_theme_stylebox_override("hover",style(base.lightened(0.12)))
	b.add_theme_stylebox_override("pressed",style(base.darkened(0.1)))
	b.add_theme_stylebox_override("disabled",style(Color("1b252a")))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = WHITE
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus",focus)
	for key in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
		b.add_theme_color_override(key,Color("172025") if strong else WHITE)
	b.add_theme_color_override("font_disabled_color",Color("677476"))
	b.pressed.connect(action)
	parent.add_child(b)
	return b
func _ready() -> void:
	display_money = game.progress.money
	var header := ColorRect.new()
	header.size = Vector2(1280,76)
	header.color = Color("11181b")
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	text("CRUSH FACTORY",26,self).position = Vector2(30,16)
	text("HYDRAULIC RECYCLING",11,self,MUTED).position = Vector2(32,48)
	wallet = text("",25,self,YELLOW)
	wallet.position = Vector2(850,17)
	object_label = text("",20,self)
	object_label.position = Vector2(32,107)
	compression = text("",34,self,YELLOW)
	compression.position = Vector2(32,139)
	debug = text("",14,self)
	debug.position = Vector2(32,215)
	debug.visible = false
	panel = PanelContainer.new()
	panel.position = Vector2(924,111)
	panel.custom_minimum_size = Vector2(326,400)
	var skin = style(Color(0.065,0.095,0.11,0.98))
	skin.content_margin_top = 20
	skin.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel",skin)
	add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	panel.add_child(content)
	game.panel = panel
	game.panel_content = content
	hint = text("",17,self)
	hint.position = Vector2(350,586)
	primary = button("PRESS",main_action,self,true)
	primary.position = Vector2(350,620)
	primary.custom_minimum_size = Vector2(270,56)
	primary.add_theme_font_size_override("font_size",22)
	secondary = button("RETURN",game.return_press,self)
	secondary.position = Vector2(632,620)
	secondary.custom_minimum_size = Vector2(140,56)
	var upgrade = button("UPGRADE",game.show_upgrade,self)
	upgrade.position = Vector2(32,620)
	upgrade.custom_minimum_size.x = 160
	all_buttons.upgrades = upgrade
	var sound = button("SOUND",game.toggle_sound,self)
	sound.position = Vector2(1000,632)
	sound.custom_minimum_size = Vector2(110,34)
	sound.add_theme_font_size_override("font_size",12)
	all_buttons.sound = sound
	var quit_button = button("QUIT",game.quit_game,self)
	quit_button.position = Vector2(1120,632)
	quit_button.custom_minimum_size = Vector2(130,34)
	quit_button.add_theme_font_size_override("font_size",12)
	text("SPACE press / pause     R return     C collect     F3 debug     RMB orbit",11,self,MUTED).position = Vector2(350,692)
	reward_label = text("",32,self,YELLOW)
	reward_label.position = Vector2(850,90)
	reward_label.hide()
	# The same visible primary control performs the current allowed operation.
	game.action_buttons = {"press":primary,"collect":primary,"new_object":primary,"return_button":secondary,"upgrades":upgrade,"sound":sound}
func main_action() -> void:
	if not moment.is_empty(): return
	match game.phase:
		"LOADED": game.toggle_press()
		"RUNNING":
			if game.limit_reached or game.press.state=="COMPACTED": game.return_press()
			else: game.toggle_press()
		"RESULT": game.collect()
		"SELECT","COLLECTED": game.new_object()
func refresh(_dt: float) -> void:
	if reward_tween==null or not reward_tween.is_running(): display_money = game.progress.money
	wallet.text = "%04d   COINS     /     LEVEL %d" % [roundi(display_money),game.progress.level]
	object_label.text = game.progress.ITEMS[game.object_id].name if not game.object_id.is_empty() else "YOUR NEXT CRUSH"
	compression.text = "%02d%%  COMPRESSED" % roundi(game.press.solver.compression*100) if not game.object_id.is_empty() else "SELECT AN OBJECT"
	compression.add_theme_font_size_override("font_size",24 if game.object_id.is_empty() else 30)
	debug.text = "PHASE %s\nSOLVER %s\nLOAD %.1f / PRESSURE %.0f\nHEIGHT %.0f mm / PEAK %.1f%%\n%s" % [game.phase,game.press.state,game.press.solver.resistance,game.press.pressure,game.press.solver.height()*1000,game.peak*100,game.progress.ITEMS.get(game.object_id,{"material":""}).material]
	var action: String = "NEW OBJECT"
	var instruction: String = "Choose something. Crush it. Get paid."
	match game.phase:
		"LOADED": action = "PRESS"; instruction = "Ready when you are."
		"RUNNING":
			if game.limit_reached:
				action = "RETURN"; instruction = "At the limit. Upgrade for a deeper crush."
			elif game.press.state=="COMPACTED": action = "RETURN"; instruction = "Crush complete. Bring the press back."
			elif game.press.state=="PAUSED": action = "CONTINUE"; instruction = "Paused. Continue or return to recycle."
			else: action = "PAUSE"; instruction = "Pressure on."
		"UNLOADING": action = "UNLOADING"; instruction = "Let the rubber rebound." if game.tire else "Returning to ready."
		"RESULT": action = "COLLECT  +%d" % game.settlement.total; instruction = "Your work. Your reward."
		"COLLECTED": instruction = "Keep recycling — the next object is free."
	if not moment.is_empty(): action = "UPGRADED"; instruction = "A stronger machine. A new material."
	primary.text = action
	primary.disabled = game.phase=="UNLOADING" or not moment.is_empty()
	secondary.visible = game.phase=="RUNNING" and action!="RETURN" or game.phase=="LOADED"
	secondary.disabled = not moment.is_empty()
	all_buttons.upgrades.disabled = not game.safe_to_change()
	all_buttons.upgrades.text = "UPGRADE / %d" % game.progress.upgrade_cost() if game.progress.level<4 else "LEVEL 4 / MAX"
	all_buttons.sound.text = "SOUND OFF" if game.progress.muted else "SOUND ON"
	hint.text = game.notice if game.notice_time>0 and (game.notice.begins_with("SAVE") or not game.progress.error.is_empty()) else instruction
	if last_action!=action and not primary.disabled and game.phase=="RESULT": primary.grab_focus()
	last_action = action
func clear_panel() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	game.item_buttons.clear()
	game.purchase_button = null
	panel.show()
func show_selection() -> void:
	if not game.safe_to_change(): return
	clear_panel()
	game.menu = "SELECT"
	text("CHOOSE YOUR\nNEXT CRUSH",27,content,YELLOW)
	text("Free objects. Real progress.",14,content,MUTED)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(288,290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",7)
	scroll.add_child(list)
	for id in game.progress.ORDER:
		var item: Dictionary = game.progress.ITEMS[id]
		var b = button(item.name if game.progress.unlocked(id) else "%s / L%d" % [item.name,item.level],game.choose.bind(id),list)
		b.add_theme_font_size_override("font_size",15)
		b.disabled = not game.progress.unlocked(id)
		game.item_buttons[id] = b
		text("%s · %d coins" % [item.material,item.base],12,list,MUTED)
		text("Recommended pressure %d" % item.recommended,11,list,MUTED)
	text("Scroll for heavier salvage. Objects are free.",12,content,YELLOW)

func show_result() -> void:
	clear_panel()
	game.menu = "RESULT"
	text("CRUSH\nCOMPLETE",34,content,YELLOW)
	text(game.progress.ITEMS[game.object_id].name,17,content)
	text("%.0f%%\nPEAK COMPRESSION" % (game.peak*100),24,content)
	text("Recycle value       %d\nCompletion bonus  +%d" % [game.settlement.value,game.settlement.bonus],16,content,MUTED)
	text("%d COINS" % game.settlement.total,34,content,YELLOW)
	text("Rubber reward uses peak compression." if game.tire else "A tighter crush earns more.",12,content,MUTED)
	button("COLLECT",game.collect,content,true)
func show_upgrade() -> void:
	if not game.safe_to_change(): return
	clear_panel()
	game.menu = "UPGRADES"
	text("MORE\nPRESSURE",34,content,YELLOW)
	var level: int = game.progress.level
	if level<4:
		text("LEVEL %d  →  LEVEL %d" % [level,level+1],21,content)
		text("MAX PRESSURE   %d → %d" % [game.progress.max_pressure(),game.progress.PRESSURES[level]],19,content)
		for id in game.progress.unlocked_at(level+1): text("Unlock: "+game.progress.ITEMS[id].name,16,content)
		text("%d COINS" % game.progress.upgrade_cost(),32,content,YELLOW)
		game.purchase_button = button("UPGRADE PRESS",game.buy_upgrade,content,true)
		game.purchase_button.disabled = game.progress.money<game.progress.upgrade_cost()
		text("Free objects always earn more coins.",13,content,MUTED)
	else: text("LEVEL 4 / MAX PRESSURE 180\n\nAll seven objects unlocked.",18,content)

	button("BACK",show_selection,content)
func reward(amount: int) -> void:
	if reward_tween: reward_tween.kill()
	reward_label.text = "+%d COINS" % amount
	reward_label.position = Vector2(350,550)
	reward_label.modulate.a = 1
	reward_label.show()
	reward_tween = create_tween().set_parallel(true)
	reward_tween.tween_property(self,"display_money",float(game.progress.money),0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reward_tween.tween_property(reward_label,"position:y",528.0,0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reward_tween.tween_property(reward_label,"modulate:a",0.0,0.4).set_delay(1.0)
	game.feedback.play("collect",game.progress.muted)
func upgraded() -> void:
	moment = "UPGRADE"
	clear_panel()
	text("PRESS\nUPGRADED",36,content,YELLOW)
	text("LEVEL %d  →  LEVEL %d" % [game.progress.level-1,game.progress.level],24,content)
	text("MAX PRESSURE",13,content,MUTED)
	text("%d  →  %d" % [game.progress.PRESSURES[game.progress.level-2],game.progress.max_pressure()],38,content)
	text("More force. Deeper compression.",15,content,MUTED)
	moment_button = button("SEE WHAT YOU UNLOCKED",unlock,content,true)
	game.feedback.play("upgrade",game.progress.muted)
	game.workshop.pulse = 1.4
	panel.scale = Vector2(0.98,0.98)
	create_tween().tween_property(panel,"scale",Vector2.ONE,0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	moment_button.grab_focus()
func unlock() -> void:
	moment = "UNLOCK"
	clear_panel()
	text("NEW OBJECT\nUNLOCKED",27,content,YELLOW)
	var icon = preload("res://scripts/material_icon.gd").new()
	icon.object_id = game.progress.unlocked_at(game.progress.level)[0]
	icon.custom_minimum_size = Vector2(0,110)
	content.add_child(icon)
	for id in game.progress.unlocked_at(game.progress.level): text(game.progress.ITEMS[id].name,23,content)
	text("New structures. New ways to break.",14,content,MUTED)
	moment_button = button("TRY IT NOW",try_tire,content,true)
	button("BACK TO OBJECTS",dismiss_unlock,content)
	game.feedback.play("unlock",game.progress.muted)
	moment_button.grab_focus()
func dismiss_unlock() -> void:
	moment = ""
	show_selection()
func try_tire() -> void:
	moment = ""
	game.choose(game.progress.unlocked_at(game.progress.level)[0])
