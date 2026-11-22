extends AnimatableBody2D

@export var move_by = Vector2(64, 0)
@export var seconds = 2.0

func _ready():
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", position + move_by, seconds).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", position, seconds).set_trans(Tween.TRANS_SINE)
