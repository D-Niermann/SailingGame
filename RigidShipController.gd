extends RigidBody

"""
Default ship rigidbody.
Parent of the whole ship

Needs a linear damping of approx 5!

"""
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var impulse_factor = 5 #overall impulse stength
var turnSpeed = 0
var sails = 0
var ocean
var hLeft
var hRight
var hFront
var hBack
var up 
var forward
var right
# Called when the node enters the scene tree for the first time.
func _ready():
	ocean = get_tree().get_nodes_in_group("Ocean")[0]
	hFront = $HFront
	hBack = $HBack
	hRight = $HRight
	hLeft = $HLeft
	pass # Replace with function body.

func _physics_process(delta):
	up = transform.basis.y
	forward = transform.basis.x
	right = transform.basis.z
	applyPosBuoyancy(hFront, delta)
	applyPosBuoyancy(hBack, delta)
	applyPosBuoyancy(hLeft, delta, 0.5)
	applyPosBuoyancy(hRight, delta, 0.5)
	apply_impulse(transform.basis.xform(hBack.translation),right*turnSpeed*impulse_factor*delta)
	apply_central_impulse(forward*sails)

func _input(event):
	if Input.is_action_pressed("turnLeft"):
		turnSpeed += 0.1
	if Input.is_action_pressed("turnRight"):
		turnSpeed -= 0.1
	if Input.is_action_pressed("sailsUp"):
		sails += 0.01
	if Input.is_action_pressed("sailsDown"):
		sails -= 0.01

func applyPosBuoyancy(obj : Spatial, delta, factor :float = 1.0):
	# apply the boyance (up force) for the given (local) position
	var p = transform.basis.xform(obj.translation) ## impulse postions always need to be transformed like this
	var waterH = ocean.getWaterHeight(obj.global_transform.origin)
	var diff = obj.global_transform.origin.y - waterH # if diff <0 = underwater
	if diff<0:
		apply_impulse(p,Vector3(0,1,0)*factor*pow(abs(diff),1.5)*impulse_factor*delta)
