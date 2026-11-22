extends Area2D

@export var reason = "HOSPITAL BILL"
@export var dodge_with_dash = false

func _on_body_entered(body):
	if dodge_with_dash and (body.is_dashing() or body.invulnerable_time > 0):
		return
	print("You died!")
	GameState.kill_player(body, reason)
