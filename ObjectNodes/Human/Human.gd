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
var bodyHeight = 0.1
var itemFetchTime = 2
# var currentTaskGroup = null
var isHuman = true # flag for shopping script to see if this kin body is human
var infoPanel
# var isAssigned = false
var id
var currentTask

var pathDeck = null # used by navigator, don't change manually
var pathLocs: Array = [] # used by navigator, don't change manually
var speed: float = 1 # maximum speed per second for this unit's movement


func _ready():
	targetPos.x += rand_range(-0.3,0.3)
	targetPos.z += rand_range(-0.3,0.3)
	id = IDGenerator.getID()

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
	targetPos.x += rand_range(-0.3,0.3)
	targetPos.z += rand_range(-0.3,0.3)
	
func walkTowards(targetPos : Vector3):
	""" for now some simple function, later will use navmesh """
	var walkDir = (targetPos-self.translation)
	if walkDir.length()>1:
		walkDir = walkDir.normalized()
	self.translation += walkDir*0.01
	self.translation.y = 0#bodyHeight

func _process(delta):
#	walkTowards(targetPos)
	targetPos = Vector3(0, 0, 0) # remove this line later, this is for test purpose
	targetDeck = get_parent() # remove this line later, this is for test purpose
	if is_instance_valid(targetDeck):
		var velocity: Vector3 = findVelocity(Vector2(targetPos.x, targetPos.z), targetDeck)
		translation += velocity * delta
		translation.y = 0


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



# Tries to get directions, using pathfinding when necessary.
func findVelocity(toLoc: Vector2, atDeck: Spatial):
	# aborting operation if deck is not found
	if !is_instance_valid(atDeck):
		return Vector3.ZERO
	# cleaning path if target has changed
	if pathDeck != atDeck || (!pathLocs.empty() && pathLocs[0] != toLoc):
			pathLocs.clear()
			pathDeck = atDeck
	# getting directions
	if atDeck != get_parent(): # then go to stairs instead
		return Vector3.ZERO # this part is under construction
	else:
		var thisPart: Vector2 = closestPartition(Vector2(translation.x, translation.y))
		var destPart: Vector2 = closestPartition(toLoc)
		print("thisPart: "+str(thisPart)+" destPart: "+str(destPart))
		var destDist = chebyshevDistance(thisPart, destPart)
		if destDist == 0: # means we already are inside the tile
#			return Vector3.ZERO # opt for this one if you don't want units to keep going till they reach the center of the tile
			return limitVelocity(Vector3(toLoc.x, 0, toLoc.y) - translation, speed)
		elif destDist < 2: # means we are so close that we can directly go towards
			return limitVelocity(Vector3(toLoc.x, 0, toLoc.y) - translation, speed)
		else: # means it is far away and we need to follow path
			if !is_instance_valid(pathDeck) || pathDeck != atDeck || pathLocs.empty() || chebyshevDistance(thisPart, pathLocs[-1]) > 1 || isOccupied(pathLocs[-1]):
				pathLocs = findPath(thisPart, destPart, true)
			if !pathLocs.empty():
				return limitVelocity(Vector3(pathLocs[-1].x, 0, pathLocs[-1].y) - translation, speed)
			else:
				return Vector3.ZERO

# Truncates length of the given velocity according to the given maximum speed.
func limitVelocity(velocity: Vector3, maxSpeed: float):
	if velocity.length_squared() > pow(maxSpeed, 2):
		return velocity.normalized() * maxSpeed
	else:
		return velocity

# Finds path between the given parts.
func findPath(from: Vector2, to: Vector2, canCross: bool):
	var temp = null
	var paths: Dictionary = {from: {"path": [from], "dist": 0}}
	var open: Dictionary = {from: null}
	var close: Dictionary = {}
	var limit: int = 100
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
	var distance: int = chebyshevDistance(from, to)
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
	if !get_parent().isTileOccupied.has(partition) || get_parent().isTileOccupied[partition]:
		return true
	return false

# Returns adjacent parts for the given part.
func findAdjacent(partition: Vector2, canCross: bool):
	var tilewidth: float = GlobalObjectReferencer.shopping.TILEWIDTH
	var keys = []
	keys.append(partition + Vector2(tilewidth, 0))
	keys.append(partition + Vector2(-tilewidth, 0))
	keys.append(partition + Vector2(0, tilewidth))
	keys.append(partition + Vector2(0, -tilewidth))
	if canCross:
		keys.append(partition + Vector2(tilewidth, tilewidth))
		keys.append(partition + Vector2(tilewidth, -tilewidth))
		keys.append(partition + Vector2(-tilewidth, tilewidth))
		keys.append(partition + Vector2(-tilewidth, -tilewidth))
	return keys

# Returns closest partition identification key for the given location according to the tilewidth.
func closestPartition(location: Vector2):
	var halfwidth: float = GlobalObjectReferencer.shopping.TILEWIDTH * 0.5
	location.x = stepify(location.x, halfwidth)
	location.y = stepify(location.y, halfwidth)
	if location.x - floor(location.x) == 0:
		location.x += halfwidth
	if location.y - floor(location.y) == 0:
		location.y += halfwidth
	return location

# Returns chebyshev distance between two three dimensional vectors.
func chebyshevDistance(from: Vector2, to: Vector2):
	return max(abs(from.x - to.x), abs(from.y - to.y))
