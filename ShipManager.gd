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
var maxSpeed = 0.2
var turnSpeed = 0
var maxTurnSpeed = 0.002
var def_transform
var height
var ship
export var height_offset = 3
var wheel : TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	humans = get_tree().get_nodes_in_group("Ship/Human")
	wheel = get_tree().get_nodes_in_group("GUI")[0].get_node("Wheel")
	print("W",wheel)
	hFront = $HFront
	hBack = $HBack
	hLeft = $HLeft
	hRight = $HRight
	ship = $Ship
	def_transform = ship.transform
	print(ship)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# for i in humans:
	# 	print(i)
	# print(global_transform)
	pitch = (hFront.transform.origin.y - hBack.transform.origin.y)*pitch_factor
	yaw = (hLeft.transform.origin.y - hRight.transform.origin.y)*yaw_factor
	height = (hFront.transform.origin.y + hBack.transform.origin.y 
	+ hLeft.transform.origin.y + hRight.transform.origin.y)/4.0
	# rotate(Vector3(0,0,1)
	ship.transform = def_transform.rotated(Vector3(0,0,1),pitch).rotated(Vector3(1,0,0),yaw)
	# ship.rotate(Vector3(0,0,1),pitch)
	ship.transform.origin.y = height+height_offset

	## move and rotate
	self.transform.origin += self.transform.basis.x*speed
	rotate(Vector3(0,1,0),turnSpeed)

func _input(event):
	if Input.is_action_pressed("turnLeft"):
		turnSpeed += 0.0001
	if Input.is_action_pressed("turnRight"):
		turnSpeed -= 0.0001
	if Input.is_action_pressed("sailsUp"):
		speed += 0.001
	if Input.is_action_pressed("sailsDown"):
		speed -= 0.001
	turnSpeed = clamp(turnSpeed,-maxTurnSpeed,maxTurnSpeed)
	wheel.set_rotation(-turnSpeed * 1000)
	speed = clamp(speed,-maxSpeed,maxSpeed)
	
# func _physics_process(delta):
	# var space_state = get_world().direct_space_state
	# # use global coordinates, not local to node
	# var camera = get_node("../Camera")
	
	# var result = space_state.intersect_ray(camera.transform.origin, Vector3(0, -1000,0))
#	print(result)
