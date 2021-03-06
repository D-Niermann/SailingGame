extends RigidBody

"""
Default ship rigidbody.
Parent of the whole ship

RigidBody Needs a linear damping of approx 5!

"""

var stairs: Array = [Vector2(-1.5, 0.0)]

# parameters 
# sailing and wind stuff
var wind_dir = Vector2(0,1) # TODO: make real wind direction vector in the ocean env
export var speed_mod = 0.2 # speed modifier, more = more max speed, could be changed because of higher load mass
export var reverse_speed_factor = -0.2 # factor on how much sailing against the wind will reverse the speed direction (0 for still stand, 0.05 for pretty heavy reverse, negative values for allowing sailing against wind)
export var crossWindForce = 0.01 # force that attacks the ship up on the sails, tilting it with the wind
export var maxTurnForce = 0.05 # max turn fomaxSailSetSpeed*clamprce of the whole shi,0,1p
export var sailsManNeeded = 40.0
export var maxSailSetSpeed = 0.002

export(bool) var isPlayer = false
export(bool) var isUnsinkable = false
export var impulse_factor = 3.0 # overall impulse stength, all impulses should be multiplied by this


### vars
var model # ref to ship model
var turnForce : float # current turn force for left right steer
var sails # current sail state (0,1) 1=full sails
var sailRefs = [] # aray of all sails on this ship (they append themselfs)
var itemNodes = {} # ref to all items in ships model (used for center of mass)
var turnCommandPressed = false
var waterLevel = 1.0 # 1 = default, how much water the ship has taken, used in boyance calculation, if near impulse_factor, its start to sink
var speed = 0.0 #keeps track of the ships speed

# force spatials
var hLeft # positions where boynacy attacks
var hRight # positions where boynacy attacks
var hFront # positions where boynacy attacks
var hBack # positions where boynacy attacks
var mainSailForce # Spatial - where the force of main sail wind is applied
var centerOfMass = Vector3.ZERO # Vector3 that keepts track of center of mass 


# directional vectors (updated every frame)
var up 
var forward
var right


func _ready():

	hFront = $HFront
	hBack = $HBack
	hRight = $HRight
	hLeft = $HLeft 
	mainSailForce = $MainSailForce # TODO: implement point of attack for turning, now its just the back point (could be further in the middle)
	model = $Model


	turnForce = 0
	sails = 0

	## add Decks to item placeable deck group if ship belongs to player
	if isPlayer:
		print("PlayerShip Ready Call")
		GlobalObjectReferencer.playerShip = self # register player ship
		var a = model.get_children()
		for i in range(1, a.size()):
			# iterate through children, skip 1st because it is Sails
			a[i].add_to_group("PlayerDeck")
		reloadDecks(2)

func registerItem(node):
	"""
	Adds Item to array containing all items that are on ship.
	Handles other stuff that needs to be handled when new item is placed
	"""
	itemNodes[node.id] = node
	if isPlayer:
		calcCenterOfMass()
	# print("registered "+node.name)

func unregisterItem(node):
	"""
	un-register item node from itemNodes array
	"""
	itemNodes.erase(node.id)

func _physics_process(delta):
	speed = sqrt(pow(linear_velocity.x,2)+pow(linear_velocity.z,2))

	if isPlayer:
		turnForce = InputManager.rudderPos 
	if isPlayer:
		sails += sign(InputManager.sailsTarget-sails)*maxSailSetSpeed*clamp(GlobalObjectReferencer.crewManager.sumRigging/sailsManNeeded,0,1)
	sails = clamp(sails,-0.01, 1)
	
	turnForce = clamp(turnForce,-maxTurnForce,maxTurnForce)	

	up = transform.basis.y
	forward = -transform.basis.z
	right = -transform.basis.x
	applyPosBuoyancy(hFront, delta, 1)
	applyPosBuoyancy(hBack, delta, 1)
	applyPosBuoyancy(hLeft, delta, 0.1) # less force because the roll is otherwise too strong
	applyPosBuoyancy(hRight, delta, 0.1) # less force because the roll is otherwise too strong
	## turn impulse
	apply_impulse(transform.basis.xform(hBack.translation),right*turnForce*clamp(speed,0.5,100)*impulse_factor*delta)
	## sail speed impulse
	apply_central_impulse(forward*calSailForce()*delta*impulse_factor/waterLevel)
	# sail wind attack to tilt the ship a bit if cross wind
	apply_impulse(mainSailForce.translation, Vector3(0,0,-1)*crossWindForce*sails*delta*impulse_factor)


		
