extends KinematicBody2D

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
var regen_amount = 1;

onready var animation = $AnimatedSprite;
onready var animation_player = $AnimatedSprite/AnimationPlayer;
onready var health_bar = get_node("EnemyHealthBar");
onready var damage_flash = $damage_flash;


func _ready():
	 pass # Replace with function body.

func _process(delta):
	 
	dir = sign(Global.player.position.x - position.x);
	if dir == 0:
		dir = 1;
	 
	health_bar.set_percent_value_int(float(health_points)/max_health_points * 100);
	if health_points < max_health_points:
		health_points = health_points + (regen_amount * delta);
	 
	match state:
		"idle":
			animation.scale.x = dir;
			   
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
			   
	if animation.scale.y != 1:
		animation.scale.y = lerp(animation.scale.y, 1, 0.14);
		  
	if flash_color != 1:
		flash_color = lerp(flash_color, 1, 15*delta);
	animation.modulate = Color(flash_color,flash_color,flash_color)
	 
	motion.y = move_and_slide(motion, Vector2.UP, true).y;

func damaged(damageRecieved, knockbackPower, knockbackType):
	var player_scale = Global.player.get_node("AnimatedSprite").scale.x;
	knockback_type = knockbackType;
	 
	health_points -= damageRecieved;
	state = "knockback";
	motion.x = knockbackPower * player_scale;
	 
	animation_player.stop();
	animation_player.play(knockbackType);
	 
	animation.scale.y = .6;
	 
	flash_color = 255;
	 
	#Elegir el sonido de daño
	var damage_id;
	damage_id = round(rand_range(0,1));

func returnToIdle():
	state = "idle";

