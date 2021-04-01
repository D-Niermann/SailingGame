extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var impulse_factor = 5
var turnSpeed = 0
var sails = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var boye = $Spatial
	var x = transform.basis.xform(boye.transform.origin) ## impulse postions always need to be transformed like this
	var up = transform.basis.y
	var forward = transform.basis.z
	var right = transform.basis.x
	if translation.y<1:
		apply_impulse(x,up*1*(1-transform.origin.y)*impulse_factor*delta)
		apply_impulse(-x,up*1*(1-transform.origin.y)*impulse_factor*delta)
	apply_impulse(x,right*turnSpeed*impulse_factor*delta)
	apply_central_impulse(forward*sails)

func _input(event):
	if Input.is_action_pressed("turnLeft"):
		turnSpeed += 0.01
	if Input.is_action_pressed("turnRight"):
		turnSpeed -= 0.01
	if Input.is_action_pressed("sailsUp"):
		sails += 0.01
	if Input.is_action_pressed("sailsDown"):
		sails -= 0.01
