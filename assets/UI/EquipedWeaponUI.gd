extends TextureRect


onready var ammo_text = $Label
var stats = load("res://Stats.gd").new()
var ammo_in_mag

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.weapon_hud = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	ammo_text.text = str(0) + "/" + str(stats.weapon_stats[Global.player.equipped_weapon][6])
	var ammo_type = stats.weapon_stats[Global.player.equipped_weapon][7]
	var ammo_type_show
	match ammo_type:
		"light_ammo":
			ammo_type_show = Global.player.light_ammo
		"heavy_ammo":
			ammo_type_show = Global.player.heavy_ammo
	ammo_text.text = str(ammo_in_mag) + "/" +str(ammo_type_show)
