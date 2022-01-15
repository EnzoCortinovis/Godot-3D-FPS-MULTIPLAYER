extends Control

onready var editIP = $TextEdit
var IP = '127.0.0.1'  # For local test on one computer it's de default ip 
var game

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected",self,"_player_connected")  # on connecte la fonc network_peer_connected à _player_connected


func _on_ButtonHost_pressed():
	var network = NetworkedMultiplayerENet.new()
	network.create_server(6969, 2)
	get_tree().set_network_peer(network)
	Globals.network = network
	print("hosting")


func _on_ButtonJoin_pressed():
	var network = NetworkedMultiplayerENet.new()
	network.create_client(IP,6969)
	get_tree().set_network_peer(network)
	Globals.network = network
	print("joining")
	
func _player_connected(id):
	var game
	Globals.player2id = id
	game = preload("res://Scenes/Game/Game.tscn").instance()
	get_tree().get_root().add_child(game)
	hide()
	
func _on_TextEdit_text_changed():		# to make it look not too bad
	if editIP.text != '    127.0.0.1' or editIP.text != '':
		IP = editIP.text

func _on_TextEdit_focus_entered():
	if editIP.text == '    127.0.0.1':
		editIP.text = ""

func _on_TextEdit_focus_exited():
	if editIP.text == '':
		editIP.text = "    127.0.0.1"


