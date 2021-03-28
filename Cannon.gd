extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var ball
var forward
var up
var force = 3
var rand_max_delay = 0.4 # max delay in seconds
var ship # parent ship container
### vars for line rendering (but the gitHub LineRenderer lags so hard that i canceled it for now)
var line
var lineSize = 30
var rotateSpeed = 0.01
var rotateMargin = 0.2 # error in rotation that is accepted (mouse position)
var maxRotateAngle = 20 # in degree
var camera
var org_rotation 
var position3D
var particles
var aimCannons

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_tree().get_nodes_in_group("Camera")[0]
	org_rotation = transform.basis.get_euler().y*180/PI
	particles = $Particles

	line = $LineRenderer
	line.points = []
	for _i in range(lineSize):
		line.points.append(Vector3(0,0,0))
	# ship = get_parent().get_parent().get_parent()
	set_process_input(true) 
	clearTrajectory()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	up = global_transform.basis.y.normalized()

	forward = global_transform.basis.x.normalized()
	
	if aimCannons:
		var dropPlane  = Plane(Vector3(0, 1, 0), 0)
		var from = camera.project_ray_origin(get_viewport().get_mouse_position())
		var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * 2000
		position3D = to_local(dropPlane.intersects_ray( from, to ))
		# print((position3D))
		if position3D.x >= 0:
			predictTrajectory()
			if position3D.z<-rotateMargin:
				rotateLeft(position3D.z)
			elif position3D.z>rotateMargin:
				rotateRight(position3D.z)
		else:
			clearTrajectory()


	

func _input(event):
	# Receives key input
	if event.is_action_pressed("FireCannons"):
		aimCannons = true
	if event.is_action_released("FireCannons"):
		aimCannons = false
		clearTrajectory()
		if position3D.x >= 0:
			fireBall()
		
	if event.is_action_released("RotateCannonLeft"):
		rotateLeft()
	if event.is_action_released("RotateCannonRight"):
		rotateRight()

	# if Input.is_key_pressed(KEY_R):
	# 	self.add_child(ball)
	# 	ball.linear_velocity = Vector3(0,0,0)
	# 	ball.transform.origin = transform.origin

func predictTrajectory():
	var point = Vector3(0,0,0)
	for i in range(lineSize):
		line.points[i] = point
		point += Vector3(1,0,0)*force*1
		point += Vector3(0,-1,0)*0.04*i
func clearTrajectory():
	var point = Vector3(0,0,0)
	for i in range(lineSize):
		line.points[i] = point

func fireBall():
	doParticles()
	yield(get_tree().create_timer(rand_range(0,rand_max_delay)),"timeout")
	var scene = load("res://Ball2.tscn")
	var ball = scene.instance()
	get_tree().get_root().add_child(ball)
	ball.set_name("Ball")
	ball.transform.origin = self.global_transform.origin+forward
	ball.dir = forward
	# ball.apply_impulse(ball.transform.origin,forward*force)
	ball.velocity = force

func rotateLeft(multiplicator=1):
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	rotate(up,rotateSpeed*multiplicator)
	if abs(getAngleDist_deg(transform.basis.get_euler().y*180/PI,org_rotation))>maxRotateAngle:
		rotate(up,-rotateSpeed*multiplicator)
func rotateRight(multiplicator=1):
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	rotate(up,-rotateSpeed*multiplicator)
	if abs(getAngleDist_deg(transform.basis.get_euler().y*180/PI,org_rotation))>maxRotateAngle:
		rotate(up,rotateSpeed*multiplicator)

func getAngleDist_deg(from, to):
	var max_angle = 360
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func doParticles():
	particles.emitting = true
	particles.restart()
	# yield(get_tree().create_timer(1),"timeout")
	
