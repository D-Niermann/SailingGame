extends Spatial

"""
base Script on each human. maybe other special humans like officers can inherit from this.
"""
## stati
const S_TIRED = "S_TIRED"  # too tired to work
const S_DRUNK = "S_DRUNK" # too drunk to work
const S_HUNGRY = "S_HUNGRY" # too hungry
const S_THIRSTY = "S_THIRSTY" # too thirsty
const S_WOUNDED = "S_WOUNDED"  # too wounded - needs to go to doctor

var onItem = null # ref to the curernt item the human is working
var stati = [] #keeps track of all stati (stati = [S_Hungry, S_THIRSTY, ...]) 


func _ready():
	pass

func assignToItem(itemRef):
	"""
	assign this human to the item itemRef
	"""
	itemRef.assignMan(self)
	
func walkTowards(targetPos : Vector3):
	pass