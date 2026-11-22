extends Control

func _ready():
	$Title.text = "LEVEL " + str(GameState.level) + " CLEARED!"
	$Text.text = GameState.LEVEL_NAMES[GameState.level - 1] + "\n\nTAX MEN BUSTED: " + str(GameState.level_busts) + "\nMONEY BAGS: " + str(GameState.level_bags) + "\nDEBT LEFT: " + GameState.money(GameState.debt) + "\nTIME: " + GameState.time_text() + "\n\nNEXT UP: " + GameState.LEVEL_NAMES[GameState.level] + "\nPRESS ENTER"

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		GameState.next_level()
