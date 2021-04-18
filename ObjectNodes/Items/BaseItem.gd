extends KinematicBody

"""
All Items shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.

Item names need to have the same name as in economy.goods dictionary
"""

## settings
export(bool) var movable = true
export(float) var penetrationFactor = 2 # penetration factor used for bullets
var maxHealth = 100
var damageMultiplier = 10 # multiple base damage by this value, just so that the maxHealth values can be bigger integers
var type = "baseItem"

var weight = 2.0 # fetched from economy class
var myShip # obj ship that this is on
var gridMesh # green/red mesh that displays the hitbox of items
var pAudio # audio player thats emitting when item is placed
var itemPlaceParticle # dynamically loaded particles 
var currentHealth = maxHealth
var particleRes = load("res://ObjectNodes/Items/ItemPlaceParticle.tscn") # universal placement particles
var isPlayerControlable = false # if player can control this item (also maybe click on it)

func _ready():
	print("BaseItem ready()")
	gridMesh = get_node("GridShowMesh")
	pAudio = $PlaceAudio
	# weight = Economy.goods[Utility.resName(self.name)]["weight"]
	# print("Weight:",weight)
	
	itemPlaceParticle = particleRes.instance()
	itemPlaceParticle.one_shot = true
	itemPlaceParticle.emitting = false
	add_child(itemPlaceParticle)
	onPlacement()


func fetchMyShip():
	## TODO: this gets also called when item is picked in shop
	myShip = get_parent().get_parent().get_parent()
	if myShip != null:
		if "isPlayer" in myShip:
			if myShip.isPlayer:
				isPlayerControlable = true


func onPlacement():
	"""
	Gets called every time the item is placed onto the ship (shopping, replacing).
	"""
	print("BaseItem onPlacement()")
	if gridMesh!=null:
		gridMesh.visible = false # make the grid item invisible again
	itemPlaceParticle.emitting = true
	
	if pAudio!=null:
		pAudio.set_pitch_scale(pAudio.pitch_scale+rand_range(-0.2,0.2))
		pAudio.play()
	fetchMyShip()
	registerToShip()

func onHover():
	"""
	Gets called when while shopping or building the mouse is hovering over item
	"""
	pass

func onRemove():
	"""
	When item is removed from deck (picked up by player, maybe later also destroyed)
	"""
	pass
	
func registerToShip():
	if myShip.has_method("registerItem"):
		myShip.registerItem(self)

func giveDmg(damage : float):
	"""
	reports damage taken by bullet to this object.
	"""
	currentHealth = clamp(currentHealth - damage*damageMultiplier,0,maxHealth)

func createInfo(placeholder):
	"""
	Overwrites in inherited item classes.
	Instances the correponding item info panel and moves it to placeholder.rect_position.
	The instanced info box connects to this item and communicates user input and item stati.
	"""
	pass

func removeInfo():
	"""
	Overwrites in inherited item classes.
	removes info panel again
	"""
	pass
