extends RigidBody

"""
Default ship rigidbody.
Parent of the whole ship

Needs a linear damping of approx 5!

"""

export(bool) var isPlayer = false
export(bool) var isUnsinkable = false

var model # ref to ship model
var turnForce : float # current turn force for left right steer
var sails # current sail state (0,1) 1=full sails
var itemNodes = [] # ref to all items in ships model (used for center of mass)
var turnCommandPressed = false
var waterLevel = 1 # 1 = default, how much water the ship has taken, used in boyance calculation, if near impulse_factor, its start to sink

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


# parameters 
const impulse_factor = 3 # overall impulse stength, all impulses should be multiplied by this
# sailing and wind stuff
var wind_dir = Vector2(0,1) # TODO: make real wind direction vector in the ocean env
var speed_mod = 5.2 # speed modifier, more = more max speed, could be changed because of higher load mass
const reverse_speed_factor = -0.2 # factor on how much sailing against the wind will reverse the speed direction (0 for still stand, 0.05 for pretty heavy reverse, negative values for allowing sailing against wind)
const crossWindForce = 0.01 # force that attacks the ship up on the sails, tilting it with the wind
const maxTurnForce = 0.7 # max turn force of the whole ship
# Called when the node enters the scene tree for the first time.
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
	itemNodes.append(node)
	if isPlayer:
		calcCenterOfMass()
	print("registered "+node.name)

func unregisterItem(node):
	"""
	un-register item node from itemNodes array
	"""
	for i in range(len(itemNodes)):
		if itemNodes[i].name==node.name:
			itemNodes.remove(i)
			break

func _physics_process(delta):
	sails = clamp(sails,-0.01, 1)
	turnForce = clamp(turnForce,-maxTurnForce,maxTurnForce)	

	up = transform.basis.y
	forward = transform.basis.x
	right = transform.basis.z
	applyPosBuoyancy(hFront, delta, 1)
	applyPosBuoyancy(hBack, delta, 1)
	applyPosBuoyancy(hLeft, delta, 0.1) # less force because the roll is otherwise too strong
	applyPosBuoyancy(hRight, delta, 0.1) # less force because the roll is otherwise too strong
	## turn impulse
	apply_impulse(transform.basis.xform(hBack.translation),right*turnForce*impulse_factor*delta)
	## sail speed impulse
	apply_central_impulse(forward*calcWindForce()*delta*impulse_factor/waterLevel)
	# sail wind attack to tilt the ship a bit if cross wind
	apply_impulse(mainSailForce.translation, Vector3(0,0,-1)*crossWindForce*sails*delta*impulse_factor)

	if !turnCommandPressed:# reset turn force slowly
		turnForce *= 0.99

func _input(event):
	if isPlayer:
		if Input.is_action_pressed("turnLeft"):
			turnCommandPressed = true
			turnForce += 0.005
		if Input.is_action_pressed("turnRight"):
			turnCommandPressed = true
			turnForce -= 0.005
		if Input.is_action_just_released("turnLeft"):
			turnCommandPressed = false
		if Input.is_action_just_released("turnRight"):
			turnCommandPressed = false


		if Input.is_action_pressed("sailsUp"):
			sails += 0.01
		if Input.is_action_pressed("sailsDown"):
			sails -= 0.01
		
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
		var impulse = Vector3(0,1,0)*factor*pow(abs(diff),1.1)*impulse_factor/waterLevel*delta
		apply_impulse(p, impulse)

func applyCannonImpulse(from : Vector3, direction : Vector3):
	""" needs to make impulse point higher than it really is because lower deck cannons are calculated
	way to much to the lower end of the ship (tilting it wrongly)"""
	from = transform.basis.xform(from)
	if from.y<0.1:
		from.y=0.1 # set to the lowerst allowed point
	apply_impulse(from, transform.basis.xform(direction))



func calcWindForce():
	"""
	Using an accurate formular to get the wind force on sail, based on angle to wind.
	Directly with the wind (angle=0) is a bit slower than at a steep angle with the wind.
	"""
	var angle_to_wind = wind_dir.angle_to(Vector2(forward.x,forward.z))
	var deg = abs(rad2deg(angle_to_wind))/180
	return sails*speed_mod*(pow(deg,2) - 0.8*pow(deg,3))-(reverse_speed_factor*speed_mod*sails)
		
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
			if theButton.pressed:
				toggleDeckVisible(deckNumber)
			else:
				toggleDeckVisible(-1)
	get_tree().get_root().get_node("GameWorld/Interface/Shopping").selectDeck(deckNumber)
	get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport/GameCamera").selectDeck(deckNumber)


# Recreates and binds buttons for decks.
func reloadDecks(numberOfDecks: int):
	var template = load("res://ControlNodes/deckButton.tscn")
	var decks = get_tree().get_root().get_node("GameWorld/Interface/Decks")
	for child in decks.get_children():
		child.name += "qd"
		child.queue_free()
	for i in range(numberOfDecks):
		var newDeckButton = template.instance()
		decks.add_child(newDeckButton)
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
	for i in range(len(itemNodes)):
		avPos += (to_local(itemNodes[i].global_transform.origin))* itemNodes[i].weight/weightFactor
	avPos*=1.0/len(itemNodes)
	centerOfMass = avPos
	print("CoM: ",centerOfMass)
	print("NumItems: ",len(itemNodes))
