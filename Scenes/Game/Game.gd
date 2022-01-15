extends Spatial



onready var player1Spawn = $Player1Spawn
onready var player2Spawn = $Player2Spawn

var player1
var player2

func _ready():
	
	player1 = preload("res://Scenes/Player/Player.tscn").instance()
	player1.set_name(str(get_tree().get_network_unique_id()))
	player1.set_network_master(get_tree().get_network_unique_id())
	player1.global_transform = player1Spawn.global_transform
	add_child(player1)
	
	player2 = preload("res://Scenes/Player/Player.tscn").instance()
	player2.set_name(str(Globals.player2id))
	player2.set_network_master(Globals.player2id)
	player2.global_transform = player2Spawn.global_transform
	add_child(player2)
	
	if player1.name == "1": # Only the host sees player1 with id = 1
		player1.global_transform = player1Spawn.global_transform
	else:  # So here this is only done for the non host who sees the host as player2
		player1.global_transform = player2Spawn.global_transform
	# Might be weird, but id = 1 is player1 for host and player2 for non host
