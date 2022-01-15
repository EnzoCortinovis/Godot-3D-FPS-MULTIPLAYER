extends KinematicBody

var speed = 6
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 7  #JUSTE CA A CHANGER POUR POUVOIR MIEUX BOUGER EN L'AIR !!
onready var accel = ACCEL_DEFAULT
var gravity = 25
var jump = 8

var cam_accel = 40
var mouse_sense = 0.1
var snap

var direction = Vector3()
var anim_dir
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()
var is_running = false
var jumping = false
var flexing = false

var movementLocked = false
var modeEchap = false
var modeFullScreen = false

var vieCombat
var vieEnnemy
var powerOfPunch = 10
var ennemyPlayer		# player à frapper
var isInReach = false   # si on peut le frapper
var isParing = false 
var isPunching = false

onready var head = $Head
onready var camera = $Head/Camera
onready var anim = get_node("RootNode/AnimationPlayer")

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

# MULTIPLAYER FUNCTIONS 

remote func _set_position(pos):
	global_transform.origin = pos

remote func _set_rotation(rota):
	rotate_y(rota)

remote func _set_animation(animat, reverse):
	if reverse:
		anim.play_backwards(animat,0.1)
	else:
		if animat == "punch" or animat == "taunt":
			anim.play(animat,0.1,2)
		else:
			anim.play(animat,0.1)


# =======================================================================#
# ============================  INPUT EVENT  ============================# 
# =======================================================================#
func _input(event):
	
	#get mouse input for camera rotation
	
	if is_network_master():
		var rota_y
		if event is InputEventMouseMotion:
			if !modeEchap:
				rota_y = deg2rad(-event.relative.x * mouse_sense)
				rotate_y(rota_y)
				head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
				head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
				if rota_y != null:
					rpc_unreliable("_set_rotation", rota_y)  # Pour voir les autres joueurs tourner
					
	if event.is_action_pressed("sprint"):		# Gestion du sprint
		speed = 10
		if direction != Vector3.ZERO:
			is_running = true
	elif event.is_action_released("sprint"):
		speed = 6
		is_running = false
	
	if event.is_action_pressed("echap"):		# Gestion d'echap
		if !modeEchap:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			modeEchap = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			modeEchap = false
			
	if event.is_action_pressed("fullscreen"):		# Gestion FullScreen ( c'est pas clean mais c'est la seule manière pour que ça fonctionne )
		if !modeFullScreen:
			OS.window_fullscreen = true
			modeFullScreen = true
		else:
			OS.window_fullscreen = false
			modeFullScreen = false
			

# =======================================================================#
# =======================================================================#


# ============================================================================#
# ============================  PHYSICS PROCESS ==============================# 
# ============================================================================#

