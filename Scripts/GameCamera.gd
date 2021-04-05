extends Camera


var ship
var targetPos : Vector3
export var minHeight = 5
export var maxHeight = 200
export var speedScale = 0.1 # between 0 (not move) and 1 (instant move)
export var rotationSensitivity = 0.2
export var zoomSensitivity = 0.2
var rotate = false

var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var target_yar = 0
func _ready():
	targetPos = translation
	ship = get_tree().get_nodes_in_group("PlayerShip")[0]

func _process(delta):
	targetPos.x = ship.global_transform.origin.x
	targetPos.z = ship.global_transform.origin.z
	targetPos.y = clamp(targetPos.y,minHeight,maxHeight)
	translation += (targetPos - translation)*speedScale
	_update_mouselook()
	rotate_y(deg2rad(-getAngleDist_deg(target_yar, rad2deg(transform.basis.get_euler().y))*speedScale))
	

func _unhandled_input(event):
	# Receives key input
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
	targetPos.y = 20

func _on_Deck0_button_up():
	targetPos.y = 20

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
