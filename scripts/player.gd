extends CharacterBody2D


const SPEED = 80.0
const JUMP_VELOCITY = -180.0
const WALL_SLIDE_SPEED = 20.0
const WALL_JUMP_PUSH = 120.0
const DASH_SPEED = 300.0
const DASH_COOLDOWN = 0.6
const SLAM_RANGE = 48
const SLAM_HEIGHT = 24

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var jump_count = 0
var max_jumps = 3
var wall_jump_lock = 0.0
var dash_time = 0.0
var dash_direction = 1
var dash_cooldown = 0.0
var can_air_dash = true
var jumped = false
var land_time = 0.0
var double_jump_time = 0.0
var attack_time = 0.0
var attack_anim = ""
var climbing = false
var hurt = false
var invulnerable_time = 0.0
var safe_position = Vector2.ZERO

var coyote_frames = 10  # How many in-air frames to allow jumping
var coyote = false  # Track whether we're in coyote time or not
var last_floor = false  # Last frame's on-floor state

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound = $DashSound
@onready var dash_particles = $DashParticles

func _ready():
	$CoyoteTimer.wait_time = coyote_frames / 60.0
	safe_position = global_position

func _physics_process(delta):
	invulnerable_time -= delta
	animated_sprite.modulate.a = 0.5 if invulnerable_time > 0 else 1.0
	if climbing or hurt:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var wall_sliding = is_on_wall_only() and velocity.y > 0
	if wall_sliding:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		jump_count = 1

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote:
			velocity.y = JUMP_VELOCITY
			jump_count = 1
			jumped = true
			coyote = false
		elif wall_sliding:
			velocity.y = JUMP_VELOCITY
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSH
			wall_jump_lock = 0.2
			jumped = true
		elif jump_count < max_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			jumped = true
			double_jump_time = 0.25
			animated_sprite.play("double_jump")
			animated_sprite.frame = 0

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")

	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	dash_cooldown -= delta
	if Input.is_action_just_pressed("dash") and dash_time <= 0 and dash_cooldown <= 0 and (is_on_floor() or can_air_dash):
		if not is_on_floor():
			can_air_dash = false
		dash_cooldown = DASH_COOLDOWN
		dash_direction = -1 if animated_sprite.flip_h else 1
		dash_time = 0.15
		dash_sound.play()
		get_viewport().get_camera_2d().add_trauma(0.3)

	land_time -= delta
	double_jump_time -= delta
	attack_time -= delta

	# Play animations
	if attack_time > 0:
		animated_sprite.play(attack_anim)
	elif dash_time > 0:
		animated_sprite.play("dash")
	elif is_on_floor():
		if land_time > 0 and direction == 0:
			animated_sprite.play("land")
		elif direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	elif wall_sliding:
		animated_sprite.play("wall_slide")
	elif wall_jump_lock > 0:
		animated_sprite.play("wall_jump")
	elif double_jump_time > 0:
		animated_sprite.play("double_jump")
	elif velocity.y < 0:
		animated_sprite.play("jump")
	elif velocity.y > 150:
		animated_sprite.play("slam")
	else:
		animated_sprite.play("fall")

	# Apply movement
	if dash_time > 0:
		dash_time -= delta
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0
	elif wall_jump_lock > 0:
		wall_jump_lock -= delta
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	dash_particles.emitting = dash_time > 0

	var was_in_air = not is_on_floor()
	move_and_slide()

	if is_on_floor():
		jump_count = 0
		can_air_dash = true
		if was_in_air:
			land_time = 0.12
			if jumped:
				slam()
		jumped = false
		var floor_hit = get_last_slide_collision()
		if floor_hit and floor_hit.get_collider() is TileMapLayer:
			safe_position = global_position

	if is_on_wall() and direction == -get_wall_normal().x:
		ledge_climb(direction)

	if !is_on_floor() and last_floor and !jumped:
		coyote = true
		$CoyoteTimer.start()
	last_floor = is_on_floor()

func _on_coyote_timer_timeout():
	coyote = false

func ledge_climb(dir):
	for h in range(2, 22, 2):
		if test_move(global_transform, Vector2(0, -h)):
			return
		if not test_move(global_transform.translated(Vector2(0, -h)), Vector2(dir * 6, 0)):
			climbing = true
			velocity = Vector2.ZERO
			animated_sprite.play("climb")
			var start = global_position
			var tween = create_tween()
			tween.tween_property(self, "global_position", start + Vector2(0, -h), 0.12)
			tween.tween_property(self, "global_position", start + Vector2(dir * 6, -h), 0.08)
			tween.tween_callback(func(): climbing = false)
			return

func slam():
	for tax_collector in get_tree().get_nodes_in_group("tax_collectors"):
		var distance = tax_collector.global_position - global_position
		if abs(distance.x) <= SLAM_RANGE and abs(distance.y) <= SLAM_HEIGHT:
			tax_collector.get_busted()
			play_attack("slam_attack")

func play_attack(anim):
	attack_anim = anim
	attack_time = 0.25
	animated_sprite.play(anim)
	animated_sprite.frame = 0

func get_hurt():
	hurt = true
	velocity = Vector2.ZERO
	animated_sprite.play("hurt")
	get_viewport().get_camera_2d().add_trauma(0.4)

func respawn():
	hurt = false
	global_position = safe_position
	velocity = Vector2.ZERO
	invulnerable_time = 1.5

func is_dashing():
	return dash_time > 0
