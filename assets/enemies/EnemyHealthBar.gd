extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var health = $TextureProgress;
onready var second_health = $TextureProgress/TextureProgress2;
onready var shake_timer = $Timer;
onready var tween = $Tween;
onready var animation = $AnimatedSprite;

var shake_amount = 0;
var default_position = rect_position;

var second_health_points = 100;

var flash_color = 1;


# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureProgress.value = 100;     
	 
func _process(delta):
	second_health_points = lerp(second_health_points, health.value, delta * 5);
	second_health.value = second_health_points;
	
	rect_position = (Vector2(rand_range(-shake_amount, shake_amount), 
	rand_range(shake_amount, -shake_amount)) * delta + default_position)
	
	if flash_color != 1:
		flash_color = lerp(flash_color, 1, delta * 15);
	
	modulate = Color(flash_color,1,1);
#	print(flash_color)

func set_percent_value_int(value):
	 health.value = value;

func health_shake(new_shake, shake_time, shake_limit):
	shake_amount += new_shake
	if shake_amount > shake_limit:
		shake_amount = shake_limit
	
	shake_timer.wait_time = shake_time
	
	tween.stop_all()
	set_process(true)
	shake_timer.start()

func _on_Timer_timeout():
	shake_amount = 0
	
	tween.interpolate_property(self, "rect_position", rect_position, default_position, 
	0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	
	tween.start()