func applyPosBuoyancy(obj : Spatial, delta, factor :float = 1.0):
	"""
	apply the boyance (up force) for the given (local) position.
	Also emit particles when boyance force is very high
	"""
	var p = transform.basis.xform(obj.translation) ## impulse postions always need to be transformed like this
	var waterH = 0
	if GlobalObjectReferencer.ocean!=null:
		waterH = GlobalObjectReferencer.ocean.getWaterHeight(obj.global_transform.origin)
	var diff = obj.global_transform.origin.y - waterH # if diff <0 = underwater
	if diff<0:
		var impulse = Vector3(0,1,0)*factor*abs(diff)*impulse_factor/waterLevel*delta
		apply_impulse(p, impulse)

func applyCannonImpulse(from : Vector3, direction : Vector3):
	""" needs to make impulse point higher than it really is because lower deck cannons are calculated
	way to much to the lower end of the ship (tilting it wrongly)"""
	from = transform.basis.xform(from)
	if from.y<0.1:
		from.y=0.1 # set to the lowerst allowed point
	apply_impulse(from, transform.basis.xform(direction))



func calSailForce():
	"""
	Iterating over all sails, adding their sail force 
	"""
	var force = 0
	for i in range(len(sailRefs)):
		force += sailRefs[i].windForce
	# print(force)
	return force
	
		
func fillWater(amount):
	"""
	Fills up the ship with water
	"""
	if !isUnsinkable:
		waterLevel += amount

# Changes visibility according to the chosen deck.
func toggleDeckVisible(deckNumber : int):
	var a = model.get_children()
	for i in range(a.size()):
		if i < deckNumber+1:
			a[i].visible = false 
		else:
			a[i].visible = true


# Changes visibility according to the chosen deck on each button press.
func selectDeck(deckNumber: int):
	var decks = get_tree().get_root().get_node("GameWorld/Interface/Decks")
	for child in decks.get_children():
		if child.name != str(deckNumber):
			child.get_node("TextureButton").pressed = false
		else:
			var theButton = child.get_node("TextureButton")
			if !theButton.pressed:
				deckNumber = -1
	toggleDeckVisible(deckNumber)
	GlobalObjectReferencer.camera.selectDeck(deckNumber)
	GlobalObjectReferencer.cursor.selectDeck(deckNumber)


# Recreates and binds buttons for decks.
func reloadDecks(numberOfDecks: int):
	var template = load("res://ControlNodes/deckButton.tscn")
	var deckButtons = get_tree().get_root().get_node("GameWorld/Interface/Decks")
	for child in deckButtons.get_children():
		child.name += "qd"
		child.queue_free()
	for i in range(numberOfDecks):
		var newDeckButton = template.instance()
		deckButtons.add_child(newDeckButton)
		newDeckButton.name = str(i)
		newDeckButton.get_node("Label").text = "Deck " + str(i+1)
		newDeckButton.get_node("TextureButton").connect("pressed", self, "selectDeck", [i])

func calcCenterOfMass():
	"""
	Calculate CoM based on all registered items positions 
	postion::local position of placed item on decks
	weight::weight of placed item
	"""
	var avPos = Vector3.ZERO
	var weightFactor = 20  # the bigger this number the less the avPos is affected by items placed (basically the ships default weight)
	for id in itemNodes:
		avPos += (to_local(itemNodes[id].global_transform.origin))* itemNodes[id].weight/weightFactor
	avPos*=1.0/len(itemNodes)
	centerOfMass = avPos
	# print("CoM: ",centerOfMass)
	# print("NumItems: ",len(itemNodes))

func onHover(isHovering):
	if isHovering:
		print("hovering")

func createInfo(placeholder):
	print("show info")


func removeInfo():
	print("remove info")
