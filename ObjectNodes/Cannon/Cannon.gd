extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var ball
export var BallScene: PackedScene
var fireSounds : Array = []
var forward
var up
export(float) var force = 0.6 # for trajectory prediction: force of ball
var drag = 0.05 # for trajectory prediction: drag of ball
var rand_max_delay = 0.4 # max delay in seconds
var ship # parent ship container
### vars for line rendering (but the gitHub LineRenderer lags so hard that i canceled it for now)
var line
const lineSize = 30 # length of trjactory prediction line (number of points) / needs some rework
const rotateSpeed = 0.005
const unprecision = 1
onready var rotateMargin = rand_range(-unprecision,unprecision) # error in rotation that is accepted (mouse position) left right
const maxRotateAngle = 20 # in degree
onready var upDownMargin = rand_range(-unprecision,unprecision) # what difference to mouse pos units to ignore when rotating  up down
export(float) var fire_delay_sec = 0.1 # fire delay after pressing fire button
var maxUpAngle = 20
var minUpAngle= 0 
var camera
var org_rotation : Vector3
var position3D
var particles
var particles_flash
var aimCannons
var ocean
var waterHitMarker
var myShip
var fakeBullet
export var isPlayerControlable = false

# Called when the node enters the BallScene tree for the first time.
func _ready():
	fakeBullet = $FakeBullet
	camera = get_viewport().get_camera()
	org_rotation = transform.basis.get_euler()*180/PI
	if get_tree().get_nodes_in_group("Ocean").size()>0:
		ocean = get_tree().get_nodes_in_group("Ocean")[0]
	myShip = get_parent().get_parent().get_parent()
	if myShip!= null and "isPlayer" in myShip:
		if myShip.isPlayer:
			isPlayerControlable = true
	fireSounds.push_back(get_node("Audio1"))
	fireSounds.push_back(get_node("Audio2"))
	fireSounds.push_back(get_node("Audio3"))
	
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



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	up = global_transform.basis.y.normalized()
	
	forward = global_transform.basis.x.normalized()
	
	if aimCannons:
		var dropPlane  = Plane(Vector3(0, 1, 0), 0)
		var from = camera.project_ray_origin(get_viewport().get_mouse_position())
		var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * 2000
		position3D = to_local(dropPlane.intersects_ray( from, to ))
		# print(position3D)
		## if mouse position in front of cannon (x>0)
		if position3D.x >= 2: 
			predictTrajectory()
			var dist = (position3D).x
			var diff = dist - (line.points[lineSize-1]).x
			if diff>upDownMargin: 
				rotateUp(diff-upDownMargin)
			elif diff<-upDownMargin:
				rotateDown(diff+upDownMargin)
			if position3D.z<-rotateMargin:
				rotateLeft(position3D.z+rotateMargin)
			elif position3D.z>rotateMargin:
				rotateRight(position3D.z-rotateMargin)
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
			if position3D!= null and position3D.x >= 2:
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
	fakeBullet.transform.origin = Vector3(0,0,0)
	var point : Vector3 
	var waterHeight = -10000
	var last_i = 0
	for i in range(lineSize):
		point = fakeBullet.transform.origin
		line.points[i] = point
		if ocean!=null:
			waterHeight = ocean.getWaterHeight(to_global(point))
		if to_global(point).y>waterHeight:
			fakeBullet.transform.origin += Vector3(1,0,0)*force*2.5
			fakeBullet.global_transform.origin += Vector3(0,-1,0)*0.02*i ## TODO: does the vector (0,-1,0) always point down globally (gravity)? -> if so why does (1,0,0) always point forwards loccally
		else:
			last_i = i
			break
	if last_i != 0: # if line ever crossed the water line (went under water)
		var aboveWater : Vector3 = (line.points[last_i-1]) #
		var underWater : Vector3 = (line.points[last_i])  # last point position in array (threw error once)
		var halfPoint
		for _i in range(8): # number of bisections (1/2 -> 1/4 -> 1/8 -> 1/16 -> ...)
			halfPoint = underWater + ((aboveWater - underWater)/2) #
			if ocean.getWaterHeight(to_global(halfPoint))<to_global(halfPoint).y:
				# half point is over water
				aboveWater = halfPoint
			else:
				# half point is under water
				underWater = halfPoint
		## now take either the underwater or above water point
		var preciseWaterPoint = aboveWater
		for i in range(last_i, lineSize):
			line.points[i] = preciseWaterPoint

	waterHitMarker.visible = true
	waterHitMarker.translation += (line.points[lineSize-1] - waterHitMarker.translation)*0.1

			
func clearTrajectory():
	var point = Vector3(0,0,0)
	waterHitMarker.translation = point
	waterHitMarker.visible = false
	for i in range(lineSize):
		line.points[i] = point

func fireBall():
	yield(get_tree().create_timer(fire_delay_sec),"timeout")
	playAudio()
	doParticles()
	yield(get_tree().create_timer(rand_range(0,rand_max_delay)),"timeout")
	var ball = BallScene.instance()
	get_tree().get_root().add_child(ball)
	ball.set_name("Ball")
	ball.transform.origin = self.global_transform.origin+forward
	ball.dir = forward
	# ball.apply_impulse(ball.transform.origin,forward*force)
	ball.velocity = force


## TODO: change these funtions into 1 or 2 functions
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
	# print("rotateUp")
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	# if abs(getAngleDist_deg(transform.basis.get_euler().z*180/PI,org_rotation.z))<maxUpAngle:
	rotate(transform.basis.z.normalized(),rotateSpeed*0.2*multiplicator)
	# # counter rotation of above threshold
	# 	rotate(transform.basis.z.normalized(),-rotateSpeed*0.21*multiplicator)
func rotateDown(multiplicator=1):
	# print("rotateDown")
	# check if current rotation angle doesnt exeed the max angle
	multiplicator = clamp(abs(multiplicator),0,1)
	# if abs(getAngleDist_deg(transform.basis.get_euler().z*180/PI,org_rotation.z))>minUpAngle:
	rotate(transform.basis.z.normalized(),-rotateSpeed*0.2*multiplicator)
	# counter rotation of above threshold
		# rotate(transform.basis.z.normalized(),rotateSpeed*0.21*multiplicator)
		
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

func playAudio():
	fireSounds[int(rand_range(0,2.4))].set_pitch_scale(rand_range(0.8,1.2))
	fireSounds[int(rand_range(0,2.4))].play()
