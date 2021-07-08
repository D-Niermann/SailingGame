extends Spatial

"""
Calculates a best orientation vector for the given position and given one enemy position and rotation.
Controls from the rigid ship that it is attached to the sails and steering.
Must be direct child of rigidShipController
TODO: All weight have to add to 1?
TODO: for no takes direct positional information, could also be made so that it takes predicted positions
TODO: island navigation (raytrayce in fron tof ship for collisions)
"""
## parameters 
var rotateSpeed = 0.05 # smoothness of rotation of own spatial, (0,1) 1=instant 0=none

export var isActive = false
export var parallelWeight = 0.2
export var windWeight  = 0.5
var towardsWeight = 1  #this can be negative as well to drive away from enemy, now gets set automatically based on optimalDistance
export var broadsideWeight = 0.2
export var optimalDistance = 4
export var windVec = Vector3(1,0,0) # TODO: listen to environment wind dir
var useTerminal = false # make it true and the terminal.gd has to call update() otherwise this will call it
var aimPrecision = 3 # in degree, how much deviation to allow from target to fire (more = more unprecise)

## vars
var enemy # ref to current enemy TODO: what about multiple enemies?
var up
var forward
var right
var org_transform
var angleDiff
var targetVector = Vector3(1,0,0)
var targetRot : Vector3
var towardsEnemy = Vector3(1,0,0)
var broadSideVec
var distToEnemy
var targetSails # not yet used
var angleToEnemy
var myShip

func _ready():
	org_transform = global_transform
	enemy = GlobalObjectReferencer.playerShip
	myShip = get_parent()

func _physics_process(delta):
	if !useTerminal and isActive:
		update(Vector2(0,0),{},[])

func update(destination: Vector2, objectsInRange : Dictionary, islandsInRange : Array):
	# TODO: performance: maybe dont do this every time, only a few times a second?
	up = (global_transform.basis.y).normalized()
	forward = -(global_transform.basis.z).normalized()
	right = -(global_transform.basis.x).normalized()

	distToEnemy = (enemy.global_transform.origin - global_transform.origin).length()
	angleToEnemy = signedAngle(forward,towardsEnemy,up)

	if distToEnemy<50:
		aimCannons()
	calcTargetSails() # calculate the target sail level for the current position
	calcTargetVector() # calculate the target vector for the current position
	rotateToAngle() # rotate this spatial to the target vector
	turnShip() # control the ship so that it follows the direciton of this spatial 
	return {}

# Calculates escape vector to not get into islands or get out of the playable area.
func escapeVector(islandsInRange: Array):
	var totalVector: Vector2 = Vector2.ZERO
	var thisProjection: Vector2 = Vector2(myShip.global_transform.origin.x, myShip.global_transform.origin.z)
	var count: int = 0
	for island in islandsInRange:
		count += 1
		var escapeDirection: Vector2 = (island - thisProjection).normalized()
		# escapeDirection /= max(1, escapeDirection.length() - 64) # 64 is PARTSIZE
		totalVector += escapeDirection
	return Vector3(totalVector.x, 0, totalVector.y) / max(1, count)
	
func aimCannons():
	for id in myShip.itemNodes: # needs to iterate all the time because cannons can be destroyed
		if myShip.itemNodes[id].has_method("aimTo"):
			myShip.itemNodes[id].aimTo(enemy.global_transform.origin)
			## fireing ball is decided by the cannon

func calcTargetSails():
	if distToEnemy<optimalDistance+10:
		myShip.sails = 0.8
	else:
		myShip.sails = 1

func calcTargetVector():
	towardsEnemy = ((enemy.global_transform.origin - global_transform.origin)).normalized()
	towardsWeight = clamp((distToEnemy-optimalDistance)*0.1,-1,1)
	if angleToEnemy>=0:
		broadSideVec = towardsEnemy.rotated(up, PI/2)
	else:
		broadSideVec = towardsEnemy.rotated(up, -PI/2)
	targetVector = -enemy.global_transform.basis.z * parallelWeight  # add the target of going parallel to enemy
	targetVector += windVec.normalized() * windWeight  # add the target of going with the wind
	targetVector += towardsEnemy * towardsWeight  # add the target of going towards or away from enemy
	targetVector += broadSideVec * broadsideWeight # add the target of turn into broadside to enemy
	
	
func turnShip():
	""" this function takes the spatial of this and tries to steer and guide the rigidbody ship towards it."""
	var diff = signedAngle(-myShip.global_transform.basis.z,forward,up)*rotateSpeed
	myShip.turnForce = (diff)*10
	
func rotateToAngle():
	angleDiff = signedAngle(targetVector,forward,up)*rotateSpeed
	rotate(up, angleDiff)

func getAngleDist_deg(from, to):
	var max_angle = 360
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func signedAngle(from: Vector3, to: Vector3, up1: Vector3):
	return atan2(to.cross(from).dot(up1), from.dot(to))
