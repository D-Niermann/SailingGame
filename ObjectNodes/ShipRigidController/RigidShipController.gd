extends RigidBody

"""
Default ship rigidbody.
Parent of the whole ship

Needs a linear damping of approx 5!

"""

export(bool) var isPlayer = false

var model # ref to ship model

const impulse_factor = 5 # overall impulse stength, all impulses should be multiplied by this
var turnSpeed = 0
var ocean # ref to ocean object

# force spatials
var hLeft # positions where boynacy attacks
var hRight # positions where boynacy attacks
var hFront # positions where boynacy attacks
var hBack # positions where boynacy attacks
var mainSailForce # Spatial - where the force of main sail wind is applied

# directional vectors (updated every frame)
var up 
var forward
var right

# wind stuff
var wind_dir = Vector2(0,1) # TODO: make real wind direction vector in the ocean env
var sails = 0
var speed_mod = 5.2 # speed modifier, more = more max speed, could be changed because of higher load mass
const reverse_speed_factor = -0.2 # factor on how much sailing against the wind will reverse the speed direction (0 for still stand, 0.05 for pretty heavy reverse, negative values for allowing sailing against wind)
const crossWindForce = 0.01
const maxTurnSpeed = 0.1
# Called when the node enters the scene tree for the first time.
func _ready():
	if get_tree().get_nodes_in_group("Ocean").size()>0:
		ocean = get_tree().get_nodes_in_group("Ocean")[0]
	hFront = $HFront
	hBack = $HBack
	hRight = $HRight
	hLeft = $HLeft
	mainSailForce = $MainSailForce
	model = $Model

	## add Decks to item placeable deck group if ship belongs to player
	if isPlayer:
		var a = model.get_children()
		for i in range(1, a.size()):
			# iterate through children, skip 1st because it is Sails
			a[i].add_to_group("PlayerDeck")
			



func _physics_process(delta):
	sails = clamp(sails,-0.01, 1)
	turnSpeed = clamp(turnSpeed,-maxTurnSpeed,maxTurnSpeed)	

	up = transform.basis.y
	forward = transform.basis.x
	right = transform.basis.z
	applyPosBuoyancy(hFront, delta)
	applyPosBuoyancy(hBack, delta)
	applyPosBuoyancy(hLeft, delta, 0.1) # less force because the roll is otherwise too strong
	applyPosBuoyancy(hRight, delta, 0.1) # less force because the roll is otherwise too strong
	## turn impulse
	apply_impulse(transform.basis.xform(hBack.translation),right*turnSpeed*impulse_factor*delta)
	## sail speed impulse
	apply_central_impulse(forward*calcWindForce()*delta*impulse_factor)
	# sail wind attack to tilt the ship a bit if cross wind
	apply_impulse(mainSailForce.translation, Vector3(0,0,-1)*crossWindForce*sails*delta*impulse_factor)

func _input(event):
	if isPlayer:
		if Input.is_action_pressed("turnLeft"):
			turnSpeed += 0.01
		if Input.is_action_pressed("turnRight"):
			turnSpeed -= 0.01
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
	if ocean!=null:
		waterH = ocean.getWaterHeight(obj.global_transform.origin)
	var diff = obj.global_transform.origin.y - waterH # if diff <0 = underwater
	if diff<0:
		var impulse = Vector3(0,1,0)*factor*pow(abs(diff),1.5)*impulse_factor*delta
		apply_impulse(p, impulse)

func applyImpulse(from : Vector3, direction : Vector3):
	apply_impulse(transform.basis.xform(from), transform.basis.xform(direction))



func calcWindForce():
	"""
	Using an accurate formular to get the wind force on sail, based on angle to wind.
	Directly with the wind (angle=0) is a bit slower than at a steep angle with the wind.
	"""
	var angle_to_wind = wind_dir.angle_to(Vector2(forward.x,forward.z))
	var deg = abs(rad2deg(angle_to_wind))/180
	return sails*speed_mod*(pow(deg,2) - 0.8*pow(deg,3))-(reverse_speed_factor*speed_mod*sails)
		

func toggleDeckVisible(deckNumber : int):
	var a = model.get_children()
	for i in range(a.size()):
		if i < deckNumber+1:
			a[i].visible = false 
		else:
			a[i].visible = true

func _on_Deck0_button_up():
	toggleDeckVisible(0)

func _on_Deck1_button_up():
	toggleDeckVisible(1)


func _on_AllDeck_button_up():
	toggleDeckVisible(-1)
