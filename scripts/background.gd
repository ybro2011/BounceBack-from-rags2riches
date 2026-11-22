extends CanvasLayer

const SEAWALL_Y = 330.0

@export var ground_y = 120.0

@onready var sky = $Sky
@onready var sun = $Sun
@onready var clouds = $Clouds
@onready var far = $Far
@onready var mid = $Mid
@onready var sea = $Sea
@onready var skyline = $Skyline
@onready var waves = $Waves
@onready var palms = $Palms

var camera_position = Vector2.ZERO
var zoom = 2.0
var drift = 0.0

func _ready():
	camera_position.y = ground_y
	_process(0)

func _process(delta):
	drift += delta
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera_position = camera.get_screen_center_position()
		zoom = camera.zoom.x

	sky.position.y = SEAWALL_Y - 720 + rise(0.02)
	sun.position.y = SEAWALL_Y - 190 + rise(0.02)
	move(clouds, 0.03, SEAWALL_Y - 300, drift * 4)
	move(far, 0.07, SEAWALL_Y - 235)
	move(mid, 0.12, SEAWALL_Y - 205)
	move(skyline, 0.2, SEAWALL_Y - 188)
	sea.position.y = SEAWALL_Y + rise(0.2)
	move(waves, 0.2, SEAWALL_Y + 4, drift * 3)
	move(palms, 0.6, 0)
	palms.scroll_offset.y = max(palms.scroll_offset.y, -60)

func rise(depth):
	return clamp(ground_y - camera_position.y, -150.0, 1200.0) * depth * zoom

func move(layer, depth, y, extra_x = 0.0):
	layer.scroll_offset = Vector2(-camera_position.x * depth * zoom - extra_x, y + rise(depth))
