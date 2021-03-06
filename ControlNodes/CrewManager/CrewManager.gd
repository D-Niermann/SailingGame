extends Node

"""
Assuming this will stay only on player ship and will be a singleton, (its referenced in the GLobalObjectReferencr)
"""

var crewAmount : int  = 0 # number of man on the player ship (managed by this crewManager)
var decks # ref list of all decks on player ship


const JOB_TASK = "taskType:job"
const FETCH_TASK = "taskType:fetch"
## define goods groups
# goods are stored in barrels, each barrel has a group, gunpowder, ammo, food...
# this assignment dictionary helps quickly finding the nearest barrel for the requested good and also keeps track of what goods are inside each item
# are strings ok or int better? int = more performance?
const IG_GUNPOWDER = "igGunpowder" # gunpowder barrels
const IG_AMMO = "igAmmo" # ammo barrels
const IG_FOOD = "igFood" # foodbarrels
const IG_UTILITY = "igUtils" # repairs, stores woods planks, ropes, tools and so on
const IG_GEAR = "igGear" # no storage items like cannons, table and so on - these typically make the requests and have fixed jobs


## define task groups
# if a man is assigned to relax, he stays in relaxed (except panic button is activated). 
# So to add a man to cannons, only look ino WEAPONS group, if there is nobody, do not look into RELAX, the player needs to reassign
const TG_WEAPONS = "tgWeapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tgNavigation"
const TG_UTILITY = "tgUtility"
const TG_RELAX = "tgRelax"

var targetCrewCount = {TG_NAVIGATION : 0, TG_WEAPONS: 0, TG_UTILITY : 0} # tells the manager how many men to assign to what group, this var gets changed by player input


# structure: tasks = [[task1, task2, ...],[task1, task2, ..], ...] with 0th eleemnt being prio 0 and so on, so new tasks are being appended to the correct list, no sorting needed
# a task is a dict: {"id": prio_12,"itemRef": asd, "position": V(0,0,0), "taskGroup": TG_Asd, }
var tasks = [] # list of lists of all queued tasks, this list is always sorted per priority (because tasks get added so), list 0 is high prio, list  99 low prio
var fetchTasks = []
var numberOfPriorities = 5 # how large the tasks list will be

var currentAssignments = {TG_RELAX:       {"idle": {}, "busy": []}, # refs to humans, stored by ID , idle means idle for new work busy means already on item or heading to it
						  TG_WEAPONS:     {"idle": {}, "busy": []}, # TODO: ? make these lists only filled with IDs and then create a separate dict for all crew members refs to access via ID
						  TG_UTILITY:     {"idle": {}, "busy": []}, # "busy" : [{} , {}, {}, ...] priority ordered dicts
						  TG_NAVIGATION:  {"idle": {}, "busy": []}} # these assignments in the busy tab also have the priority herarchy so that code can quickly infer on what priority the man currently is, or if he is idle

var items = {} # {itemID: {"itemRef": ref, "jobs": {jobID1 : {manID : ID, isReady: false}, jobID2 : {}, ...}}} # to quicly find man with manID, check the item.jobID description - it has the TG and prio in it

var itemAssignmentsAndInventory = { # keeps track of all items based on these assignments and also whats stored in their inventory
		IG_GUNPOWDER: {},      # ID: {position : Vec3, inventory : {"goodName1" : {}, "goodName2" : {}}}
		IG_AMMO     : {},      # ID: {position : Vec3, inventory : {"goodName1" : {}, "goodName2" : {}}}
		IG_FOOD     : {},      # ID: {position : Vec3, inventory : {"goodName1" : {}, "goodName2" : {}}}
		IG_UTILITY  : {},      # ID: {position : Vec3, inventory : {"goodName1" : {}, "goodName2" : {}}}
		IG_GEAR     : {},      # ID: {position : Vec3, inventory : {"goodName1" : {}, "goodName2" : {}}}
}

var goodCapacity = {IG_GUNPOWDER : 0, # (how much can be stored on ship)
					IG_AMMO : 0 ,
					IG_FOOD : 0 ,
					IG_UTILITY : 0,
					IG_GEAR : 0}
