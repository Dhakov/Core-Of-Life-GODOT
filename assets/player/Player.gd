extends KinematicBody2D


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

onready var animation = $AnimatedSprite/AnimationPlayer;
onready var anim_scale = $AnimatedSprite;

export var footstepPart : PackedScene;
export var jumpPart : PackedScene;

func _ready():
     pass;


func _physics_process(delta):
     var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left");
     
     $Camera2D.position.x = lerp($Camera2D.position.x, (get_global_mouse_position().x - global_position.x) / 2, cam_speed);
     $Camera2D.position.y = lerp($Camera2D.position.y, (get_global_mouse_position().y - (global_position.y) - 7) / 2, cam_speed);
     
     $Camera2D.position.x = clamp($Camera2D.position.x, -max_cam_x, max_cam_x);
     $Camera2D.position.y = clamp($Camera2D.position.y, -max_cam_y, max_cam_y);
     
     match state:
          "idle":
               if (x_input != 0):
                    motion.x += x_input * acceleration * delta;
                    motion.x = clamp(motion.x, -max_speed, max_speed);

                    anim_scale.scale.x = x_input;

               motion.y += gravity * delta;
               
               if is_on_floor():
                    
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
                    if (Input.is_action_just_pressed("ui_up")):
                         
                         anim_scale.scale.y = 1.5;
                         motion.y = -jump_force;
                         
                         snap_vector = Vector2(0, 0);
                         
                    anim_scale.scale.y = lerp(anim_scale.scale.y, 1, 0.1);
               else:
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
                    
#		"attacking":
#			motion.x = lerp(motion.x, 0, 0.1);
#			motion.y += gravity * delta;
#			animatedSprite.play("Attack_1");
#
#			if (animatedSprite.frame >= 1 and animatedSprite.frame <= 3):
#				attackAreaColl.disabled = false;
#		"aiming":
#			motion.x += x_input * acceleration * delta;
#			motion.x = clamp(motion.x, -max_speed/2, max_speed/2);
#
#			if (x_input == 0):
#				motion.x = lerp(motion.x, 0, friction);
#
#			animatedSprite.play("Aiming");
#
#			attackArea.set_scale(Vector2(gun_y_scale(), 1))
#			animatedSprite.set_scale(Vector2(gun_y_scale(),1));
#
#			motion.y += gravity * delta;
#
#			if Input.is_action_just_released("mouse_right_click"):
#				state = "idle";
     
     motion.y = move_and_slide_with_snap(motion, snap_vector,
               Vector2.UP, true, 4, floor_max_angle).y;


func createFootstep():
     var fPart = footstepPart.instance() as Particles2D;
     get_parent().add_child(fPart);
     fPart.global_position = position;
