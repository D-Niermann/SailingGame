extends Spatial

"""
Assuming this will stay only on player ship and will be a singleton, (its referenced in the GLobalObjectReferencr)
"""

## define task groups
# if a man is assigned to relax, he stays in relaxed (except panic button is activated). 
# So to add a man to cannons, only look ino WEAPONS group, if there is nobody, do not look into RELAX, the player needs to reassign
const TG_WEAPONS = "tgWeapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tgNavigation"
const TG_UTILITY = "tgUtility"
const TG_RELAX = "tgRelax"

var myShip # parent ship of this manager
var humanNodes # list of all humans on ship (refs) needed? -> check currentAssignments

# task dict (maybe change this to specific crewRequestsDict)
# structure: tasks = {"0":[task1, task2, ...], "1" : [task1, task2, ..], "2": } these numbers can also be names 
# a task is a dict: {"id": prio_12,"itemRef": asd, "position": V(0,0,0), "taskGroup": TG_Asd, }
var tasks = {"0": [], "1": [], "2": [], "3": [], "4": []} # dict of all idle tasks, this list is always sorted per priority (because tasks get added so), key 0 is high prio, key 99 low


var currentAssignments = {TG_RELAX:       {"idle": [], "busy": []}, # TODO: change the arrays into dictionaries and use man ID to quicker acess man based on ID?
						  TG_WEAPONS:     {"idle": [], "busy": []}, # make these lists only filled with IDs and then create a separate dict for all crew members refs to access via ID
						  TG_UTILITY:     {"idle": [], "busy": []},
						  TG_NAVIGATION:  {"idle": [], "busy": []}} # refs to humans, idle means idle for new work busy means already on item

# var crew = {} # crewID: {ref (referenceOfTheCrew), type (typeOfTheCrew), job (jobID), inventory, tired, xform (localTransform),..}
# var jobs = {} # jobID: {ref (referenceOfTheItem), name (nameOfTheJob), crew (crewID), refName (refID in baseItem for loadGame)}
# var jobSpecs = {} # nameOfTheJob: {type (typeOfTheJob), priority (priorityOfTheJob)}

const HUMAN: PackedScene = preload("res://ObjectNodes/Human/Human.tscn")

func _ready():
	myShip = get_parent()
	humanNodes = get_children()
	for i in range(len(humanNodes)):
		currentAssignments[TG_WEAPONS]["idle"].append(humanNodes[i])
	print(currentAssignments)
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
	## first priority
	var t
	for i in range(len(tasks["0"])):
		t = tasks["0"][i]
		var manRef = findBestMen(t.position, t.taskGroup)
		if manRef!=null:
			## do something with the found man
			manRef.giveTarget(t.itemRef, t.position, t.taskGroup)
			tasks["0"].remove(i)
			break

	
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
	for _i in range(amount):
		# add the request to tasks array already in the correct order (prio)
		tasks[str(priority)].append({"id": str(priority)+str(len(tasks[str(priority)])),"itemRef": itemRef, "position": targetPosition, "taskGroup": taskGroup})



func findBestMen(itemPos : Vector3, taskGroup):
	"""
	Searches for the best fitting crew member to do the task, removes him already from idle group and adds him to busy
	"""
	## for now could only return the nearset
	var foundMen
	for i in range(len(currentAssignments[taskGroup]["idle"])):
		if true: # TODO: put real check here
			foundMen = currentAssignments[taskGroup]["idle"][i]
			## put human into busy list and remove from idle list
			currentAssignments[taskGroup]["busy"].append(foundMen)
			currentAssignments[taskGroup]["idle"].remove(i)
			return foundMen


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