var goodGroupCount = {IG_GUNPOWDER : 0,  # GGGroup : 0 how many goods are per group on player ship
					IG_AMMO : 0 ,
					IG_FOOD : 0 ,
					IG_UTILITY : 0,
					IG_GEAR : 0} 
var goodCount = {} # goodName : 0 (how much of one good the player ship has)


var sumRigging = 0 # how many man are ready on rigging items

const HUMAN: PackedScene = preload("res://ObjectNodes/Human/Human.tscn")
var requestsToPathfind: Array = []

func _ready():
	## base variable init
	decks = get_tree().get_nodes_in_group("PlayerDeck")
	GlobalObjectReferencer.crewManager = self

	## fetch all humans ( later will get loaded in )
	var humanNodes = get_children()
	crewAmount = len(humanNodes)

	## init all arrays that contain prio arrays
	for i in range((numberOfPriorities)):
		tasks.append([]) 
		fetchTasks.append([])
		currentAssignments[TG_RELAX].busy.append({})
		currentAssignments[TG_WEAPONS].busy.append({})
		currentAssignments[TG_UTILITY].busy.append({})
		currentAssignments[TG_NAVIGATION].busy.append({})

	## init the assignment data
	for i in range(len(humanNodes)):
		currentAssignments[TG_UTILITY]["idle"][humanNodes[i].id] = humanNodes[i]
		humanNodes[i].assignDeck(decks[0])
	
		
	## init the goodCount keys
	for goodkey in Economy.consumables:
		goodCount[goodkey] = 0

func getCrewCount() -> int:
	"""
	Returns the total amount of man on the ship.
	"""
	return crewAmount


func hire(amount : int) -> void: 
	"""
	Called when player selects to hire man from the UI. Adds the amount man to crew 
	"""
	print("Hire: ", amount)
	pass

func fire(amount : int) -> void:
	"""
	Called when player selects to fire man from the UI. removes man from crew
	"""
	print("Fire: ", amount)
	pass

func _physics_process(delta):
	checkAndUpdateMen(delta)
	checkAndLetPathfinding()
	checkAndAssignJobTasks() 
	checkAndAssignFetchTasks()

func checkAndLetPathfinding():
	if !requestsToPathfind.empty():
		requestsToPathfind.shuffle()
		var luckyOne = requestsToPathfind.pop_back()
		luckyOne.who.requestedForPathfinding = false
		luckyOne.who.pathLocs = luckyOne.who.findPath(luckyOne.from, luckyOne.to, true)
#		print("grantedPermissionToFindPath")

func checkAndAssignJobTasks():
	"""
	Go through all open job tasks and assign men if possible.
	"""
	var task
	# get a tasks beginning from prio 0 and the oldest task i that prio
	for p in range(numberOfPriorities):
		for i in range(len(tasks[p])):
			task = tasks[p][i]
			if items.has(task.itemID): # check if item still exists, could be deleted in the main time, task stays in task array when item unregisterd
				## if task is found, find a suitable man
				var hasFound =  findAndAssignBestMen(task)
				if hasFound==true:
					## remove task if man was found
					tasks[p].remove(i)
					## break here to save CPU (only one task per frame gets assigned this way)
					return
			else:
				# task has no item anymore so delete it
				tasks[p].remove(i)
				return



func checkAndAssignFetchTasks():
	"""
	Go through all open fetch tasks and assign men if possible.
	"""
	var task
	# beginning from prio 0 and the oldest task i that prio
	for p in range(numberOfPriorities):
		for i in range(len(fetchTasks[p])):
			task = fetchTasks[p][i]

			if task.storageItemID!= null and not items.has(task.storageItemID): # if storage item is gone, queue new task and remove old one
				requestGood(task.goodName, items[task.targetItemID].itemRef, task.storageIG, task.priority)
				fetchTasks[p].remove(i)
				return
 
			elif items.has(task.targetItemID): # check if target item still exists and if there are any idle man in tg, if so , search man
				## search fo nearest storage barrel item
				var itemFound = searchAndAddNearStorageItem(task)
				if itemFound:
					var manFound =  findAndAssignBestMen(task)
					if manFound == true:
						## reduce item count of the found resource barel
						consumeGood(task.storageIG, task.storageItemID, task.goodName)
						## if inventory of barrel empty, request new items with low priority (this will more or less equally distribute goods in barrels)
						## IDea: track total ammout of each item on the ship and use that number for if check if its high enought to make new barrel request
						# if (task.storageIG == Economy.IG_GUNPOWDER or task.storageIG == Economy.IG_AMMO) and getInventoryCount(task.storageItemID, task.goodName)==0:
							# for _i in range(Economy.getCapacity(items[task.storageItemID].databaseName)[task.goodName]/4):
							# 	print("Warning [Buggy]: Barrel makes request because its empty!")
							# 	requestGood(task.goodName, items[task.storageItemID].itemRef, task.storageIG, numberOfPriorities-1)
						## remove task if man was found
						fetchTasks[p].remove(i)
						## break here to save CPU (only one fetch task per frame gets assigned this way)
						return
				
			else:
				# task has no target item anymore so delete it
				fetchTasks[p].remove(i)
				return
				