func _physics_process(delta):
	#get keyboard input
	direction = Vector3.DOWN
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("backward") - Input.get_action_strength("forward") # To move in every direction and not only on axis
	var h_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	if !movementLocked:
		direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	anim_dir = "idle"
	if !movementLocked:
		# Maybe not the best way, but way easier to handle animations
		if Input.is_action_pressed("forward"):
			anim_dir = "fd"
		if Input.is_action_pressed("backward"):
			anim_dir = "bd"
		if Input.is_action_pressed("left") and !(Input.is_action_pressed("forward") or Input.is_action_pressed("backward")) :
			anim_dir = "left"
		if Input.is_action_pressed("right") and !(Input.is_action_pressed("forward") or Input.is_action_pressed("backward")):
			anim_dir = "right"
		if Input.is_action_pressed("paring"):
			anim_dir = "paring"
			isParing = true
		else : 
			isParing = false

	if is_network_master() and !jumping and !flexing:
		set_anim(anim_dir , is_running)

	
	#jumping and gravity
	if is_on_floor():
		#snap = Vector3.DOWN
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
		jumping = false
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor() and !flexing:
		print('jump')
		direction = Vector3.UP
		snap = Vector3.ZERO
		if (!Input.is_action_pressed("left") and !Input.is_action_pressed("right") and !Input.is_action_pressed("forward") and !Input.is_action_pressed("backward")):
			gravity_vec = Vector3.UP * jump * 1.5
		else:
			gravity_vec = Vector3.UP * jump
		direction = Vector3.UP
		anim.play("jump",0.1)
		jumping = true
		if is_network_master():
			rpc_unreliable("_set_animation", "jump", false)
		
	# Player doesn't stay in air if you aren't pressing anything
	if (!Input.is_action_pressed("left") and !Input.is_action_pressed("right") and !Input.is_action_pressed("forward") and !Input.is_action_pressed("backward")):
		direction = Vector3.DOWN
	
	# EMOTES & PUNCHING ANIMS
	
	if Input.is_action_just_pressed("emote1") and is_on_floor() and !flexing: 
		anim.play("backflip",0.1)
		flexing = true
		if is_network_master():
			rpc_unreliable("_set_animation", "backflip", false)
	
	if Input.is_action_just_pressed("emote2") and is_on_floor() and !flexing: 
		anim.play("gangnam",0.1)
		flexing = true
		if is_network_master():
			rpc_unreliable("_set_animation", "gangnam", false)
	
	if Input.is_action_just_pressed("emote3") and is_on_floor() and !flexing: 
		anim.play("danseVague",0.1)
		flexing = true
		if is_network_master():
			rpc_unreliable("_set_animation", "danseVague", false)
	
	if Input.is_action_just_pressed("punch")  and is_on_floor() and !flexing:
		anim.play("punch",0.1,2)
		flexing = true
		isPunching = true
		if is_network_master():
			rpc_unreliable("_set_animation", "punch", false)	
#		if isInReach:
#			sendDamages(powerOfPunch)
#			print("Sending damages to gameversus")
#		if isInReach:						# si ennemy dans notre reach alors on lui envoie
#			if is_network_master():			#  qu'il a prit des dégats
#				rpc_unreliable("_set_degats", 10)
#				vieEnnemy = vieEnnemy-10
			#ennemyPlayer.takeDamage(10)
			
	if Input.is_action_just_pressed("victory") and is_on_floor() and !flexing: 
		anim.play("victory",0.1)
		flexing = true
		if is_network_master():
			rpc_unreliable("_set_animation", "victory", false)
			
	if Input.is_action_just_pressed("emote4")  and is_on_floor() and !flexing:
		anim.play("taunt",0.1,2)
		flexing = true
		if is_network_master():
			rpc_unreliable("_set_animation", "taunt", false)

#	What finaly make the player move 
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
	if direction != Vector3() and !movementLocked:
		if is_network_master():
			move_and_slide_with_snap(movement, snap, Vector3.UP,true)
			rpc_unreliable("_set_position", global_transform.origin)  # Send info to other player

# ============================================================================#
# ============================================================================#

#        PLAYER ANIMATIONS  :
func set_anim(dir, is_running):
	var animation
	var reverse = false
	if dir == "idle" and anim.current_animation != "idle":
		anim.play("idle",0.1)
		animation = "idle"
	elif dir == "fd" and !is_running and anim.current_animation !="walk":
		anim.play("walk",0.1)
		animation = "walk"
	elif dir == "fd" and is_running and anim.current_animation != "run":
		anim.play("run",0.1)
		animation = "run"
	elif dir == "left" and !is_running and anim.current_animation !="strafe_left":
		anim.play("strafe_left",0.1)
		animation = "strafe_left"
	elif dir == "right" and !is_running and anim.current_animation !="strafe_left":
		anim.play_backwards("strafe_left",0.1)
		animation = "strafe_left"
		reverse = true
	elif dir == "bd" and anim.current_animation !="backward":
		anim.play_backwards("walk",0.1)
		animation = "walk"
		reverse = true
	elif dir == "paring" and anim.current_animation !="paring":
		anim.play_backwards("paring",0.1)
		animation = "paring"
		reverse = true
		print(vieCombat)
		print(self.name)
	if animation != null:
			rpc_unreliable("_set_animation", animation, reverse)  # Send animation to other player

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "backflip" or anim_name == "gangnam" or anim_name == "danseVague" or anim_name == "punch" or anim_name == "victory" or anim_name == "taunt":
		flexing = false
	if anim_name == "punch":
		isPunching = false
