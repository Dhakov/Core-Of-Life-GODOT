extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var pick_color = rand_range(0.5, 1.5)
	frame = rand_range(0, 6);
	modulate = Color(pick_color, pick_color, 0);

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#     pass
