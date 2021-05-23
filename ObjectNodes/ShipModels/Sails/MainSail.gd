extends Spatial

export var canRotate = true
export var doPrint = false
export var maxManRequired = 10.0 # needs to be float for division
var maxRotSpeed = 0.001 + rand_range(-0.0004, 0.0004) ## TODO: based on number of man on navigation gear
var windDir = Vector3(0,0,-1) ## wind direction, TODO fetch from real wind manager
var rand_time_offset = 0.0
var calledLateReady = false
var myShip = null
var baseRotSpeed = 0.1 
var windForce = 0.0
var windAngle = 0.0
var angleToShip = 0.0
var rotateSpeed = 0.0 # depending on how many man are on the rigging gear, [0,1] -> 1 = maxSpeed

func _ready():
	rand_time_offset = rand_range(0,2) # if max rand number is around PI, the difference in the shaders is not that big, set to inf and diff is also maximum possible
	$Sail.material_override.set_shader_param("time_offset", rand_time_offset)
	$Sail.material_override.set_shader_param("sail_in", 1.0)

func _process(delta):
	if not calledLateReady:
		lateReady()
		calledLateReady = true
	if is_instance_valid(myShip):
		$Sail.material_override.set_shader_param("sail_in", 1-myShip.sails)
	
		windAngle = Utility.signedAngle(global_transform.basis.x, windDir, transform.basis.y.normalized())/PI
		angleToShip = myShip.forward.angle_to(global_transform.basis.x)

		## rotate towards wind direction
		if canRotate:
			
			rotate(transform.basis.y.normalized(), clamp(-windAngle*baseRotSpeed * rotateSpeed,-maxRotSpeed,maxRotSpeed))

		## calc wind force (TODO: For now just use wind angle)
		windForce = calcWindForce()
		rotateSpeed = calcRotateSpeed()
	# if doPrint: 
	# 	print("a: ", angleToShip)

func lateReady():
	## register to player item
	myShip = GlobalObjectReferencer.playerShip
	## register to ship
	if is_instance_valid(myShip):
		myShip.sailRefs.append(self)

func calcRotateSpeed():
	"""
	For now only uses the man in prio group 1 and 2. problem is that they are in that group even when not
	already on the rigging item. also other jobs that have nothing to do with sails could be in this prio
		group. 

	TODO: make a global variable somwhere (crewmanager) that kepps track of number of man on rigging items
	"""
	var n = len(GlobalObjectReferencer.crewManager.currentAssignments[Economy.TG_NAVIGATION].busy[1])
	var m = len(GlobalObjectReferencer.crewManager.currentAssignments[Economy.TG_NAVIGATION].busy[2])

	return clamp((n+m)/maxManRequired,0,1)


func calcWindForce():
	"""
	Using an accurate formular to get the wind force on sail, based on angle to wind.
	Directly with the wind (angle=0) is a bit slower than at a steep angle with the wind.
	"""
	var deg = 1-abs(windAngle)
	return myShip.sails*myShip.speed_mod*(pow(deg,2) - 0.8*pow(deg,3))-(myShip.reverse_speed_factor*myShip.speed_mod*myShip.sails)
