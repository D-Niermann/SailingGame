extends Node

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
var decks # ref list of all decks on player ship
# var humanNodes # list of all humans on ship (refs) needed? -> check currentAssignments

# structure: tasks = [[task1, task2, ...],[task1, task2, ..], ...] with 0th eleemnt being prio 0 and so on, so new tasks are being appended to the correct list, no sorting needed
# a task is a dict: {"id": prio_12,"itemRef": asd, "position": V(0,0,0), "taskGroup": TG_Asd, }
var tasks = [] # list of lists of all queued tasks, this list is always sorted per priority (because tasks get added so), list 0 is high prio, list  99 low prio
var numberOfPriorities = 5 # how large the tasks list will be

var currentAssignments = {TG_RELAX:       {"idle": {}, "busy": []}, # refs to humans, idle means idle for new work busy means already on item or heading to it
						  TG_WEAPONS:     {"idle": {}, "busy": []}, # make these lists only filled with IDs and then create a separate dict for all crew members refs to access via ID
						  TG_UTILITY:     {"idle": {}, "busy": []}, 
						  TG_NAVIGATION:  {"idle": {}, "busy": []}} # these assignments in the busy tab also have the priority herarchy so that code can quickly infer on what priority the man currently is, or if he is idle

var items = {} # {itemID: {"itemRef": ref, "jobs": {jobID1 : {manID : ID, isReady: false}, jobID2 : {}, ...}}} # to quicly find man with manID, check the item.jobID description - it has the TG and prio in it

# var crew = {} # crewID: {ref (referenceOfTheCrew), type (typeOfTheCrew), job (jobID), inventory, tired, xform (localTransform),..}
# var jobs = {} # jobID: {ref (referenceOfTheItem), name (nameOfTheJob), crew (crewID), refName (refID in baseItem for loadGame)}
# var jobSpecs = {} # nameOfTheJob: {type (typeOfTheJob), priority (priorityOfTheJob)}

const HUMAN: PackedScene = preload("res://ObjectNodes/Human/Human.tscn")

func _ready():
	## base variable init
	myShip = get_parent()
	decks = get_tree().get_nodes_in_group("PlayerDeck")
	GlobalObjectReferencer.crewManager = self

	## fetch all humans ( later will get loaded in )
	var humanNodes = get_children()
	

	## init all arrays that contain prio arrays
	for i in range((numberOfPriorities)):
		tasks.append([]) 
		currentAssignments[TG_RELAX].busy.append({})
		currentAssignments[TG_WEAPONS].busy.append({})
		currentAssignments[TG_UTILITY].busy.append({})
		currentAssignments[TG_NAVIGATION].busy.append({})

	## init the assignment data
	for i in range(len(humanNodes)):
		currentAssignments[TG_WEAPONS]["idle"][humanNodes[i].id] = humanNodes[i]
		humanNodes[i].assignDeck(decks[0])
	print(currentAssignments)

	
func _physics_process(delta):
	checkMen()
	checkTasks() 


	
func checkTasks():
	"""
	Go through all open tasks and assign men if possible.
	For now doesnt remove men when a tasks with higher prio than the currently done tasks is open (this is ok when humans are not loaded while building new things or human activity fluctuates quickly)
	"""
	# var bestMan = findBestMan(itemRef.translation, taskGroup)
	## first priority
	var task
	# fetch a tasks beginning from prio 0 and the oldest task i that prio
	for p in range(numberOfPriorities):
		for i in range(len(tasks[p])):
			task = tasks[p][i]
			if items.has(task.itemID): # check if item still exists, could be deleted in the main time, task stays in task array when item unregisterd
				## if task is found, find a suitable man
				var manRef = findAndAssignBestMen(task.position, task.taskGroup, p)
				if manRef!=null:
					## do something with the found man
					## give man the new item target
					manRef.giveTarget(task.position, task.itemID, task.jobID) #todo: wrap this into one function "assignMantoitem"
					items[task.itemID].jobs[task.jobID].manID = manRef.id
					
					## remove task
					tasks[p].remove(i)
					## break here to save CPU (only one task per frame gets assigned this way)
					break

	
func checkMen():
	"""
	checks if men is able to stay in assigned group, maybe he is too tired or hungry. If a man is not, force him into RELAX group, de-assign him from item that he is on.
	Caution: if tired he goes to hammock: then do not remove him from hammock again, he will still be tired, so only check TGs that are non RELAX (?)
	Maybe also here check if human is in range to assign to item and assign him? could enable partitioning of these checks
	"""
	# for i in humans:
		# if human.S_HUNGRY:
			# item.unassignManFromItem(human)
			# searchFood
		# if human.S_TIRED:
			# search hammock
		# if human.S_WOUNDED:
			# ...
		# ...


	var man
	# iterate all men
	for tg in currentAssignments: # TODO: partioning idea: only check one TG per frame, (at the end of process(), go change the current tg to the next one)
		for manID in currentAssignments[tg]["idle"]:
			## do stuff with the idle man, like move them randomly or make them group together
			pass
		for prio in range(numberOfPriorities):
			for manID in currentAssignments[tg]["busy"][prio]:
				man = currentAssignments[tg]["busy"][prio][manID]
				## do stuff with busy man (that are in tg and working in priority prio), maybe reduce their stamina faster
				## if man is not assigned to his item yet, check if he can be
				if man.itemID!=null && items[man.itemID].jobs[man.jobID].isReady==false:
					if (man.translation-man.targetPos).length()<man.bodyHeight*5: # if human is within his body height close to item
						# man.targetItem.assignManToItem(manID, {"taskGroup": tg, "priority": prio}) # give item and infoDict so that later the item can also tell CrewManager where to find id
						## set the man of the item to "is ready"
						items[man.itemID].jobs[man.jobID].isReady = true


