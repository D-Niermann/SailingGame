extends Spatial

## define task groups
# if a man is assigned to relax, he stays in relaxed (except panic button is activated). 
# So to add a man to cannons, only look ino WEAPONS group, if there is nobody, do not look into RELAX, the player needs to reassign
const TG_WEAPONS = "tg-weapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tg-navigation"
const TG_UTILITY = "tg-utility"
const TG_RELAX = "tg-relax"

var myShip # parent ship of this manager
var humanNodes # list of all humans on ship (refs)

var currentAssignments = {TG_RELAX: [], TG_WEAPONS: [], TG_UTILITY: [], TG_NAVIGATION: []}

func _ready():
	myShip = get_parent()
	humanNodes = get_children()
	
func _physics_process(delta):
	checkMen()



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

func requestCrew(itemRef, amount : int, taskGroup):
	"""
	When a cannon or something requests crew of type taskgroup, this function gets called.

	itemRef: refernce to the item that requested the crew
	amunt: how many men are needed
	taskGroup: from which task group
	"""
	# for i in range(amount)
		# var bestMan = findBestMan(itemRef.translation, taskGroup)
		# itemRef.assignMan(bestMan)

	pass

func findBestMen(itemPos : Vector3, taskGroup):
	"""
	Searches for the best fitting crew member to do the task
	"""
	## for now could only return the nearset
	# for i in range(len(currentAssignments.IDLE)):
		# if dist < ...
	pass

func requestItems(items : Dictionary):
	"""
	When a cannon or something requests items like gunpowder and cannonballs, this function gets called.
	
	"""
	var itemsChunked = groupItemsIntoChunks(items)
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