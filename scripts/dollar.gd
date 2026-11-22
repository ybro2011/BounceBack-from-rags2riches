extends Area2D

var speed = 90
var direction = 1

func _physics_process(delta):
	position.x += direction * speed * delta

func _on_body_entered(body):
	queue_free()

func _on_timer_timeout():
	queue_free()
