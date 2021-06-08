extends AnimatedSprite


var max_scale

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.cursor = self
	pass # Replace with function body.


func _process(delta):
	global_position = get_global_mouse_position()
	
	if Global.player.state == "aiming":
		$AnimationPlayer.play("Aiming")
	else:
		$AnimationPlayer.play("Idle")
	
	scale.x = lerp(scale.x, 0.5, 3.5 * delta)
	scale.y = scale.x
	
	scale.x = clamp(scale.x, 0, max_scale)
	scale.y = clamp(scale.y, 0, max_scale)
	
	pass
