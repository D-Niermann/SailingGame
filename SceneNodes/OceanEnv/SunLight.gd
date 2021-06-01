extends DirectionalLight


## paramas
var height = 2 # the heigher the less the shadows and angles
var horizonDist = -0.4 # the bigger the flatter the sun angle (closer to horizon)
var maxDist = 2.0 # distance the light is moved 
var speed = 0.001 # the bigger the faster a day / noght cicle will be
var threshold = 5 # threshold dist for when to recalcualte the directional_shadow_max_distance
var nightSpeedMod = 4 # night is this times faster than day
var speedMod = 1 # for UI controls


## vars
var lastheight = 0
var sunAngle = 0.0
var up = Vector3.ZERO
var isDay = true

func _ready():
	translation.y = height
	translation.x = horizonDist
	pass

func _process(delta):
	up = global_transform.basis.y
	self.light_color = Color(1,1,1)

	translation.z += speed * speedMod
	if translation.z>=maxDist and isDay:
		isDay = false
		translation.y = -20
		# print("Disabling Shadows in Sunlight")
		# self.shadow_enabled = false
		speed = -speed*nightSpeedMod
	elif translation.z<=-maxDist and not isDay:
		isDay = true
		# self.shadow_enabled = true
		speed = -speed*1/nightSpeedMod
		translation.y = height


	# sunAngle =  Vector3(0,1,0).angle_to(-global_transform.basis.z) * 180/PI
	sunAngle = abs(translation.z)/maxDist
	changeColor()
	look_at(Vector3.ZERO, up)
	if is_instance_valid(GlobalObjectReferencer.camera):
		## use these to if states because shadow is flickering else
		if (GlobalObjectReferencer.camera.targetPos.y-lastheight) >= threshold:
			lastheight = GlobalObjectReferencer.camera.targetPos.y
			directional_shadow_max_distance = lastheight+threshold+2
		elif (GlobalObjectReferencer.camera.transform.origin.y-lastheight) < threshold:
			lastheight = GlobalObjectReferencer.camera.transform.origin.y
			directional_shadow_max_distance = lastheight+threshold+2


func changeColor():
	if isDay:
		self.light_color.r = 1+sunAngle/4
		self.light_color.g = 1-sunAngle/2
		self.light_color.b = 1-sunAngle
		self.light_energy = 1.6*(1-sunAngle)
		self.shadow_color.r = sunAngle
		self.shadow_color.g = sunAngle
		self.shadow_color.b = sunAngle
