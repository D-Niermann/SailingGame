extends KinematicBody

"""
All player Gear shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.

Item names need to have the same name as in economy.goods dictionary
"""

export(bool) var movable = true # set false in godot editor for pre placed gear 
export var databaseName = "putEconomyItemDictKeyHere" # the name in the economy gear list, set this in the inherited gear
export var InfoPanel: PackedScene # scene object of cannons info ui panel

## item specifc settings (TODO: should be fetched from dictionary)
var penetrationFactor = 0.5 # penetration factor used for bullets, 0-1, 1 = like air, 0 = inpenetrable
var maxHealth = 1
var damageMultiplier = 10 # multiple base damage by this value, just so that the maxHealth values can be bigger integers
var weight = 2.0 

## crew and task stuff
# var maxCrew = 0 # TODO :could also be defined in some dictionary
# var targetCrewSize = 0 # for maybe if  player makes restictions to this item 
# var assignedMen = {} # IDs and data of all men assigned to this item, if specific refernce to human is needed, call the crewManager with the mans ID -> cannot control human directly. values are infoDictionaries  {taskGropup :xxx, priority: yyy}

## 
var gridMesh # green/red mesh that displays the hitbox of gear
var pAudio # audio player thats emitting when item is placed
var itemPlaceParticle # dynamically loaded particles 
var currentHealth = maxHealth
var particleRes = load("res://ObjectNodes/Items/ItemPlaceParticle.tscn") # universal placement particles
var isPlaced = false
var id # id of this item

func _ready():
	if databaseName!=null:
		print("Fetch from: ", databaseName)
		fetchDictParams(databaseName)
	else:
		print("no fetch name was null")
	id = IDGenerator.getID()
	## TODO: this gets also called when item is picked in shop
	# print("BaseItem ready()")
	gridMesh = get_node("GridShowMesh")
	pAudio = $PlaceAudio
	# weight = Economy.goods[Utility.resName(self.name)]["weight"]
	# print("Weight:",weight)
	
	itemPlaceParticle = particleRes.instance()
	itemPlaceParticle.one_shot = true
	itemPlaceParticle.emitting = false
	add_child(itemPlaceParticle)




# func fetchMyShip():
# 	myShip = get_parent().get_parent().get_parent()
# 	if myShip != null:
# 		if "isPlayer" in myShip:
# 			if myShip.isPlayer:
# 				isPlayerControlable = true
# 		else:
# 			myShip = null # reset this var to null because it is not a rigid body ship node


func onPlacement():
	"""
	Gets called every time the item is placed onto the ship (shopping, replacing, loading).
	"""
	# fetchMyShip() # obsolete cause this is player item, use globalObjectReferencer
	registerItem()
	if gridMesh!=null:
		gridMesh.visible = false # make the grid item invisible again
	itemPlaceParticle.emitting = true
	# play Audio
	if pAudio!=null:
		pAudio.set_pitch_scale(pAudio.pitch_scale+rand_range(-0.2,0.2))
		pAudio.play()
	isPlaced = true


func onHover(is_hovered: bool):
	"""
	Gets called when while shopping or building the mouse is hovering over item.
	"""
	var sprite = get_node("Sprite3D")
	if is_hovered:
		sprite.modulate = Color(1.0, 1.0, 0.5, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func onRemove():
	"""
	When item is removed from deck (picked up by player, maybe later also destroyed)
	"""
	print("item remove")
	# for id in assignedMen:
	# 	print("making man idle :item id: ", id)
	# 	GlobalObjectReferencer.crewManager.makeManIdle(id, assignedMen[id])
	# assignedMen = {}
	# if GlobalObjectReferencer.playerShip.has_method("unregisterItem"):
	unregisterItem()
	isPlaced = false
	

func registerItem():
	""" registers item in all necessary control units (ship, crewmanager)"""
	GlobalObjectReferencer.playerShip.registerItem(self)
	GlobalObjectReferencer.crewManager.registerItem(self)


func unregisterItem():
	""" unregisters item in all necessary control units (ship, crewmanager)"""
	GlobalObjectReferencer.playerShip.unregisterItem(self)
	GlobalObjectReferencer.crewManager.unregisterItem(self)


func giveDmg(damage : float):
	"""
	reports damage taken by bullet to this object.
	"""
	currentHealth = clamp(currentHealth - damage*damageMultiplier,0,maxHealth)


func fetchDictParams(name : String):
	"""
	gets all parameters for this item defined in a item dictionary
	Called in the corresponding item
	"""
	# TODO: if values in dictionary are constant, dont save them in this item, just use the dictionary entries (saves Ram)
	if Economy.goods.has(name):
		weight = Economy.goods[name].weight
		penetrationFactor = Economy.goods[name].penetrationFactor
		maxHealth = Economy.goods[name].maxHealth
		# the only important one
		currentHealth = Economy.goods[name].maxHealth


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



# func assignManToItem(id:int, infoDict):
# 	""" assign a human to this item, called from Crewmanager """
# 	assignedMen[id] = infoDict # {taskGropup :xxx, priority: yyy}
	
# func unassignManfromItem(id):
# 	""" 
# 	unassign a human from this item, called from this item when removed and from crew manager when reassigning man to better prio
# 	"""
# 	assignedMen.erase(id)
	## request new crew because a man got removed
	# GlobalObjectReferencer.crewManager.makeManIdle(assignedMen[i])
	# for i in range(len(assignedMen)):
	# 	if assignedMen[i].name == manRef.name:
	# 		assignedMen.remove(i)
	# 		break
	# pass

# func unassignManfromItem(id):
# 	""" 
# 	unassign a human from this item, called from Crewmanager
# 	and directly request a new man
# 	"""
# 	if id in assignedMen.keys():
# 		GlobalObjectReferencer.crewManager.requestCrew(self,assignedMen[id].taskGroup, global_transform.origin, assignedMen[id].priority) # TODO: need to know what position of man was removed (what prio) so that the request crew function requests the same position again
# 		assignedMen.erase(id)
# 	else:
# 		print("failed try to unassign man from item: ",self.name)
