extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var ball
export var BallScene: PackedScene
var forward
var up
export(float) var force = 0.6 # for trajectory prediction: force of ball
var drag = 0.05 # for trajectory prediction: drag of ball
var rand_max_delay = 0.4 # max delay in seconds
var ship # parent ship container
### vars for line rendering (but the gitHub LineRenderer lags so hard that i canceled it for now)
var line
const lineSize = 60 # length of trjactory prediction line (number of points) / needs some rework
const rotateSpeed = 0.005
onready var rand_rot_offset = rand_range(-2,2)
onready var rotateMargin = 1+rand_rot_offset # error in rotation that is accepted (mouse position) left right
const maxRotateAngle = 20 # in degree
const upDownMargin = 2 # what difference to mouse pos units to ignore when rotating  up down
export(float) var fire_delay_sec = 0.1 # fire delay after pressing fire button
var camera
var org_rotation : Vector3
var position3D
var particles
var particles_flash
var aimCannons
var ocean
var waterHitMarker
var myShip
var isPlayerControlable = false

# Called when the node enters the BallScene tree for the first time.
func _ready():
	camera = get_viewport().get_camera()
	org_rotation = transform.basis.get_euler()*180/PI
	if get_tree().get_nodes_in_group("Ocean").size()>0:
		ocean = get_tree().get_nodes_in_group("Ocean")[0]
	if get_parent()!=null:
		if get_parent().get_parent()!=null:
			myShip = get_parent().get_parent().get_parent()
			if myShip.isPlayer:
				isPlayerControlable = true
	waterHitMarker = $WaterHitMarker
	particles = $Particles
	particles_flash = $ParticlesFlash

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
		# print(((line.points[lineSize-1]).x))
		## if mouse position in front of cannon (x>0)
		if position3D.x >= 0: 
			predictTrajectory()
			var dist = (position3D).x
			var diff = dist - (line.points[lineSize-1]).x
			if diff>upDownMargin: 
				rotateUp(diff)
			elif diff<-upDownMargin:
				rotateDown(diff)
			if position3D.z<-rotateMargin:
				rotateLeft(position3D.z)
			elif position3D.z>rotateMargin:
				rotateRight(position3D.z)
		else:
			clearTrajectory()


	

func _unhandled_input(event):
	# Receives key input
	if isPlayerControlable:
		if event.is_action_pressed("FireCannons"):
			aimCannons = true
		if event.is_action_released("FireCannons"):
			aimCannons = false
			clearTrajectory()
			if position3D!= null and position3D.x >= 0:
				fireBall()
		
	# if event.is_action_released("RotateCannonLeft"):
	# 	rotateLeft()
	# if event.is_action_released("RotateCannonRight"):
	# 	rotateRight()

	# if Input.is_key_pressed(KEY_R):
	# 	self.add_child(ball)
	# 	ball.linear_velocity = Vector3(0,0,0)
	# 	ball.transform.origin = transform.origin

func predictTrajectory():
	"""
	Calculates the balls trajectory (approx). If water is hit, always adds this last point to the array of 
	trajectory points.
	TODO: Better synch actuall ball traj. with this calculation.
	"""
	var point : Vector3 = Vector3(0,0,0)
	var waterHeight = 0
	for i in range(lineSize):
		line.points[i] = point
		if ocean!=null:
			waterHeight = ocean.getWaterHeight(to_global(point))
		if to_global(point).y>waterHeight:
			point += Vector3(1,0,0)*force*2.5
			point += Vector3(0,-1,0)*0.02*i ## TODO: does the vector (0,-1,0) always point down (gravity)? -> if so why does (1,0,0) always point forwards loccally
	waterHitMarker.visible = true
	waterHitMarker.translation += (point - waterHitMarker.translation)*0.05

			
func clearTrajectory():
	var point = Vector3(0,0,0)
	waterHitMarker.translation = point
	waterHitMarker.visible = false
	for i in range(lineSize):
		line.points[i] = point

func fireBall():
	yield(get_tree().create_timer(fire_delay_sec),"timeout")
	doParticles()
	yield(get_tree().create_timer(rand_range(0,rand_max_delay)),"timeout")
	var ball = BallScene.instance()
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
	# counter rotation of above threshold
	if abs(getAngleDist_deg(transform.basis.get_euler().y*180/PI,org_rotation.y))>maxRotateAngle:
		rotate(up,-rotateSpeed*multiplicator)
func rotateRight(multiplicator=1):
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	rotate(up,-rotateSpeed*multiplicator)
	# counter rotation of above threshold
	if abs(getAngleDist_deg(transform.basis.get_euler().y*180/PI,org_rotation.y))>maxRotateAngle:
		rotate(up,rotateSpeed*multiplicator)

func rotateUp(multiplicator=1):
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	rotate(transform.basis.z.normalized(),rotateSpeed*0.2*multiplicator)
	# counter rotation of above threshold
	if abs(getAngleDist_deg(transform.basis.get_euler().z*180/PI,org_rotation.z))>maxRotateAngle/2:
		rotate(transform.basis.z.normalized(),-rotateSpeed*0.21*multiplicator)
func rotateDown(multiplicator=1):
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	rotate(transform.basis.z.normalized(),-rotateSpeed*0.2*multiplicator)
	# counter rotation of above threshold
	if abs(getAngleDist_deg(transform.basis.get_euler().z*180/PI,org_rotation.z))>maxRotateAngle/2:
		rotate(transform.basis.z.normalized(),rotateSpeed*0.21*multiplicator)
		
func getAngleDist_deg(from, to):
	var max_angle = 360
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func doParticles():
	particles.restart()
	particles_flash.restart()
	particles.emitting = true
	particles_flash.emitting = true
	# yield(get_tree().create_timer(1),"timeout")
	
