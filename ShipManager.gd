extends Spatial


# Declare member variables here.
var people: Dictionary = {}
var stations: Dictionary = {}
var professions: Dictionary = {"surgery": "surgeon", "repairing": "craftsman", "reloading": "gunner", "firstGunner": "gunner", "secondGunner": "gunner", "thirdGunner": "gunner", "fourthGunner": "gunner", "cooking": "cook"}
var crew: Dictionary = {"surgeon": [], "craftsman": [], "gunner": [], "cook": []}
var jobs: Dictionary = {"surgery": [], "repairing": [], "reloading": [], "firstGunner": [], "secondGunner": [], "thirdGunner": [], "fourthGunner": [], "cooking": []}
var priorities: Array = ["surgery", "repairing", "reloading", "firstGunner", "secondGunner", "thirdGunner", "fourthGunner", "cooking"]

var humans;
export var pitch_factor = 0.1
export var yaw_factor = 0.1
var pitch
var yaw
var hFront
var hBack
var hLeft
var hRight

var def_transform
var height
var ship
export var height_offset = 1.5

# Called when the node enters the scene tree for the first time.
func _ready():
	humans = get_tree().get_nodes_in_group("Ship/Human")
	hFront = $HFront
	hBack = $HBack
	hLeft = $HLeft
	hRight = $HRight
	ship = $Ship
	def_transform = ship.transform
	print(ship)
	
	insertStation(get_node("Testing/Spatial"), ["firstGunner", "secondGunner", "thirdGunner", "fourthGunner"])
	insertPerson(get_node("Testing/Spatial2"))
	insertPerson(get_node("Testing/Spatial3"))
	insertPerson(get_node("Testing/Spatial4"))
	insertPerson(get_node("Testing/Spatial5"))
	insertPerson(get_node("Testing/Spatial6"))
	changeProfession(get_node("Testing/Spatial2"), "gunner")
	changeProfession(get_node("Testing/Spatial3"), "gunner")
	changeProfession(get_node("Testing/Spatial4"), "gunner")
	changeProfession(get_node("Testing/Spatial5"), "gunner")
	changeProfession(get_node("Testing/Spatial6"), "gunner")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# for i in humans:
	# 	print(i)
	# print(global_transform)
	pitch = (hFront.transform.origin.y - hBack.transform.origin.y)*pitch_factor
	yaw = (hLeft.transform.origin.y - hRight.transform.origin.y)*yaw_factor
	height = (hFront.transform.origin.y + hBack.transform.origin.y 
	+ hLeft.transform.origin.y + hRight.transform.origin.y)/4.0
	# rotate(Vector3(0,0,1)
	ship.transform = def_transform.rotated(Vector3(0,0,1),pitch).rotated(Vector3(1,0,0),yaw)
	# ship.rotate(Vector3(0,0,1),pitch)
	ship.transform.origin.y = height+height_offset
	self.transform.origin += self.transform.basis.x*0.02
	# self.transform = self.transform.rotated(Vector3(0,1,0),0.01)
	rotate(Vector3(0,1,0),0.001)

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# var space_state = get_world().direct_space_state
	# # use global coordinates, not local to node
	# var camera = get_node("../Camera")
	
	# var result = space_state.intersect_ray(camera.transform.origin, Vector3(0, -1000,0))
#	print(result)
	
	getJobs()
	runJobs()

# Iterates over each crew member to progress their jobs and exit if they need to do something else.
func runJobs():
	for person in people.keys():
		var properties: Dictionary = people[person]
		var currentJobType = properties["assignedJobType"]
		var currentStation = properties["assignedStation"]
		var profession = properties["profession"]
		if currentJobType != null: # can add more conditions here, like if distance to station is high, it might have to move instead of working
			# progress station's related job
			print("working at " + str(currentStation) + " for " + currentJobType + " as " + profession)
		# check needs, exit job if necessary

# Finds and calls crew to available jobs, according to priority and professions.
func getJobs():
	for jobType in priorities:
		if jobs.has(jobType):
			var jobsOfType: Array = jobs.get(jobType)
			if jobsOfType.empty() || !crew.has(professions[jobType]):
				continue
			var crewOfType: Array = crew.get(professions[jobType])
			if crewOfType.empty():
				continue
			var priority: int = priorities.find(jobType)
			for station in jobsOfType:
				# we search for the correct person for the job
				var closest = null
				var distance = 999999999
				var currentJobType = null
				var currentStation = null
				for member in crewOfType:
					var memberSProperties: Dictionary = people[member]
					currentJobType = memberSProperties["assignedJobType"]
					currentStation = memberSProperties["assignedStation"]
					var profession = memberSProperties["profession"]
					# we can get crew from other stations if priority of this station is higher (means lower as a number)
					# can add more conditions here, like ignoring sleepy crew members, unless panic button is activated
					if (currentJobType == null || priority < priorities.find(currentJobType)) && profession == professions[jobType]:
						# how to check floor number?
						var tempDist = station.global_transform.origin.distance_squared_to(member.global_transform.origin)
						if tempDist < distance || closest == null:
							distance = tempDist
							closest = member
				if closest != null:
					if currentJobType != null:
						jobs[currentJobType].append(currentStation)
						stations[currentStation]["assignedCrew"].erase(closest)
					jobs[jobType].erase(station)
					people[closest]["assignedJobType"] = jobType
					people[closest]["assignedStation"] = station
					stations[station]["assignedCrew"].append(closest)
	# notes: if a member dies then add its station to jobs, if a station is added to ship then add it to jobs and vice versa, stuff like that

# Changes person's profession.
func changeProfession(pointer, profession: String):
	var properties: Dictionary = people[pointer]
	var currentJobType = properties["assignedJobType"]
	var currentStation = properties["assignedStation"]
	if currentJobType != null:
		jobs[currentJobType].append(currentStation)
	properties["assignedJobType"] = null
	properties["assignedStation"] = null
	var currentProfession = properties["profession"]
	if currentProfession != null:
		crew[currentProfession].erase(pointer)
	properties["profession"] = profession
	crew[profession].append(pointer)

# Inserts new station into the circulation.
func insertStation(pointer, jobTypes: Array):
	stations[pointer] = {"assignedCrew": []}
	for jobType in jobTypes:
		jobs[jobType].append(pointer)

# Removes existing station from the circulation.
func removeStation(pointer):
	var properties: Dictionary = stations[pointer]
	for person in properties["assignedCrew"]:
		var personSProperties: Dictionary = people[person]
		personSProperties["assignedJobType"] = null
		personSProperties["assignedStation"] = null
	for jobType in jobs.keys():
		if jobType.has(pointer):
			jobs[jobType].erase(pointer)
	stations.erase(pointer)

# Inserts new person into the circulation.
func insertPerson(pointer):
	people[pointer] = {"assignedJobType": null, "assignedStation": null, "profession": null}

# Removes existing person from the circulation.
func removePerson(pointer):
	var properties: Dictionary = people[pointer]
	var currentJobType = properties["assignedJobType"]
	var currentStation = properties["assignedStation"]
	if currentJobType != null:
		jobs[currentJobType].append(currentStation)
		stations[currentStation]["assignedCrew"].erase(pointer)
	crew["profession"].erase(pointer)
	people.erase(pointer)
