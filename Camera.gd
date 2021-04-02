extends Camera

export(float, 0.0, 1.0) var sensitivity = 0.25
export var gameCam = true
var camLock = false
var playerShip
# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0

# Movement state
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 5

# Keyboard state
var _w = false
var _s = false
var _a = false
var _d = false
var _q = false
var _e = false


func _ready():
	if get_tree().get_nodes_in_group("PlayerShip").size()>0:
		playerShip = get_tree().get_nodes_in_group("PlayerShip")[0]

func _input(event):

	if event.is_action_pressed("centerCamera"):
		camLock = not camLock

	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_RIGHT: # Only allows rotation if right click down
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			BUTTON_WHEEL_UP: # Increases max velocity
				transform.origin.y -= 5
				_vel_multiplier = clamp(_vel_multiplier / 1.05, 0.2, 100)
				size -= 5
			BUTTON_WHEEL_DOWN: # Decereases max velocity
				transform.origin.y += 5
				_vel_multiplier = clamp(_vel_multiplier * 1.05, 0.2, 100)
				size += 5

	# Receives key input
	if event is InputEventKey:
		match event.scancode:
			KEY_W:
				_w = event.pressed
			KEY_S:
				_s = event.pressed
			KEY_A:
				_a = event.pressed
			KEY_D:
				_d = event.pressed
			# KEY_Q:
			# 	_q = event.pressed
			# KEY_E:
			# 	_e = event.pressed
				


# Updates mouselook and movement every frame
func _process(delta):
	_update_mouselook()
	_update_movement(delta)
	if camLock:
		transform.origin.x = playerShip.transform.origin.x
		transform.origin.z = playerShip.transform.origin.z

# Updates camera movement
func _update_movement(delta):
	# Computes desired direction from key states
	if not gameCam:
		_direction = Vector3(_d as float - _a as float, 
							_e as float - _q as float,
							_s as float - _w as float)
	else:
		_direction = Vector3(_d as float - _a as float, 
							_w as float - _s as float,
							_e as float - _q as float)

	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Checks if we should bother translating the camera
	if _direction == Vector3.ZERO and offset.length_squared() > _velocity.length_squared():
		# Sets the velocity to 0 to prevent jittering due to imperfect deceleration
		_velocity = Vector3.ZERO
	else:
		# Clamps speed to stay within maximum value (_vel_multiplier)
		_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
		_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
		_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	
		translate(_velocity * delta)

# Updates mouse look 
func _update_mouselook():
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg2rad(-yaw))
		if not gameCam:
			rotate_object_local(Vector3(1,0,0), deg2rad(-pitch))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _input(event):
	# var space_state = get_world().direct_space_state
	# # use global coordinates, not local to node
	# var camera = get_node("../Camera")
	
	# var result = space_state.intersect_ray(camera.transform.origin, Vector3(0, -1000,0))
#	print(result)
	
func _on_Body_mouse_entered(a):
	print("Mouse2")
