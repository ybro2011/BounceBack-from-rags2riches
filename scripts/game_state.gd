extends Node

const START_DEBT = 1000000
const BUST_REWARD = 10000
const BAG_REWARD = 2000
const CLEAR_REWARD = 20000
const LEVEL_NAMES = ["SOUTH BEACH", "OCEAN DRIVE", "LITTLE HAVANA", "THE DOCKS", "ROOFTOPS", "CONSTRUCTION SITE", "BAYSIDE MARKET", "THE TOWER", "DOWNTOWN", "THE IRS BUILDING"]
const HIT_PENALTY = 5000

var debt = START_DEBT
var level = 1
var taken = []
var level_busts = 0
var level_bags = 0
var dying = false
var messages = []
var time = 0.0
var timer_running = false

func _process(delta):
	if timer_running:
		time += delta
	for m in messages.duplicate():
		m.time -= delta
		if m.time <= 0:
			messages.erase(m)

func start_game():
	debt = START_DEBT
	taken.clear()
	messages.clear()
	dying = false
	time = 0.0
	timer_running = true
	Engine.time_scale = 1.0
	level = 1
	level_busts = 0
	level_bags = 0
	get_tree().change_scene_to_file(level_path())

func level_path():
	return "res://scenes/levels/level_%d.tscn" % level

func level_count():
	return LEVEL_NAMES.size()

func is_taken(thing_name):
	return taken.has(thing_name)

func collect(bag_name):
	taken.append(bag_name)
	level_bags += 1
	change_debt(-BAG_REWARD, "MONEY BAG")

func bust(tax_collector_name):
	taken.append(tax_collector_name)
	level_busts += 1
	change_debt(-BUST_REWARD, "TAX MAN BUSTED")

func level_cleared():
	if debt == 0:
		return
	taken.clear()
	if level == level_count():
		change_debt(-debt, "DEBT PAID OFF")
		return
	change_debt(-CLEAR_REWARD, "LEVEL CLEARED")
	if debt > 0:
		timer_running = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/level_clear.tscn")

func next_level():
	level += 1
	timer_running = true
	level_busts = 0
	level_bags = 0
	get_tree().change_scene_to_file(level_path())

func kill_player(player, reason):
	if dying:
		return
	dying = true
	Engine.time_scale = 0.5
	player.get_hurt()
	var scene = get_tree().current_scene
	await get_tree().create_timer(0.6).timeout
	Engine.time_scale = 1.0
	dying = false
	if get_tree().current_scene == scene:
		change_debt(HIT_PENALTY, reason)
		player.respawn()

func change_debt(amount, why):
	debt = max(0, debt + amount)
	var text = ("+" if amount > 0 else "-") + money(abs(amount)) + "  " + why
	var color = Color(1, 0.35, 0.4) if amount > 0 else Color(0.4, 1, 0.5)
	messages.append({"text": text, "color": color, "time": 1.6})
	if messages.size() > 6:
		messages.pop_front()
	if debt == 0:
		timer_running = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/win_screen.tscn")

func money(amount):
	var digits = str(amount)
	var text = ""
	while digits.length() > 3:
		text = "," + digits.right(3) + text
		digits = digits.left(-3)
	return "$" + digits + text

func time_text():
	var hundredths = int(time * 100)
	return "%d:%02d.%02d" % [hundredths / 6000, hundredths / 100 % 60, hundredths % 100]
