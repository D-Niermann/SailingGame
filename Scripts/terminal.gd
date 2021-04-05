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
var items: Dictionary = {Vector3(0, 0, 0): ["example"]} # arrays of partitions, filled with dynamic stuff which are dumb (can be picked up and dropped)
var live: Dictionary = {} # partitions that are live/spawned already
var data: Dictionary = {"example": {"preset": "example", "xform": Transform.IDENTITY}} # names and properties of every single scene in the world

var image: Image = Image.new() # what we use for maintaining multi-partition stuff, like islands
var picked: Dictionary = {} # like live, but for the multi-partition stuff
var colors: Dictionary = {"0234": {"res": "res://SceneNodes/Islands/Island_Small.tscn", "origin": Vector3(0, 0, 0)}} # like data, but for the multi-partition stuff
var presets: Dictionary = { # constants are not copied over the instance, this is where we summon stuff from, and also check some constant variables from
	"example": {"TYPE": "item", "RES": "res://exampleItem.tscn", "MAXHP": 100, "health": 100}
}


# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_node("ViewportContainer/Viewport")
	camera = viewport.get_node("Camera")
	image.load("res://icon.png")
	Utility.matrix = image # here we set the grid for pathfinding in utility, it'll just use this image, unless we change it for performance reasons


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
	if image != null: # here we do the same loading/unloading thing for multi-partition stuff, like items, it uses the image
		image.lock()
		var codes: Dictionary = {}
		for part in live.keys():
			var pixel: Color = image.get_pixel(fmod(abs(part.x), image.get_width()), fmod(abs(part.z), image.get_height()))
			var code: String = str(stepify(pixel.r, 0.1) * 10) + str(stepify(pixel.g, 0.1) * 10) + str(stepify(pixel.b, 0.1) * 10)
			if pixel != Color.black && !picked.has(code):
				if !colors.has(code):
					continue
				var island = load(colors[code]["res"]).instance()
				viewport.add_child(island)
				island.global_transform.origin = colors[code]["origin"]
				picked[code] = island
			codes[code] = null
		image.unlock()
		for code in picked.keys():
			if !codes.has(code):
				picked[code].queue_free()
				picked.erase(code)
	# running behavior
	for part in units.keys(): # for all partitions that include at least one unit inside
		# getting the array of the units in proximity, that is units in this and adjacent partitions
		adjacent = Utility.findAdjacent(part, CANCROSS, EXTENDED)
		adjacent.append(part)
		var inProx: Array = []
		for partition in adjacent:
			if units.has(partition):
				inProx += units[partition]
		# iterating units
		for unit in part: # for each unit in this part, note that, the inProx array above will be same for all units in this part, so can be used by any
			var holo = null # holo stands for physical representations of units, that is actual scenes in the world, loaded
			var info: Dictionary = data[unit] # info stands for variables of this unit, like health and transform (xform)
			var preset: Dictionary = presets[info["preset"]] # preset has constants of this unit, like max health and resource path
			if live.has(part): # if part of this unit is live, we can find its holo
				holo = viewport.get_node_or_null(unit)
			pass # run specific behavior, you could add any sort of AI here
			# maintaining consistency, we update all necessary data after the behavior, so things don't fall apart
			info["xform"] = info["xform"] # update transform, is a must
			var newPart = Utility.partitionID(info["xform"].origin, PARTSIZE, EXTENDED) # new partition of this unit
			if newPart != part: # if partition has changed, we update and load/unload if necessary
				part.erase(unit)
				if part.empty():
					units.erase(part)
				if !units.has(newPart):
					units[newPart] = []
				units[newPart].append(unit)
			if live.has(newPart): # if new partition is live but unit is not spawned, we spawn it
				if holo == null:
					holo = load(preset["RES"]).instance()
					viewport.add_child(holo)
					holo.name = unit
					holo.global_transform = info["xform"]
			elif holo != null: # if new partition is not live, we kill holo, but it keeps living in the database
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
			var type: String = preset["TYPE"]
			var list: Dictionary = get(type + "s")
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
					info[entry] = preset[entry].duplicate(true)
			info["xform"] = Transform.IDENTITY
			info["xform"].origin = at
			data[unique] = info
			# place in part
			var type: String = preset["TYPE"]
			var list: Dictionary = get(type + "s")
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