func requestCrew(itemID, jobID, taskGroup, targetPosition : Vector3, priority : int):
	"""
	When a cannon or something requests crew of type taskgroup, this function gets called.
	itemID: id to the item that requested the crew
	amunt: how many men are needed
	jobID: the name of the item specific job 
	taskGroup: from which task group
	"""
	# add the request to tasks array already in the correct order (prio)
	tasks[priority].append({"id": IDGenerator.getID(), "itemID": itemID, "jobID": jobID, "position": targetPosition, "taskGroup": taskGroup})



func findAndAssignBestMen(itemPos : Vector3, taskGroup, priority : int):
	"""
	Searches for the best fitting crew member to do the task and assigns him to item
	searches first men that are completly idle, if none are found searches for man that do less prioritzed work 
	returns manID
	"""
	var foundMen
	var foundID

	## first check idle men in task group
	for id in currentAssignments[taskGroup]["idle"]:
		if true: # TODO: put real check here
			foundMen = currentAssignments[taskGroup]["idle"][id]
			foundID = id
			## put human into busy list and remove from idle list
			currentAssignments[taskGroup]["busy"][priority][id] = foundMen
			currentAssignments[taskGroup]["idle"].erase(id)
			print("Found man for task with prio", priority)
			return foundMen
	## if non are idle or suitable, check busy men from lower priorites, but check the lowest prio first
	for prio in range(numberOfPriorities-1,priority,-1): # doest go to priority, stops at priority+1
		for id in currentAssignments[taskGroup]["busy"][prio]:
			if true: # TODO: put actual condition here
				foundMen = currentAssignments[taskGroup]["busy"][prio][id]
				foundID = id
				## put man in new group and del from old group
				currentAssignments[taskGroup]["busy"][priority][id] = foundMen
				# and unassign from item that he was on, while also allowing the item to directly search for new man
				# foundMen.targetItem.unassignManfromItem(id)
				currentAssignments[taskGroup]["busy"][prio].erase(id)
				print("Found man for task with prio", priority)
				return foundMen


func requestItems(items : Dictionary, priority):
	"""
	When a cannon or something requests items like gunpowder and cannonballs, this function gets called.
	
	"""
	###
	## no more chunking, crew can only carry one unit of anything
	###
	# var itemsChunked = groupItemsIntoChunks(items)
	# for every chunk: 
	# check where items are stored (needs global storage array with positions to calc distance)
	# findClosestItem(pos)
	# that barrel makes then some kind of request crew task, but with target item in it
	# human registers to barrel, fetches item. (what if item then is already gone? - items need to be reserved)
	pass




func makeManIdle(manID : int, tg, priority):
	"""
	move man into the idle group , remove targets on man,
	when man was busy, he was connected to an item, so disconnect him from that
	also when men gets disconnected from item, item needs to request new one
	"""
	var manRef = currentAssignments[tg]["busy"][priority][manID]
	manRef.removeTarget()
	# add to idle
	currentAssignments[tg]["idle"][manID] = manRef
	## remove from busy
	currentAssignments[tg]["busy"][priority].erase(manID)


func forceManintoRelaxed(id):
	""" 
	Called from crew manager when man is too tired and then gets into relax TG
	when that happens, automatically replace the removed man with a man from RELAX[idle] group - if non there take the relax[busy] man that has most health and stamina
	"""
	pass

func registerItem(itemRef):
	""" called from item when item is placed 
	only adds item to item dict and requests the crew (adds taks)"""
	if not items.has(itemRef.id): # could be because of loaded items dictionary
		if Economy.goods.has(itemRef.databaseName):
			print("CM: registered item")
			
			items[itemRef.id] = {"databaseName" : itemRef.databaseName, "jobs": {}} 
			
			# add job data
			for jobID in Economy.goods[itemRef.databaseName]["jobs"]:
				items[itemRef.id].jobs[jobID] = {"manID" : null, "isReady" : false}
				
				# make crew request for each job
				requestCrew(
					itemRef.id, # id of item
					jobID, # id of the item specific job
					Economy.goods[itemRef.databaseName]["jobs"][jobID].tg,  # taskgroup
					Economy.goods[itemRef.databaseName]["jobs"][jobID].posOffset + itemRef.transform.origin,  # position
					Economy.goods[itemRef.databaseName]["jobs"][jobID].priority) # prio
		else:
			print("warning: name not found in economy: ",itemRef.databaseName)

func unregisterItem(itemRef):
	""" called from item when item is placed 
	only removes assigned man from items dict and makes man idle """
	print("CM: unregistered item")
	## iterate all jobs of that item, and remove assigned man from items list
	for jobID in items[itemRef.id].jobs:
		if items[itemRef.id].jobs[jobID].manID != null: 
			var taskGroup = Economy.goods[itemRef.databaseName]["jobs"][jobID].tg
			var priority = Economy.goods[itemRef.databaseName]["jobs"][jobID].priority
			makeManIdle(items[itemRef.id].jobs[jobID].manID, taskGroup, priority)
		items[itemRef.id].jobs[jobID] = {"manID" : null, "isReady" : false}
	# remove item from items list
	items.erase(itemRef.id)
### mayonnace stuff
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
