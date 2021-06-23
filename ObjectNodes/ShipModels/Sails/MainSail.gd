extends Spatial

export var rotateAllowed = true
export var doPrint = false
export var rotateAngleMax = 30
export var isParallelSail = false
export var maxManRequired = 30.0 # needs to be float for division, how many man are needed for max rotation speed
var maxRotSpeed = 0.001 + rand_range(-0.0004, 0.0004) ## TODO: based on number of man on navigation gear
var windDir = Vector3(0,0,-1) ## wind direction, TODO fetch from real wind manager
var rand_time_offset = 0.0
var calledLateReady = false
var myShip = null
var baseRotSpeed = 0.1 
var windForce = 0.0 # this val is read out by myShip to compute the total amount of wind force on the ship
var windProportion = 0.0
var angleToShip = 0.0
var rotateSpeed = 0.0 # depending on how many man are on the rigging gear, [0,1] -> 1 = maxSpeed
var rotateStep 
func _ready():
	rand_time_offset = rand_range(0,2) # if max rand number is around PI, the difference in the shaders is not that big, set to inf and diff is also maximum possible
	$Sail.material_override.set_shader_param("time_offset", rand_time_offset)
	$Sail.material_override.set_shader_param("sail_in", 1.0)

func _process(delta):
	## register to my ship
	if not calledLateReady:
		lateReady()
		calledLateReady = true

	## process
	if is_instance_valid(myShip):
		$Sail.material_override.set_shader_param("sail_in",  1-(1-abs(windProportion))*(myShip.sails))
	
		windProportion = Utility.signedAngle(global_transform.basis.x, windDir, transform.basis.y.normalized())/PI
		if myShip.forward!=null:
			angleToShip = Utility.signedAngle(myShip.forward , global_transform.basis.x, myShip.up)
		if isParallelSail:
			angleToShip+=PI/2
		## rotate towards wind direction
		rotateStep = clamp(-windProportion*baseRotSpeed * rotateSpeed,-maxRotSpeed,maxRotSpeed)
		if rotateAllowed and abs(angleToShip-rotateStep*20)<(rotateAngleMax*PI/180):
			rotate(transform.basis.y.normalized(), rotateStep)
		## calc wind force (TODO: For now just use wind angle)
		windForce = calcWindForce()
		rotateSpeed = calcRotateSpeed()

	# if doPrint: 
		# print("sails: ", myShip.sails)
		# print("step: ", rotateStep)

func lateReady():
	## register to player item
	## path is : mast  -   sailsgroup - shipmodel - shipRigid
	myShip = get_parent().get_parent().get_parent().get_parent()
	## register to ship
	myShip.sailRefs.append(self)

func calcRotateSpeed():
	"""
	For now only uses the man in prio group 1 and 2. problem is that they are in that group even when not
	already on the rigging item. also other jobs that have nothing to do with sails could be in this prio
		group. 

	TODO: make a global variable somwhere (crewmanager) that kepps track of number of man on rigging items
	"""
	if myShip.isPlayer:
		return clamp(GlobalObjectReferencer.crewManager.sumRigging/maxManRequired,0,1)
	else:
		return 1 #TODO: implement crew losses on npc ship and slow it here 


func calcWindForce():
	"""
	Using an accurate formular to get the wind force on sail, based on angle to wind.
	Directly with the wind (angle=0) is a bit slower than at a steep angle with the wind.
	"""
	var deg = 1-abs(windProportion)
	return myShip.sails*myShip.speed_mod*(pow(deg,2) - 0.8*pow(deg,3))-(myShip.reverse_speed_factor*myShip.speed_mod*myShip.sails)
