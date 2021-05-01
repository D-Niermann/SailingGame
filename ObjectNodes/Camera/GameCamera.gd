extends Camera

### parameters (user changeable)

export var minHeight = 5 # how many units above ground
export var maxHeight = 200 # how many units above ground
export var speedScale = 0.1 # between 0 (not move) and 1 (instant move)
export var rotationSensitivity = 0.2
export var zoomSensitivity = 0.2
export var defaultMousePanEdgeSize = 0.02 # how much percent of screen is a edge for panning 
export var aimMousePanEdgeSize = 0.6 # how much percent of screen is a edge for panning 
export var panSpeed = 1.0
export var maxDistFromShip = 100


## init of vars, dont change
var mousePanEdgeSize
var rotate = false
var do_center = false
var shake_val = 0
var cursorPos : Vector2
# var viewport 
var _mouse_position = Vector2(0.0, 0.0)
var target_yar = 0
var right : Vector3
var up : Vector3
# var playerShip = null
var shopping = null
var targetPos : Vector3
var heightToggle = true
var playerIsAiming = false
var localShipVec  = Vector2(0,0)
var mouseDistFromMid = 0.0
var y_save = 0.0 # just a buffer to save the cams y coord
var dist_from_ship_xz = 0.0

func _ready():
	GlobalObjectReferencer.camera = self
	targetPos = Vector3.ZERO
	shopping = get_tree().get_nodes_in_group("Shopping")[0]


func _physics_process(delta):
	

	dist_from_ship_xz = Vector2(global_transform.origin.x - GlobalObjectReferencer.playerShip.global_transform.origin.x,
								global_transform.origin.z - GlobalObjectReferencer.playerShip.global_transform.origin.z).length()

	cursorPos = GlobalObjectReferencer.viewport.get_mouse_position()/GlobalObjectReferencer.viewport.size
	mouseDistFromMid = (cursorPos - Vector2(0.5,0.5)).length()*2


	var relMousePos : Vector2 = (cursorPos - Vector2(0.5,0.5))
	var moveVector : Vector2 = relMousePos 
	if playerIsAiming:
		mousePanEdgeSize = aimMousePanEdgeSize # if player is aiming cannons, edge size can get bigger
	else:
		mousePanEdgeSize = defaultMousePanEdgeSize
		
	## detemine if panning with mouse (get screen edges)
	if abs(moveVector.x)<0.5-mousePanEdgeSize*0.5:
		moveVector.x = 0
	if abs(moveVector.y)<0.5-mousePanEdgeSize*0.5:
		moveVector.y = 0
	
	if playerIsAiming:
		moveVector.x -= (0.5-mousePanEdgeSize*0.5)*sign(moveVector.x)
		moveVector.y -= (0.5-mousePanEdgeSize*0.5)*sign(moveVector.y)

	right = transform.basis.x
	up = transform.basis.y

	if GlobalObjectReferencer.playerShip!=null:
		## if camera is centered around ship
		# if do_center:
		if shopping.open!=null: # shop is open
			localShipVec = Vector2(moveVector.x * 0.1   ,  moveVector.y * 0.1 )
			target_yar = rad2deg(GlobalObjectReferencer.playerShip.transform.basis.get_euler().y+PI/2) # TODO: rotation doent work if cam is not in center of ship
		else: # shop not open
			localShipVec = Vector2.ZERO

		# calc target position
		y_save = targetPos.y # save the y position of the camera
		targetPos += localShipVec.x * -GlobalObjectReferencer.playerShip.transform.basis.z
		targetPos += localShipVec.y * GlobalObjectReferencer.playerShip.transform.basis.x
		targetPos.y = y_save


		## apply calcualtions to target position
		if shopping.open==null: # shop is not open
			targetPos += (moveVector.x *right - moveVector.y * up)*panSpeed*clamp(translation.y*0.01,0.1,5)
			
		targetPos.y = clamp(targetPos.y,clamp(minHeight+dist_from_ship_xz*2,0,maxHeight),maxHeight)

		## camera shake
		targetPos += Vector3(rand_range(-shake_val,shake_val),0,rand_range(-shake_val,shake_val))

		if do_center:
			targetPos.x = 0
			targetPos.z = 0
			do_center = false
		## translate camera towards target position
		translation += ((targetPos + GlobalObjectReferencer.playerShip.global_transform.origin) - translation)*speedScale

		mouseRotate()
		checkToggleOnHeight(50)
		rotate_y(deg2rad(-getAngleDist_deg(target_yar, rad2deg(transform.basis.get_euler().y))*speedScale))
	shake_val*=0.87




func _unhandled_input(event):
	# Receives key input
	if event.is_action_pressed("FireCannons"):
		playerIsAiming = true
	if event.is_action_released("FireCannons"):
		playerIsAiming = false
	if event.is_action_released("centerCamera"):
		do_center = !do_center
	if event.is_action_pressed("zoomOut"):
		targetPos.y *= 1 + zoomSensitivity
	if event.is_action_pressed("zoomIn"):
		targetPos.y *= 1 - zoomSensitivity
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event.is_action_pressed("rotateCamera"):
		rotate = true
	elif event.is_action_released("rotateCamera"):
		rotate = false
	

# Changes camera position according to the chosen deck.
func selectDeck(deckNumber):
	if deckNumber != -1:
		var difference = deckNumber * 2
		if targetPos.y > 20 - difference:
			targetPos.y = 20 - difference
			do_center = true


func mouseRotate():
	if rotate:
		_mouse_position *= 0.25
		target_yar -= _mouse_position.x * rotationSensitivity


func getAngleDist_deg(from, to):
	var max_angle = 360
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference


func checkToggleOnHeight(heightThresh):
	"""
	Checks if the height of height tresh is surpassed and then toggles stuff one.
	Camera height must then be lower to toggle again.
	"""
	if translation.y>heightThresh and heightToggle:
		GlobalObjectReferencer.playerShip.toggleDeckVisible(-1)
		var deckButtons = get_tree().get_root().get_node("GameWorld/Interface/Decks")
		for deckButton in deckButtons.get_children():
			var theButton = get_node_or_null("TextureButton")
			if is_instance_valid(theButton):
				theButton.pressed = false
		GlobalObjectReferencer.camera.selectDeck(-1)
		GlobalObjectReferencer.cursor.selectDeck(-1)
		var decks = get_tree().get_root().get_node("GameWorld/Interface/Decks")
		for child in decks.get_children():
			child.get_node("TextureButton").pressed = false
		heightToggle = false
	if translation.y<heightThresh:
		heightToggle = true
