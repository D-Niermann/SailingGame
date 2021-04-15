extends Control


var time: int = 0
var frac: float = 0.0
var updatePeriodForEconomy: float = 60.0

const PARTSIZE: float = 64.0 # width of each partition
const EXTENDED: bool = false # if the grid is 3D, or 2D
const CANCROSS: bool = true # if moving crosswise is possible
var viewport: Viewport = null
var camera: Camera = null
var walls: Dictionary = {} # arrays of partitions, filled with static stuff
var units: Dictionary = {} # arrays of partitions, filled with dynamic stuff which are intelligent (self-driving)
var items: Dictionary = {} # {Vector3(0, 0, 0): ["example"]} # arrays of partitions, filled with dynamic stuff which are dumb (can be picked up and dropped)
var live: Dictionary = {} # partitions that are live/spawned already
var data: Dictionary = {} # {"example": {"preset": "example", "xform": Transform.IDENTITY}} # names and properties of every single scene in the world

var wars: Dictionary = {
	"spanish": ["french"],
	"french": ["spanish"]
}
var flags: Dictionary = {
	Color(1.0, 1.0, 0.0): "spanish",
	Color(0.0, 0.0, 1.0): "french",
	Color(0.0, 0.0, 0.0): "pirates"
}
var dominions: Image = Image.new() # what we use for defining regions, like what part of the world belongs to whom
var topograph: Image = Image.new() # what we use for maintaining multi-partition stuff, like islands
var picked: Dictionary = {} # like live, but for the multi-partition stuff
var colors: Dictionary = { # like data, but for the multi-partition stuff
	"010": {"res": "res://SceneNodes/Islands/dummyIslandOne.tscn", "origin": Vector3(1, 0, 1)},
	"020": {"res": "res://SceneNodes/Islands/dummyIslandTwo.tscn", "origin": Vector3(1, 0, 6)},
	"030": {"res": "res://SceneNodes/Islands/dummyIslandThree.tscn", "origin": Vector3(5, 0, 1)}
}
var presets: Dictionary = { # constants are not copied over the instance, this is where we summon stuff from, and also check some constant variables from
	"example": {"CON": "units", "RES": "res://exampleItem.tscn", "TYPE": "trade", "SPEED": 1, "MAXHP": 100, "health": 100, "weight": 1, "side": "spanish", "pack": []}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_node("ViewportContainer/Viewport")
	camera = viewport.get_node("Camera")
	topograph.load("res://topograph.png")
	dominions.load("res://dominions.png")
	Utility.topograph = topograph # map for loading islands and also for pathfinding
	Utility.dominions = dominions # map for goalfinding and pathfinding, shows regions
	#spawn("example", Utility.partitionLocation(Vector3(0, 0, 0), PARTSIZE, false))


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# pause, a menu may be added later on
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
	# advancing time
	if !get_tree().paused:
		frac += delta
	if frac > 1.0:
		frac -= 1.0
		var newTime: int = time + 1
		if floor(newTime / updatePeriodForEconomy) > floor(time / updatePeriodForEconomy):
			# fluctuating prices
			Economy.cycle()
			var shopping = get_tree().get_root().get_node_or_null("GameWorld/Interface/Shopping")
			if shopping.open != null:
				shopping.updateList()
		time = newTime
	# loading world
	var current: Vector3 = Utility.partitionID(camera.global_transform.origin, PARTSIZE, EXTENDED) # current partition
	var adjacent: Array = Utility.findAdjacent(current, CANCROSS, EXTENDED) # adjacent partitions
	adjacent.append(current) # plus the current partition
	var copy: Dictionary = live.duplicate()
	for part in adjacent: # here we check and load any "not live yet" adjacent partitions
		if !live.has(part):
			insertPart(part)
			live[part] = null
			copy.erase(part)
	for part in copy.keys(): # here we check and unload any "live yet needs to die" partitions, partitions that are far away
		if Utility.chebyshevDistance(current, part) > 2:
			removePart(part)
			live.erase(part)
			copy.erase(part)
	# loading image
	if topograph != null: # here we do the same loading/unloading thing for multi-partition stuff, like items, it uses the image
		var codes: Dictionary = {}
		topograph.lock()
		for part in live.keys():
			if part.x < 0 || part.z < 0 || part.x > topograph.get_width() - 1 || part.z > topograph.get_height() - 1:
				continue
			var pixel: Color = topograph.get_pixel(part.x, part.z)
			var code: String = str(stepify(pixel.r, 0.1) * 10) + str(stepify(pixel.g, 0.1) * 10) + str(stepify(pixel.b, 0.1) * 10)
			if pixel != Color.black && !picked.has(code):
				if !colors.has(code):
					continue
				var island = load(colors[code]["res"]).instance()
				viewport.add_child(island)
				island.global_transform.origin = Utility.partitionLocation(colors[code]["origin"], PARTSIZE, false)
				picked[code] = island
				#print("loaded: " + str(code))
			codes[code] = null
		topograph.unlock()
		for code in picked.keys():
			if !codes.has(code):
				picked[code].queue_free()
				picked.erase(code)
				#print("unloaded: " + str(code))
	# running behavior
	for part in units.keys(): # for all partitions that include at least one unit inside
		# getting the array of the units in proximity, that is units in this and adjacent partitions
		adjacent = Utility.findAdjacent(part, CANCROSS, EXTENDED)
		adjacent.append(part)
		var inProx: Dictionary = {}
		for partition in adjacent:
			if units.has(partition):
				for unit in units[partition]:
					inProx[unit] = data[unit]
		# iterating units
		for unit in units[part]: # for each unit in this part, note that, the inProx array above will be same for all units in this part, so can be used by any
			var holo = runAI(unit, part, inProx, delta)
			# maintaining consistency, we update all necessary data after the behavior, so things don't fall apart
			var info: Dictionary = data[unit]
			var newPart = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED) # new partition of this unit
			if newPart != part: # if partition has changed, we update and load/unload if necessary
				units[part].erase(unit)
				if units[part].empty():
					units.erase(part)
				if !units.has(newPart):
					units[newPart] = []
				units[newPart].append(unit)
			if live.has(newPart): # if new partition is live but unit is not spawned, we spawn it
				if holo == null:
					print("spawned")
					holo = load(presets[info["preset"]]["RES"]).instance()
					viewport.add_child(holo)
					holo.name = unit
					holo.global_transform = info["xform"]
			elif holo != null: # if new partition is not live, we kill holo, but it keeps living in the database
				print("destroyed")
				holo.queue_free()