func searchAndAddNearStorageItem(task):
	"""
	called when fetch task is searched, adds a suitable storage item to the given task
	"""
	var storageItemRef = null
	var minDist = 9999999
	## search for nearest barrel of item group 
	for id in (itemAssignmentsAndInventory[task.storageIG]):
		if (task.targetItemPos-items[id].itemRef.translation).length()<minDist and itemAssignmentsAndInventory[task.storageIG][id].inventory[task.goodName]>0: 
			minDist = (task.targetItemPos-items[id].itemRef.translation).length()
			storageItemRef = items[id].itemRef
	# add the found item to task  
	if storageItemRef != null:
		task["storageItemID"] = storageItemRef.id 
		task["storageItemPos"] = storageItemRef.transform.origin
		task["storageItemDeck"] = storageItemRef.get_parent() # TODO: inlcude deck search
		return true
	return false


func checkAndUpdateMen(delta):
	"""
	checks if men is able to stay in assigned group, maybe he is too tired or hungry. If a man is tired or hungry, force him into RELAX group, de-assign him from item that he is on.
	Caution: if tired he goes to hammock: then do not remove him from hammock again, he will still be tired, so only check TGs that are non RELAX (?)
	
	TODO: chunk the iteration of all men so that cpu saves ressourced (maybe each frame only check 10 man) -> profiler says 100 man take around 0.18 ms to processess, which is very good
	"""
	var manRef
	
	#########################
	## check difference of the actual assigned crew and the requested crew assignments	
	#########################
	var diff = {} # TODO : calc only when changed targetCrewCount
	for TG in targetCrewCount:
		var count = 0
		for prio in range(numberOfPriorities):
			count+=len(currentAssignments[TG]["busy"][prio])
		diff[TG] = targetCrewCount[TG] - (len(currentAssignments[TG]["idle"])+count)
	for TG in diff:
		if diff[TG]<0:
			## man needs to be removed from TG into relaxed
			## first pick idle man, then the ones with highest priorityNumber
			for manID in currentAssignments[TG]["idle"]:
				# print("force idle into relax: ",manID)
				forceManintoRelaxed(TG, "idle", currentAssignments[TG]["idle"][manID])
				return
			for prio in range(numberOfPriorities-1,-1,-1):
				## reverse prio search
				for manID in currentAssignments[TG]["busy"][prio]:
					print("force busy into relax: ",manID)
					forceManintoRelaxed(TG, "busy", currentAssignments[TG]["busy"][prio][manID])
					return
	
	#########################
	## iterate all men
	#########################
	for TG in currentAssignments: # TODO: partioning idea: only check one TG per frame, (at the end of process(), go change the current TG to the next one)
		
		## IDLE MAN
		for manID in currentAssignments[TG]["idle"]:
			## relaxed idle man
			manRef = currentAssignments[TG]["idle"][manID]
			## check status of man 
			if manRef.S_HUNGRY: # if man is hungry
				if TG != TG_RELAX:
					forceManintoRelaxed(TG, "idle", manRef)
					break
			## do stuff with the idle manRef, like move them randomly or make them group together
					
			# player is only allowed to request as many man as are in relax idle, exept the panic button is pressed, then only allowed as many man as in relaxed
			if TG==TG_RELAX: # move man from idle relax group inot the requested TGs (if panic button is pressed, also move from TG_RELAX, busy group!)
				## search where to put him (where men are needed)
				for diffTG in diff:
					if diff[diffTG]>0: #if men are requested in that TG
						## reassign man (put ref into other assignment group (idle) and remove him from the current one)
						currentAssignments[diffTG]["idle"][manRef.id] = manRef
						## CAUTION: if would be busy, then also would need to unassign from item!
						currentAssignments[TG]["idle"].erase(manID)


		## BUSY MEN
		for prio in range(numberOfPriorities):
			for manID in currentAssignments[TG]["busy"][prio]:
				manRef = currentAssignments[TG]["busy"][prio][manID]
				## check human states and remove them from job when exhausted
				if manRef.S_HUNGRY: # if man is hungry
					if TG != TG_RELAX:
						forceManintoRelaxed(TG, "busy", manRef)
						break
					# else: # hungry man in TG Relax busy
					# 	# search for food storage and assign fetch task
					# 	var task = {"type" : FETCH_TASK, "id": IDGenerator.getID(),
					# 	"taskGroup": TG_RELAX, "goodName": "Apple", "storageIG" : IG_FOOD,
					# 	"targetItemID": null , "targetItemPos" : null , "targetItemDeck" : null ,
					# 	"storageItemID" : null, "storageItemPos" : null, "storageItemDeck" : null,
					# 	"priority": 0}
					# 	manRef.S_SEARCHFOOD = true
					# 	var found = searchAndAddNearStorageItem(task)
					# 	if found: manRef.S_SEARCHFOOD = false

				## check busy man with job tasks (put this into one function like checkManTaskComplete(manRef))
				if manRef.currentTask!= null and manRef.currentTask.type == JOB_TASK: 
					## if manRef is not assigned to his item yet, check if he can be
					if manRef.itemID!=null && items[manRef.itemID].jobs[manRef.jobID].isReady==false:
						if (manRef.translation-manRef.targetPos).length()<manRef.bodyHeight: # if human is within his body height close to item
							setJobToReady(manRef.itemID, manRef.jobID)

					## if manRef is assigned to his item yet, do stuff with him here
					elif manRef.itemID!=null && items[manRef.itemID].jobs[manRef.jobID].isReady==true:
						if manRef.S_HUNGRY: # if man is hungry
							## add up some number (*delta)  on each man to keep track on how long he is sitting on table, then if time is long enough, 
							manRef.eatTime += delta
							## consumeGood(someFood) and increase stamina
							if manRef.eatTime >= manRef.timeTakesToEat:
								var consumed = consumeGood(IG_GEAR, manRef.itemID, "Apples", true) # TODO : Make APPLES more generic, aka random? see what the table has to offer
								if consumed : 
									manRef.eatTime = 0
									manRef.stamina += 0.2 # if stamina is high enough, hungry effect is gone 
									if manRef.stamina > 0.8:
										forceManintoRelaxed(TG, "busy", manRef)
										break

										
				## check busy man with fetch task
				elif manRef.currentTask!= null and manRef.currentTask.type == FETCH_TASK:
					checkManFetchTaskComplete(manRef)
		
