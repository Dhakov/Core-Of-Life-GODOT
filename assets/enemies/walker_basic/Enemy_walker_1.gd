extends KinematicBody2D

export var bloodSplash : PackedScene;

const acceleration = 1516;
const friction = 0.6;
const air_resistance = 0.05;
const jump_force = 320;

var max_speed = 112;

var gravity = 1024;
var motion = Vector2.ZERO;

var state = "idle";
var dir = 1;
var knockback_type = "weak_damage";
var is_moving = false;
var flash_color = 1;

export (int) var health_points = 50;
var max_health_points = 50;
var regen_amount = 5;

onready var animation = $AnimatedSprite;
onready var animation_player = $AnimatedSprite/AnimationPlayer;
onready var health_bar = $HpIndex/EnemyHealthBar;
onready var damage_flash = $damage_flash;

onready var snd_damage_1 = $Sounds/sndDamage1
onready var snd_damage_2 = $Sounds/sndDamage2
onready var snd_damage_3 = $Sounds/sndDamage3

onready var bullet_polygon = $BulletPoligon

onready var eye_light = $Light2DOrigin

onready var particles_position = $Misc/BloodPosition

func _ready():
#	animation.modulate = animation.modulate.duplicate()
	pass

func _process(delta):
	 
	$Label.text = str(flash_color)
	
	dir = sign(Global.player.position.x - position.x);
	if dir == 0:
		dir = 1;
	
	eye_light.scale.x = dir
	
	#Actualizar barra de salud
	health_bar.set_percent_value_int(float(health_points)/max_health_points * 100)
	#Regeneracion de salud
	if health_points < max_health_points:
		health_points = health_points + (regen_amount * delta)
	health_points = clamp(health_points, 0, max_health_points)
	
	#Muerte
	if health_points <= 1:
		state = "dead"
		
	match state:
		"idle":
			animation.scale.x = dir
			bullet_polygon.scale.x = dir
			   
			if (is_moving):
				motion.x += dir * acceleration * delta;
				motion.x = clamp(motion.x, -max_speed, max_speed);
			
			motion.y += gravity * delta;
			   
			if is_on_floor():
				#Animaciones en el piso
				if !is_moving:
					animation_player.play("idle");
					
					#Cosas de friccion y salto
					if (!is_moving):
						motion.x = lerp(motion.x, 0, friction);
		"knockback":
			motion.y += gravity * delta;
			if motion.x != 0:
				motion.x = lerp(motion.x, 0, delta * 5);
		"dead":
			animation_player.play("dead")
			motion.x = lerp(motion.x, 0, delta * 5)
#			motion.y += gravity * delta
			
			regen_amount = 0
			set_collision_layer_bit(2, false)
			$Area2D.set_collision_mask_bit(0, false)
			
	if animation.scale.y != 1:
		animation.scale.y = lerp(animation.scale.y, 1, 0.14);
#
	if flash_color != 1:
		flash_color = lerp(flash_color, 1, 15*delta);
	modulate = Color(flash_color,1,1)

	motion.y = move_and_slide(motion, Vector2.UP, true).y;

func damaged(damageRecieved, knockbackPower, knockbackType):
	if state != "dead":
		var player_scale = Global.player.get_node("AnimatedSprite").scale.x;
		knockback_type = knockbackType;
		 
		health_points -= damageRecieved;
		state = "knockback";
		motion.x = knockbackPower * player_scale;
		 
		animation_player.stop();
		animation_player.play(knockbackType);
		 
		animation.scale.y = .6
		 
		flash_color = 100
		 
		#Elegir el sonido de daño
		var damage_snd_id = [0, 1, 2]
		var snd_id = damage_snd_id[randi() % damage_snd_id.size()]
		match snd_id:
			0:
				snd_damage_1.play();
			1:
				snd_damage_2.play();
			2:
				snd_damage_3.play();

func returnToIdle():
	state = "idle";

func die():
	state = "dead"


func create_particle(pos, amount):
	
	var blood = bloodSplash.instance() as Particles2D
	get_node("/root").add_child(blood)
	blood.amount = amount
	blood.global_position = pos
	blood.rotation = rotation




