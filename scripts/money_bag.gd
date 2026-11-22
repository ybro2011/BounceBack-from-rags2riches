extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

func _ready():
	if GameState.is_taken(name):
		queue_free()

func _on_body_entered(body):
	game_manager.add_money(name)
	animation_player.play("pickup")