# Loads the given part of the world.
func insertPart(part):
	if walls.has(part):
		for wall in walls[part]:
			var info: Dictionary = data[wall]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = wall
			holo.global_transform = info["xform"]
	if units.has(part):
		for unit in units[part]:
			var info: Dictionary = data[unit]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = unit
			holo.global_transform = info["xform"]
	if items.has(part):
		for item in items[part]:
			var info: Dictionary = data[item]
			var preset: Dictionary = presets[info["preset"]]
			var holo = load(preset["RES"]).instance()
			viewport.add_child(holo)
			holo.name = item
			holo.global_transform = info["xform"]


# Unloads the given part of the world.
func removePart(part):
	if walls.has(part):
		for wall in walls[part]:
			var holo = viewport.get_node_or_null(wall)
			if holo != null:
				holo.queue_free()
	if units.has(part):
		for unit in units[part]:
			var holo = viewport.get_node_or_null(unit)
			if holo != null:
				holo.queue_free()
	if items.has(part):
		for item in items[part]:
			var holo = viewport.get_node_or_null(item)
			if holo != null:
				holo.queue_free()


# Spawns node from data, or creates new from preset. Everytime you create/spawn something that should persist as data, use this.
func spawn(key: String, at: Vector3):
	var target: Vector3 = Utility.partitionID(at, PARTSIZE, EXTENDED)
	var info = data.get(key)
	# if exists, reposition
	if info != null:
		var current = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED)
		info["xform"].origin = at
		# if parts are different, switch
		if target != current:
			var preset: Dictionary = presets[info["preset"]]
			var type: String = preset["CON"]
			var list: Dictionary = get(type)
			if list.has(current):
				list[current].erase(key)
				if list[current].empty():
					list.erase(current)
			if !list.has(target):
				list[target] = []
			list[target].append(key)
		# if part is live, summon
		if live.has(target):
			var holo = viewport.get_node_or_null(key)
			if holo == null:
				var preset: Dictionary = presets[info["preset"]]
				holo = load(preset["RES"]).instance()
				viewport.add_child(holo)
				holo.name = key
			holo.global_transform = info["xform"]
		elif live.has(current):
			var holo = viewport.get_node_or_null(key)
			if holo != null:
				holo.queue_free()
	# if doesn't exist, create and position
	else:
		var preset = presets.get(key)
		if preset != null:
			var unique: String = findName(key)
			info = {}
			info["preset"] = key
			for entry in preset.keys():
				if entry.to_lower()[0] == entry[0]:
					if preset[entry] is Array || preset[entry] is Dictionary:
						info[entry] = preset[entry].duplicate(true)
					else:
						info[entry] = preset[entry]
			info["xform"] = Transform.IDENTITY
			info["xform"].origin = at
			data[unique] = info
			# place in part
			var type: String = preset["CON"]
			var list: Dictionary = get(type)
			if !list.has(target):
				list[target] = []
			list[target].append(unique)
			# if part is live, summon
			if live.has(target):
				var holo = load(preset["RES"]).instance()
				viewport.add_child(holo)
				holo.name = unique
				holo.global_transform.origin = at


