extends KinematicBody2D

export (Resource) var footstep_grass;
export (Resource) var footstep_wood;


const acceleration = 1516;
const friction = 0.6;
const air_resistance = 0.05;
const jump_force = 320;
const snap_dir = Vector2.DOWN;
const floor_max_angle = deg2rad(60);

var gravity = 1024;
var motion = Vector2.ZERO;
var snap_length = 3;
var snap_vector = snap_dir * snap_length;

var max_cam_x = 30;
var max_cam_y = 30;
var cam_speed = 0.02;
var max_speed = 156;
var state = "idle";

var play_fall_sound = false;

var num_combo = 0;
var max_combo = 3;
var can_attack = true;
var can_air_attack = true;

#Animacion
onready var animation = $AnimatedSprite/AnimationPlayer;
onready var anim_scale = $AnimatedSprite;

#Colisiones de ataques
	#Ataques basicos
onready var attack_area = $AttackCollisions/BasicAttackArea;
onready var attack_collision = $AttackCollisions/BasicAttackArea/BasicAttackCollision;
	#Ataque Aereo
onready var air_attack_area = $AttackCollisions/AirAttackArea;
onready var air_attack_collision = $AttackCollisions/AirAttackArea/AirAttackCollision;

#Armas
onready var gun = $Position2D/Gun
onready var gun_holder = $Position2D
onready var head = $PlayerHead
var deg_for_bullet : float

#Sonidos
onready var footstep_sound = $AnimatedSprite/AnimationPlayer/FootstepSound;
onready var snd_attack_1 = $Sounds/AttackSounds/sndAttack1;
onready var snd_attack_2 = $Sounds/AttackSounds/sndAttack2;

#Camara y UI
onready var camera = $Camera2D;
onready var health_bar = $UiLayer/HealthBar;

#Particulas
export var footstepPart : PackedScene;
export var jumpPart : PackedScene;

#Variables de HP
export (int) var health_points = 50;
var max_health_points = 100;
var regen_amount = 0;


func _ready():
	footstep_sound.stream = footstep_grass;
	Global.player = self;
	pass;


