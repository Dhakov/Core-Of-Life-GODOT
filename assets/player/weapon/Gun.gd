extends Node2D


export var bulletScene : PackedScene;
export var MuzzleFlash : PackedScene;

onready var timer = $ShotCD
onready var m4shot = $Sounds/AudioMFusilShot

onready var gun_sprite = $Position2D/AnimatedSprite
onready var gun_origin = $Position2D
onready var bullet_spawn = $Muzzle/BulletSpawn

var real_weapon_rotation
var real_weapon_rotation_degrees

var can_shot = true

var bullet_dispersion = 5
var head_damage = 35
var body_damage = 10
var weapon_recoil = 10

var bullet_speed = 2000;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	scale.x = lerp(scale.x, 1, 0.1);
	gun_origin.rotation_degrees = lerp(gun_origin.rotation_degrees, 0, 20 * delta);
	
	if (Input.is_action_pressed("ui_attack") and Global.player.state == "aiming" and can_shot):
		
		can_shot = false
		$Sounds/AudioMFusilShot.pitch_scale = rand_range(.9, 1.1)
		
		timer.wait_time = 6 * delta;
		m4shot.play()
		timer.start()
		
		gun_origin.rotation_degrees = (rotation_degrees - 800) * delta
		  
		Global.camera.cam_shake(60, 0.2, 60);
		  
#		$ShotSound.play();
		  
		var bullet = bulletScene.instance() as Node2D;
		
		get_node("/root").add_child(bullet);
		
#		bullet.global_position = bullet_spawn.global_position;
#		bullet.direction = ((get_global_mouse_position() + 
#		Vector2(rand_range(-bullet_dispersion, bullet_dispersion), 
#		rand_range(-bullet_dispersion,bullet_dispersion)))
#		 - global_position).normalized()
#		bullet.rotation = bullet.direction.angle()#Global.player.deg_for_bullet;
#		bullet.head_damage = head_damage;
#		bullet.body_damage = body_damage;
		
		bullet.global_position = bullet_spawn.global_position;
		bullet.rotation_degrees = real_weapon_rotation_degrees
		bullet.apply_impulse(Vector2(), Vector2(bullet_speed, 0).rotated(real_weapon_rotation))
		bullet.head_damage = head_damage;
		bullet.body_damage = body_damage;
		
		var muzzle = MuzzleFlash.instance() as Node2D

		get_node("/root").add_child(muzzle)
		muzzle.global_position = $Muzzle.global_position
		muzzle.rotation = Global.player.deg_for_bullet;


func _on_ShotCD_timeout():
	can_shot = true;
	timer.stop()

