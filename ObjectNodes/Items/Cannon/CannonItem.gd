extends "res://ObjectNodes/Items/BaseItem.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var ball
export var BallScene: PackedScene
var fireSounds : Array = []
var forward : Vector3
var up : Vector3
var right : Vector3
export(float) var force = 0.6 # for trajectory prediction: force of ball
var drag = 0.05 # for trajectory prediction: drag of ball
var rand_max_delay = 0.4 # max delay in seconds
var reload_time_sec = 5
var cam_shake = 0.2 # the amount of camera shake added to camera when shooting
var ship # parent ship container
### vars for line rendering (but the gitHub LineRenderer lags so hard that i canceled it for now)
# var line
var lineSize  # length of trjactory prediction line (number of points) / needs some rework
const rotateSpeed = 0.008 # max rotation speed of cannons (up/down rotation is scaled down )
const maxRotateAngle = 20 # in degree, left right rotation
var maxUpAngle = 10 # angle distance in degreee from original rotation that is allowed
var minUpAngle= -2 # angle distance in degreee from original rotation that is allowed
const unprecision = 4 # in units, how max unprecise a connon is (random)
onready var rotateMargin = rand_range(-unprecision,unprecision) # error in rotation that is accepted (mouse position) left right
onready var upDownMargin = rand_range(-unprecision,unprecision) # what difference to mouse pos units to ignore when rotating  up down
export(float) var fire_delay_sec = 0.1 # fire delay after pressing fire button
export(float) var recoil_impulse = 0.3 # when firing to the ship

var reloaded = true

var camera
var org_rotation : Vector3
var aimPosition # the position the cannons will aim to (needs to be local)
var particles
var particles_flash
var playerAimCannons # flag thats true if the player uses input to aim
var ocean
var waterHitMarker
var myShip
var fakeBullet
export var isPlayerControlable = false
var marker 
var canShoot :bool = false
var aimDiffAngle # angle between target aim position and forward
var forward2d = Vector2(1,0)
var trajectoryPoints : Array
export var isTestCannon = false
var org_forward
var reloadTimer : Timer
func _ready():
	marker = $TrajectoryMarkerGroup.get_children()
	lineSize = marker.size()
	fakeBullet = $FakeBullet
	camera = get_viewport().get_camera()
	org_rotation = transform.basis.get_euler()*180/PI
	org_forward = transform.basis.x.normalized() # used for angle calculation
	if get_tree().get_nodes_in_group("Ocean").size()>0:
		ocean = get_tree().get_nodes_in_group("Ocean")[0]
	
	reloadTimer = Timer.new()
	add_child(reloadTimer)
	reloadTimer.connect("timeout", self, "_on_Timer_timeout")
	reloadTimer.set_wait_time(reload_time_sec)
	reloadTimer.set_one_shot(true) # Make sure it loops
	
	## TODO: this gets also called when item is picked in shop
	myShip = get_parent().get_parent().get_parent()
	if myShip != null:
		## register as cannon on ship parent
		if myShip.has_method("registerCannon"):
			myShip.registerCannon(self.get_path())
		if "isPlayer" in myShip:
			if myShip.isPlayer:
				isPlayerControlable = true



	fireSounds.push_back(get_node("Audio1"))
	fireSounds.push_back(get_node("Audio2"))
	fireSounds.push_back(get_node("Audio3"))
	fireSounds.push_back(get_node("Audio4"))
	fireSounds.push_back(get_node("Audio5"))
	
	waterHitMarker = $WaterHitMarker
	particles = $Particles
	particles_flash = $ParticlesFlash

	# line = $LineRenderer
	trajectoryPoints = []
	for _i in range(lineSize):
		trajectoryPoints.append(Vector3(0,0,0))
	# ship = get_parent().get_parent().get_parent()
	set_process_input(true) 
	clearTrajectory()

func on_placement():
	.on_placement() # calls the parent function
	org_rotation = transform.basis.get_euler()*180/PI
	org_forward = transform.basis.x.normalized() # used for angle calculation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	up = transform.basis.y.normalized()
	right = transform.basis.z.normalized()
	
	forward = transform.basis.x.normalized()

	if playerAimCannons:
		aimTo(ocean.waterMousePos)
	


func aimTo(global_position : Vector3):
	aimPosition = to_local(global_position)
	aimDiffAngle = rad2deg(forward2d.angle_to(Vector2(aimPosition.x ,aimPosition.z)))
	if abs(aimDiffAngle) <= maxRotateAngle*2: 
		canShoot = true
		predictTrajectory()
		var dist = (aimPosition).x
		var diff_x = dist - (trajectoryPoints[lineSize-1]).x
		if diff_x>upDownMargin: 
			rotateUpDown(diff_x-upDownMargin, "up")
		elif diff_x<-upDownMargin:
			rotateUpDown(diff_x+upDownMargin, "down")
		if aimPosition.z<-rotateMargin:
			rotateLeftRight(aimPosition.z+rotateMargin, "left")
		elif aimPosition.z>rotateMargin:
			rotateLeftRight(aimPosition.z-rotateMargin, "right")
	else:
		canShoot = false
		clearTrajectory()

	

