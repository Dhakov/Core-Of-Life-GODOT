extends KinematicBody2D

export var smokeScene : PackedScene;
export var bulletImpact : PackedScene;

export var speed := 1000
var vel : Vector2
var direction = Vector2.ZERO

var head_damage;
var body_damage;


func _ready():
	var collision_result = move_and_collide(direction)
	
	if collision_result != null:
		queue_free()

func _process(delta):
	var collision_result = move_and_collide(direction * speed * delta)
	
	if collision_result != null:
	
		var collider = collision_result.collider
	
		if collider.is_in_group("Wall"):
			create_smoke(collision_result, collider)
			queue_free()
		elif collider.is_in_group("Enemy"):
			#Crear humo
			var polygon_six = collider.bullet_polygon.polygon[6].y
			var head_start_point = 19 + (polygon_six * -1)
			
#			create_smoke(collision_result, collider)
			
			#Si es headshot
			if (collision_result.position.y <= (collider.position.y - head_start_point)):
				collider.damaged(head_damage, 60, "medium_damage")
				queue_free()
			#Si no es headshot
			else:
				collider.damaged(body_damage, 60, "medium_damage")
				queue_free()


func create_smoke(collision_result, collider):
	var smoke = smokeScene.instance() as Particles2D
	get_node("/root").add_child(smoke)
	smoke.global_position = collision_result.position
	smoke.rotation = collision_result.normal.angle()
	
	var impact = bulletImpact.instance() as Node2D
	
	get_node("/root").add_child(impact)
	impact.global_position = collision_result.position
	impact.rotation = collision_result.normal.angle()

