extends RigidBody2D



export var speed := 1
var vel : Vector2
var direction = Vector2.ZERO



func _ready():
	pass

func _process(delta):
#	var collision_result = move_and_collide(direction * speed * delta)
	print(get_colliding_bodies())
