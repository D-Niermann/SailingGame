extends KinematicBody
class_name Human
"""
base Script on each human. maybe other special humans like officers can inherit from this.
gets controlled by crew manager, only feature is that he gets a target position and walks there, maybe later adding stamina and so on, but that can be done in crew manager too
"""

export var InfoPanel: PackedScene # scene object of cannons info ui panel

## stati
const S_TIRED = "S_TIRED"  # too tired to work
const S_DRUNK = "S_DRUNK" # too drunk to work
const S_HUNGRY = "S_HUNGRY" # too hungry
const S_THIRSTY = "S_THIRSTY" # too thirsty
const S_WOUNDED = "S_WOUNDED"  # too wounded - needs to go to doctor

var itemID = null # ref to the curernt item the human is working
var jobID = null # ref to the curernt item the human is working
var stati = [] #keeps track of all stati (stati = [S_Hungry, S_THIRSTY, ...]) 
var targetPos = Vector3.ZERO
var targetDeck = null # this needs to get set
var currentDeck = 0 # I don't need that, you can remove this variable
var bodyHeight = 0.3
var itemFetchTime = 2
# var currentTaskGroup = null
var isHuman = true # flag for shopping script to see if this kin body is human
var infoPanel
# var isAssigned = false
var id
var currentTask

var pathDeck = null # used by navigator, don't change manually
var pathLocs: Array = [] # used by navigator, don't change manually
var nextDest = null # used by navigator, don't change manually
var speed: float = 1 # maximum speed per second for this unit's movement


func _ready():
	targetPos = Vector3(0, 0, 0) # remove this line later, this is for test purpose
	targetDeck = get_tree().get_nodes_in_group("PlayerDeck")[0] # remove this line later, this is for test purpose

	targetPos.x += rand_range(-0.3,0.3)
	targetPos.z += rand_range(-0.3,0.3)
	id = IDGenerator.getID()
	# make sprite randomly height
	$Sprite3D.translation.y += rand_range(-0.01,0.01)
	$Sprite3D.modulate*= rand_range(0.4,1.0)
	$Sprite3D.modulate.b*= rand_range(0.4,1.0)
	$Sprite3D.modulate.a = 1

func assignDeck(deckRef):
	get_parent().remove_child(self)
	deckRef.add_child(self)

func giveGoToTask(task):
	"""
	gives a task
	"""
	currentTask = task
	targetPos = task.position
	self.itemID = task.itemID # the current target item ,  mark itemID for crew manager so he can check if close to item
	self.jobID = task.jobID 
	# currentTaskGroup = TG

func giveFetchTask(task):
	currentTask = task
	targetPos = task.storageItemPos
	self.itemID = task.storageItemID # the current target item , mark itemID for crew manager so he can check if close to item
	self.jobID = null

func proceedFetchTask():
	print("proceed called . ", self.name)
	# yield(get_tree().create_timer(itemFetchTime),"timeout")
	self.itemID = currentTask.targetItemID
	targetPos = currentTask.targetItemPos


func removeTask():
	# targetPos = (target_position)
	self.itemID = null
	currentTask = null
	self.jobID = null
	targetPos = Vector3.ZERO
	targetPos.x += rand_range(-0.6,0.6)
	targetPos.z += rand_range(-0.6,0.6)
	
func walkTowards(targetPos : Vector3): # this function is not needed anymore
	""" for now some simple function, later will use navmesh """
	var walkDir = (targetPos-self.translation)
	if walkDir.length()>1:
		walkDir = walkDir.normalized()
	self.translation += walkDir * 0.01
	self.translation.y = 0 #bodyHeight


func _process(delta):
#	walkTowards(targetPos) # this is not needed anymore
	moveTo(delta, targetPos, targetDeck)
	# this part below is for debugging, you can comment it out
	for tile in pathLocs:
		get_parent().markTile(tile)


func createInfo(placeholder):
	"""
	Overwrites in inherited item classes.
	Instances the correponding item info panel and moves it to placeholder.rect_position.
	The instanced info box connects to this item and communicates user input and item stati.
	"""
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
	"""
	Overwrites in inherited item classes.
	removes info panel again
	"""
	if infoPanel!=null:
		infoPanel.queue_free()