func _unhandled_input(event):
	# Receives key input
	if isPlayerControlable:
		if event.is_action_pressed("FireCannons"):
			playerAimCannons = true
		if event.is_action_released("FireCannons"):
			playerAimCannons = false
			clearTrajectory()
			if canShoot:
				fireBall()
		if playerAimCannons:
			if event.is_action_released("testFire") and isTestCannon and canShoot:
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
		trajectoryPoints[i] = point
		if ocean!=null:
			waterHeight = ocean.getWaterHeight(to_global(point))
		if to_global(point).y>waterHeight:
			marker[i].translation += (trajectoryPoints[i] - marker[i].translation)*0.1
			if i>1:
				marker[i].visible = true
			fakeBullet.transform.origin += Vector3(1,0,0)*force*5.2/(1+i*0.05)
			fakeBullet.global_transform.origin += Vector3(0,-1,0)*0.015*i ## TODO: does the vector (0,-1,0) always point down globally (gravity)? -> if so why does (1,0,0) always point forwards loccally
		else:
			last_i = i
			break
	if last_i != 0: # if line ever crossed the water line (went under water)
		var aboveWater : Vector3 = (trajectoryPoints[last_i-1]) #
		var underWater : Vector3 = (trajectoryPoints[last_i])  # last point position in array (threw error once)
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
			trajectoryPoints[i] = preciseWaterPoint
			marker[i].translation += (trajectoryPoints[i] - marker[i].translation)*0.1
			marker[i].visible = true


	waterHitMarker.visible = true
	waterHitMarker.translation += (trajectoryPoints[lineSize-1] - waterHitMarker.translation)*0.1

			
func clearTrajectory():
	var point = Vector3(0,0,0)
	waterHitMarker.translation = point
	waterHitMarker.visible = false

	for i in range(lineSize):
		marker[i].visible = false
		marker[i].translation = point
		trajectoryPoints[i] = point

func fireBall():
	if reloaded:
		reloaded = false
		yield(get_tree().create_timer(fire_delay_sec),"timeout")
		playAudio()
		doParticles()
		camera.shake_val += cam_shake/clamp(camera.global_transform.origin.distance_to(global_transform.origin)*0.02,1,99999)
		myShip.applyCannonImpulse(translation, -transform.basis.x.normalized()*recoil_impulse)
		yield(get_tree().create_timer(rand_range(0,rand_max_delay)),"timeout")
		var ball = BallScene.instance()
		get_tree().get_root().add_child(ball)
		ball.set_name("Ball")
		ball.transform.origin = self.global_transform.origin+ self.global_transform.basis.x*1 # + foward to give ball a forward offset to get behind own walls
		ball.dir = global_transform.basis.x
		ball.velocity = force
		reloadTimer.start()


## TODO: change these funtions into 1 or 2 functions
func rotateLeftRight(multiplicator=1, dir : String = ""):
	"""
	Rotate the cannons around either left or right. Speed Weighted by multiplicator e[0,1]
	dir :: either 'left' or 'right'
	TODO: change dir to -1,1 to increase performance
	"""
	multiplicator = clamp(abs(multiplicator),0,1)
	## left rotation = negative angle distance
	var angle_dist = rad2deg(Utility.signedAngle(org_forward,(forward),up)) #getAngleDist_deg(transform.basis.get_euler().y*180/PI,org_rotation.y)
	if dir == "left" and angle_dist>-maxRotateAngle:
		rotate(up,rotateSpeed*multiplicator)
	elif dir == "right" and angle_dist<maxRotateAngle:
		rotate(up,-rotateSpeed*multiplicator)


func rotateUpDown(multiplicator=1, dir : String = ""):
	"""
	Rotate the cannons around either left or right. Speed Weighted by multiplicator e[0,1]
	dir :: either 'left' or 'right'
	TODO: change dir to -1,1 to increase performance
	"""
	multiplicator = clamp(abs(multiplicator),0,1)
	## up rotation = positive angle distance
	var angle_dist = -rad2deg(Utility.signedAngle(org_forward,(forward),right)) # -getAngleDist_deg(transform.basis.get_euler().z*180/PI,org_rotation.z)
	if dir == "up" and angle_dist<maxUpAngle:
		rotate(transform.basis.z.normalized(),rotateSpeed*0.2*multiplicator)
	elif dir == "down" and angle_dist>minUpAngle:
		rotate(transform.basis.z.normalized(),-rotateSpeed*0.2*multiplicator)
		
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
	var sound = fireSounds[int(rand_range(0,fireSounds.size()))]
	sound.set_pitch_scale(rand_range(0.6,1.0))
	sound.play()

func _on_Timer_timeout():
	reloaded = true
