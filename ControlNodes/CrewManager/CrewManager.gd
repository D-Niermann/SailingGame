extends Spatial

"""
Assuming this will stay only on player ship and will be a singleton, (its referenced in the GLobalObjectReferencr)
"""

## define task groups
# if a man is assigned to relax, he stays in relaxed (except panic button is activated). 
# So to add a man to cannons, only look ino WEAPONS group, if there is nobody, do not look into RELAX, the player needs to reassign
const TG_WEAPONS = "tg-weapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tg-navigation"
const TG_UTILITY = "tg-utility"
const TG_RELAX = "tg-relax"

var myShip # parent ship of this manager
var humanNodes # list of all humans on ship (refs)
var tasks = [] # list of all open tasks

var currentAssignments = {TG_RELAX: [], TG_WEAPONS: [], TG_UTILITY: [], TG_NAVIGATION: []}

func _ready():
	myShip = get_parent()
	humanNodes = get_children()
	GlobalObjectReferencer.crewManager = self
	
func _physics_process(delta):
	checkMen()
	# is this needed?: sortTasks() # sorting tasks array by priority 
	checkTasks() # go through tasks and assign men

# func sortTasks():
# 	"""
# 	sorting the tasks array by prio.
# 	"""
# 	pass

	
func checkTasks():
	"""
	Go through all open tasks and assign men if possible
	"""
	# var bestMan = findBestMan(itemRef.translation, taskGroup)
		
	pass

	
func checkMen():
	"""
	checks if men is able to stay in assigned group. If a man is not, force him into RELAX group, de-assign him from item that he is on.
	Caution: if tired he goes to hammock: then do not remove him from hammock again, so only check TGs that are non RELAX
	"""
	# for i in humans:
		# if human.S_HUNGRY:
			# item.unassignMan(human)
			# searchFood
		# if human.S_TIRED:
			# search hammock
		# if human.S_WOUNDED:
			# ...
		# ...
	pass

func requestCrew(itemRef, amount : int, taskGroup, targetPosition, priority):
	"""
	When a cannon or something requests crew of type taskgroup, this function gets called.

	itemRef: refernce to the item that requested the crew
	amunt: how many men are needed
	taskGroup: from which task group
	"""
	# for i in range(amount)
		# _addCrewRequest()

	pass

	
func _addCrewRequest(itemRef, prio):
	"""
	private function. adds task into task list. 

	"""
	# append( {"type": , "pos", } )
	pass


func findBestMen(itemPos : Vector3, taskGroup):
	"""
	Searches for the best fitting crew member to do the task
	"""
	## for now could only return the nearset
	# for i in range(len(currentAssignments.IDLE)):
		# if dist < ...
	pass

func requestItems(items : Dictionary, priority):
	"""
	When a cannon or something requests items like gunpowder and cannonballs, this function gets called.
	
	"""
	var itemsChunked = groupItemsIntoChunks(items)
	# for every chunk: 
	# check where items are stored (needs global storage array with positions to calc distance)
	# findClosestItem(pos)
	# that barrel makes then some kind of request crew task, but with target item in it
	# human registers to barrel, fetches item. (what if item then is already gone? - items need to be reserved)
	pass

func groupItemsIntoChunks(items : Dictionary):
	"""
	groups item dictionary into chunks useable per crew member when item dictionary request is large.
	one crew member can hold N items, so one chunk also contains N items, maybe even of the same type, so crew is walking optimal.

	returns a new array with the chunks. 
	eg: [{gunpowder:10}, #chunk1
		{gunpowder:2, cannonballs:5}] #chunk 2
	"""
	pass