func setJobToReady(itemID, jobID):
	## set the isReady flag to true
	items[itemID].jobs[jobID].isReady = true
	## set the crew rating to this item
	items[itemID].crewScore = getCrewScore(itemID)
	## update accumulated data
	if "Rigging" in jobID:
		sumRigging += 1

func checkManFetchTaskComplete(manRef):
	"""
	Checks if man manRef is close to his target item, if so proceeds to next item. checks if items still are defined, if not clears man from task and so on
	"""
	var currTask = manRef.currentTask
	if items.has(currTask.targetItemID) && (items.has(currTask.storageItemID) || manRef.itemID == currTask.targetItemID) :
		## if man is near barrel
		if manRef.itemID!=null && (manRef.translation-manRef.targetPos).length()<manRef.bodyHeight:
			if manRef.itemID == currTask.storageItemID:
				## set the next position and stuff from the fetch task
				manRef.proceedFetchTask()
			else:
				## man has already collected good and now gives good to targetItem
				itemAssignmentsAndInventory[Economy.getIG(items[currTask.targetItemID].databaseName)][manRef.itemID].inventory[currTask.goodName] += 1 # give good to target item
				print("giving item to: ",items[manRef.itemID].itemRef.name, currTask.goodName)
				fromBusyToIdle(manRef.id, currTask.taskGroup, currTask.priority)
	elif not items.has(currTask.storageItemID):
		## if the barrel is removed queue a new request from the targetitem
		print("only barrel is missing") 
		if manRef.itemID == currTask.storageItemID:
			## if target was the barrel that is missing, free the man and make new request
			requestGood(currTask.goodName, items[currTask.targetItemID].itemRef, currTask.storageIG, currTask.priority)
			fromBusyToIdle(manRef.id, currTask.taskGroup, currTask.priority)
	else:
		# target item not there anymore, delete task
		# TODO: add good back to original barrel to bring back item? now, item is just lost
		print("giving up fetch task because target item not there anymore")
		fromBusyToIdle(manRef.id, currTask.taskGroup, currTask.priority)