func makeManIdle(manRef):
	var a = currentAssignments[manRef.currentTaskGroup]["busy"]
	for i in range(len(a)):
		if a[i].name == manRef.name:
			currentAssignments[manRef.currentTaskGroup]["idle"].append(manRef)
			currentAssignments[manRef.currentTaskGroup]["busy"].remove(i)
			print("making man idle")
			break

	# func reconnectJobs():
	# 	"""
	# 	Reconnects item references with the help of refName in their data.
	# 	"""
	# 	#???
	# 	pass

	# func repopulate():
	# 	"""
	# 	Deletes all children, iterates over crew data, and recreates their instances.
	# 	"""
	# 	for child in get_children():
	# 		child.queue_free()
	# 	for crewID in crew.keys():
	# 		var crewSpec = crew[crewID]
	# 		var newHuman = HUMAN.instance()
	# 		add_child(newHuman)
	# 		newHuman.transform = crewSpec["xform"]

	# func checkAndUpdate():
	# 	"""
	# 	Iterates over crew members, checks their status, runs their AI for pathfinding etc., and updates their locations.
	# 	"""
	# 	for crewID in crew.keys():
	# 		var crewSpec = crew[crewID]
	# 		#???

	# func matchJobsToCrew():
	# 	"""
	# 	Tries to match existing but not picked jobs, to the closest crew member of that job type.
	# 	"""
	# 	for key in jobs.keys():
	# 		var job = jobs[key]
	# 		var crewID = job["crew"]
	# 		if crewID != null: # this job is already getting done by someone
	# 			continue
	# 		var jobSpec = jobSpecs[job["name"]]
	# 		var jobType = jobSpec["type"]
	# 		var jobPriority = jobSpec["priority"]
	# 		var jobReference = job["ref"]
	# 		var closest = null
	# 		var distance = 999999999
	# 		for crewIDTwo in currentAssignments[jobType]:
	# 			var crewSpec = crew[crewIDTwo]
	# 			var crewJob = crewSpec["job"]
	# 			var crewPriority = jobSpecs[jobs[crewJob]["name"]]["priority"]
	# 			if crewJob != null && crewPriority <= jobPriority: # this crew is already getting done some job with equal or less priority
	# 				continue
	# 			var crewReference = crewSpec["ref"]
	# 			var tempDist = jobReference.transform.origin.distance_squared_to(crewReference.transform.origin) # may want to use path length instead
	# 			if tempDist < distance:
	# 				distance = tempDist
	# 				closest = crewIDTwo
	# 		if closest != null: # means a suitable crew member is found to do the job
	# 			var crewSpec = crew[closest]
	# 			var crewOldJob = crewSpec["job"]
	# 			jobs[crewOldJob]["crew"] = null
	# 			crewSpec["job"] = key
	# 			job["crew"] = closest
	# 			break # only one job gets matched in a physics frame, to prevent performance issues

	# func removeJob(jobID):
	# 	"""
	# 	Removes an existing job from the list.
	# 	"""
	# 	crew[jobs[jobID]["crew"]]["job"] = null
	# 	jobs.erase(jobID)

	# func removeCrew(crewID):
	# 	"""
	# 	Deletes an existing crew.
	# 	"""
	# 	jobs[crew[crewID]["job"]]["crew"] = null
	# 	crew.erase(crewID)
	# 	crew.queue_free()

	# func insertJob(nameOfTheJob, reference):
	# 	"""
	# 	Puts a new job on the list.
	# 	"""
	# 	var ID = 0
	# 	while jobs.has(ID):
	# 		ID += 1
	# 	jobs[ID] = {"crew": null, "name": nameOfTheJob, "ref": reference}

	# func insertCrew(reference):
	# 	"""
	# 	Creates new crew on board.
	# 	"""
	# 	var ID = 0
	# 	while crew.has(ID):
	# 		ID += 1
	# 	crew[ID] = {"job": null, "type": TG_RELAX, "ref": reference, "xform": Transform.IDENTITY}
	# 	currentAssignments[TG_RELAX].append(ID)
	# 	var newHuman = HUMAN.instance()
	# 	add_child(newHuman)
	# 	newHuman.transform = crew[ID]["xform"]

	# func changeType(crewID, newType):
	# 	"""
	# 	Changes current assignment of the given crew to the given type.
	# 	"""
	# 	var oldType = crew[crewID]["type"]
	# 	if oldType != newType:
	# 		currentAssignments[oldType].erase(crewID)
	# 		currentAssignments[newType].append(crewID)
	# 		var oldJob = crew[crewID]["job"]
	# 		if oldJob != null && jobSpecs[jobs[oldJob]["name"]]["type"] != newType:
	# 			jobs[oldJob]["crew"] = null
	# 			crew[crewID]["job"] = null
