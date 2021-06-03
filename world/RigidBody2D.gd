extends RigidBody2D

export var smokeScene : PackedScene;
export var bulletImpact : PackedScene;

var head_damage
var body_damage
onready var raycast = $RayCast2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
#	set_continuous_collision_detection_mode(2)
	var collider = raycast.get_collider()
	var collision_point = raycast.get_collision_point()
	
	if collider != null:
		if collider.is_in_group("Enemy"):
			var polygon_six = collider.bullet_polygon.polygon[6].y
			var head_start_point = 19 + (polygon_six * -1)
			
			if (collision_point.y <= (collider.position.y - head_start_point)):
				collider.damaged(head_damage, 60, "medium_damage")
			else:
				collider.damaged(body_damage, 60, "medium_damage")
		
		create_particles(collision_point, collider)
		queue_free()

func _on_bullet_body_entered(body):
#	if body.is_in_group("Enemy"):
#		var polygon_six = body.bullet_polygon.polygon[6].y
#		var head_start_point = 19 + (polygon_six * -1)
#
#		if (position.y <= (body.position.y - head_start_point)):
#			body.damaged(head_damage, 60, "medium_damage")
#		else:
#			body.damaged(body_damage, 60, "medium_damage")
#	create_particles(position, body)
#	queue_free()
	pass


func create_particles(pos, body):
	var smoke = smokeScene.instance() as Particles2D
	get_node("/root").add_child(smoke)
	smoke.global_position = pos
	smoke.rotation = rotation

	var impact = bulletImpact.instance() as Node2D

	get_node("/root").add_child(impact)
	impact.global_position = pos
	impact.rotation = rotation