func requestCrew(itemID, jobID, taskGroup, targetPosition : Vector3, targetDeckRef, priority : int):
	"""
	When a cannon or something requests crew of type taskgroup, this function gets called.
	itemID: id to the item that requested the crew
	amunt: how many men are needed
	jobID: the name of the item specific job 
	taskGroup: from which task group
	"""
	# add the request to tasks array already in the correct order (prio)
	tasks[priority].append({"type" : JOB_TASK, "id": IDGenerator.getID(),
							"itemID": itemID, "jobID": jobID, "position": targetPosition,
							"targetDeckRef" : targetDeckRef, "taskGroup": taskGroup, "priority": priority})



func requestGood(name : String, targetItemRef, storageItemGroup, priority : int):
	"""
	When a cannon or something requests goods like gunpowder and cannonballs, this function gets called.
	Only requests one item at a time, since man can only carry one
	creates task and adds it to task list
	"""
	fetchTasks[priority].append({"type" : FETCH_TASK, "id": IDGenerator.getID(),
								"taskGroup": TG_UTILITY, "goodName": name, "storageIG" : storageItemGroup,
								"targetItemID": targetItemRef.id, "targetItemPos" : targetItemRef.transform.origin, "targetItemDeck" : targetItemRef.get_parent(),
								"storageItemID" : null, "storageItemPos" : null, "storageItemDeck" : null, # is set when actually searching for the storage item
								"priority": priority})

func requestAllGoods(itemRef):
	"""
	If item is placed and all goods need to be requested
	"""
	var capacity = Economy.getCapacity(itemRef.databaseName)
	for good in capacity:
		for i in range(capacity[good]):
			var prio = clamp(i,0,numberOfPriorities-1) # TODO : think aboput how to do priorities here (wall leak objects needs items more than cannons), for now, first item request is always high rpio then it gets lower
			requestGood(good, itemRef, Economy.consumables[good].GG,  prio) 

func findAndAssignBestMen(task):
	"""
	Searches for the best fitting crew member to do the task and assigns him to item
	searches first men that are completly idle, if none are found searches for man that do less prioritzed work 
	returns manID
	"""
	var foundMen = null

	## first check all idle men in task group
	for id in currentAssignments[task.taskGroup]["idle"]:
		foundMen = currentAssignments[task.taskGroup]["idle"][id]
		## Here the found man is checked if suitable for the current task. Down below is another if state that should be identical. TODO: Add near check, same deck check and so on
		if task.taskGroup != TG_RELAX and not foundMen.S_HUNGRY: 
			if task.type == JOB_TASK:
				## assign man the new item target
				fromIdleToBusy(foundMen, task)
				_assignManToItem(foundMen, task)
			elif task.type == FETCH_TASK:
				## for fetch tasks, just assign human to task
				fromIdleToBusy(foundMen, task)
				foundMen.giveFetchTask(task)
			return true
		## for relaxed tasks, other conditions apply
		elif task.taskGroup == TG_RELAX:
			if foundMen.stamina<0.2:
				if task.type == JOB_TASK:
					## assign man the new item target
					fromIdleToBusy(foundMen, task)
					_assignManToItem(foundMen, task)
				return true
	## if non are idle or suitable, check busy men from lower priorites, but check the lowest prio first
	if foundMen!=null and task.taskGroup!=TG_RELAX and task.type == JOB_TASK:
		for oldPrio in range(numberOfPriorities-1,task.priority,-1): # doest go to priority, stops at priority+1
			for id in currentAssignments[task.taskGroup]["busy"][oldPrio]:
				## Here the found man is checked if suitable for the current task. Above is another if state that should be identical. TODO: Add near check, same deck check and so on
				if not foundMen.S_HUNGRY: # TODO: put actual condition here
					foundMen = currentAssignments[task.taskGroup]["busy"][oldPrio][id]
					fromBusyToBusy(foundMen, task, foundMen.currentTask)
					return true

	# if non is found return false
	return false