func _physics_process(delta):
	#Variables de INPUT
	var key_right = Input.get_action_strength("ui_right");
	var key_left = Input.get_action_strength("ui_left");
	var key_jump = Input.is_action_just_pressed("ui_up");
	var key_aim = Input.is_action_pressed("ui_aim");
	 
	var x_input = key_right - key_left;
	 
	camera.position.x = lerp(camera.position.x, (get_global_mouse_position().x - global_position.x) / 2, cam_speed);
	camera.position.y = lerp(camera.position.y, (get_global_mouse_position().y - (global_position.y) - 7) / 2, cam_speed);
	
	camera.position.x = clamp(camera.position.x, -max_cam_x, max_cam_x);
	camera.position.y = clamp(camera.position.y, -max_cam_y, max_cam_y);
	
	#Realizar Ataque
	attack();
	
	#Probar daño
	if Input.is_action_just_pressed("ui_cancel"):
		damaged(rand_range(5, 80))
	if Input.is_action_just_pressed("ui_end"):
		health_points = max_health_points
	
	#Health Regen
	if health_points < max_health_points:
		health_points = health_points + (regen_amount * delta);
	
	#Update health value
	health_points = clamp(health_points, 0, max_health_points)
	health_bar.set_percent_value_int(float(health_points)/max_health_points * 100);
	 
	attack_area.scale.x = anim_scale.scale.x;

	
	match state:
		"idle":
			can_attack = true;
			   
			if (x_input != 0):
				motion.x += x_input * acceleration * delta;
				motion.x = clamp(motion.x, -max_speed, max_speed);
			
				anim_scale.scale.x = x_input;
			motion.y += gravity * delta;
			
			if is_on_floor():
				if key_aim:
					state = "aiming"
				can_air_attack = true;
				if play_fall_sound:
					var jPart = jumpPart.instance() as Particles2D;
					get_parent().add_child(jPart);
					jPart.global_position = position;
					 
					$Sounds/SoundGrassFall.play();
					play_fall_sound = false;
					
				#Animaciones en el piso
				if x_input == 0:
					animation.play("idle");
				else:
					animation.play("run");
					
				#Cosas de friccion y salto
				snap_vector = snap_dir * snap_length;
				if (x_input == 0):
					motion.x = lerp(motion.x, 0, friction);
				
				
				if (key_jump):
					anim_scale.scale.y = 1.5;
					motion.y = -jump_force;
						 
					snap_vector = Vector2(0, 0);
			elif !nextToWall():
				play_fall_sound = true;
				
				anim_scale.scale.y = lerp(anim_scale.scale.y, 1, 0.1);
				if (Input.is_action_just_released("ui_up") and motion.y < -jump_force/2):
					motion.y = -jump_force/3;
				if (x_input == 0):
					motion.x = lerp(motion.x, 0, air_resistance);
					 
				if motion.y < 0:
					animation.play("jump_start");
				else:
					animation.play("jump_fall");
			
			if nextToWall():
				if (key_jump):
					anim_scale.scale.y = 1.5;
					motion.y = -jump_force;
						 
					snap_vector = Vector2(0, 0);
			
			attack_collision.disabled = true;
		"attacking":
			var can_attack_frame = 7;
			   
			motion.x = lerp(motion.x, 0, 0.1);
			motion.y += gravity * delta;
			   
			var interrump_jump = Input.is_action_pressed("ui_up")
			
			match num_combo:
				1:
					animation.play("slash_attack_1");
						 
					if x_input != 0 and anim_scale.frame >= can_attack_frame + 4:
						state = "idle"
					
					if interrump_jump and anim_scale.frame >= can_attack_frame + 1:
						motion.y = -jump_force;
						snap_vector = Vector2(0, 0);
						state = "idle";
					
					if anim_scale.frame >= can_attack_frame + 1:
						 can_attack = true;
					else:
						can_attack = false;
						 
					if anim_scale.frame > 5 and anim_scale.frame <= 7:
						attack_collision.disabled = false;
					else:
						attack_collision.disabled = true;
				2:
					animation.play("slash_attack_2");
						 
					if x_input != 0 and anim_scale.frame >= can_attack_frame + 3:
						state = "idle";
					
					if interrump_jump and anim_scale.frame >= can_attack_frame + 1:
						motion.y = -jump_force;
						snap_vector = Vector2(0, 0);
						state = "idle";
					
					if anim_scale.frame >= can_attack_frame:
						can_attack = true;
					else:
						can_attack = false;
						 
					if anim_scale.frame > 4 and anim_scale.frame <= 6:
						attack_collision.disabled = false;
					else:
						attack_collision.disabled = true;
				3:
					animation.play("slash_attack_3");
					  
					if anim_scale.frame >= can_attack_frame - 7:
						can_attack = true;
					else:
						can_attack = false;
					
					if anim_scale.frame >= 5 and anim_scale.frame < 7:
						attack_collision.disabled = false;
					else:
						attack_collision.disabled = true;
						 
				_:
					attack_collision.disabled = true;
		"air_attack":
			motion.x = lerp(motion.x, 0, 0.1)
			motion.y += (gravity / 3) * delta
			
			animation.play("slash_air")
			
			if anim_scale.frame >= 5 and anim_scale.frame < 7:
				air_attack_collision.disabled = false;
			else:
				air_attack_collision.disabled = true;
		"aiming":
			motion.x = lerp(motion.x, 0, 0.1)
			motion.y += (gravity / 3) * delta
			
			animation.play("aiming")
			
			if Input.is_action_just_released("ui_aim"):
				state = "idle"
	gun_stuff()
	motion.y = move_and_slide_with_snap(motion, snap_vector, Vector2.UP, true, 4, floor_max_angle).y;
	anim_scale.scale.y = lerp(anim_scale.scale.y, 1, 0.1);

func createFootstep():
	var fPart = footstepPart.instance() as Particles2D;
	get_parent().add_child(fPart);
	fPart.global_position = position;

func returnToIdle():
	state = "idle";

