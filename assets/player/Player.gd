extends KinematicBody2D

export (Resource) var footstep_grass
export (Resource) var footstep_wood
var stats = load("res://Stats.gd").new()
#export (Resource) var stats


#Particulas
export var footstepPart : PackedScene
export var jumpPart : PackedScene

var inertia = 100

#Animacion
onready var animation = $AnimatedSprite/AnimationPlayer
onready var anim_scale = $AnimatedSprite

#Colisiones
	#Ataques basicos
onready var attack_area = $AttackCollisions/BasicAttackArea
onready var attack_collision = $AttackCollisions/BasicAttackArea/BasicAttackCollision
	#Ataque Aereo
onready var air_attack_area = $AttackCollisions/AirAttackArea
onready var air_attack_collision = $AttackCollisions/AirAttackArea/AirAttackCollision

	#De pie o agachado
onready var standing_collision = $StandingShape
onready var crouching_collision = $CrouchingShape

#Armas
onready var gun = $Position2D/Gun
onready var gun_holder = $Position2D
onready var head = $PlayerHead
var deg_for_bullet : float

#Sonidos
onready var footstep_sound = $AnimatedSprite/AnimationPlayer/FootstepSound
onready var snd_attack_1 = $Sounds/AttackSounds/sndAttack1
onready var snd_attack_2 = $Sounds/AttackSounds/sndAttack2

#Camara y UI
onready var camera = $Camera2D
onready var health_bar = $UiLayer/HealthBar

const acceleration = 1516
const friction = 0.6
const air_resistance = 0.1
const jump_force = 320
const snap_dir = Vector2.DOWN
const floor_max_angle = deg2rad(60)

var gravity = 1024
var motion = Vector2.ZERO
var snap_length = 3
var snap_vector = snap_dir * snap_length

var max_cam_x = 30
var max_cam_y = 30
var cam_speed = 0.02

var max_speed = 156

var state = "idle"

var play_fall_sound = false

var num_combo = 0
var max_combo = 3
var can_attack = true
var can_air_attack = true

var is_crouching = false
var is_sprinting = false

var going_to_attack = false;

#Variables de HP
var health_points = 50
var max_health_points = 100
var regen_amount = 0

var can_damage = true

var bullet_dispersion = 300
var weapon_recoil = 850

var equipped_weapon = 2
var has_weapon = true

#Ammo types
var heavy_ammo = 300
var light_ammo = 300



func _ready():
	footstep_sound.stream = footstep_grass;
	Global.player = self;
	
	pass;


func _physics_process(delta):
	#Variables de INPUT
	var key_right = Input.get_action_strength("ui_right")
	var key_left = Input.get_action_strength("ui_left")
	var key_jump = Input.is_action_just_pressed("ui_up")
	var key_crouch = Input.is_action_pressed("ui_down")
	var key_aim = Input.is_action_pressed("ui_aim")
	var key_attack = Input.is_action_just_pressed("ui_attack")
	var key_sprint = Input.is_action_pressed("ui_movement")
	 
	var x_input = key_right - key_left;
	 
	camera.position.x = lerp(camera.position.x, (get_global_mouse_position().x - global_position.x) / 2, cam_speed);
	camera.position.y = lerp(camera.position.y, (get_global_mouse_position().y - (global_position.y) - 7) / 2, cam_speed);
	
	camera.position.x = clamp(camera.position.x, -max_cam_x, max_cam_x);
	camera.position.y = clamp(camera.position.y, -max_cam_y, max_cam_y);
	
	_cam_Zoom(delta)
	
	#Realizar Ataque
	if !_can_Stand():
		if key_attack and state != "aiming":
			if !going_to_attack:
				$AnimatedSprite/AnimationPlayer/SaveAttackTimer.wait_time = 0.3
				$AnimatedSprite/AnimationPlayer/SaveAttackTimer.start()
				going_to_attack = true
		attack()
	
	if is_on_floor():
		can_air_attack = true;
	
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
			
			if key_crouch:
				_on_Crouch()
			else:
				if !_can_Stand():
					_on_Stand()
			
			if is_on_floor():
				if key_aim and has_weapon:
					state = "aiming"
				if play_fall_sound:
					createJumpParticle()
					 
					$Sounds/SoundGrassFall.play();
					play_fall_sound = false;
					
				#Animaciones en el piso
				if x_input == 0:
					if is_crouching:
						animation.play("crouch")
					else:
						animation.play("idle")
				else:
					if is_crouching:
						animation.play("crouch_run")
					else:
						if is_sprinting:
							animation.play("sprint")
						else:
							animation.play("run")
					
				#Cosas de friccion y salto
				snap_vector = snap_dir * snap_length;
				if (x_input == 0):
					motion.x = lerp(motion.x, 0, friction);
				
				
				if (key_jump and !_can_Stand()):
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
			
			if (key_sprint and x_input != 0 and !is_crouching):
				is_sprinting = true
				max_speed = 230
			
			if !key_sprint:
				is_sprinting = false
			
			attack_collision.disabled = true;
			change_weapon()
			initialize_roll()
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
					
					if interrump_jump and anim_scale.frame >= can_attack_frame:
						motion.y = -jump_force;
						snap_vector = Vector2(0, 0);
						state = "idle";
					
					if anim_scale.frame >= can_attack_frame + 1:
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
			
			if key_crouch:
				_on_Crouch()
			else:
				if !_can_Stand():
					_on_Stand()
			
			motion.x = lerp(motion.x, 0, 0.1)
			motion.y += (gravity / 3) * delta
			
			if is_crouching:
				animation.play("crouch_aim")
			else:
				animation.play("aiming")
			
			if Input.is_action_just_released("ui_aim"):
				state = "idle"
		"roll":
			motion.x = lerp(motion.x, 0, 0.05);
			motion.y += (gravity/2) * delta;
			
			anim_scale.scale.x = lerp(anim_scale.scale.x, 1 * sign(anim_scale.scale.x), 0.2)
			
			animation.play("roll")
			
			if anim_scale.frame >= 1 and anim_scale.frame <= 5:
				can_damage = false
			else:
				can_damage = true
	
	
	gun_stuff()
	motion.y = move_and_slide_with_snap(motion, snap_vector, Vector2.UP, true, 4, floor_max_angle, false).y;
	inertia = abs(motion.x)
	
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * inertia)
	
	anim_scale.scale.y = lerp(anim_scale.scale.y, 1, 0.1);