func _assignManToItem(manRef, task):
	""" simple wrapper function for only assigning a man to an item """
	manRef.giveGoToTask(task) 
	items[task.itemID].jobs[task.jobID].manID = manRef.id


func _unassignManFromItem(manRef):
	""" simple wrapper function for only unassigning a man to an item """
	## search item on what job the man was, TODO: maybe its smarter to give the task dictionary to the manRef?
	for jobID in items[manRef.itemID].jobs:
		# set the item to not having a man on it on that job
		if items[manRef.itemID].jobs[jobID].manID == manRef.id:
			items[manRef.itemID].jobs[jobID].manID = null
			items[manRef.itemID].jobs[jobID].isReady = false
			items[manRef.itemID].crewScore = getCrewScore(manRef.itemID)
			## update summed values
			if "Rigging" in jobID:
				sumRigging -= 1
	manRef.removeTask()
	
	
func fromIdleToBusy(manRef, task):
	"""
	put human into the correct busy assignment
	"""
	## put human into busy list and remove from idle list
	currentAssignments[task.taskGroup]["busy"][task.priority][manRef.id] = manRef
	currentAssignments[task.taskGroup]["idle"].erase(manRef.id)
	


func fromBusyToBusy(manRef, task, oldTask):
	"""
	Move man from priority 'oldPrio' into new priority, that makes him stay in busy assignment but his item switches. 
	Also the new prio is more important than the old one.
	"""
	## put man in new group and del from old group
	currentAssignments[task.taskGroup]["busy"][task.priority][manRef.id] = manRef
	# and unassign from item that he was on,
	_unassignManFromItem(manRef)
	# while also allowing the item to directly search for new man for the task that the man was on
	requestCrew(
		oldTask.itemID, # id of item
		oldTask.jobID, # id of the item specific job
		oldTask.taskGroup,  # taskgroup
		oldTask.position,  # position
		oldTask.targetDeckRef,
		oldTask.priority)

	currentAssignments[task.taskGroup]["busy"][oldTask.priority].erase(manRef.id)
	_assignManToItem(manRef, task)





func fromBusyToIdle(manID : int, tg, priority):
	"""
	move man into the idle group , remove targets on man,
	when man was busy, he was connected to an item, so disconnect him from that
	also when men gets disconnected from item, item needs to request new one
	"""
	var manRef = currentAssignments[tg]["busy"][priority][manID]
	_unassignManFromItem(manRef)
	# add to idle
	currentAssignments[tg]["idle"][manID] = manRef
	## remove from busy
	currentAssignments[tg]["busy"][priority].erase(manID)


func forceManintoRelaxed(currentTaskGroup, currentState, manRef):
	""" 
	Called from crew manager when man is too tired and then gets into relax TG, or if man gets unassigned by player input
	removes man from current assignment and puts him into relaxed idle
	"""
	currentAssignments[TG_RELAX]["idle"][manRef.id] = manRef
	if currentState == "idle":
		## man not working on item
		currentAssignments[currentTaskGroup][currentState].erase(manRef.id)
	elif currentState == "busy":
		## directly call new crew request
		var t = manRef.currentTask
		if t!= null: # can be null if the process already forced into relax but player also quickly changed the assignment sliders?
			if t.type == JOB_TASK:
				requestCrew(t.itemID, t.jobID, t.taskGroup,  t.position, t.targetDeckRef,  t.priority)
			elif t.type == FETCH_TASK:
				## append good again so that it is not lost when often unassigning man and make new request
				itemAssignmentsAndInventory[t.storageIG][t.storageItemID].inventory[t.goodName] += 1
				requestGood(t.goodName, items[t.targetItemID].itemRef, t.storageIG, t.priority)
			## man worked on item
			currentAssignments[currentTaskGroup][currentState][t.priority].erase(manRef.id)
			_unassignManFromItem(manRef)