# Finds unique name to be used in data for a given preset name. Simply checks database and tries to make up a unique name for a new entity.
func findName(key: String):
	var number: int = 1
	var suggestion: String = key
	while data.has(suggestion):
		number += 1
		suggestion = key + "@" + str(number)
	return suggestion


# Runs artificial intelligence for the given unit.
func runAI(unit: String, part: Vector3, inProx: Dictionary, delta: float):
#	If I was a ship:
#	- I'd have a class like pirate, trade, military; and a faction like spanish, french, whatnot
#	- I'd have an end goal depending on my class or faction or current cargo or health
#	- I'd get list of ships nearby
#	- I'd categorize them as ally, neutral, enemy
#	- I'd do some risk management depending on total powers or perhaps powers at directions
#	- If I could, I'd like to keep pursuing my goal, (follow route if trading, attack enemy if pirate or military)
#	- If my goal doesn't seem plausible, I'd create a temporary goal to follow till the conditions change (flee or fight, probably trying to flee, but also shooting whenever possible, as you have suggested once)
	var dest = null
	var holo = null # holo stands for physical representations of units, that is actual scenes in the world, loaded
	var info: Dictionary = data[unit] # info stands for variables of this unit, like health and transform (xform)
	var preset: Dictionary = presets[info["preset"]] # preset has constants of this unit, like max health and resource path
	var side: String = info["side"]
	var type: String = preset["TYPE"]
#	var task: String = info["task"]
	var pack: Array = info["pack"]
	if live.has(part): # if part of this unit is live, we can find its holo
		holo = viewport.get_node_or_null(unit)
	var wait = info.get("wait")
	if wait != null: # waits if set to wait
		print("waiting")
		wait -= delta
		if wait <= 0:
			info.erase("wait")
	else:
		var goal = info.get("goal")
		var follow = info.get("follow")
		if follow != null:
			print("following")
			var followUnit = units.get(follow)
			if followUnit != null:
				var followPart = Utility.partitionID(followUnit["xform"].origin, PARTSIZE, false)
				if followPart != goal:
					goal = followPart
		if goal == null: # finds goal if doesn't have one
			print("goalfinding")
			if type == "trade":
				var targetShop = null
				var targetPart = null
				dominions.lock()
				var targetDistance = 999999999
				var highestProfit: float = -1
				for mallName in Economy.malls.keys():
					var profit: float = 0
					var mall: Dictionary = Economy.malls[mallName]
					var mallPart: Vector3 = mall["part"]
					var pixelColor: Color = dominions.get_pixel(mallPart.x, mallPart.z)
					var mallSide: String = flags[pixelColor]
					if wars.has(side) && wars[side].has(mallSide):
						continue
					for item in pack:
						profit += Economy.getPrice(item, mallName)
					var dist = Utility.chebyshevDistance(part, mallPart)
					if profit > highestProfit || (profit == highestProfit && dist < targetDistance):
						highestProfit = profit
						targetDistance = dist
						targetShop = mallName
						targetPart = mallPart
				dominions.unlock()
				info["goal"] = targetPart
			elif type == "pirate":
				pass
			elif type == "military":
				pass
		elif goal != part: # needs path if is not at goal
			var path = info.get("path")
			if path == null: # finds path if doesn't have one
				print("pathfinding")
				var filter: Array = []
				if wars.has(side):
					filter = wars[side].duplicate()
				info["path"] = Utility.findPath(part, goal, true, false, filter)
#			elif path[0] != goal: # changes goal if can't reach
#				pass
			else: # follows path
				var dist: int = Utility.chebyshevDistance(part, path[-1])
				if dist == 0: # if reached, remove waypoint
					path.pop_back()
					if path.empty():
						info.erase("path")
				elif dist > 1: # if distant, clear path, so can search from scratch
					info.erase("path")
				else: # go towards the next waypoint
					dest = path[-1]
		else: # works at goal
			if info.has("path"):
				info.erase("path")
			pass
			
		
	if holo != null: # runs when unit is live
		var results: Dictionary
		var controller = holo.get_node_or_null("AIController")
		if controller != null:
			var temp: Vector3 = Utility.partitionLocation(dest, PARTSIZE, false)
			results = controller.update(Vector2(temp.x, temp.z), inProx)
		info["xform"] = holo.global_transform # at the end, update transform
	else: # runs when unit is offscreen
		# move transform
		var direction = Vector3.ZERO
		if dest != null:
			direction = (dest - part).normalized()
		# update transform
		if direction != Vector3.ZERO:
			info["xform"].origin += direction * delta * preset["SPEED"] / info["weight"]
			info["xform"] = info["xform"].looking_at(info["xform"].origin + direction, Vector3.UP)
		#print(info["xform"].origin)
	
	return holo
