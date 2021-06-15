extends Node2D


export var bulletScene : PackedScene;
export var MuzzleFlash : PackedScene;

onready var timer = $ShotCD
onready var shot_sound = $Sounds/AudioShot

var m4_shot = "res://assets/sounds/Shots/m4_shot_3.wav"
var ak_shot = "res://assets/sounds/Shots/ak_shot_2.wav"
var an_shot = "res://assets/sounds/Shots/an_shot_1.wav"
var famas_shot = "res://assets/sounds/Shots/famas_shot_1.wav"

onready var gun_sprite = $Position2D/AnimatedSprite
onready var gun_origin = $Position2D
onready var bullet_spawn = $Muzzle/BulletSpawn
onready var muzzle = $Muzzle

onready var laser_cast = $RayCast2D
onready var laser = $Line2D

onready var right_sprite = $Position2D/rightArm/RightAnimationPlayer
onready var left_sprite = $Position2D/leftArm/LeftAnimationPlayer

var real_weapon_rotation
var real_weapon_rotation_degrees

var can_shot = true

var bullet_dispersion = 300

#Stats
var weapon
var weapon_num
var max_bullet_dispersion
var recoil
var head_damage
var body_damage
var fire_rate

var bullet_speed = 1800

var shoot_mode = 0

var stats = load("res://Stats.gd").new()

var equipped_weapon

var second_shot
var third_shot

var ammo_in_mag = 0

# Called when the node enters the scene tree for the first time.
func _ready():
#	laser.add_point(to_local(laser.get_point_position(1)), 2)
	pass # Replace with function body.

func _physics_process(delta):
	_update_weapon()
	scale.x = lerp(scale.x, 1, 0.1);
	gun_origin.rotation_degrees = lerp(gun_origin.rotation_degrees, 0, 15 * delta);
	bullet_dispersion = lerp(bullet_dispersion, 0, 1.7 * delta)
	bullet_dispersion = clamp(bullet_dispersion, 0, max_bullet_dispersion)
	
	var key_shoot
	
	if Global.player.state == "aiming":
		if Input.is_action_just_pressed("ui_change_action"):
			if shoot_mode == 0:
				shoot_mode = 1
			else:
				shoot_mode = 0
	
	reload()
	
	if shoot_mode == 0:
		key_shoot = Input.is_action_pressed("ui_attack")
	else:
		key_shoot = Input.is_action_just_pressed("ui_attack")
	
	if Global.cursor != null:
		Global.cursor.max_scale = max_bullet_dispersion/40
	
#	Global.weapon_hud.ammo_text.text = str(ammo_in_mag())
	
	if (key_shoot and Global.player.state == "aiming" and can_shot) and ammo_in_mag > 0:
		shot_sound.stop()
		var sfx
		match weapon:
			"m4":
				sfx = load(m4_shot)
			"ak":
				sfx = load(ak_shot)
			"an":
				sfx = load(an_shot)
				$SecondShot.wait_time = 3 * delta
				$SecondShot.start()
			"famas":
				sfx = load(famas_shot)
				$SecondShot.wait_time = 4*delta
				$SecondShot.start()
				$ThirdShot.wait_time = 8*delta
				$ThirdShot.start()
		
		shot_sound.stream = sfx
		shot_sound.pitch_scale = rand_range(.9, 1)
		shot_sound.play()
		
		can_shot = false
		
		if Global.cursor != null:
			Global.cursor.scale.x += .8
		
		timer.wait_time = fire_rate * delta;
		timer.start()
		
		gun_origin.rotation_degrees = (rotation_degrees - recoil) * delta
		
		Global.camera.cam_shake(90, 0.2, 90);
		
		var bullet = bulletScene.instance() as Node2D;
		
		get_node("/root").add_child(bullet);
		
		var dispersion = rand_range(-bullet_dispersion, bullet_dispersion)
		
		bullet.global_position = bullet_spawn.global_position;
		bullet.rotation = real_weapon_rotation
		bullet.apply_impulse(Vector2(), Vector2(bullet_speed, 0 + dispersion).rotated(real_weapon_rotation))
		bullet.head_damage = head_damage;
		bullet.body_damage = body_damage;
		_minus_bullet()
		
		var muzzle = MuzzleFlash.instance() as Node2D
		get_node("/root").add_child(muzzle)
		muzzle.global_position = $Muzzle.global_position
		muzzle.rotation = Global.player.deg_for_bullet;
		
		bullet_dispersion += 250
	if second_shot:
		second_shot()
	if third_shot:
		third_shot()
	laser_update()
