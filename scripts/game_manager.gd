extends Node

@onready var debt_label = $HUD/DebtLabel
@onready var message_label = $HUD/MessageLabel
@onready var time_label = $HUD/TimeLabel
@onready var level_label = $HUD/LevelLabel
@onready var level_name_label = $HUD/LevelNameLabel
@onready var level_bar = $HUD/LevelBar
@onready var cash_sound = $CashSound
@onready var message_labels = [message_label]

func _ready():
	level_label.text = "LEVEL %d/%d" % [GameState.level, GameState.level_count()]
	level_name_label.text = GameState.LEVEL_NAMES[GameState.level - 1]
	for i in GameState.level_count():
		var box = ColorRect.new()
		box.custom_minimum_size = Vector2(0, 4)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i + 1 < GameState.level:
			box.color = Color(1, 0.3, 0.7)
		elif i + 1 == GameState.level:
			box.color = Color(1, 1, 1)
		else:
			box.color = Color(1, 1, 1, 0.2)
		level_bar.add_child(box)

func _process(_delta):
	debt_label.text = "DEBT " + GameState.money(GameState.debt)
	while message_labels.size() < GameState.messages.size():
		var label = message_label.duplicate()
		$HUD.add_child(label)
		message_labels.append(label)
	for i in message_labels.size():
		var label = message_labels[i]
		label.visible = i < GameState.messages.size()
		if label.visible:
			label.text = GameState.messages[i].text
			label.modulate = GameState.messages[i].color
			label.position.y = 37 + i * 10
	time_label.text = GameState.time_text()
	if Input.is_action_just_pressed("reset"):
		GameState.start_game()

func can_score():
	return not GameState.dying and GameState.debt > 0

func add_money(bag_name):
	if can_score():
		GameState.collect(bag_name)
		return true
	return false

func bust(tax_collector):
	if not can_score():
		return
	cash_sound.play()
	GameState.bust(tax_collector.name)
	tax_collector.remove_from_group("tax_collectors")
	tax_collector.queue_free()
	if get_tree().get_nodes_in_group("tax_collectors").is_empty():
		GameState.level_cleared()
