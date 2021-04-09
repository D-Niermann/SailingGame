extends Camera

### parameters (user changeable)

export var minHeight = 5 # how many units above ground
export var maxHeight = 200 # how many units above ground
export var speedScale = 0.1 # between 0 (not move) and 1 (instant move)
export var rotationSensitivity = 0.2
export var zoomSensitivity = 0.2
export var defaultMousePanEdgeSize = 0.02 # how much percent of screen is a edge for panning 
export var aimMousePanEdgeSize = 0.4 # how much percent of screen is a edge for panning 
export var panSpeed = 1.0

## init of vars, dont change
var mousePanEdgeSize
var rotate = false
var do_center = false
var shake_val = 0
var cursorPos : Vector2
var viewport 
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var target_yar = 0
var moveLeftRight = 0.0
var moveUpDown = 0.0
var right : Vector3
var up : Vector3
var playerShip = null
var shopping = null
var targetPos : Vector3
var heightToggle = true
var playerIsAiming = false
var localShipVec  = Vector2(0,0)
var mouseDistFromMid = 0.0
var y_save = 0.0 # just a buffer to save the cams y coord

func _ready():
	targetPos = translation
	viewport = get_tree().get_root().get_viewport()
	shopping = get_tree().get_nodes_in_group("Shopping")[0]
	if get_tree().get_nodes_in_group("PlayerShip").size()>0:
		playerShip = get_tree().get_nodes_in_group("PlayerShip")[0]


func _process(delta):
	cursorPos = viewport.get_mouse_position()/viewport.size
	mouseDistFromMid = (cursorPos - Vector2(0.5,0.5)).length()*2

	if playerIsAiming:
		mousePanEdgeSize = aimMousePanEdgeSize # if player is aiming cannons, edge size can get bigger
	else:
		mousePanEdgeSize = defaultMousePanEdgeSize

	## detemine if panning with mouse
	if cursorPos.x<mousePanEdgeSize:
		moveLeftRight = -panSpeed * (mouseDistFromMid-aimMousePanEdgeSize) # subtract aimMousePanEdgeSize for smooth transition from not move to move
	if cursorPos.x>1-mousePanEdgeSize:
		moveLeftRight = +panSpeed * (mouseDistFromMid-aimMousePanEdgeSize)
	if cursorPos.y<mousePanEdgeSize:
		moveUpDown = panSpeed * (mouseDistFromMid-aimMousePanEdgeSize)
	if cursorPos.y>1-mousePanEdgeSize:
		moveUpDown = -panSpeed * (mouseDistFromMid-aimMousePanEdgeSize)

	right = transform.basis.x
	up = transform.basis.y

	if playerShip!=null:

		## if camera is centered around ship
		if do_center:
			if shopping.open!=null: # shop is open
				localShipVec += Vector2(moveLeftRight * 0.1   ,  moveUpDown * 0.1 )
				target_yar = rad2deg(playerShip.transform.basis.get_euler().y) # TODO: rotation doent work if cam is not in center of ship
			else: # shop not open
				localShipVec = Vector2.ZERO

			# calc target position
			targetPos.x = playerShip.global_transform.origin.x
			targetPos.z = playerShip.global_transform.origin.z
			y_save = targetPos.y
			targetPos += localShipVec.x * playerShip.transform.basis.x
			targetPos += localShipVec.y * -playerShip.transform.basis.z
			targetPos.y = y_save

			
			moveLeftRight*=5 # making the mouse edge pan more, because locket to own playerShip
			moveUpDown*= 5 # making the mouse edge pan more, because locket to own playerShip

			if playerIsAiming: # if aiming while centered increase even further
				moveLeftRight*=5 # making the mouse edge pan less, because aiming with cannons
				moveUpDown*= 5 # making the mouse edge pan less, because aiming with cannons
		
		else:
			if playerIsAiming:
				moveLeftRight*=0.6 # making the mouse edge pan less, because aiming with cannons
				moveUpDown*= 0.6 # making the mouse edge pan less, because aiming with cannons

			
	
		## apply calcualtions to target position
		if shopping.open==null: # shop is not open
			targetPos += moveLeftRight*right + moveUpDown * up
			
		targetPos.y = clamp(targetPos.y,minHeight,maxHeight)
		## camera shake
		targetPos += Vector3(rand_range(-shake_val,shake_val),0,rand_range(-shake_val,shake_val))

		## translate camera towards target position
		translation += (targetPos - translation)*speedScale
		# if do_center and (Vector2(targetPos.x,targetPos.z)-Vector2(translation.x,translation.z)).length()<0.1:
		# 	translation.x = playerShip.global_transform.origin.x
		# 	translation.z = playerShip.global_transform.origin.z
		_update_mouselook()
		checkToggleOnHeight(50)
		rotate_y(deg2rad(-getAngleDist_deg(target_yar, rad2deg(transform.basis.get_euler().y))*speedScale))
	shake_val*=0.87
	moveUpDown = 0
	moveLeftRight = 0



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
		# match event.button_index:
		# 	BUTTON_RIGHT: # Only allows rotation if right click down
		# 		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)

func _on_Deck1_button_up():
	if targetPos.y > 18:
		targetPos.y = 18
		do_center = true

func _on_Deck0_button_up():
	if targetPos.y > 20:
		targetPos.y = 20
		do_center = true

func _update_mouselook():
	# Only rotates mouse if the mouse is captured
	# if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
	if rotate:
		_mouse_position *= 0.25
		target_yar -= _mouse_position.x * rotationSensitivity
		# _mouse_position = Vector2(0, 0)


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
		playerShip.toggleDeckVisible(-1)
		shopping.selected_deck = -1
		heightToggle = false
	if translation.y<heightThresh:
		heightToggle = true


# func _on_MouseCameraMoveLeft_mouse_exited():
# 	moveLeftRight= 0
# func _on_MouseCameraMoveLeft_mouse_entered():
# 	moveLeftRight= -1

# func _on_MouseCameraMoveRight_mouse_exited():
# 	moveLeftRight= 0
# func _on_MouseCameraMoveRight_mouse_entered():
# 	moveLeftRight= +1

# func _on_MouseCameraMoveTop_mouse_exited():
# 	moveUpDown= 0
# func _on_MouseCameraMoveTop_mouse_entered():
# 	moveUpDown= +1

# func _on_MouseCameraMoveDown_mouse_exited():
# 	moveUpDown= 0
# func _on_MouseCameraMoveDown_mouse_entered():
# 	moveUpDown= -1
