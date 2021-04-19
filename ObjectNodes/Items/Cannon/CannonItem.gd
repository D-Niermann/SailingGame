extends "res://ObjectNodes/Items/BaseItem.gd"



### Paramters
export var BallScene: PackedScene # scene object of ball
export var InfoPanel: PackedScene # scene object of cannons info ui panel

export(float) var force          = 0.6 # for trajectory prediction: force of ball
export(float) var fire_delay_sec = 0.1 # fire delay after pressing fire button
export(float) var recoil_impulse = 0.3 # when firing to the ship
export var isTestCannon          = false # if cannon is fired when aiming and left clicking, (to test trajectory, without firing the whole broadside), can be set as a gameplay elemetn in th info panel
var    drag                      = 0.05 # for trajectory prediction: drag of ball
var    rand_max_delay            = 0.4 # max delay in seconds # TODO: all these contant parameters could be set in item dictionary to save RAM
var    reload_time_sec           = 4 # reload time in seconds # TODO: all these contant parameters could be set in item dictionary to save RAM
var    cam_shake                 = 0.1 # the amount of camera shake added to camera when shooting
const  rotateSpeed               = 0.004 # max rotation speed of cannons (up/down rotation is scaled down )
const  maxRotateAngle            = 20 # in degree,                                           left right rotation
var    maxUpAngle                = 10 # angle distance in degreee from original rotation that is allowed
var    minUpAngle                = -5 # angle distance in degreee from original rotation that is allowed
const  unprecision               = 4 # in units,                                             how max unprecise a connon is (random)
var    markerMoveSpeed           = 0.05 # how fast markes of trajectory move


### 
var forward : Vector3
var up : Vector3
var right : Vector3
onready var rotateMargin = rand_range(-unprecision,unprecision) # error in rotation that is accepted (mouse position) left right
onready var upDownMargin = rand_range(-unprecision,unprecision) # what difference to mouse pos units to ignore when rotating  up down
var fireSounds : Array = [] # refs to aduio players (randomly chooses one of them when fired)
var infoPanel = null # ref to instanced info panel
var lineSize  # length of trjactory prediction line , gets fetched automatically based on amount of sprites in the TrajectoryMarkerGroup
var reloaded = true # if cannon is ready to fire or not
# var camera # ref to camera (for shake)
var aimPosition # the position the cannons will aim to (needs to be local)
var particles
var particles_flash
var playerAimCannons # flag thats true if the player uses input to aim
var isActive = true # flag that tells if this is active or not (deactived cannons dont aim or shoot)
var waterHitMarker
var fakeBullet # spatial used for trajectory planning
var marker 
var canShoot :bool = false # if is in angle range and range and stuff (if cannon can shoot)
var aimDiffAngle # angle between target aim position and forward
var forward2d = Vector2(1,0) 
var trajectoryPoints : Array
var org_forward
var reloadTimer : Timer



func _ready():
	## overwrite parent vars
	maxCrew = 4
	fetchDictParams("CannonLarge")

	marker = $TrajectoryMarkerGroup.get_children()
	fakeBullet = $FakeBullet
	lineSize = marker.size()
	org_forward = transform.basis.x.normalized() # used for angle calculation
	

	
	reloadTimer = Timer.new()
	add_child(reloadTimer)
	reloadTimer.connect("timeout", self, "_on_reloadTimer_timeout")
	reloadTimer.set_wait_time(reload_time_sec)
	reloadTimer.set_one_shot(true) # Make sure it loops


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

func onPlacement():
	.onPlacement() # calls the parent function
	org_forward = transform.basis.x.normalized() # used for angle calculation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	up = transform.basis.y.normalized()
	right = transform.basis.z.normalized()
	
	forward = transform.basis.x.normalized()

	if playerAimCannons and isActive:
		aimTo(GlobalObjectReferencer.ocean.waterMousePos)
	
	if infoPanel!=null:
		isActive = infoPanel.isActive


func aimTo(global_position : Vector3):
	aimPosition = to_local(global_position)
	aimDiffAngle = rad2deg(forward2d.angle_to(Vector2(aimPosition.x ,aimPosition.z)))
	if abs(aimDiffAngle) <= maxRotateAngle*2: 
		canShoot = true
		predictTrajectory()
		var dist = (aimPosition).x
		var diff_x = dist - (trajectoryPoints[lineSize-1]).x
		if diff_x>upDownMargin: 
			rotateUpDown((diff_x+upDownMargin)*0.5, "up")
		elif diff_x<-upDownMargin:
			rotateUpDown((diff_x-upDownMargin)*0.5, "down")
		if aimPosition.z<-rotateMargin:
			rotateLeftRight((aimPosition.z-rotateMargin)*0.5, "left")
		elif aimPosition.z>rotateMargin:
			rotateLeftRight((aimPosition.z+rotateMargin)*0.5, "right")
	else:
		canShoot = false
		clearTrajectory()