func registerItem(itemRef):
	""" called from item when item is placed 
	only adds item to item dict and requests the crew (adds taks)"""
	if not items.has(itemRef.id): # could be because of loaded items dictionary
		if Economy.goods.has(itemRef.databaseName):
			var IG = Economy.getIG(itemRef.databaseName) # fetch item group for easy access

			## add item to items dict and itemASsignment dict
			items[itemRef.id] = {"crewScore": 0, "itemRef" : itemRef, "databaseName" : itemRef.databaseName, "jobs": {}} 
			itemAssignmentsAndInventory[IG][itemRef.id] = {"position" : itemRef.translation, "inventory": {}}
			## add item names to inventory based on economy capacity dict
			for key in Economy.getCapacity(itemRef.databaseName):
				itemAssignmentsAndInventory[IG][itemRef.id].inventory[key] = 0
				if IG!=IG_GEAR:
					goodCapacity[Economy.getGG(key)] += Economy.getCapacity(itemRef.databaseName)[key]
			print("capacities: " , goodCapacity)

			## fill inventory for debuggin
			# TODO: delete this part
			# if itemRef.databaseName=="Gunpowder Barrel":
			# 	itemAssignmentsAndInventory[IG][itemRef.id].inventory["Gunpowder"] = Economy.getCapacity(itemRef.databaseName)["Gunpowder"]
			# if itemRef.databaseName=="Ammo Barrel":
			# 	itemAssignmentsAndInventory[IG][itemRef.id].inventory["Cannonballs"] = Economy.getCapacity(itemRef.databaseName)["Cannonballs"]
			
			# request goods
			if IG == IG_GEAR:
				requestAllGoods(itemRef)
				
			# request crew and  add job data
			for jobID in Economy.getJobs(itemRef.databaseName):
				items[itemRef.id].jobs[jobID] = {"manID" : null, "isReady" : false}
				
				# make crew request for each job
				requestCrew(
					itemRef.id, # id of item
					jobID, # id of the item specific job
					Economy.getJobs(itemRef.databaseName)[jobID].TG,  # taskgroup
					Economy.getJobs(itemRef.databaseName)[jobID].posOffset.rotated(itemRef.transform.basis.y,itemRef.rotation.y)  + itemRef.transform.origin,  # position
					itemRef.get_parent(), # deck reference
					Economy.getJobs(itemRef.databaseName)[jobID].priority) # prio
		else:
			print("warning: name not found in economy and thus not  added to crew manager: ",itemRef.databaseName)



func unregisterItem(itemRef):
	""" called from item when item is removed 
	removes item and assigned man from items dict and makes man idle """
	if items.has(itemRef.id):

		## iterate all jobs of that item, and remove assigned man from items list
		print("CM: unregistered item")
		for jobID in items[itemRef.id].jobs:
			if items[itemRef.id].jobs[jobID].manID != null: 
				var taskGroup = Economy.getJobs(itemRef.databaseName)[jobID].TG
				var priority = Economy.getJobs(itemRef.databaseName)[jobID].priority
				fromBusyToIdle(items[itemRef.id].jobs[jobID].manID, taskGroup, priority)
			items[itemRef.id].jobs[jobID] = {"manID" : null, "isReady" : false}
			
		## reduce ships capacity
		if Economy.getIG(itemRef.databaseName)!=IG_GEAR:
			for goodName in Economy.getCapacity(itemRef.databaseName):
				goodCapacity[Economy.getGG(goodName)] -= Economy.getCapacity(itemRef.databaseName)[goodName]
			print("capa: ", goodCapacity)

		## remove item from items list and assignment list
		items.erase(itemRef.id)
		itemAssignmentsAndInventory[Economy.getIG(itemRef.databaseName)].erase(itemRef.id)
		print(itemAssignmentsAndInventory)

func getCapacity(GG_Name : String):
	"""
	return the capacity of the player ship per good group
	"""
	return goodCapacity[GG_Name]

func getGroupAmount(GG_Name : String):
	"""
	return the amount of all goods within the given good group
	"""
	return goodGroupCount[GG_Name]


