extends Spatial
class_name Human
"""
base Script on each human. maybe other special humans like officers can inherit from this.
"""
## stati
const S_TIRED = "S_TIRED"  # too tired to work
const S_DRUNK = "S_DRUNK" # too drunk to work
const S_HUNGRY = "S_HUNGRY" # too hungry
const S_THIRSTY = "S_THIRSTY" # too thirsty
const S_WOUNDED = "S_WOUNDED"  # too wounded - needs to go to doctor

var targetItem = null # ref to the curernt item the human is working
var stati = [] #keeps track of all stati (stati = [S_Hungry, S_THIRSTY, ...]) 
var targetPos = Vector3.ZERO
var currentDeck = 0
var currentDeckHeigth = 2.8
var currentTaskGroup

func _ready():
	pass

func giveTarget(itemRef, target_position : Vector3, TG):
	"""
	gives a target item to walk to
	"""
	targetPos = to_local(target_position)
	targetItem = itemRef
	currentTaskGroup = TG
	
func walkTowards(targetPos : Vector3):
	""" for now some simple function, later will use navmesh """
	self.translation = targetPos
	self.translation.y = currentDeckHeigth

func _process(delta):
	walkTowards(targetPos)
	## if near the item, assign to it
	if translation==targetPos: #TODO: give a bit of wiggle room
		targetItem.assignMan(self)