func createFootstep():
	var fPart = footstepPart.instance() as Particles2D;
	get_parent().add_child(fPart);
	fPart.global_position = position;

func createJumpParticle():
	if is_on_floor():
		var jPart = jumpPart.instance() as Particles2D;
		get_parent().add_child(jPart);
		jPart.global_position = position;

func returnToIdle():
	state = "idle";

func attack():
	var key_attack = Input.is_action_just_pressed("ui_attack")
	if (key_attack or going_to_attack) and (num_combo < max_combo):
		if is_on_floor() and (state != "air_attack") and state != "aiming":
			if can_attack:
				
				going_to_attack = false
				
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
						timer.set_wait_time(0.4);
				
				if x_input != 0:
					anim_scale.scale.x = x_input;
				   
				can_attack = false;
				motion.x = 0;
				motion.x += attack_jump * sign(anim_scale.scale.x);
				   
				timer.start();
		elif !is_on_floor():
			if can_air_attack:
				#Ataque aereo
				going_to_attack = false
				can_air_attack = false
				motion.y = 0
				motion.y -= 70
				anim_scale.frame = 0
				state = "air_attack"

func damaged(damage_recieved):
	if can_damage:
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
		attacksOnEnemy(area, 13 * num_combo/2)

#Hitbox de Ataque aereo
func _on_AirAttackArea_area_entered(area):
	if air_attack_collision.disabled == false:
		attacksOnEnemy(area, 10)

func attacksOnEnemy(body, damage):
	if body.is_in_group("Enemy_hit"):
		var enemy_root = body.owner
		var knockback_power;
		var knockback_type = "weak_damage"
		
		match num_combo:
			1:
				knockback_power = 100;
				knockback_type = "weak_damage"
			2:
				knockback_power = 150;
				knockback_type = "medium_damage"
			3:
				knockback_power = 240;
				knockback_type = "hard_damage"
			_:
				knockback_power = 120;
				knockback_type = "weak_damage"
		
		enemy_root.damaged(damage, knockback_power, knockback_type);
		enemy_root.create_particle(enemy_root.particles_position.global_position, 15 * num_combo)
		  
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
#		gun_holder.look_at(mouse_pos)
		gun_holder.rotation = lerp_angle(gun_holder.rotation, 
							(mouse_pos - gun_holder.global_position).normalized().angle(), 
							0.3)
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

func _on_Crouch():
	
	is_crouching = true
	standing_collision.disabled = true
	crouching_collision.disabled = false
	max_speed = 60

func _on_Stand():
	
	is_crouching = false
	standing_collision.disabled = false
	crouching_collision.disabled = true
	max_speed = 156

func _can_Stand():
	return $CrouchingShape/CanStandRay.is_colliding() or $CrouchingShape/CanStandRay2.is_colliding()

func _cam_Zoom(delta):
	var target_zoom
	var target_max_cam
	
	if state == "aiming":
		target_zoom = 1.4
		target_max_cam = 80
	else:
		target_zoom = 1
		target_max_cam = 30
	
	max_cam_x = lerp(max_cam_x, target_max_cam, 4 * delta)
	max_cam_y = max_cam_x
	camera.zoom.x = lerp(camera.zoom.x, target_zoom, 4 * delta)
	camera.zoom.y = camera.zoom.x

func _on_SaveAttackTimer_timeout():
	going_to_attack = false
	$AnimatedSprite/AnimationPlayer/SaveAttackTimer.stop()

func change_weapon():
	var key_change = Input.is_action_just_pressed("ui_select")
	
	if key_change:
		equipped_weapon += 1
		gun.ammo_in_mag = 0
	
	if equipped_weapon > 3:
		equipped_weapon = 0

func initialize_roll():
	var key_roll = Input.is_action_just_pressed("ui_change_action")
	
	if key_roll:
		state = "roll"
		anim_scale.scale.x *= 1.6
		motion.y = 0
		motion.x = 0
		motion.x += max_speed * 2 * sign(anim_scale.scale.x);