func _on_ShotCD_timeout():
	can_shot = true;
	timer.stop()

func laser_update() -> void:
	var collider = laser_cast.get_collider()
	
	laser_cast.set_cast_to(to_local(get_global_mouse_position()))

	laser.set_point_position(0, muzzle.position)
	laser.remove_point(1)
	
	if collider != null:
		laser.add_point(to_local(laser_cast.get_collision_point()))
	else:
		laser.add_point(to_local(get_global_mouse_position()), 1)
	
	
#	if laser_cast.is_colliding():
#		laser.set_point_position(1, to_local(laser_cast.get_collision_point()))
#	else:
#		laser.set_point_position(1, to_local(get_global_mouse_position()))

func _update_weapon():
	var is_crouching = Global.player.is_crouching
	
	equipped_weapon = Global.player.equipped_weapon
	
	weapon = stats.weapon_stats[equipped_weapon][0]
	
	right_sprite.play(weapon)
	left_sprite.play(weapon)
	
	head_damage = stats.weapon_stats[equipped_weapon][1]
	body_damage = stats.weapon_stats[equipped_weapon][2]
	
	if is_crouching:
		max_bullet_dispersion = stats.weapon_stats[equipped_weapon][3] / 3
		recoil = stats.weapon_stats[equipped_weapon][4] / 1.4
	else:
		max_bullet_dispersion = stats.weapon_stats[equipped_weapon][3]
		recoil = stats.weapon_stats[equipped_weapon][4]
	
	fire_rate = stats.weapon_stats[equipped_weapon][5]

func _ammo_type():
	var ammo_type = stats.weapon_stats[equipped_weapon][7]
	var ammo_amount
	match ammo_type:
		"light_ammo":
			ammo_amount = Global.player.light_ammo
		"heavy_ammo":
			ammo_amount = Global.player.heavy_ammo
	return ammo_amount

func _minus_bullet():
	ammo_in_mag -= 1

func reload():
	var ammo_amount = _ammo_type()
	var max_ammo = stats.weapon_stats[equipped_weapon][6]
	var ammo_type = stats.weapon_stats[equipped_weapon][7]
	
	if Input.is_action_just_pressed("ui_reload") and Global.player.state == "aiming" and ammo_in_mag < ammo_amount:
		if ammo_amount > max_ammo:
			match ammo_type:
				"light_ammo":
					Global.player.light_ammo -= max_ammo
				"heavy_ammo":
					Global.player.heavy_ammo -= max_ammo
			ammo_in_mag = max_ammo
		else:
			match ammo_type:
				"light_ammo":
					Global.player.light_ammo = 0
				"heavy_ammo":
					Global.player.heavy_ammo = 0
			ammo_in_mag = ammo_amount
	Global.weapon_hud.ammo_in_mag = ammo_in_mag

func _on_SecondShot_timeout():
	if ammo_in_mag > 0:
		second_shot = true
	
	$SecondShot.stop()

func _on_ThirdShot_timeout():
	if ammo_in_mag > 0:
		third_shot = true
	
	$ThirdShot.stop()

func second_shot():
	var bullet2 = bulletScene.instance() as Node2D;
	
	get_node("/root").add_child(bullet2);
	
	var dispersion_2 = rand_range(-bullet_dispersion, bullet_dispersion)
	
	bullet2.global_position = bullet_spawn.global_position;
	bullet2.rotation = real_weapon_rotation
	bullet2.apply_impulse(Vector2(), Vector2(bullet_speed, 0 + dispersion_2).rotated(real_weapon_rotation))
	bullet2.head_damage = head_damage;
	bullet2.body_damage = body_damage;
	
	_minus_bullet()
	second_shot = false

func third_shot():
	var bullet3 = bulletScene.instance() as Node2D;
	
	get_node("/root").add_child(bullet3);
	
	var dispersion_3 = rand_range(-bullet_dispersion, bullet_dispersion)
	
	bullet3.global_position = bullet_spawn.global_position;
	bullet3.rotation = real_weapon_rotation
	bullet3.apply_impulse(Vector2(), Vector2(bullet_speed, 0 + dispersion_3).rotated(real_weapon_rotation))
	bullet3.head_damage = head_damage;
	bullet3.body_damage = body_damage;
	
	_minus_bullet()
	third_shot = false
