extends Spatial

## define task groups
# if a man is assigned to relax, he stays in relaxed (except panic button is activated). 
# So to add a man to cannons, only look ino WEAPONS group, if there is nobody, do not look into RELAX, the player needs to reassign
const TG_WEAPONS = "tg-weapons" # are strings ok or int better? int = more performance?
const TG_NAVIGATION = "tg-navigation"
const TG_UTILITY = "tg-utility"
const TG_RELAX = "tg-relax"

var myShip # parent ship of this manager

var currentAssignments = {TG_RELAX: [], TG_WEAPONS: [], TG_UTILITY: [], TG_NAVIGATION: []} # crewIDs
var crew = {} # crewID: {ref (referenceOfTheCrew), type (typeOfTheCrew), job (jobID), inventory, tired, xform (localTransform),..}
var jobs = {} # jobID: {ref (referenceOfTheItem), name (nameOfTheJob), crew (crewID), refName (refID in baseItem for loadGame)}
var jobSpecs = {} # nameOfTheJob: {type (typeOfTheJob), priority (priorityOfTheJob)}

const HUMAN: PackedScene = preload("res://ObjectNodes/Human/Human.tscn")

func _ready():
	myShip = get_parent()
	repopulate()
	reconnectJobs()

func _physics_process(delta):
	checkAndUpdate()
	matchJobsToCrew()

func reconnectJobs():
	"""
	Reconnects item references with the help of refName in their data.
	"""
	#???
	pass

func repopulate():
	"""
	Deletes all children, iterates over crew data, and recreates their instances.
	"""
	for child in get_children():
		child.queue_free()
	for crewID in crew.keys():
		var crewSpec = crew[crewID]
		var newHuman = HUMAN.instance()
		add_child(newHuman)
		newHuman.transform = crewSpec["xform"]

func checkAndUpdate():
	"""
	Iterates over crew members, checks their status, runs their AI for pathfinding etc., and updates their locations.
	"""
	for crewID in crew.keys():
		var crewSpec = crew[crewID]
		#???

func matchJobsToCrew():
	"""
	Tries to match existing but not picked jobs, to the closest crew member of that job type.
	"""
	for key in jobs.keys():
		var job = jobs[key]
		var crewID = job["crew"]
		if crewID != null: # this job is already getting done by someone
			continue
		var jobSpec = jobSpecs[job["name"]]
		var jobType = jobSpec["type"]
		var jobPriority = jobSpec["priority"]
		var jobReference = job["ref"]
		var closest = null
		var distance = 999999999
		for crewIDTwo in currentAssignments[jobType]:
			var crewSpec = crew[crewIDTwo]
			var crewJob = crewSpec["job"]
			var crewPriority = jobSpecs[jobs[crewJob]["name"]]["priority"]
			if crewJob != null && crewPriority <= jobPriority: # this crew is already getting done some job with equal or less priority
				continue
			var crewReference = crewSpec["ref"]
			var tempDist = jobReference.transform.origin.distance_squared_to(crewReference.transform.origin) # may want to use path length instead
			if tempDist < distance:
				distance = tempDist
				closest = crewIDTwo
		if closest != null: # means a suitable crew member is found to do the job
			var crewSpec = crew[closest]
			var crewOldJob = crewSpec["job"]
			jobs[crewOldJob]["crew"] = null
			crewSpec["job"] = key
			job["crew"] = closest
			break # only one job gets matched in a physics frame, to prevent performance issues

func removeJob(jobID):
	"""
	Removes an existing job from the list.
	"""
	crew[jobs[jobID]["crew"]]["job"] = null
	jobs.erase(jobID)

func removeCrew(crewID):
	"""
	Deletes an existing crew.
	"""
	jobs[crew[crewID]["job"]]["crew"] = null
	crew.erase(crewID)
	crew.queue_free()

func insertJob(nameOfTheJob, reference):
	"""
	Puts a new job on the list.
	"""
	var ID = 0
	while jobs.has(ID):
		ID += 1
	jobs[ID] = {"crew": null, "name": nameOfTheJob, "ref": reference}

func insertCrew(reference):
	"""
	Creates new crew on board.
	"""
	var ID = 0
	while crew.has(ID):
		ID += 1
	crew[ID] = {"job": null, "type": TG_RELAX, "ref": reference, "xform": Transform.IDENTITY}
	currentAssignments[TG_RELAX].append(ID)
	var newHuman = HUMAN.instance()
	add_child(newHuman)
	newHuman.transform = crew[ID]["xform"]

func changeType(crewID, newType):
	"""
	Changes current assignment of the given crew to the given type.
	"""
	var oldType = crew[crewID]["type"]
	if oldType != newType:
		currentAssignments[oldType].erase(crewID)
		currentAssignments[newType].append(crewID)
		var oldJob = crew[crewID]["job"]
		if oldJob != null && jobSpecs[jobs[oldJob]["name"]]["type"] != newType:
			jobs[oldJob]["crew"] = null
			crew[crewID]["job"] = null


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