func attack():
	var key_attack = Input.is_action_just_pressed("ui_attack")
	if key_attack and (num_combo < max_combo):
		if is_on_floor() and (state != "air_attack") and state != "aiming":
			if can_attack:
				anim_scale.frame = 0;
				var attack_jump = 0;
				var key_right = Input.get_action_strength("ui_right");
				var key_left = Input.get_action_strength("ui_left");
				var timer = $AnimatedSprite/AnimationPlayer/AttackTimer;
				var x_input = key_right - key_left;
				
				timer.stop();
				num_combo += 1;
				attack_collision.disabled = true;
				state = "attacking";
				
				#Dar movimiento
				match num_combo:
					1:
						attack_jump = 110;
						timer.set_wait_time(1.2);
					2:
						attack_jump = 170;
						timer.set_wait_time(1.2);
					3:
						attack_jump = 260;
						timer.set_wait_time(0.5);
				
				if x_input != 0:
					anim_scale.scale.x = x_input;
				   
				can_attack = false;
				motion.x = 0;
				motion.x += attack_jump * sign(anim_scale.scale.x);
				   
				timer.start();
		elif !is_on_floor():
			if can_air_attack:
				#Ataque aereo
				can_air_attack = false
				motion.y = 0
				motion.y -= 70
				anim_scale.frame = 0
				state = "air_attack"

func damaged(damage_recieved):
	var shake_value = (damage_recieved * 1) / (max_health_points/2.5)
	health_bar.flash_color = 255;
	health_points -= damage_recieved;
	
	camera.cam_shake(200 * (shake_value * 1.5), 0.1 * (shake_value * 4), 400)
	health_bar.health_shake(200 * (shake_value), 0.1 * (shake_value * 6), 400)

func _on_AttackTimer_timeout():
	num_combo = 0;
	$AnimatedSprite/AnimationPlayer/AttackTimer.stop();

#Hitbox de ataques basicos
func _on_BasicAttackArea_area_entered(area):
	if attack_collision.disabled == false:
		attacksOnEnemy(area, 10 * num_combo/2)

#Hitbox de Ataque aereo
func _on_AirAttackArea_area_entered(area):
	if air_attack_collision.disabled == false:
		attacksOnEnemy(area, 12)

func attacksOnEnemy(body, damage):
	if body.is_in_group("Enemy_hit"):
		var enemy_root = body.owner
#		if enemy_root.state != "dead":
		var knockback_power;
			
		match num_combo:
			1:
				knockback_power = 100;
			2:
				knockback_power = 150;
			3:
				knockback_power = 240;
			_:
				knockback_power = 120;
		
		enemy_root.damaged(damage, knockback_power, "weak_damage");
		  
		var sound_id = [0, 1]
		var sound = sound_id[randi() % sound_id.size()]
		  
		match sound:
			0:
				snd_attack_1.play();
			1:
				snd_attack_2.play();
		
		health_points += 5;
		camera.cam_shake(200, .15 * num_combo/2.5, 200 * (num_combo/1.3));

func gun_stuff() -> void:
	if state == "aiming":
		var mouse_pos : Vector2 = get_global_mouse_position()
		
		deg_for_bullet = mouse_pos.angle_to_point(gun.global_position)
		gun_holder.look_at(mouse_pos)
		gun.real_weapon_rotation = gun_holder.rotation
		gun.real_weapon_rotation_degrees = gun_holder.rotation_degrees
		head.look_at(mouse_pos)
		
		gun.visible = true
		head.visible = true;
		if (global_position.x > mouse_pos.x):
			head.scale.y = -1
			gun.scale.y = -1
			anim_scale.scale.x = -1
		else:
			head.scale.y = 1;
			gun.scale.y = 1
			anim_scale.scale.x = 1
	else:
		gun.visible = false
		head.visible = false;

func nextToWall():
	return nextToRightWall() or nextToLeftWall()

func nextToRightWall():
	return $WallRaycast/RightWall.is_colliding()

func nextToLeftWall():
	return $WallRaycast/LeftWall.is_colliding()



















