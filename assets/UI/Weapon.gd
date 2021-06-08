extends AnimatedSprite


var stats = load("res://Stats.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	play(stats.weapon_stats[Global.player.equipped_weapon][0])
	pass
