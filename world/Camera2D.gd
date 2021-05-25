extends Camera2D


#onready var player = get_parent();
#
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	var target = player.position;
#	var target_pos_x;
#	var target_pos_y;
#	target_pos_x = int(lerp(position.x, target.x, 0.1));
#	target_pos_y = int(lerp(position.y, target.y, 0.1));
#	global_position = Vector2(target_pos_x, target_pos_y);
