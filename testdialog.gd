extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
#	$AnimatedSprite/AnimationPlayer.play("default")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_attack"):
		$AnimatedSprite.offset.y -= 10
		var next = $AnimatedSprite/AnimationPlayer.animation_get_next($AnimatedSprite/AnimationPlayer.get_current_animation())
		$AnimatedSprite/AnimationPlayer.play(next)
	$AnimatedSprite.offset.y = lerp($AnimatedSprite.offset.y, 0, 0.1)
