extends Node2D

const SPEED = 30

var direction = 1

@export var Bullet : PackedScene

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var ray_cast_floor_right = $RayCastFloorRight
@onready var ray_cast_floor_left = $RayCastFloorLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var gun = $Gun
@onready var hitbox = $Hitbox
@onready var shoot_sound = $ShootSound
@onready var game_manager = %GameManager

func _ready():
	if GameState.is_taken(name):
		remove_from_group("tax_collectors")
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ray_cast_right.is_colliding() or not ray_cast_floor_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding() or not ray_cast_floor_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta

	gun.flip_h = animated_sprite.flip_h
	gun.position.x = -4 - gun.texture.get_width() if direction < 0 else 4

	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_dashing() and hitbox.overlaps_body(player):
		get_busted()

func _on_shoot_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player or GameState.dying:
		return
	var distance = player.global_position - global_position
	if abs(distance.y) < 16 and abs(distance.x) < 140 and sign(distance.x) == direction:
		shoot()

func shoot():
	var b = Bullet.instantiate()
	owner.add_child(b)
	b.global_position = gun.global_position + Vector2(0, 3)
	b.direction = direction
	shoot_sound.play()

func get_busted():
	var burst = preload("res://scenes/burst.tscn").instantiate()
	burst.global_position = global_position + Vector2(0, -8)
	owner.add_child(burst)
	get_viewport().get_camera_2d().add_trauma(0.5)
	game_manager.bust(self)
