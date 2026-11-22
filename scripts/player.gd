extends CharacterBody2D


const SPEED = 80.0
const JUMP_VELOCITY = -180.0
const WALL_SLIDE_SPEED = 30.0
const WALL_JUMP_PUSH = 120.0
const DASH_SPEED = 300.0
const SLAM_RANGE = 32
const SLAM_HEIGHT = 16

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var jump_count = 0
var max_jumps = 2
var wall_jump_lock = 0.0
var dash_time = 0.0
var dash_direction = 1
var jumped = false

var coyote_frames = 6  # How many in-air frames to allow jumping
var coyote = false  # Track whether we're in coyote time or not
var last_floor = false  # Last frame's on-floor state

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound = $DashSound
@onready var dash_particles = $DashParticles

func _ready():
	$CoyoteTimer.wait_time = coyote_frames / 60.0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var wall_sliding = is_on_wall_only() and velocity.y > 0
	if wall_sliding:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

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
			jump_count = max_jumps
			jumped = true

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")

	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if Input.is_action_just_pressed("dash") and dash_time <= 0:
		dash_direction = -1 if animated_sprite.flip_h else 1
		dash_time = 0.15
		dash_sound.play()
		get_viewport().get_camera_2d().add_trauma(0.3)

	# Play animations
	if dash_time > 0:
		animated_sprite.play("dash")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	elif wall_sliding:
		animated_sprite.play("wall_slide")
	elif wall_jump_lock > 0:
		animated_sprite.play("wall_jump")
	elif velocity.y < 0:
		animated_sprite.play("jump")
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
		if was_in_air and jumped:
			slam()
		jumped = false

	if !is_on_floor() and last_floor and !jumped:
		coyote = true
		$CoyoteTimer.start()
	last_floor = is_on_floor()

func _on_coyote_timer_timeout():
	coyote = false

func slam():
	for tax_collector in get_tree().get_nodes_in_group("tax_collectors"):
		var distance = tax_collector.global_position - global_position
		if abs(distance.x) <= SLAM_RANGE and abs(distance.y) <= SLAM_HEIGHT:
			tax_collector.get_busted()

func is_dashing():
	return dash_time > 0
