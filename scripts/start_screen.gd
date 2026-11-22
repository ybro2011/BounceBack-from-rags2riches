extends Control

func _ready():
	if has_node("Text"):
		$Text.text = $Text.text.replace("0:00.00", GameState.time_text())

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		GameState.start_game()