func getAmount(goodName : String):
	"""
	Returns the amount of the item / good that the player ship holds  
	"""
	return goodCount[goodName]

func addGood(itemGroup : String, itemID, goodName : String) -> bool:
	## check if inventory still has space
	if getInventoryCount(itemID, goodName) < Economy.getCapacity(items[itemID].databaseName)[goodName]:
		## if so, add item to inventory and increase global ship counts
		itemAssignmentsAndInventory[itemGroup][itemID].inventory[goodName] += 1
		goodCount[goodName] += 1
		goodGroupCount[Economy.getGG(goodName)] += 1
		return true
	return false

func consumeGood(itemGroup : String, itemID, goodName : String, requestNew = false) -> bool:
	"""
	Reduces goods in ItemAssignmentAndInventory dictionary
	returns true if good was consumed and false if not (inventory was empty)
	if requestNew is true, the consumed good is directly requested again
	"""
	var amount : int = getInventoryCount(itemID, goodName)
	if amount != null and amount>0:
		itemAssignmentsAndInventory[itemGroup][itemID].inventory[goodName] -= 1
		goodCount[goodName] -= 1
		goodGroupCount[Economy.getGG(goodName)] -= 1

		if requestNew:
			requestGood(goodName,items[itemID].itemRef,Economy.getGG(goodName),clamp(amount-1,0,numberOfPriorities-1)) 
		return true
	return false

func tradeGood(amount : int, goodName : String) -> void:
	"""
	This funciton is called when player is shopping for goods and makes a trade.
	Amount can be positive (buying, adding to ship) or negative (selling, removing from ship) 
	goodName is one of the names in the economy consumables list.
	THis function adds or removes the goods distributed evenly amongst all gear on ship, if buying or selling. 
	"""
	var goodGroup = Economy.getGG(goodName)
	var kind = "buy"
	if amount < 0:
		kind = "sell"
	amount = abs(amount)

	## count how many items of that group are on ship
	var numberOfItems = len(itemAssignmentsAndInventory[goodGroup]) 
	print("Trading count: ", amount)
	print("Group : ", goodGroup)
	print("Number of Containers for selected group: ", numberOfItems)
	## calc how much each container should get
	var amountPerContainer = floor(amount / numberOfItems)
	var rest = fmod(amount, numberOfItems)
	print("Amount per container: ", amountPerContainer)
	print("rest: ", rest)

	if kind == "buy":
		for itemID in itemAssignmentsAndInventory[goodGroup]:
			for _i in range(amountPerContainer):
				if not addGood(goodGroup, itemID, goodName):
					rest += 1 # if good could not be added the rest count is increased
			for _i in range(rest):
				if addGood(goodGroup, itemID, goodName):
					rest-=1
	elif kind == "sell":
		for itemID in itemAssignmentsAndInventory[goodGroup]:
			for _i in range(amountPerContainer):
				if not consumeGood(goodGroup, itemID, goodName):
					rest += 1 # if good could not be added the rest count is increased
			for _i in range(rest):
				if consumeGood(goodGroup, itemID, goodName):
					rest-=1




func setCrewCount(taskGroup, value):
	"""
	sets the amount to the value, has to manage that no more than the max number of man are allowed to be set?
	TODO : Maybe for that also just limit how far up the crew sliders can go
	"""
	targetCrewCount[taskGroup] = value

func getCrewScore(itemID) -> float:
	"""
	called to get to know how much crew is assigned and ready on that item
	maybe later modify it by crews experience
	Returns a score between 0 and 1 - 0 = no crew on item
	"""
	var score = 0.0
	## go through all jobs and see in man are there and ready
	for jobID in items[itemID].jobs:
		if items[itemID].jobs[jobID].isReady: 
			score += 1
	score = score / len(items[itemID].jobs)
	return score

func getInventoryCount(itemID, goodName) -> int:
	"""
	Returns -1 if item is not registered.
	returns the inventory count  of the given item (returning only the count to secure that inventory is not modified)
	"""
	if items.has(itemID):
		return itemAssignmentsAndInventory[Economy.getIG(items[itemID].databaseName)][itemID].inventory[goodName]
	else:
		return -1
