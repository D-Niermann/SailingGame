extends KinematicBody

"""
All Items shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.

Item names need to have the same name as in economy.goods dictionary
"""

export(bool) var movable = true # set false in godot editor for pre placed items 

## item specifc settings (fetched from dictionary)
var penetrationFactor = 0 # penetration factor used for bullets, 0-1, 1 = like air, 0 = inpenetrable
var dataBaseName = "baseName" # set this in the inherited items
var maxHealth = 1
var damageMultiplier = 10 # multiple base damage by this value, just so that the maxHealth values can be bigger integers
var isCannon = false # used for AI
var weight = 2.0 

## 
var myShip # obj ship that this is on
var gridMesh # green/red mesh that displays the hitbox of items
var pAudio # audio player thats emitting when item is placed
var itemPlaceParticle # dynamically loaded particles 
var currentHealth = maxHealth
var particleRes = load("res://ObjectNodes/Items/ItemPlaceParticle.tscn") # universal placement particles
var isPlayerControlable = false # if player can control this item (also maybe click on it)
var assignedMen = [] # refs to all men assigned to this item

func _ready():
	## TODO: this gets also called when item is picked in shop
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
	myShip = get_parent().get_parent().get_parent()
	if myShip != null:
		if "isPlayer" in myShip:
			if myShip.isPlayer:
				isPlayerControlable = true
		else:
			myShip = null # reset this var to null because it is not a rigid body ship node


func onPlacement():
	"""
	Gets called every time the item is placed onto the ship (shopping, replacing, loading).
	"""
	print("BaseItem onPlacement()")
	fetchMyShip()
	if myShip!=null: #if actually on ship
		registerToShip()
		if gridMesh!=null:
			gridMesh.visible = false # make the grid item invisible again
		itemPlaceParticle.emitting = true
		
		if pAudio!=null:
			pAudio.set_pitch_scale(pAudio.pitch_scale+rand_range(-0.2,0.2))
			pAudio.play()

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


func fetchDictParams(name : String):
	"""
	gets all parameters for this item defined in a item dictionary
	"""
	weight = Economy.goods[name].weight
	isCannon = Economy.goods[name].isCannon
	penetrationFactor = Economy.goods[name].penetrationFactor
	maxHealth = Economy.goods[name].maxHealth
	currentHealth = maxHealth


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


func assignMan(manRef):
	""" assign a human to this item """
	assignedMen.append(manRef)
	
func unassignMan(manRef):
	for i in range(len(assignedMen)):
		if assignedMen[i].name == manRef.name:
			assignedMen.remove(i)
			print("test if i really is the right index")
			break
	pass