func giveDmg(damage):
	.giveDmg(damage)
	if infoPanel!=null:
		infoPanel.updateHealth(currentHealth)

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
		if GlobalObjectReferencer.ocean!=null:
			waterHeight = GlobalObjectReferencer.ocean.getWaterHeight(to_global(point))
		if to_global(point).y>waterHeight:
			if myShip.isPlayer:
				marker[i].translation += (trajectoryPoints[i] - marker[i].translation)*markerMoveSpeed
				if i>1:
					if reloaded:
						marker[i].material_override.albedo_color = Color(1,1,1,0.5)
					else:
						marker[i].material_override.albedo_color = Color(0.6,0.2,0.2,0.5)
					marker[i].visible = true
			fakeBullet.transform.origin += Vector3(1,0,0)*force*5.2/(1+i*0.05)
			fakeBullet.global_transform.origin += Vector3(0,-1,0)*0.015*i 
		else:
			last_i = i
			break
	if last_i != 0: # if line ever crossed the water line (went under water)
		var aboveWater : Vector3 = (trajectoryPoints[last_i-1]) #
		var underWater : Vector3 = (trajectoryPoints[last_i])  # last point position in array (threw error once)
		var halfPoint
		for _i in range(8): # number of bisections (1/2 -> 1/4 -> 1/8 -> 1/16 -> ...)
			halfPoint = underWater + ((aboveWater - underWater)/2) #
			if GlobalObjectReferencer.ocean.getWaterHeight(to_global(halfPoint))<to_global(halfPoint).y:
				# half point is over water
				aboveWater = halfPoint
			else:
				# half point is under water
				underWater = halfPoint
		## now take either the underwater or above water point
		var preciseWaterPoint = aboveWater
		if myShip.isPlayer:
			for i in range(last_i, lineSize):
				trajectoryPoints[i] = preciseWaterPoint
				marker[i].translation += (trajectoryPoints[i] - marker[i].translation)*markerMoveSpeed
				marker[i].visible = true


	if myShip.isPlayer:
		if reloaded:
			waterHitMarker.material_override.albedo_color = Color(1,1,1,0.5)
		else:
			waterHitMarker.material_override.albedo_color = Color(0.6,0.2,0.2,0.5)
		waterHitMarker.visible = true
		waterHitMarker.translation += (trajectoryPoints[lineSize-1] - waterHitMarker.translation)*markerMoveSpeed

			
func clearTrajectory():
	var point = Vector3(0,0,0)
	waterHitMarker.translation = point
	waterHitMarker.visible = false

	for i in range(lineSize):
		marker[i].visible = false
		marker[i].translation = point
		trajectoryPoints[i] = point

func fireBall():
	if reloaded and isActive:
		reloaded = false
		yield(get_tree().create_timer(fire_delay_sec),"timeout")
		playAudio()
		doParticles()
		GlobalObjectReferencer.camera.shake_val += cam_shake/clamp(GlobalObjectReferencer.camera.global_transform.origin.distance_to(global_transform.origin)*0.02,1,99999)
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
	var angle_dist = rad2deg(Utility.signedAngle(org_forward,(forward),up))
	if dir == "left" and angle_dist>-maxRotateAngle:
		rotate(up,rotateSpeed*multiplicator)
		$CollisionShape.rotate(up,-rotateSpeed*multiplicator) # counter rotate the collider so it stays on grid
	elif dir == "right" and angle_dist<maxRotateAngle:
		rotate(up,-rotateSpeed*multiplicator)
		$CollisionShape.rotate(up,rotateSpeed*multiplicator) # counter rotate the collider so it stays on grid


func rotateUpDown(multiplicator=1, dir : String = ""):
	"""
	Rotate the cannons around either left or right. Speed Weighted by multiplicator e[0,1]
	dir :: either 'left' or 'right'
	TODO: change dir to -1,1 to increase performance
	"""
	multiplicator = clamp(abs(multiplicator),0,1)
	## up rotation = positive angle distance
	var angle_dist = -rad2deg(Utility.signedAngle(org_forward,(forward),right)) 
	if dir == "up" and angle_dist<maxUpAngle:
		rotate(transform.basis.z.normalized(),rotateSpeed*0.2*multiplicator)
	elif dir == "down" and angle_dist>minUpAngle:
		rotate(transform.basis.z.normalized(),-rotateSpeed*0.2*multiplicator)
		

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

func _on_reloadTimer_timeout():
	reloaded = true


func createInfo(placeholder):
	if InfoPanel!=null:
		## instance panel
		infoPanel = InfoPanel.instance()
		infoPanel.visible = false
		infoPanel.positionRef = placeholder
		self.add_child(infoPanel)
		infoPanel.rect_position = placeholder.rect_position

		## link self to panel, enables info access
		infoPanel.link(self)

		## make panel visible
		infoPanel.visible = true

func removeInfo():
	if infoPanel!=null:
		infoPanel.queue_free()