# Tries to move to the given location.
func moveTo(delta: float, toLoc: Vector3, atDeck: Spatial):
	if is_instance_valid(atDeck):
		var velocity: Vector3 = findVelocity(delta, Vector2(toLoc.x, toLoc.z), atDeck)
		translation += velocity * delta
		translation.y = 0

# Tries to find velocity to reach the given location.
func findVelocity(delta: float, toLoc: Vector2, atDeck: Spatial):
	# aborting operation if deck is not found
	if !is_instance_valid(atDeck):
		return Vector3.ZERO
	# cleaning path if target deck has changed
	if pathDeck != atDeck || (nextDest != null && !pathLocs.empty() && pathLocs[0] != partitionID(nextDest, GlobalObjectReferencer.shopping.TILEWIDTH)):
		pathLocs.clear()
		pathDeck = atDeck
		nextDest = null
	# removing location from path if reached
	var thisPart: Vector2 = partitionID(Vector2(translation.x, translation.z), GlobalObjectReferencer.shopping.TILEWIDTH)
	if !pathLocs.empty() && pathLocs[-1] == thisPart:
		pathLocs.pop_back()
#		print("waypointReached")
	# deciding either target or stairs
	if atDeck == get_parent(): # can go directly towards the target
		nextDest = toLoc
#		print("sameDeck")
	elif nextDest == null: # needs to find stairs
		var closestStairs = null
		var shortestDistance = 999999999
		for stairs in GlobalObjectReferencer.playerShip.stairs:
			var destPart: Vector2 = partitionID(stairs, GlobalObjectReferencer.shopping.TILEWIDTH)
			var destDist = chebyshevDistance(thisPart, destPart)
			if destDist < shortestDistance:
				shortestDistance = destDist
				closestStairs = stairs
		if closestStairs != null:
			nextDest = closestStairs
#			print("stairsFound")
		else:
			nextDest = null
#			print("stairsNotFound")
	# getting directions
	if nextDest == null:
#		print("noDestinations")
		return Vector3.ZERO
	elif atDeck != get_parent():
		if Vector3(translation.x, 0, translation.z).distance_squared_to(Vector3(nextDest.x, 0, nextDest.y)) < 0.25:
			assignDeck(atDeck)
#			print("changedDecks")
			return Vector3.ZERO
	var destPart: Vector2 = partitionID(nextDest, GlobalObjectReferencer.shopping.TILEWIDTH)
#	print("thisPart: "+str(thisPart)+" destPart: "+str(destPart))
	var destDist = chebyshevDistance(thisPart, destPart)
	if destDist == 0: # means we already are inside the tile
#		print("sameTile")
#		return Vector3.ZERO # opt for this one if you don't want units to keep going till they reach the center of the tile
		return adjustVelocity(delta, Vector3(nextDest.x, 0, nextDest.y) - Vector3(translation.x, 0, translation.z), speed)
	elif destDist < 2: # means we are so close that we can directly go towards
#		print("adjacentTile")
		return adjustVelocity(delta, Vector3(nextDest.x, 0, nextDest.y) - Vector3(translation.x, 0, translation.z), speed)
	else: # means it is far away and we need to follow path
		if !is_instance_valid(pathDeck) || pathDeck != atDeck || pathLocs.empty() || chebyshevDistance(thisPart, pathLocs[-1]) > 1 || isOccupied(pathLocs[-1]):
			if GlobalObjectReferencer.crewManager.currentlyPathfinding == null:
				GlobalObjectReferencer.crewManager.currentlyPathfinding = self
				pathLocs = findPath(thisPart, destPart, true)
#				print("pathfinding...")
		if !pathLocs.empty(): # path is available
#			print("followingPath")
			var localCoordinates = partitionLocation(pathLocs[-1], GlobalObjectReferencer.shopping.TILEWIDTH)
#			print("local: "+str(localCoordinates)+" for: "+str(pathLocs[-1]))
			return adjustVelocity(delta, Vector3(localCoordinates.x, 0, localCoordinates.y) - Vector3(translation.x, 0, translation.z), speed)
		else:
#			print("pathIsEmpty")
			return Vector3.ZERO # this means no path has been found

# Clamps length of the given velocity according to the given maximum speed.
func adjustVelocity(delta: float, velocity: Vector3, maxSpeed: float):
	var sqrMagnitude: float = velocity.length_squared()
	if sqrMagnitude > pow(maxSpeed, 2):
		return velocity.normalized() * maxSpeed
	else:
		var estLength: float = pathLocs.size() * GlobalObjectReferencer.shopping.TILEWIDTH
		if maxSpeed > pow(estLength, 2):
			return velocity.normalized() * estLength
		else:
			return velocity.normalized() * maxSpeed

# Finds path between the given parts.
func findPath(from: Vector2, to: Vector2, canCross: bool):
	var temp = null
	var paths: Dictionary = {from: {"path": [from], "dist": 0}}
	var open: Dictionary = {from: null}
	var close: Dictionary = {}
	var limit: int = 300
	while limit > 0 && !open.empty():
		var lowest: Vector2
		var value: int = -1
		for part in open.keys():
			var score: int = paths[part]["dist"] + chebyshevDistance(part, to)
			if value < 0 || score < value:
				value = score
				lowest = part
		close[lowest] = null
		open.erase(lowest)
		var adjacent: Array = findAdjacent(lowest, canCross)
		for part in adjacent:
			if open.has(part) || close.has(part) || !canPass(lowest, part, canCross):
				continue
			var path: Array = paths[lowest]["path"].duplicate(true)
			path.append(part)
			paths[part] = {"path": path, "dist": paths[lowest]["dist"] + 1}
			open[part] = null
			if part == to:
				temp = path
				limit = 0
				break
		limit -= 1
	if temp == null:
		print("failedToFindPath to: ",to)
		return []
		var lowest: Vector2
		var value: int = -1
		for part in close.keys():
			var score: int = paths[part]["dist"] + chebyshevDistance(part, to)
			if value < 0 || score < value:
				value = score
				lowest = part
		temp = paths[lowest]["path"]
	temp.invert()
	return temp

# Checks if transition between the given parts is possible.
func canPass(from: Vector2, to: Vector2, canCross: bool):
	var difference: Vector2 = to - from
	var distance = chebyshevDistance(from, to)
	if distance > 1:
		return false
	if difference.length_squared() > 1:
		if !canCross:
			return false
		var comp: Vector2
		comp = Vector2(difference.x, 0)
		if comp != Vector2.ZERO && isOccupied(from + comp):
			return false
		comp = Vector2(0, difference.y)
		if comp != Vector2.ZERO && isOccupied(from + comp):
			return false
	if isOccupied(to):
		return false
	#print("canPassTo: " + str(to) + " from: " + str(from))
	return true

# Checks if the given part is occupied.
func isOccupied(partition: Vector2):
	if !get_parent().isTileOccupied.has(partition) || (get_parent().isTileOccupied[partition] != null && get_parent().isTileOccupied[partition] != itemID):
		return true
	return false

# Returns adjacent parts for the given part.
func findAdjacent(partition: Vector2, canCross: bool):
	var keys = []
	keys.append(partition + Vector2(1, 0))
	keys.append(partition + Vector2(-1, 0))
	keys.append(partition + Vector2(0, 1))
	keys.append(partition + Vector2(0, -1))
	if canCross:
		keys.append(partition + Vector2(1, 1))
		keys.append(partition + Vector2(1, -1))
		keys.append(partition + Vector2(-1, 1))
		keys.append(partition + Vector2(-1, -1))
	return keys

# Returns partition identification key for the given location.
func partitionID(location: Vector2, length: float):
	var partition = location / length
	return partition.floor()

# Returns location of the given partition.
func partitionLocation(partition: Vector2, length: float):
	var halfLength = length * 0.5
	return partition * length + Vector2(halfLength, halfLength)

# Returns chebyshev distance between two three dimensional vectors.
func chebyshevDistance(from: Vector2, to: Vector2):
	return max(abs(from.x - to.x), abs(from.y - to.y))
