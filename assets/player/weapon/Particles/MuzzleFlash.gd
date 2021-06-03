extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Light2D.scale.x = lerp($Light2D.scale.x, 0, 4 * delta)
	$Light2D.scale.y = $Light2D.scale.x
	$Light2D.energy = lerp($Light2D.energy, 0, 5 * delta)
