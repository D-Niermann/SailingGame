extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var humans;
export var pitch_factor = 0.1
export var yaw_factor = 0.1
var pitch
var yaw
var hFront
var hBack
var hLeft
var hRight
var speed = 0
var sails = 0.01 # 0.01 = no sails , 1 = full sails - modifies the ships speed, should never be 0, at least should be something like 0.01 (ship always has some drag)
var wind_dir : Vector2 = Vector2(0,1)  ## TODO: change this constant to the actual wind direction from a wind manager (ocean manager)
var angle_to_wind = 0 # agnle to the wind direction interval [0, 180,-180?]
var speed_mod = 0.2 # speed modifier, more = more max speed
var maxSpeed = 0.2
var turnSpeed = 0
var reverse_speed_factor = 0.02 # factor on how much sailing against the wind will reverse the speed direction (0 for still stand, 0.05 for pretty heavy reverse)
var maxTurnSpeed = 0.004
var def_transform
var height
var ship
var forward : Vector3
export var height_offset = 3
var wheelTexture : TextureRect
var shoppingScreen: Control
var shopIndicator: Button
var shopArea: Area
var deck = null

# Called when the node enters the scene tree for the first time.
func _ready():
	humans = get_tree().get_nodes_in_group("Ship/Human")
	wheelTexture = get_tree().get_root().get_node("Terminal/Interface/Ship/Wheel")
	shoppingScreen = get_tree().get_root().get_node("Terminal/Interface/Shopping")
	shopIndicator = get_tree().get_root().get_node("Terminal/Interface/VBoxContainer/ShopIndicator")
	shopArea = get_node("ShopRangeArea")
	deck = get_node("Ship/Decks/0")
	resetDecksVisibility()
	print("W",wheelTexture)
	hFront = $HFront
	hBack = $HBack
	hLeft = $HLeft
	hRight = $HRight
	ship = $Ship
	def_transform = ship.transform
	print(ship)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# shop detection
	# var colliders: Array = shopArea.get_overlapping_bodies()
	# if !colliders.empty():
	# 	shopIndicator.visible = true
	# else:
	# 	shopIndicator.visible = false
	# 	if shoppingScreen.open != null:
	# 		shoppingScreen.closeShop()

	
	# for i in humans:
	# 	print(i)
	# print(global_transform)
	pitch = (hFront.transform.origin.y - hBack.transform.origin.y)*pitch_factor
	yaw = (hLeft.transform.origin.y - hRight.transform.origin.y)*yaw_factor
	height = (hFront.transform.origin.y + hBack.transform.origin.y 
	+ hLeft.transform.origin.y + hRight.transform.origin.y)/4.0
	# rotate(Vector3(0,0,1)
	# print(pitch)
	ship.transform = def_transform.rotated(Vector3(0,0,1),pitch).rotated(Vector3(1,0,0),yaw)
	# ship.rotate(Vector3(0,0,1),pitch)
	ship.transform.origin.y = height+height_offset

	## move and rotate
	forward = global_transform.basis.x.normalized()
	self.transform.origin += forward*speed
	rotate(Vector3(0,1,0),turnSpeed)
	angle_to_wind = wind_dir.angle_to(Vector2(forward.x,forward.z))
	calcSpeed()
	


func _input(event):
	if Input.is_action_pressed("turnLeft"):
		turnSpeed += 0.0001
	if Input.is_action_pressed("turnRight"):
		turnSpeed -= 0.0001
	if Input.is_action_pressed("sailsUp"):
		sails += 0.01
	if Input.is_action_pressed("sailsDown"):
		sails -= 0.01
	turnSpeed = clamp(turnSpeed,-maxTurnSpeed,maxTurnSpeed)
	sails = clamp(sails,-0.01, 1)
	print(sails)
	# wheelTexture.set_rotation(-turnSpeed * 1000)

func calcSpeed():
	var deg = abs(rad2deg(angle_to_wind))/180
	self.speed =  sails*speed_mod*(pow(deg,2) - 0.8*pow(deg,3))-(reverse_speed_factor*speed_mod*sails)


func angle_deg_diff(angle1, angle2):
	var diff = angle2 - angle1
	return diff if abs(diff) < 180 else diff + (360 * -sign(diff))
	

# func _physics_process(delta):
	# var space_state = get_world().direct_space_state
	# # use global coordinates, not local to node
	# var camera = get_node("../Camera")
	
	# var result = space_state.intersect_ray(camera.transform.origin, Vector3(0, -1000,0))
#	print(result)

func _on_ShopIndicator_pressed():
	if shoppingScreen.open != null:
		shoppingScreen.closeShop()
	else:
		var colliders: Array = shopArea.get_overlapping_bodies()
		if !colliders.empty():
			shoppingScreen.openShop(Utility.resName(colliders[0].name))
			shoppingScreen.target = deck


func _on_DeckUp_pressed():
	var order = int(deck.name) - 1
	if order < 0:
		order = get_node("Ship/Decks").get_child_count() - 1
	deck = get_node("Ship/Decks/" + str(order))
	shoppingScreen.target = deck
	resetDecksVisibility()


func _on_DeckDown_pressed():
	var order = int(deck.name) + 1
	if order > get_node("Ship/Decks").get_child_count() - 1:
		order = 0
	deck = get_node("Ship/Decks/" + str(order))
	shoppingScreen.target = deck
	resetDecksVisibility()


func resetDecksVisibility():
	var order = int(deck.name)
	for child in get_node("Ship/Decks").get_children():
		if int(child.name) < order:
			child.visible = false
		else:
			child.visible = true
